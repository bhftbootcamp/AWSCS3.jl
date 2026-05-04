using .Util: byte_cursor, assert_nonnull

#__ runtime

mutable struct RuntimeState
    initialized::Bool
    refcount::Int
    allocator::Ptr{Libaws_c_s3.aws_allocator}
end

const RUNTIME_LOCK = ReentrantLock()
const RUNTIME_STATE = RuntimeState(false, 0, Ptr{Libaws_c_s3.aws_allocator}(C_NULL))
const RUNTIME_ATEXIT_REGISTERED = Ref(false)

function init_runtime!(alloc::AllocPtr)::Nothing
    aws_common_library_init(alloc)
    io_init(alloc)
    http_init(alloc)
    auth_init(alloc)
    Libaws_c_s3.aws_s3_library_init(alloc)
    return nothing
end

function runtime_cleanup!()::Nothing
    Libaws_c_s3.aws_s3_library_clean_up()
    auth_cleanup()
    http_cleanup()
    io_cleanup()
    common_cleanup()
    return nothing
end

function register_runtime_atexit!()::Nothing
    if !RUNTIME_ATEXIT_REGISTERED[]
        atexit(() -> force_shutdown_runtime!())
        RUNTIME_ATEXIT_REGISTERED[] = true
    end
    return nothing
end

function ensure_runtime!(alloc::AllocPtr = default_allocator())::AllocPtr
    lock(RUNTIME_LOCK)
    try
        if !RUNTIME_STATE.initialized
            init_runtime!(alloc)
            RUNTIME_STATE.initialized = true
            RUNTIME_STATE.refcount = 1
            RUNTIME_STATE.allocator = alloc
            register_runtime_atexit!()
        else
            alloc != RUNTIME_STATE.allocator && error("ensure_runtime! called with different allocator")
            RUNTIME_STATE.refcount += 1
        end
        return RUNTIME_STATE.allocator
    finally
        unlock(RUNTIME_LOCK)
    end
end

function force_shutdown_runtime!()::Nothing
    do_cleanup = false
    lock(RUNTIME_LOCK)
    try
        if RUNTIME_STATE.initialized
            do_cleanup = true
            RUNTIME_STATE.initialized = false
            RUNTIME_STATE.refcount = 0
            RUNTIME_STATE.allocator = Ptr{Libaws_c_s3.aws_allocator}(C_NULL)
        end
    finally
        unlock(RUNTIME_LOCK)
    end
    do_cleanup && runtime_cleanup!()
    return nothing
end

function shutdown_runtime!()::Nothing
    do_cleanup = false
    lock(RUNTIME_LOCK)
    try
        !RUNTIME_STATE.initialized && return nothing
        RUNTIME_STATE.refcount = max(0, RUNTIME_STATE.refcount - 1)
        if RUNTIME_STATE.refcount == 0
            do_cleanup = true
            RUNTIME_STATE.initialized = false
            RUNTIME_STATE.allocator = Ptr{Libaws_c_s3.aws_allocator}(C_NULL)
        end
    finally
        unlock(RUNTIME_LOCK)
    end
    do_cleanup && runtime_cleanup!()
    return nothing
end

#__ constants

const DEFAULT_USER_AGENT = "AWSCS3.jl"
const DEFAULT_CONNECT_TIMEOUT_MS = 3000
const DEFAULT_TLS_ENABLED = true
const DEFAULT_THROUGHPUT_TARGET_GBPS = 10.0
const DEFAULT_MAX_PART_SIZE = UInt64(2_147_483_648)
const EMPTY_CURSOR = ByteCursor(0, Ptr{UInt8}(C_NULL))

function _normalize_host(host::String)::String
    host = replace(strip(host), r"^https?://" => "")
    host = rstrip(host, '/')
    isempty(host) && throw(ArgumentError("host must not be empty"))
    return host
end

#__ S3Config

"""
    S3Config

Configuration for creating an [`S3Client`](@ref).

## Fields
- `host::String`: S3 endpoint hostname (e.g. `"s3.amazonaws.com"`).
- `region::String`: AWS region.
- `access_key::String`: Access key ID.
- `secret_key::String`: Secret access key.
- `user_agent::String`: User agent string (default `"AWSCS3.jl"`).
- `connect_timeout_ms::Int`: Connection timeout in milliseconds (default `3000`).
- `tls::Bool`: Whether to use TLS (default `true`).
"""
Base.@kwdef struct S3Config
    host::String
    region::String
    access_key::String
    secret_key::String
    user_agent::String = DEFAULT_USER_AGENT
    connect_timeout_ms::Int = DEFAULT_CONNECT_TIMEOUT_MS
    tls::Bool = DEFAULT_TLS_ENABLED
end

_redact(s::String)::String = isempty(s) ? "" : "***"
_redact(bytes::Vector{UInt8})::String = isempty(bytes) ? "" : "***"

function Base.show(io::IO, c::S3Config)::Nothing
    print(io,
        "S3Config(",
        "host=", repr(c.host),
        ", region=", repr(c.region),
        ", access_key=", repr(_redact(c.access_key)),
        ", secret_key=", repr(_redact(c.secret_key)),
        ", user_agent=", repr(c.user_agent),
        ", connect_timeout_ms=", c.connect_timeout_ms,
        ", tls=", c.tls,
        ")",
    )
    return nothing
end

#__ S3Client

struct ClientPinnedBytes
    region_bytes::Vector{UInt8}
    access_key_bytes::Vector{UInt8}
    secret_key_bytes::Vector{UInt8}
    user_agent_bytes::Vector{UInt8}
end

"""
    S3Client

Client for AWS S3-compatible storage.
Manages connections, credentials, and request lifecycle via the AWS C SDK.

## Constructors
- `S3Client(; host, region, access_key, secret_key, ...)` — create from keyword arguments.
- `S3Client(cfg::S3Config)` — create from an [`S3Config`](@ref).
- `S3Client(f::Function; kwargs...)` — executes `f(client)` then calls [`shutdown!`](@ref).

## Examples

```julia
S3Client(
    host = "s3.amazonaws.com",
    region = "us-east-1",
    access_key = ENV["AWS_ACCESS_KEY_ID"],
    secret_key = ENV["AWS_SECRET_ACCESS_KEY"],
) do client
    put_object(client, "my-bucket", "hello.txt", "Hello, World!")
    body = get_object(client, "my-bucket", "hello.txt") |> String
    objects = list_objects(client, "my-bucket"; prefix = "hello")
    delete_object(client, "my-bucket", "hello.txt")
end
```
"""
mutable struct S3Client
    host::String
    alloc::Ptr{Libaws_c_s3.aws_allocator}
    client::Ptr{Libaws_c_s3.aws_s3_client}
    signing_config::Ref{Libaws_c_s3.aws_signing_config_aws}
    signing_config_ptr::Ptr{Libaws_c_s3.aws_signing_config_aws}
    bootstrap::Ptr{Libaws_c_s3.aws_client_bootstrap}
    resolver::Ptr{aws_host_resolver}
    event_loop_group::Ptr{aws_event_loop_group}
    credentials::Ptr{Libaws_c_s3.aws_credentials_provider}
    client_config::Ref{Libaws_c_s3.aws_s3_client_config}
    pinned::ClientPinnedBytes
    lifecycle_lock::ReentrantLock
    inflight_requests::Int
    closed::Bool
end

function _client_display_fields(c::S3Client)
    return (
        region = String(c.pinned.region_bytes),
        user_agent = String(c.pinned.user_agent_bytes),
        connect_timeout_ms = Int(c.client_config[].connect_timeout_ms),
        tls = c.client_config[].tls_mode == Libaws_c_s3.AWS_MR_TLS_ENABLED,
    )
end

function Base.show(io::IO, c::S3Client)::Nothing
    f = _client_display_fields(c)
    print(io,
        "S3Client(",
        "host=", repr(c.host),
        ", region=", repr(f.region),
        ", user_agent=", repr(f.user_agent),
        ", connect_timeout_ms=", f.connect_timeout_ms,
        ", tls=", f.tls,
        ", access_key=", repr(_redact(c.pinned.access_key_bytes)),
        ", secret_key=", repr(_redact(c.pinned.secret_key_bytes)),
        ", open=", isopen(c),
        ")",
    )
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", c::S3Client)::Nothing
    get(io, :compact, false) && return show(io, c)
    f = _client_display_fields(c)
    print(io,
        "S3Client\n",
        "  host: ", repr(c.host), "\n",
        "  region: ", repr(f.region), "\n",
        "  user_agent: ", repr(f.user_agent), "\n",
        "  connect_timeout_ms: ", f.connect_timeout_ms, "\n",
        "  tls: ", f.tls, "\n",
        "  access_key: ", repr(_redact(c.pinned.access_key_bytes)), "\n",
        "  secret_key: ", repr(_redact(c.pinned.secret_key_bytes)), "\n",
        "  status: ", isopen(c) ? "open" : "closed",
    )
    return nothing
end

#__ constructors

function create_client_config(
    region_cur::ByteCursor, bootstrap, signing_config_ptr,
    connect_timeout_ms::Int, tls_enabled::Bool,
)::Ref{Libaws_c_s3.aws_s3_client_config}
    connect_timeout_ms < 0 && throw(ArgumentError("connect_timeout_ms must be non-negative"))
    tls_mode = tls_enabled ? Libaws_c_s3.AWS_MR_TLS_ENABLED : Libaws_c_s3.AWS_MR_TLS_DISABLED
    return Ref(Libaws_c_s3.aws_s3_client_config(
        UInt32(64),
        region_cur,
        bootstrap,
        tls_mode,
        Ptr{Libaws_c_s3.aws_tls_connection_options}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_file_io_options}(C_NULL),
        signing_config_ptr,
        UInt64(0),
        UInt64(0),
        UInt64(0),
        DEFAULT_THROUGHPUT_TARGET_GBPS,
        DEFAULT_MAX_PART_SIZE,
        Ptr{Libaws_c_s3.aws_retry_strategy}(C_NULL),
        Libaws_c_s3.AWS_MR_CONTENT_MD5_DISABLED,
        Ptr{Libaws_c_s3.aws_s3_client_shutdown_complete_callback_fn}(C_NULL),
        Ptr{Cvoid}(C_NULL),
        Ptr{Libaws_c_s3.aws_http_proxy_options}(C_NULL),
        Ptr{Libaws_c_s3.proxy_env_var_settings}(C_NULL),
        UInt32(connect_timeout_ms),
        Ptr{Libaws_c_s3.aws_s3_tcp_keep_alive_options}(C_NULL),
        Ptr{Libaws_c_s3.aws_http_connection_monitoring_options}(C_NULL),
        false,
        Csize_t(0),
        false,
        Ptr{Libaws_c_s3.aws_s3express_provider_factory_fn}(C_NULL),
        Ptr{Cvoid}(C_NULL),
        Ptr{Libaws_c_s3.aws_byte_cursor}(C_NULL),
        Csize_t(0),
        Ptr{Libaws_c_s3.aws_s3_buffer_pool_factory_fn}(C_NULL),
        Ptr{Cvoid}(C_NULL),
    ))
end

function S3Client(;
    alloc::AllocPtr = default_allocator(),
    host::String,
    region::String,
    access_key::String,
    secret_key::String,
    user_agent::String = DEFAULT_USER_AGENT,
    connect_timeout_ms::Int = DEFAULT_CONNECT_TIMEOUT_MS,
    tls::Bool = DEFAULT_TLS_ENABLED,
)::S3Client
    host = _normalize_host(host)

    runtime_attached = false
    event_loop_group = Ptr{aws_event_loop_group}(C_NULL)
    resolver = Ptr{aws_host_resolver}(C_NULL)
    bootstrap = Ptr{Libaws_c_s3.aws_client_bootstrap}(C_NULL)
    credentials = Ptr{Libaws_c_s3.aws_credentials_provider}(C_NULL)
    client = Ptr{Libaws_c_s3.aws_s3_client}(C_NULL)

    try
        alloc = ensure_runtime!(alloc)
        runtime_attached = true

        event_loop_group = assert_nonnull(event_loop_group_new(alloc), "aws_event_loop_group_new_default")
        resolver_opts = Ref(aws_host_resolver_default_options(32, event_loop_group, C_NULL, C_NULL))
        resolver = assert_nonnull(host_resolver_new_default(alloc, resolver_opts), "aws_host_resolver_new_default")
        bootstrap_opts = Ref(aws_client_bootstrap_options(event_loop_group, resolver, C_NULL, C_NULL, C_NULL))
        bootstrap = assert_nonnull(client_bootstrap_new(alloc, bootstrap_opts), "aws_client_bootstrap_new")

        access_key_bytes = Vector{UInt8}(codeunits(access_key))
        secret_key_bytes = Vector{UInt8}(codeunits(secret_key))
        creds_opts = Ref(
            aws_credentials_provider_static_options(
                Libaws_c_s3.aws_credentials_provider_shutdown_options(C_NULL, C_NULL),
                byte_cursor(access_key_bytes), byte_cursor(secret_key_bytes),
                EMPTY_CURSOR, EMPTY_CURSOR,
            )
        )
        credentials = GC.@preserve access_key_bytes secret_key_bytes creds_opts begin
            credentials_provider_new_static(alloc, creds_opts)
        end
        assert_nonnull(credentials, "aws_credentials_provider_new_static")

        region_bytes = Vector{UInt8}(codeunits(region))
        region_cur = byte_cursor(region_bytes)
        user_agent_bytes = Vector{UInt8}(codeunits(user_agent))
        signing_config = Ref{Libaws_c_s3.aws_signing_config_aws}(
            Libaws_c_s3.aws_signing_config_aws(ntuple(_ -> UInt8(0), 256))
        )
        s3client = GC.@preserve region_bytes access_key_bytes secret_key_bytes signing_config begin
            Libaws_c_s3.aws_s3_init_default_signing_config(signing_config, region_cur, credentials)
            signing_config_ptr = Base.unsafe_convert(Ptr{Libaws_c_s3.aws_signing_config_aws}, signing_config)

            client_config = create_client_config(
                region_cur,
                bootstrap,
                signing_config_ptr,
                connect_timeout_ms,
                tls,
            )
            client = Libaws_c_s3.aws_s3_client_new(alloc, client_config)
            assert_nonnull(client, "aws_s3_client_new")

            pinned = ClientPinnedBytes(region_bytes, access_key_bytes, secret_key_bytes, user_agent_bytes)
            S3Client(
                host, alloc, client, signing_config, signing_config_ptr,
                bootstrap, resolver, event_loop_group, credentials, client_config, pinned,
                ReentrantLock(), 0, false,
            )
        end
        finalizer(shutdown!, s3client)
        return s3client
    catch
        client != C_NULL && Libaws_c_s3.aws_s3_client_release(client)
        credentials != C_NULL && credentials_provider_release(credentials)
        bootstrap != C_NULL && client_bootstrap_release(bootstrap)
        resolver != C_NULL && host_resolver_release(resolver)
        event_loop_group != C_NULL && event_loop_group_release(event_loop_group)
        runtime_attached && shutdown_runtime!()
        rethrow()
    end
end

function S3Client(cfg::S3Config; alloc::AllocPtr = default_allocator())::S3Client
    return S3Client(;
        alloc,
        host = cfg.host,
        region = cfg.region,
        access_key = cfg.access_key,
        secret_key = cfg.secret_key,
        user_agent = cfg.user_agent,
        connect_timeout_ms = cfg.connect_timeout_ms,
        tls = cfg.tls,
    )
end

#__ lifecycle

"""
    Base.isopen(client::S3Client) -> Bool

Check whether `client` has not been shut down.
"""
function Base.isopen(client::S3Client)::Bool
    lock(client.lifecycle_lock)
    try
        return !client.closed
    finally
        unlock(client.lifecycle_lock)
    end
end

function _acquire_request_access!(client::S3Client)
    lock(client.lifecycle_lock)
    try
        client.closed && throw(ArgumentError("S3Client is closed"))
        client.inflight_requests += 1
        return client.client, client.signing_config_ptr, client.alloc
    finally
        unlock(client.lifecycle_lock)
    end
end

function _release_request_access!(client::S3Client)::Nothing
    lock(client.lifecycle_lock)
    try
        client.inflight_requests > 0 && (client.inflight_requests -= 1)
    finally
        unlock(client.lifecycle_lock)
    end
    return nothing
end

"""
    shutdown!(client::S3Client)

Release all resources held by `client`.
Safe to call multiple times.
"""
function shutdown!(client::S3Client)::Nothing
    lock(client.lifecycle_lock)
    try
        client.closed && return nothing
        client.closed = true

        while client.inflight_requests > 0
            unlock(client.lifecycle_lock)
            try
                yield()
            finally
                lock(client.lifecycle_lock)
            end
        end

        if client.client != C_NULL
            Libaws_c_s3.aws_s3_client_release(client.client)
            client.client = Ptr{Libaws_c_s3.aws_s3_client}(C_NULL)
        end
        if client.credentials != C_NULL
            credentials_provider_release(client.credentials)
            client.credentials = Ptr{Libaws_c_s3.aws_credentials_provider}(C_NULL)
        end
        if client.bootstrap != C_NULL
            client_bootstrap_release(client.bootstrap)
            client.bootstrap = Ptr{Libaws_c_s3.aws_client_bootstrap}(C_NULL)
        end
        if client.resolver != C_NULL
            host_resolver_release(client.resolver)
            client.resolver = Ptr{aws_host_resolver}(C_NULL)
        end
        if client.event_loop_group != C_NULL
            event_loop_group_release(client.event_loop_group)
            client.event_loop_group = Ptr{aws_event_loop_group}(C_NULL)
        end
        if client.alloc != Ptr{Libaws_c_s3.aws_allocator}(C_NULL)
            shutdown_runtime!()
            client.alloc = Ptr{Libaws_c_s3.aws_allocator}(C_NULL)
        end
    finally
        unlock(client.lifecycle_lock)
    end
    return nothing
end

Base.close(client::S3Client)::Nothing = shutdown!(client)

function (::Type{S3Client})(f::Function; alloc::AllocPtr = default_allocator(), kwargs...)
    client = S3Client(; alloc, kwargs...)
    try
        return f(client)
    finally
        shutdown!(client)
    end
end

function (::Type{S3Client})(f::Function, cfg::S3Config; alloc::AllocPtr = default_allocator())
    return S3Client(f;
        alloc,
        host = cfg.host,
        region = cfg.region,
        access_key = cfg.access_key,
        secret_key = cfg.secret_key,
        user_agent = cfg.user_agent,
        connect_timeout_ms = cfg.connect_timeout_ms,
        tls = cfg.tls,
    )
end
