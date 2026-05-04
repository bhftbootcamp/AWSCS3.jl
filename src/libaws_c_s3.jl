module Libaws_c_s3

export libs3_jl_shim,
    libaws_c_s3,
    time_t,
    pthread_t,
    aws_thread_id_t,
    AllocPtr,
    ByteCursor,
    S3ShimResult

export aws_allocator,
    aws_array_list,
    aws_byte_buf,
    aws_byte_cursor,
    aws_atomic_var,
    aws_string,
    tm,
    aws_shutdown_callback_options,
    aws_host_resolver_default_options,
    aws_host_resolution_config,
    aws_client_bootstrap_options,
    aws_credentials_provider_shutdown_options,
    aws_credentials_provider_static_options,
    aws_ref_count,
    aws_date_time,
    aws_credentials_provider_vtable,
    aws_credentials_provider,
    aws_signing_config_aws,
    aws_retry_strategy_vtable,
    aws_retry_strategy,
    aws_s3_platform_info,
    aws_s3_buffer_ticket_vtable,
    aws_s3_buffer_ticket,
    aws_s3_buffer_pool_reserve_meta,
    aws_s3_buffer_pool_vtable,
    aws_s3_buffer_pool,
    aws_s3_buffer_pool_config,
    aws_s3_file_io_options,
    aws_s3_upload_part_review,
    aws_s3_upload_review,
    aws_s3_tcp_keep_alive_options,
    aws_s3_client_config,
    aws_s3_checksum_config,
    aws_s3_meta_request_options,
    aws_s3_meta_request_result,
    aws_s3_meta_request_receive_body_extra_info,
    aws_s3_meta_request_progress,
    aws_s3_meta_request_poll_write_result,
    aws_s3_upload_resume_token_options,
    aws_credentials_properties_s3express,
    aws_s3express_credentials_provider_vtable,
    aws_s3express_credentials_provider,
    var"##Ctag#378"

export aws_event_loop_group,
    aws_host_resolver,
    aws_credentials,
    aws_future_s3_buffer_ticket,
    aws_s3_client,
    aws_s3_meta_request,
    aws_http_stream,
    aws_input_stream,
    aws_hash_table,
    aws_s3_request,
    aws_s3_request_metrics,
    aws_client_bootstrap,
    aws_tls_connection_options,
    aws_http_proxy_options,
    proxy_env_var_settings,
    aws_http_connection_monitoring_options,
    aws_http_message,
    aws_async_input_stream,
    aws_uri,
    aws_s3_meta_request_resume_token,
    aws_http_headers,
    aws_endpoints_request_context,
    aws_endpoints_rule_engine

export aws_signing_config_type,
    aws_signing_algorithm,
    aws_signature_type,
    aws_signed_body_header_type,
    aws_s3_errors,
    aws_s3_subject,
    aws_s3_meta_request_type,
    aws_s3_request_type,
    aws_s3_meta_request_tls_mode,
    aws_s3_meta_request_compute_content_md5,
    aws_s3_checksum_algorithm,
    aws_s3_checksum_location,
    aws_s3_recv_file_options

export aws_credentials_provider_shutdown_completed_fn,
    aws_simple_completion_callback,
    aws_future_callback_fn,
    aws_should_sign_header_fn,
    aws_credentials_provider_get_credentials_fn,
    aws_credentials_provider_destroy_fn,
    aws_on_get_credentials_callback_fn,
    aws_s3_buffer_pool_factory_fn,
    aws_s3_meta_request_headers_callback_fn,
    aws_s3_meta_request_receive_body_callback_fn,
    aws_s3_meta_request_finish_fn,
    aws_s3_meta_request_receive_body_callback_ex_fn,
    aws_s3_meta_request_progress_fn,
    aws_s3_meta_request_telemetry_fn,
    aws_s3_meta_request_shutdown_fn,
    aws_s3_client_shutdown_complete_callback_fn,
    aws_s3_meta_request_full_object_checksum_fn,
    aws_s3_meta_request_upload_review_fn,
    aws_s3express_provider_factory_fn

export aws_s3_library_init,
    aws_s3_library_clean_up,
    aws_s3_get_current_platform_info,
    aws_s3_get_current_platform_ec2_intance_type,
    aws_s3_get_platforms_with_recommended_config,
    aws_future_s3_buffer_ticket_new,
    aws_future_s3_buffer_ticket_set_result_by_move,
    aws_future_s3_buffer_ticket_get_result_by_move,
    aws_future_s3_buffer_ticket_peek_result,
    aws_future_s3_buffer_ticket_acquire,
    aws_future_s3_buffer_ticket_release,
    aws_future_s3_buffer_ticket_set_error,
    aws_future_s3_buffer_ticket_is_done,
    aws_future_s3_buffer_ticket_get_error,
    aws_future_s3_buffer_ticket_register_callback,
    aws_future_s3_buffer_ticket_register_callback_if_not_done,
    aws_future_s3_buffer_ticket_register_event_loop_callback,
    aws_future_s3_buffer_ticket_register_channel_callback,
    aws_future_s3_buffer_ticket_wait,
    aws_s3_buffer_ticket_claim,
    aws_s3_buffer_ticket_acquire,
    aws_s3_buffer_ticket_release,
    aws_s3_buffer_pool_reserve,
    aws_s3_buffer_pool_trim,
    aws_s3_buffer_pool_acquire,
    aws_s3_buffer_pool_release,
    aws_s3_buffer_pool_add_special_size,
    aws_s3_buffer_pool_release_special_size,
    aws_s3_buffer_pool_derive_aligned_buffer_size,
    aws_s3_client_new,
    aws_s3_client_acquire,
    aws_s3_client_release,
    aws_s3_client_make_meta_request,
    aws_s3_meta_request_poll_write,
    aws_s3_meta_request_write,
    aws_s3_meta_request_increment_read_window,
    aws_s3_meta_request_cancel,
    aws_s3_meta_request_pause,
    aws_s3_meta_request_resume_token_new_upload,
    aws_s3_meta_request_resume_token_acquire,
    aws_s3_meta_request_resume_token_release,
    aws_s3_meta_request_resume_token_type,
    aws_s3_meta_request_resume_token_part_size,
    aws_s3_meta_request_resume_token_total_num_parts,
    aws_s3_meta_request_resume_token_num_parts_completed,
    aws_s3_meta_request_resume_token_upload_id,
    aws_s3_meta_request_acquire,
    aws_s3_meta_request_release,
    aws_s3_init_default_signing_config,
    aws_s3_request_type_operation_name,
    aws_s3_request_metrics_acquire,
    aws_s3_request_metrics_release,
    aws_s3_request_metrics_get_request_id,
    aws_s3_request_metrics_get_extended_request_id,
    aws_s3_request_metrics_get_start_timestamp_ns,
    aws_s3_request_metrics_get_end_timestamp_ns,
    aws_s3_request_metrics_get_total_duration_ns,
    aws_s3_request_metrics_get_send_start_timestamp_ns,
    aws_s3_request_metrics_get_send_end_timestamp_ns,
    aws_s3_request_metrics_get_sending_duration_ns,
    aws_s3_request_metrics_get_receive_start_timestamp_ns,
    aws_s3_request_metrics_get_receive_end_timestamp_ns,
    aws_s3_request_metrics_get_sign_start_timestamp_ns,
    aws_s3_request_metrics_get_sign_end_timestamp_ns,
    aws_s3_request_metrics_get_signing_duration_ns,
    aws_s3_request_metrics_get_mem_acquire_start_timestamp_ns,
    aws_s3_request_metrics_get_mem_acquire_end_timestamp_ns,
    aws_s3_request_metrics_get_mem_acquire_duration_ns,
    aws_s3_request_metrics_get_delivery_start_timestamp_ns,
    aws_s3_request_metrics_get_delivery_end_timestamp_ns,
    aws_s3_request_metrics_get_delivery_duration_ns,
    aws_s3_request_metrics_get_receiving_duration_ns,
    aws_s3_request_metrics_get_response_status_code,
    aws_s3_request_metrics_get_response_headers,
    aws_s3_request_metrics_get_request_path_query,
    aws_s3_request_metrics_get_host_address,
    aws_s3_request_metrics_get_ip_address,
    aws_s3_request_metrics_get_connection_id,
    aws_s3_request_metrics_get_request_ptr,
    aws_s3_request_metrics_get_thread_id,
    aws_s3_request_metrics_get_request_stream_id,
    aws_s3_request_metrics_get_operation_name,
    aws_s3_request_metrics_get_request_type,
    aws_s3_request_metrics_get_error_code,
    aws_s3_request_metrics_get_retry_attempt,
    aws_s3_request_metrics_get_memory_allocated_from_pool,
    aws_s3_request_metrics_get_part_range_start,
    aws_s3_request_metrics_get_part_range_end,
    aws_s3_request_metrics_get_part_number,
    aws_s3_request_metrics_get_s3_request_first_attempt_start_timestamp_ns,
    aws_s3_request_metrics_get_s3_request_last_attempt_end_timestamp_ns,
    aws_s3_request_metrics_get_s3_request_total_duration_ns,
    aws_s3_request_metrics_get_conn_acquire_start_timestamp_ns,
    aws_s3_request_metrics_get_conn_acquire_end_timestamp_ns,
    aws_s3_request_metrics_get_conn_acquire_duration_ns,
    aws_s3_request_metrics_get_retry_delay_start_timestamp_ns,
    aws_s3_request_metrics_get_retry_delay_end_timestamp_ns,
    aws_s3_request_metrics_get_retry_delay_duration_ns,
    aws_s3_request_metrics_get_service_call_duration_ns,
    aws_s3_endpoint_resolver_new,
    aws_s3express_credentials_provider_release,
    aws_s3express_credentials_provider_init_base,
    aws_s3express_credentials_provider_get_credentials,
    event_loop_group_new,
    default_allocator,
    aws_common_library_init,
    common_cleanup,
    io_init,
    io_cleanup,
    http_init,
    http_cleanup,
    auth_init,
    auth_cleanup,
    event_loop_group_release,
    host_resolver_new_default,
    host_resolver_release,
    client_bootstrap_new,
    client_bootstrap_release,
    credentials_provider_new_static,
    credentials_provider_release,
    http_headers_new,
    http_headers_add,
    http_headers_release,
    http_message_new_request,
    http_message_set_method,
    http_message_set_path,
    http_message_get_headers,
    http_message_set_body_stream,
    http_message_release,
    s3_shim_make_request,
    s3_shim_result_clean,
    aws_last_error,
    input_stream_new_from_cursor,
    input_stream_release,
    aws_error_str

using CEnum: CEnum, @cenum
using Libdl

using aws_c_s3_jll
import aws_c_auth_jll
import aws_c_cal_jll
import aws_c_common_jll
import aws_c_compression_jll
import aws_c_http_jll
import aws_c_io_jll
import aws_c_sdkutils_jll
import aws_checksums_jll
import s2n_tls_jll

const Lib = Libaws_c_s3

# Locate the shim library
const _SHIM_NAME = "libs3_jl_shim.$(Libdl.dlext)"
const _SHIM_DIR = joinpath(@__DIR__, "..", "deps", "lib")

function _locate_shim()
    path = normpath(joinpath(_SHIM_DIR, _SHIM_NAME))
    if isfile(path)
        return path
    end
    error("""
    Could not locate $(_SHIM_NAME) in $(_SHIM_DIR).
    
    Build first:
      cd deps && bash build_shim.sh
    
    Or install the package normally:
      using Pkg; Pkg.add("AWSCS3")
    """)
end

const libs3_jl_shim = _locate_shim()
const libaws_c_s3 = aws_c_s3_jll.libaws_c_s3

const time_t = Clong
const pthread_t = Culong
const aws_thread_id_t = pthread_t

struct aws_allocator
    mem_acquire::Ptr{Cvoid}
    mem_release::Ptr{Cvoid}
    mem_realloc::Ptr{Cvoid}
    mem_calloc::Ptr{Cvoid}
    impl::Ptr{Cvoid}
end

struct aws_array_list
    alloc::Ptr{aws_allocator}
    current_size::Csize_t
    length::Csize_t
    item_size::Csize_t
    data::Ptr{Cvoid}
end

struct aws_byte_buf
    len::Csize_t
    buffer::Ptr{UInt8}
    capacity::Csize_t
    allocator::Ptr{aws_allocator}
end

struct aws_byte_cursor
    len::Csize_t
    ptr::Ptr{UInt8}
end

const ByteCursor = Lib.aws_byte_cursor

struct aws_atomic_var
    value::Ptr{Cvoid}
end

struct aws_string
    allocator::Ptr{aws_allocator}
    len::Csize_t
    bytes::NTuple{1, UInt8}
end

struct tm
    tm_sec::Cint
    tm_min::Cint
    tm_hour::Cint
    tm_mday::Cint
    tm_mon::Cint
    tm_year::Cint
    tm_wday::Cint
    tm_yday::Cint
    tm_isdst::Cint
    tm_gmtoff::Clong
    tm_zone::Ptr{Cchar}
end

mutable struct aws_event_loop_group end
mutable struct aws_host_resolver end

struct aws_shutdown_callback_options
    shutdown_callback_fn::Ptr{Cvoid}
    shutdown_callback_user_data::Ptr{Cvoid}
end

struct aws_host_resolver_default_options
    max_entries::Csize_t
    el_group::Ptr{aws_event_loop_group}
    shutdown_options::Ptr{aws_shutdown_callback_options}
    system_clock_override_fn::Ptr{Cvoid}
end

struct aws_host_resolution_config
    impl::Ptr{Cvoid}
    max_ttl::Csize_t
    impl_data::Ptr{Cvoid}
    resolve_frequency_ns::UInt64
end

struct aws_client_bootstrap_options
    event_loop_group::Ptr{aws_event_loop_group}
    host_resolver::Ptr{aws_host_resolver}
    host_resolution_config::Ptr{aws_host_resolution_config}
    on_shutdown_complete::Ptr{Cvoid}
    user_data::Ptr{Cvoid}
end

const aws_credentials_provider_shutdown_completed_fn = Cvoid

struct aws_credentials_provider_shutdown_options
    shutdown_callback::Ptr{aws_credentials_provider_shutdown_completed_fn}
    shutdown_user_data::Ptr{Cvoid}
end

struct aws_credentials_provider_static_options
    shutdown_options::Lib.aws_credentials_provider_shutdown_options
    access_key_id::ByteCursor
    secret_access_key::ByteCursor
    session_token::ByteCursor
    account_id::ByteCursor
end

struct S3ShimResult
    body::Lib.aws_byte_buf
    status::Cint
    error_code::Cint
end

const aws_simple_completion_callback = Cvoid

struct aws_ref_count
    ref_count::aws_atomic_var
    object::Ptr{Cvoid}
    on_zero_fn::Ptr{aws_simple_completion_callback}
end

const aws_future_callback_fn = Cvoid

struct aws_date_time
    timestamp::time_t
    milliseconds::UInt16
    tz::NTuple{6, Cchar}
    gmt_time::tm
    local_time::tm
    utc_assumed::Bool
end

const aws_should_sign_header_fn = Cvoid

@cenum aws_signing_config_type::UInt32 begin
    AWS_SIGNING_CONFIG_AWS = 1
end

@cenum aws_signing_algorithm::UInt32 begin
    AWS_SIGNING_ALGORITHM_V4 = 0
    AWS_SIGNING_ALGORITHM_V4_ASYMMETRIC = 1
    AWS_SIGNING_ALGORITHM_V4_S3EXPRESS = 2
end

@cenum aws_signature_type::UInt32 begin
    AWS_ST_HTTP_REQUEST_HEADERS = 0
    AWS_ST_HTTP_REQUEST_QUERY_PARAMS = 1
    AWS_ST_HTTP_REQUEST_CHUNK = 2
    AWS_ST_HTTP_REQUEST_EVENT = 3
    AWS_ST_CANONICAL_REQUEST_HEADERS = 4
    AWS_ST_CANONICAL_REQUEST_QUERY_PARAMS = 5
    AWS_ST_HTTP_REQUEST_TRAILING_HEADERS = 6
end

@cenum aws_signed_body_header_type::UInt32 begin
    AWS_SBHT_NONE = 0
    AWS_SBHT_X_AMZ_CONTENT_SHA256 = 1
end

struct var"##Ctag#378"
    use_double_uri_encode::UInt32
    should_normalize_uri_path::UInt32
    omit_session_token::UInt32
end

function Base.getproperty(x::Ptr{var"##Ctag#378"}, f::Symbol)
    f === :use_double_uri_encode && return (Ptr{UInt32}(x + 0), 0, 1)
    f === :should_normalize_uri_path && return (Ptr{UInt32}(x + 0), 1, 1)
    f === :omit_session_token && return (Ptr{UInt32}(x + 0), 2, 1)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#378", f::Symbol)
    r = Ref{var"##Ctag#378"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#378"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#378"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

mutable struct aws_credentials end

const aws_credentials_provider_get_credentials_fn = Cvoid
const aws_credentials_provider_destroy_fn = Cvoid

struct aws_credentials_provider_vtable
    get_credentials::Ptr{aws_credentials_provider_get_credentials_fn}
    destroy::Ptr{aws_credentials_provider_destroy_fn}
end

struct aws_credentials_provider
    vtable::Ptr{aws_credentials_provider_vtable}
    allocator::Ptr{aws_allocator}
    shutdown_options::aws_credentials_provider_shutdown_options
    impl::Ptr{Cvoid}
    ref_count::aws_atomic_var
end

struct aws_signing_config_aws
    data::NTuple{256, UInt8}
end

function Base.getproperty(x::Ptr{aws_signing_config_aws}, f::Symbol)
    f === :config_type && return Ptr{aws_signing_config_type}(x + 0)
    f === :algorithm && return Ptr{aws_signing_algorithm}(x + 4)
    f === :signature_type && return Ptr{aws_signature_type}(x + 8)
    f === :region && return Ptr{aws_byte_cursor}(x + 16)
    f === :service && return Ptr{aws_byte_cursor}(x + 32)
    f === :date && return Ptr{aws_date_time}(x + 48)
    f === :should_sign_header && return Ptr{Ptr{aws_should_sign_header_fn}}(x + 184)
    f === :should_sign_header_ud && return Ptr{Ptr{Cvoid}}(x + 192)
    f === :flags && return Ptr{var"##Ctag#378"}(x + 200)
    f === :signed_body_value && return Ptr{aws_byte_cursor}(x + 208)
    f === :signed_body_header && return Ptr{aws_signed_body_header_type}(x + 224)
    f === :credentials && return Ptr{Ptr{aws_credentials}}(x + 232)
    f === :credentials_provider && return Ptr{Ptr{aws_credentials_provider}}(x + 240)
    f === :expiration_in_seconds && return Ptr{UInt64}(x + 248)
    return getfield(x, f)
end

function Base.getproperty(x::aws_signing_config_aws, f::Symbol)
    r = Ref{aws_signing_config_aws}(x)
    ptr = Base.unsafe_convert(Ptr{aws_signing_config_aws}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{aws_signing_config_aws}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function Base.propertynames(x::aws_signing_config_aws, private::Bool = false)
    (:config_type, :algorithm, :signature_type, :region, :service, :date, :should_sign_header, :should_sign_header_ud, :flags, :signed_body_value, :signed_body_header, :credentials, :credentials_provider, :expiration_in_seconds,
        if private
            fieldnames(typeof(x))
        else
            ()
        end...)
end

struct aws_retry_strategy_vtable
    destroy::Ptr{Cvoid}
    acquire_token::Ptr{Cvoid}
    schedule_retry::Ptr{Cvoid}
    record_success::Ptr{Cvoid}
    release_token::Ptr{Cvoid}
end

struct aws_retry_strategy
    allocator::Ptr{aws_allocator}
    vtable::Ptr{aws_retry_strategy_vtable}
    ref_count::aws_atomic_var
    impl::Ptr{Cvoid}
end

@cenum aws_exponential_backoff_jitter_mode::UInt32 begin
    AWS_EXPONENTIAL_BACKOFF_JITTER_DEFAULT = 0
    AWS_EXPONENTIAL_BACKOFF_JITTER_NONE = 1
    AWS_EXPONENTIAL_BACKOFF_JITTER_FULL = 2
    AWS_EXPONENTIAL_BACKOFF_JITTER_DECORRELATED = 3
end

struct aws_exponential_backoff_retry_options
    el_group::Ptr{aws_event_loop_group}
    max_retries::Csize_t
    backoff_scale_factor_ms::UInt32
    max_backoff_secs::UInt32
    jitter_mode::aws_exponential_backoff_jitter_mode
    generate_random::Ptr{Cvoid}
    generate_random_impl::Ptr{Cvoid}
    generate_random_user_data::Ptr{Cvoid}
    shutdown_options::Ptr{aws_shutdown_callback_options}
end

struct aws_no_retry_options
    shutdown_options::Ptr{aws_shutdown_callback_options}
end

struct aws_standard_retry_options
    backoff_retry_options::aws_exponential_backoff_retry_options
    initial_bucket_capacity::Csize_t
end

const aws_on_get_credentials_callback_fn = Cvoid

@cenum aws_s3_errors::UInt32 begin
    AWS_ERROR_S3_MISSING_CONTENT_RANGE_HEADER = 14336
    AWS_ERROR_S3_INVALID_CONTENT_RANGE_HEADER = 14337
    AWS_ERROR_S3_MISSING_CONTENT_LENGTH_HEADER = 14338
    AWS_ERROR_S3_INVALID_CONTENT_LENGTH_HEADER = 14339
    AWS_ERROR_S3_MISSING_ETAG = 14340
    AWS_ERROR_S3_INTERNAL_ERROR = 14341
    AWS_ERROR_S3_SLOW_DOWN = 14342
    AWS_ERROR_S3_INVALID_RESPONSE_STATUS = 14343
    AWS_ERROR_S3_MISSING_UPLOAD_ID = 14344
    AWS_ERROR_S3_PROXY_PARSE_FAILED = 14345
    AWS_ERROR_S3_UNSUPPORTED_PROXY_SCHEME = 14346
    AWS_ERROR_S3_CANCELED = 14347
    AWS_ERROR_S3_INVALID_RANGE_HEADER = 14348
    AWS_ERROR_S3_MULTIRANGE_HEADER_UNSUPPORTED = 14349
    AWS_ERROR_S3_RESPONSE_CHECKSUM_MISMATCH = 14350
    AWS_ERROR_S3_CHECKSUM_CALCULATION_FAILED = 14351
    AWS_ERROR_S3_PAUSED = 14352
    AWS_ERROR_S3_LIST_PARTS_PARSE_FAILED = 14353
    AWS_ERROR_S3_RESUMED_PART_CHECKSUM_MISMATCH = 14354
    AWS_ERROR_S3_RESUME_FAILED = 14355
    AWS_ERROR_S3_OBJECT_MODIFIED = 14356
    AWS_ERROR_S3_NON_RECOVERABLE_ASYNC_ERROR = 14357
    AWS_ERROR_S3_METRIC_DATA_NOT_AVAILABLE = 14358
    AWS_ERROR_S3_INCORRECT_CONTENT_LENGTH = 14359
    AWS_ERROR_S3_REQUEST_TIME_TOO_SKEWED = 14360
    AWS_ERROR_S3_FILE_MODIFIED = 14361
    AWS_ERROR_S3_EXCEEDS_MEMORY_LIMIT = 14362
    AWS_ERROR_S3_INVALID_MEMORY_LIMIT_CONFIG = 14363
    AWS_ERROR_S3EXPRESS_CREATE_SESSION_FAILED = 14364
    AWS_ERROR_S3_INTERNAL_PART_SIZE_MISMATCH_RETRYING_WITH_RANGE = 14365
    AWS_ERROR_S3_REQUEST_HAS_COMPLETED = 14366
    AWS_ERROR_S3_RECV_FILE_ALREADY_EXISTS = 14367
    AWS_ERROR_S3_RECV_FILE_NOT_FOUND = 14368
    AWS_ERROR_S3_REQUEST_TIMEOUT = 14369
    AWS_ERROR_S3_BUFFER_ALLOCATION_FAILED = 14370
    AWS_ERROR_S3_END_RANGE = 15359
end

@cenum aws_s3_subject::UInt32 begin
    AWS_LS_S3_GENERAL = 14336
    AWS_LS_S3_CLIENT = 14337
    AWS_LS_S3_CLIENT_STATS = 14338
    AWS_LS_S3_REQUEST = 14339
    AWS_LS_S3_META_REQUEST = 14340
    AWS_LS_S3_ENDPOINT = 14341
    AWS_LS_S3_LAST = 15359
end

struct aws_s3_platform_info
    instance_type::aws_byte_cursor
    max_throughput_gbps::Cdouble
    has_recommended_configuration::Bool
end

function aws_s3_library_init(allocator)
    ccall((:aws_s3_library_init, libaws_c_s3), Cvoid, (Ptr{aws_allocator},), allocator)
end

function aws_s3_library_clean_up()
    ccall((:aws_s3_library_clean_up, libaws_c_s3), Cvoid, ())
end

function aws_s3_get_current_platform_info()
    ccall((:aws_s3_get_current_platform_info, libaws_c_s3), Ptr{aws_s3_platform_info}, ())
end

function aws_s3_get_current_platform_ec2_intance_type(cached_only)
    ccall((:aws_s3_get_current_platform_ec2_intance_type, libaws_c_s3), aws_byte_cursor, (Bool,), cached_only)
end

function aws_s3_get_platforms_with_recommended_config()
    ccall((:aws_s3_get_platforms_with_recommended_config, libaws_c_s3), aws_array_list, ())
end

mutable struct aws_future_s3_buffer_ticket end

function aws_future_s3_buffer_ticket_new(alloc)
    ccall((:aws_future_s3_buffer_ticket_new, libaws_c_s3), Ptr{aws_future_s3_buffer_ticket}, (Ptr{aws_allocator},), alloc)
end

struct aws_s3_buffer_ticket_vtable
    claim::Ptr{Cvoid}
    acquire::Ptr{Cvoid}
    release::Ptr{Cvoid}
end

struct aws_s3_buffer_ticket
    vtable::Ptr{aws_s3_buffer_ticket_vtable}
    ref_count::aws_ref_count
    impl::Ptr{Cvoid}
end

function aws_future_s3_buffer_ticket_set_result_by_move(future, pointer_address)
    ccall((:aws_future_s3_buffer_ticket_set_result_by_move, libaws_c_s3), Cvoid, (Ptr{aws_future_s3_buffer_ticket}, Ptr{Ptr{aws_s3_buffer_ticket}}), future, pointer_address)
end

function aws_future_s3_buffer_ticket_get_result_by_move(future)
    ccall((:aws_future_s3_buffer_ticket_get_result_by_move, libaws_c_s3), Ptr{aws_s3_buffer_ticket}, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_peek_result(future)
    ccall((:aws_future_s3_buffer_ticket_peek_result, libaws_c_s3), Ptr{aws_s3_buffer_ticket}, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_acquire(future)
    ccall((:aws_future_s3_buffer_ticket_acquire, libaws_c_s3), Ptr{aws_future_s3_buffer_ticket}, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_release(future)
    ccall((:aws_future_s3_buffer_ticket_release, libaws_c_s3), Ptr{aws_future_s3_buffer_ticket}, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_set_error(future, error_code)
    ccall((:aws_future_s3_buffer_ticket_set_error, libaws_c_s3), Cvoid, (Ptr{aws_future_s3_buffer_ticket}, Cint), future, error_code)
end

function aws_future_s3_buffer_ticket_is_done(future)
    ccall((:aws_future_s3_buffer_ticket_is_done, libaws_c_s3), Bool, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_get_error(future)
    ccall((:aws_future_s3_buffer_ticket_get_error, libaws_c_s3), Cint, (Ptr{aws_future_s3_buffer_ticket},), future)
end

function aws_future_s3_buffer_ticket_register_callback(future, on_done, user_data)
    ccall((:aws_future_s3_buffer_ticket_register_callback, libaws_c_s3), Cvoid, (Ptr{aws_future_s3_buffer_ticket}, Ptr{aws_future_callback_fn}, Ptr{Cvoid}), future, on_done, user_data)
end

function aws_future_s3_buffer_ticket_register_callback_if_not_done(future, on_done, user_data)
    ccall((:aws_future_s3_buffer_ticket_register_callback_if_not_done, libaws_c_s3), Bool, (Ptr{aws_future_s3_buffer_ticket}, Ptr{aws_future_callback_fn}, Ptr{Cvoid}), future, on_done, user_data)
end

function aws_future_s3_buffer_ticket_register_event_loop_callback(future, event_loop, on_done, user_data)
    ccall((:aws_future_s3_buffer_ticket_register_event_loop_callback, libaws_c_s3), Cvoid, (Ptr{aws_future_s3_buffer_ticket}, Ptr{Cvoid}, Ptr{aws_future_callback_fn}, Ptr{Cvoid}), future, event_loop, on_done, user_data)
end

function aws_future_s3_buffer_ticket_register_channel_callback(future, channel, on_done, user_data)
    ccall((:aws_future_s3_buffer_ticket_register_channel_callback, libaws_c_s3), Cvoid, (Ptr{aws_future_s3_buffer_ticket}, Ptr{Cvoid}, Ptr{aws_future_callback_fn}, Ptr{Cvoid}), future, channel, on_done, user_data)
end

function aws_future_s3_buffer_ticket_wait(future, timeout_ns)
    ccall((:aws_future_s3_buffer_ticket_wait, libaws_c_s3), Bool, (Ptr{aws_future_s3_buffer_ticket}, UInt64), future, timeout_ns)
end

mutable struct aws_s3_client end
mutable struct aws_s3_meta_request end

struct aws_s3_buffer_pool_reserve_meta
    client::Ptr{aws_s3_client}
    meta_request::Ptr{aws_s3_meta_request}
    size::Csize_t
    can_block::Bool
end

function aws_s3_buffer_ticket_claim(ticket)
    ccall((:aws_s3_buffer_ticket_claim, libaws_c_s3), aws_byte_buf, (Ptr{aws_s3_buffer_ticket},), ticket)
end

function aws_s3_buffer_ticket_acquire(ticket)
    ccall((:aws_s3_buffer_ticket_acquire, libaws_c_s3), Ptr{aws_s3_buffer_ticket}, (Ptr{aws_s3_buffer_ticket},), ticket)
end

function aws_s3_buffer_ticket_release(ticket)
    ccall((:aws_s3_buffer_ticket_release, libaws_c_s3), Ptr{aws_s3_buffer_ticket}, (Ptr{aws_s3_buffer_ticket},), ticket)
end

struct aws_s3_buffer_pool_vtable
    reserve::Ptr{Cvoid}
    trim::Ptr{Cvoid}
    add_special_size::Ptr{Cvoid}
    release_special_size::Ptr{Cvoid}
    derive_aligned_buffer_size::Ptr{Cvoid}
    acquire::Ptr{Cvoid}
    release::Ptr{Cvoid}
end

struct aws_s3_buffer_pool
    vtable::Ptr{aws_s3_buffer_pool_vtable}
    ref_count::aws_ref_count
    impl::Ptr{Cvoid}
end

function aws_s3_buffer_pool_reserve(buffer_pool, meta)
    ccall((:aws_s3_buffer_pool_reserve, libaws_c_s3), Ptr{aws_future_s3_buffer_ticket}, (Ptr{aws_s3_buffer_pool}, aws_s3_buffer_pool_reserve_meta), buffer_pool, meta)
end

function aws_s3_buffer_pool_trim(buffer_pool)
    ccall((:aws_s3_buffer_pool_trim, libaws_c_s3), Cvoid, (Ptr{aws_s3_buffer_pool},), buffer_pool)
end

function aws_s3_buffer_pool_acquire(buffer_pool)
    ccall((:aws_s3_buffer_pool_acquire, libaws_c_s3), Ptr{aws_s3_buffer_pool}, (Ptr{aws_s3_buffer_pool},), buffer_pool)
end

function aws_s3_buffer_pool_release(buffer_pool)
    ccall((:aws_s3_buffer_pool_release, libaws_c_s3), Ptr{aws_s3_buffer_pool}, (Ptr{aws_s3_buffer_pool},), buffer_pool)
end

struct aws_s3_buffer_pool_config
    client::Ptr{aws_s3_client}
    part_size::Csize_t
    max_part_size::Csize_t
    memory_limit::Csize_t
end

const aws_s3_buffer_pool_factory_fn = Cvoid

function aws_s3_buffer_pool_add_special_size(buffer_pool, buffer_size)
    ccall((:aws_s3_buffer_pool_add_special_size, libaws_c_s3), Cint, (Ptr{aws_s3_buffer_pool}, Csize_t), buffer_pool, buffer_size)
end

function aws_s3_buffer_pool_release_special_size(buffer_pool, buffer_size)
    ccall((:aws_s3_buffer_pool_release_special_size, libaws_c_s3), Cvoid, (Ptr{aws_s3_buffer_pool}, Csize_t), buffer_pool, buffer_size)
end

function aws_s3_buffer_pool_derive_aligned_buffer_size(buffer_pool, size)
    ccall((:aws_s3_buffer_pool_derive_aligned_buffer_size, libaws_c_s3), UInt64, (Ptr{aws_s3_buffer_pool}, UInt64), buffer_pool, size)
end

mutable struct aws_http_stream end
mutable struct aws_input_stream end
mutable struct aws_hash_table end
mutable struct aws_s3_request end
mutable struct aws_s3_request_metrics end

@cenum aws_s3_meta_request_type::UInt32 begin
    AWS_S3_META_REQUEST_TYPE_DEFAULT = 0
    AWS_S3_META_REQUEST_TYPE_GET_OBJECT = 1
    AWS_S3_META_REQUEST_TYPE_PUT_OBJECT = 2
    AWS_S3_META_REQUEST_TYPE_COPY_OBJECT = 3
    AWS_S3_META_REQUEST_TYPE_MAX = 4
end

@cenum aws_s3_request_type::UInt32 begin
    AWS_S3_REQUEST_TYPE_UNKNOWN = 0
    AWS_S3_REQUEST_TYPE_HEAD_OBJECT = 1
    AWS_S3_REQUEST_TYPE_GET_OBJECT = 2
    AWS_S3_REQUEST_TYPE_LIST_PARTS = 3
    AWS_S3_REQUEST_TYPE_CREATE_MULTIPART_UPLOAD = 4
    AWS_S3_REQUEST_TYPE_UPLOAD_PART = 5
    AWS_S3_REQUEST_TYPE_ABORT_MULTIPART_UPLOAD = 6
    AWS_S3_REQUEST_TYPE_COMPLETE_MULTIPART_UPLOAD = 7
    AWS_S3_REQUEST_TYPE_UPLOAD_PART_COPY = 8
    AWS_S3_REQUEST_TYPE_COPY_OBJECT = 9
    AWS_S3_REQUEST_TYPE_PUT_OBJECT = 10
    AWS_S3_REQUEST_TYPE_CREATE_SESSION = 11
    AWS_S3_REQUEST_TYPE_MAX = 12
    AWS_S3_REQUEST_TYPE_DEFAULT = 0
end

const aws_s3_meta_request_headers_callback_fn = Cvoid
const aws_s3_meta_request_receive_body_callback_fn = Cvoid
const aws_s3_meta_request_finish_fn = Cvoid

struct aws_s3_meta_request_receive_body_extra_info
    range_start::UInt64
    ticket::Ptr{aws_s3_buffer_ticket}
end

const aws_s3_meta_request_receive_body_callback_ex_fn = Cvoid

struct aws_s3_meta_request_progress
    bytes_transferred::UInt64
    content_length::UInt64
end

const aws_s3_meta_request_progress_fn = Cvoid
const aws_s3_meta_request_telemetry_fn = Cvoid
const aws_s3_meta_request_shutdown_fn = Cvoid
const aws_s3_client_shutdown_complete_callback_fn = Cvoid
const aws_s3_meta_request_full_object_checksum_fn = Cvoid

@cenum aws_s3_meta_request_tls_mode::UInt32 begin
    AWS_MR_TLS_ENABLED = 0
    AWS_MR_TLS_DISABLED = 1
end

@cenum aws_s3_meta_request_compute_content_md5::UInt32 begin
    AWS_MR_CONTENT_MD5_DISABLED = 0
    AWS_MR_CONTENT_MD5_ENABLED = 1
end

@cenum aws_s3_checksum_algorithm::UInt32 begin
    AWS_SCA_NONE = 0
    AWS_SCA_INIT = 1
    AWS_SCA_CRC32C = 1
    AWS_SCA_CRC32 = 2
    AWS_SCA_SHA1 = 3
    AWS_SCA_SHA256 = 4
    AWS_SCA_CRC64NVME = 5
    AWS_SCA_END = 5
end

@cenum aws_s3_checksum_location::UInt32 begin
    AWS_SCL_NONE = 0
    AWS_SCL_HEADER = 1
    AWS_SCL_TRAILER = 2
end

@cenum aws_s3_recv_file_options::UInt32 begin
    AWS_S3_RECV_FILE_CREATE_OR_REPLACE = 0
    AWS_S3_RECV_FILE_CREATE_NEW = 1
    AWS_S3_RECV_FILE_CREATE_OR_APPEND = 2
    AWS_S3_RECV_FILE_WRITE_TO_POSITION = 3
end

struct aws_s3_file_io_options
    should_stream::Bool
    disk_throughput_gbps::Cdouble
    direct_io::Bool
end

struct aws_s3_upload_part_review
    size::UInt64
    checksum::aws_byte_cursor
end

struct aws_s3_upload_review
    checksum_algorithm::aws_s3_checksum_algorithm
    part_count::Csize_t
    part_array::Ptr{aws_s3_upload_part_review}
end

const aws_s3_meta_request_upload_review_fn = Cvoid
const aws_s3express_provider_factory_fn = Cvoid

struct aws_s3_tcp_keep_alive_options
    keep_alive_interval_sec::UInt16
    keep_alive_timeout_sec::UInt16
    keep_alive_max_failed_probes::UInt16
end

mutable struct aws_client_bootstrap end
mutable struct aws_tls_connection_options end
mutable struct aws_http_proxy_options end
mutable struct proxy_env_var_settings end
mutable struct aws_http_connection_monitoring_options end

struct aws_s3_client_config
    max_active_connections_override::UInt32
    region::aws_byte_cursor
    client_bootstrap::Ptr{aws_client_bootstrap}
    tls_mode::aws_s3_meta_request_tls_mode
    tls_connection_options::Ptr{aws_tls_connection_options}
    fio_opts::Ptr{aws_s3_file_io_options}
    signing_config::Ptr{aws_signing_config_aws}
    part_size::UInt64
    max_part_size::UInt64
    multipart_upload_threshold::UInt64
    throughput_target_gbps::Cdouble
    memory_limit_in_bytes::UInt64
    retry_strategy::Ptr{aws_retry_strategy}
    compute_content_md5::aws_s3_meta_request_compute_content_md5
    shutdown_callback::Ptr{aws_s3_client_shutdown_complete_callback_fn}
    shutdown_callback_user_data::Ptr{Cvoid}
    proxy_options::Ptr{aws_http_proxy_options}
    proxy_ev_settings::Ptr{proxy_env_var_settings}
    connect_timeout_ms::UInt32
    tcp_keep_alive_options::Ptr{aws_s3_tcp_keep_alive_options}
    monitoring_options::Ptr{aws_http_connection_monitoring_options}
    enable_read_backpressure::Bool
    initial_read_window::Csize_t
    enable_s3express::Bool
    s3express_provider_override_factory::Ptr{aws_s3express_provider_factory_fn}
    factory_user_data::Ptr{Cvoid}
    network_interface_names_array::Ptr{aws_byte_cursor}
    num_network_interface_names::Csize_t
    buffer_pool_factory_fn::Ptr{aws_s3_buffer_pool_factory_fn}
    buffer_pool_user_data::Ptr{Cvoid}
end

struct aws_s3_checksum_config
    location::aws_s3_checksum_location
    checksum_algorithm::aws_s3_checksum_algorithm
    full_object_checksum_callback::Ptr{aws_s3_meta_request_full_object_checksum_fn}
    user_data::Ptr{Cvoid}
    validate_response_checksum::Bool
    validate_checksum_algorithms::Ptr{aws_array_list}
end

mutable struct aws_http_message end
mutable struct aws_async_input_stream end
mutable struct aws_uri end
mutable struct aws_s3_meta_request_resume_token end

struct aws_s3_meta_request_options
    type::aws_s3_meta_request_type
    operation_name::aws_byte_cursor
    signing_config::Ptr{aws_signing_config_aws}
    message::Ptr{aws_http_message}
    recv_filepath::aws_byte_cursor
    recv_file_option::aws_s3_recv_file_options
    recv_file_position::UInt64
    recv_file_delete_on_failure::Bool
    send_filepath::aws_byte_cursor
    fio_opts::Ptr{aws_s3_file_io_options}
    send_async_stream::Ptr{aws_async_input_stream}
    send_using_async_writes::Bool
    checksum_config::Ptr{aws_s3_checksum_config}
    part_size::UInt64
    force_dynamic_part_size::Bool
    multipart_upload_threshold::UInt64
    user_data::Ptr{Cvoid}
    headers_callback::Ptr{aws_s3_meta_request_headers_callback_fn}
    body_callback::Ptr{aws_s3_meta_request_receive_body_callback_fn}
    body_callback_ex::Ptr{aws_s3_meta_request_receive_body_callback_ex_fn}
    finish_callback::Ptr{aws_s3_meta_request_finish_fn}
    shutdown_callback::Ptr{aws_s3_meta_request_shutdown_fn}
    progress_callback::Ptr{aws_s3_meta_request_progress_fn}
    telemetry_callback::Ptr{aws_s3_meta_request_telemetry_fn}
    upload_review_callback::Ptr{aws_s3_meta_request_upload_review_fn}
    endpoint::Ptr{aws_uri}
    resume_token::Ptr{aws_s3_meta_request_resume_token}
    object_size_hint::Ptr{UInt64}
    copy_source_uri::aws_byte_cursor
    max_active_connections_override::UInt32
end

mutable struct aws_http_headers end

struct aws_s3_meta_request_result
    error_response_headers::Ptr{aws_http_headers}
    error_response_body::Ptr{aws_byte_buf}
    error_response_operation_name::Ptr{aws_string}
    response_status::Cint
    did_validate::Bool
    validation_algorithm::aws_s3_checksum_algorithm
    error_code::Cint
end

function aws_s3_client_new(allocator, client_config)
    ccall((:aws_s3_client_new, libaws_c_s3), Ptr{aws_s3_client}, (Ptr{aws_allocator}, Ptr{aws_s3_client_config}), allocator, client_config)
end

function aws_s3_client_acquire(client)
    ccall((:aws_s3_client_acquire, libaws_c_s3), Ptr{aws_s3_client}, (Ptr{aws_s3_client},), client)
end

function aws_s3_client_release(client)
    ccall((:aws_s3_client_release, libaws_c_s3), Ptr{aws_s3_client}, (Ptr{aws_s3_client},), client)
end

function aws_s3_client_make_meta_request(client, options)
    ccall((:aws_s3_client_make_meta_request, libaws_c_s3), Ptr{aws_s3_meta_request}, (Ptr{aws_s3_client}, Ptr{aws_s3_meta_request_options}), client, options)
end

struct aws_s3_meta_request_poll_write_result
    is_pending::Bool
    error_code::Cint
    bytes_processed::Csize_t
end

function aws_s3_meta_request_poll_write(meta_request, data, eof, waker, user_data)
    ccall((:aws_s3_meta_request_poll_write, libaws_c_s3), aws_s3_meta_request_poll_write_result, (Ptr{aws_s3_meta_request}, aws_byte_cursor, Bool, Ptr{aws_simple_completion_callback}, Ptr{Cvoid}), meta_request, data, eof, waker, user_data)
end

function aws_s3_meta_request_write(meta_request, data, eof)
    ccall((:aws_s3_meta_request_write, libaws_c_s3), Ptr{Cvoid}, (Ptr{aws_s3_meta_request}, aws_byte_cursor, Bool), meta_request, data, eof)
end

function aws_s3_meta_request_increment_read_window(meta_request, bytes)
    ccall((:aws_s3_meta_request_increment_read_window, libaws_c_s3), Cvoid, (Ptr{aws_s3_meta_request}, UInt64), meta_request, bytes)
end

function aws_s3_meta_request_cancel(meta_request)
    ccall((:aws_s3_meta_request_cancel, libaws_c_s3), Cvoid, (Ptr{aws_s3_meta_request},), meta_request)
end

function aws_s3_meta_request_pause(meta_request, out_resume_token)
    ccall((:aws_s3_meta_request_pause, libaws_c_s3), Cint, (Ptr{aws_s3_meta_request}, Ptr{Ptr{aws_s3_meta_request_resume_token}}), meta_request, out_resume_token)
end

struct aws_s3_upload_resume_token_options
    upload_id::aws_byte_cursor
    part_size::UInt64
    total_num_parts::Csize_t
    num_parts_completed::Csize_t
end

function aws_s3_meta_request_resume_token_new_upload(allocator, options)
    ccall((:aws_s3_meta_request_resume_token_new_upload, libaws_c_s3), Ptr{aws_s3_meta_request_resume_token}, (Ptr{aws_allocator}, Ptr{aws_s3_upload_resume_token_options}), allocator, options)
end

function aws_s3_meta_request_resume_token_acquire(resume_token)
    ccall((:aws_s3_meta_request_resume_token_acquire, libaws_c_s3), Ptr{aws_s3_meta_request_resume_token}, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_release(resume_token)
    ccall((:aws_s3_meta_request_resume_token_release, libaws_c_s3), Ptr{aws_s3_meta_request_resume_token}, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_type(resume_token)
    ccall((:aws_s3_meta_request_resume_token_type, libaws_c_s3), aws_s3_meta_request_type, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_part_size(resume_token)
    ccall((:aws_s3_meta_request_resume_token_part_size, libaws_c_s3), UInt64, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_total_num_parts(resume_token)
    ccall((:aws_s3_meta_request_resume_token_total_num_parts, libaws_c_s3), Csize_t, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_num_parts_completed(resume_token)
    ccall((:aws_s3_meta_request_resume_token_num_parts_completed, libaws_c_s3), Csize_t, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_resume_token_upload_id(resume_token)
    ccall((:aws_s3_meta_request_resume_token_upload_id, libaws_c_s3), aws_byte_cursor, (Ptr{aws_s3_meta_request_resume_token},), resume_token)
end

function aws_s3_meta_request_acquire(meta_request)
    ccall((:aws_s3_meta_request_acquire, libaws_c_s3), Ptr{aws_s3_meta_request}, (Ptr{aws_s3_meta_request},), meta_request)
end

function aws_s3_meta_request_release(meta_request)
    ccall((:aws_s3_meta_request_release, libaws_c_s3), Ptr{aws_s3_meta_request}, (Ptr{aws_s3_meta_request},), meta_request)
end

function aws_s3_init_default_signing_config(signing_config, region, credentials_provider)
    ccall((:aws_s3_init_default_signing_config, libaws_c_s3), Cvoid, (Ptr{aws_signing_config_aws}, aws_byte_cursor, Ptr{aws_credentials_provider}), signing_config, region, credentials_provider)
end

function aws_s3_request_type_operation_name(type)
    ccall((:aws_s3_request_type_operation_name, libaws_c_s3), Ptr{Cchar}, (aws_s3_request_type,), type)
end

function aws_s3_request_metrics_acquire(metrics)
    ccall((:aws_s3_request_metrics_acquire, libaws_c_s3), Ptr{aws_s3_request_metrics}, (Ptr{aws_s3_request_metrics},), metrics)
end

function aws_s3_request_metrics_release(metrics)
    ccall((:aws_s3_request_metrics_release, libaws_c_s3), Ptr{aws_s3_request_metrics}, (Ptr{aws_s3_request_metrics},), metrics)
end

function aws_s3_request_metrics_get_request_id(metrics, out_request_id)
    ccall((:aws_s3_request_metrics_get_request_id, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_request_id)
end

function aws_s3_request_metrics_get_extended_request_id(metrics, out_extended_request_id)
    ccall((:aws_s3_request_metrics_get_extended_request_id, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_extended_request_id)
end

function aws_s3_request_metrics_get_start_timestamp_ns(metrics, out_start_time)
    ccall((:aws_s3_request_metrics_get_start_timestamp_ns, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_start_time)
end

function aws_s3_request_metrics_get_end_timestamp_ns(metrics, out_end_time)
    ccall((:aws_s3_request_metrics_get_end_timestamp_ns, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_end_time)
end

function aws_s3_request_metrics_get_total_duration_ns(metrics, out_total_duration)
    ccall((:aws_s3_request_metrics_get_total_duration_ns, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_total_duration)
end

function aws_s3_request_metrics_get_send_start_timestamp_ns(metrics, out_send_start_time)
    ccall((:aws_s3_request_metrics_get_send_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_send_start_time)
end

function aws_s3_request_metrics_get_send_end_timestamp_ns(metrics, out_send_end_time)
    ccall((:aws_s3_request_metrics_get_send_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_send_end_time)
end

function aws_s3_request_metrics_get_sending_duration_ns(metrics, out_sending_duration)
    ccall((:aws_s3_request_metrics_get_sending_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_sending_duration)
end

function aws_s3_request_metrics_get_receive_start_timestamp_ns(metrics, out_receive_start_time)
    ccall((:aws_s3_request_metrics_get_receive_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_receive_start_time)
end

function aws_s3_request_metrics_get_receive_end_timestamp_ns(metrics, out_receive_end_time)
    ccall((:aws_s3_request_metrics_get_receive_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_receive_end_time)
end

function aws_s3_request_metrics_get_sign_start_timestamp_ns(metrics, out_signing_start_time)
    ccall((:aws_s3_request_metrics_get_sign_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_signing_start_time)
end

function aws_s3_request_metrics_get_sign_end_timestamp_ns(metrics, out_signing_end_time)
    ccall((:aws_s3_request_metrics_get_sign_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_signing_end_time)
end

function aws_s3_request_metrics_get_signing_duration_ns(metrics, out_signing_duration)
    ccall((:aws_s3_request_metrics_get_signing_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_signing_duration)
end

function aws_s3_request_metrics_get_mem_acquire_start_timestamp_ns(metrics, out_mem_acquire_start_time)
    ccall((:aws_s3_request_metrics_get_mem_acquire_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_mem_acquire_start_time)
end

function aws_s3_request_metrics_get_mem_acquire_end_timestamp_ns(metrics, out_mem_acquire_end_time)
    ccall((:aws_s3_request_metrics_get_mem_acquire_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_mem_acquire_end_time)
end

function aws_s3_request_metrics_get_mem_acquire_duration_ns(metrics, out_mem_acquire_duration)
    ccall((:aws_s3_request_metrics_get_mem_acquire_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_mem_acquire_duration)
end

function aws_s3_request_metrics_get_delivery_start_timestamp_ns(metrics, out_delivery_start_time)
    ccall((:aws_s3_request_metrics_get_delivery_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_delivery_start_time)
end

function aws_s3_request_metrics_get_delivery_end_timestamp_ns(metrics, out_delivery_end_time)
    ccall((:aws_s3_request_metrics_get_delivery_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_delivery_end_time)
end

function aws_s3_request_metrics_get_delivery_duration_ns(metrics, out_delivery_duration)
    ccall((:aws_s3_request_metrics_get_delivery_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_delivery_duration)
end

function aws_s3_request_metrics_get_receiving_duration_ns(metrics, out_receiving_duration)
    ccall((:aws_s3_request_metrics_get_receiving_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_receiving_duration)
end

function aws_s3_request_metrics_get_response_status_code(metrics, out_response_status)
    ccall((:aws_s3_request_metrics_get_response_status_code, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Cint}), metrics, out_response_status)
end

function aws_s3_request_metrics_get_response_headers(metrics, out_response_headers)
    ccall((:aws_s3_request_metrics_get_response_headers, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_http_headers}}), metrics, out_response_headers)
end

function aws_s3_request_metrics_get_request_path_query(metrics, out_request_path_query)
    ccall((:aws_s3_request_metrics_get_request_path_query, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_request_path_query)
end

function aws_s3_request_metrics_get_host_address(metrics, out_host_address)
    ccall((:aws_s3_request_metrics_get_host_address, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_host_address)
end

function aws_s3_request_metrics_get_ip_address(metrics, out_ip_address)
    ccall((:aws_s3_request_metrics_get_ip_address, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_ip_address)
end

function aws_s3_request_metrics_get_connection_id(metrics, out_connection_ptr)
    ccall((:aws_s3_request_metrics_get_connection_id, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Csize_t}), metrics, out_connection_ptr)
end

function aws_s3_request_metrics_get_request_ptr(metrics, out_request_ptr)
    ccall((:aws_s3_request_metrics_get_request_ptr, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Csize_t}), metrics, out_request_ptr)
end

function aws_s3_request_metrics_get_thread_id(metrics, out_thread_id)
    ccall((:aws_s3_request_metrics_get_thread_id, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{aws_thread_id_t}), metrics, out_thread_id)
end

function aws_s3_request_metrics_get_request_stream_id(metrics, out_stream_id)
    ccall((:aws_s3_request_metrics_get_request_stream_id, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt32}), metrics, out_stream_id)
end

function aws_s3_request_metrics_get_operation_name(metrics, out_operation_name)
    ccall((:aws_s3_request_metrics_get_operation_name, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{Ptr{aws_string}}), metrics, out_operation_name)
end

function aws_s3_request_metrics_get_request_type(metrics, out_request_type)
    ccall((:aws_s3_request_metrics_get_request_type, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{aws_s3_request_type}), metrics, out_request_type)
end

function aws_s3_request_metrics_get_error_code(metrics)
    ccall((:aws_s3_request_metrics_get_error_code, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics},), metrics)
end

function aws_s3_request_metrics_get_retry_attempt(metrics)
    ccall((:aws_s3_request_metrics_get_retry_attempt, libaws_c_s3), UInt32, (Ptr{aws_s3_request_metrics},), metrics)
end

function aws_s3_request_metrics_get_memory_allocated_from_pool(metrics)
    ccall((:aws_s3_request_metrics_get_memory_allocated_from_pool, libaws_c_s3), Bool, (Ptr{aws_s3_request_metrics},), metrics)
end

function aws_s3_request_metrics_get_part_range_start(metrics, out_part_range_start)
    ccall((:aws_s3_request_metrics_get_part_range_start, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_part_range_start)
end

function aws_s3_request_metrics_get_part_range_end(metrics, out_part_range_end)
    ccall((:aws_s3_request_metrics_get_part_range_end, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_part_range_end)
end

function aws_s3_request_metrics_get_part_number(metrics, out_part_number)
    ccall((:aws_s3_request_metrics_get_part_number, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt32}), metrics, out_part_number)
end

function aws_s3_request_metrics_get_s3_request_first_attempt_start_timestamp_ns(metrics, out_s3_request_first_attempt_start_time)
    ccall((:aws_s3_request_metrics_get_s3_request_first_attempt_start_timestamp_ns, libaws_c_s3), Cvoid, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_s3_request_first_attempt_start_time)
end

function aws_s3_request_metrics_get_s3_request_last_attempt_end_timestamp_ns(metrics, out_s3_request_last_attempt_end_time)
    ccall((:aws_s3_request_metrics_get_s3_request_last_attempt_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_s3_request_last_attempt_end_time)
end

function aws_s3_request_metrics_get_s3_request_total_duration_ns(metrics, out_request_duration)
    ccall((:aws_s3_request_metrics_get_s3_request_total_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_request_duration)
end

function aws_s3_request_metrics_get_conn_acquire_start_timestamp_ns(metrics, out_conn_acquire_start_time)
    ccall((:aws_s3_request_metrics_get_conn_acquire_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_conn_acquire_start_time)
end

function aws_s3_request_metrics_get_conn_acquire_end_timestamp_ns(metrics, out_conn_acquire_end_time)
    ccall((:aws_s3_request_metrics_get_conn_acquire_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_conn_acquire_end_time)
end

function aws_s3_request_metrics_get_conn_acquire_duration_ns(metrics, out_conn_acquire_duration)
    ccall((:aws_s3_request_metrics_get_conn_acquire_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_conn_acquire_duration)
end

function aws_s3_request_metrics_get_retry_delay_start_timestamp_ns(metrics, out_retry_delay_start_time)
    ccall((:aws_s3_request_metrics_get_retry_delay_start_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_retry_delay_start_time)
end

function aws_s3_request_metrics_get_retry_delay_end_timestamp_ns(metrics, out_retry_delay_end_time)
    ccall((:aws_s3_request_metrics_get_retry_delay_end_timestamp_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_retry_delay_end_time)
end

function aws_s3_request_metrics_get_retry_delay_duration_ns(metrics, out_retry_delay_duration)
    ccall((:aws_s3_request_metrics_get_retry_delay_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_retry_delay_duration)
end

function aws_s3_request_metrics_get_service_call_duration_ns(metrics, out_service_call_duration)
    ccall((:aws_s3_request_metrics_get_service_call_duration_ns, libaws_c_s3), Cint, (Ptr{aws_s3_request_metrics}, Ptr{UInt64}), metrics, out_service_call_duration)
end

mutable struct aws_endpoints_request_context end
mutable struct aws_endpoints_rule_engine end

function aws_s3_endpoint_resolver_new(allocator)
    ccall((:aws_s3_endpoint_resolver_new, libaws_c_s3), Ptr{aws_endpoints_rule_engine}, (Ptr{aws_allocator},), allocator)
end

struct aws_credentials_properties_s3express
    host::aws_byte_cursor
    region::aws_byte_cursor
    headers::Ptr{aws_http_headers}
end

struct aws_s3express_credentials_provider_vtable
    get_credentials::Ptr{Cvoid}
    destroy::Ptr{Cvoid}
end

struct aws_s3express_credentials_provider
    vtable::Ptr{aws_s3express_credentials_provider_vtable}
    allocator::Ptr{aws_allocator}
    shutdown_complete_callback::Ptr{aws_simple_completion_callback}
    shutdown_user_data::Ptr{Cvoid}
    impl::Ptr{Cvoid}
    ref_count::aws_ref_count
end

function aws_s3express_credentials_provider_release(provider)
    ccall((:aws_s3express_credentials_provider_release, libaws_c_s3), Ptr{aws_s3express_credentials_provider}, (Ptr{aws_s3express_credentials_provider},), provider)
end

function aws_s3express_credentials_provider_init_base(provider, allocator, vtable, impl)
    ccall((:aws_s3express_credentials_provider_init_base, libaws_c_s3), Cvoid, (Ptr{aws_s3express_credentials_provider}, Ptr{aws_allocator}, Ptr{aws_s3express_credentials_provider_vtable}, Ptr{Cvoid}), provider, allocator, vtable, impl)
end

function aws_s3express_credentials_provider_get_credentials(provider, original_credentials, properties, callback, user_data)
    ccall((:aws_s3express_credentials_provider_get_credentials, libaws_c_s3), Cint, (Ptr{aws_s3express_credentials_provider}, Ptr{aws_credentials}, Ptr{aws_credentials_properties_s3express}, aws_on_get_credentials_callback_fn, Ptr{Cvoid}), provider, original_credentials, properties, callback, user_data)
end

const AllocPtr = Ptr{Lib.aws_allocator}

const libcommon = aws_c_common_jll.libaws_c_common
const libauth = aws_c_auth_jll.libaws_c_auth
const libio = aws_c_io_jll.libaws_c_io
const libhttp = aws_c_http_jll.libaws_c_http

function event_loop_group_new(alloc; threads::Integer = 1)
    ccall((:aws_event_loop_group_new_default, libio), Ptr{aws_event_loop_group}, (AllocPtr, UInt16, Ptr{aws_shutdown_callback_options}), alloc, UInt16(threads), C_NULL)
end

function default_allocator()
    ccall((:aws_default_allocator, libcommon), AllocPtr, ())
end

function aws_common_library_init(arg1::AllocPtr)
    ccall((:aws_common_library_init, libcommon), Cvoid, (AllocPtr,), arg1)
end

function common_cleanup()
    ccall((:aws_common_library_clean_up, libcommon), Cvoid, ())
end

function io_init(arg1::AllocPtr)
    ccall((:aws_io_library_init, libio), Cvoid, (AllocPtr,), arg1)
end

function io_cleanup()
    ccall((:aws_io_library_clean_up, libio), Cvoid, ())
end

function aws_retry_strategy_new_exponential_backoff(arg1::AllocPtr, arg2::Ref{aws_exponential_backoff_retry_options})
    ccall((:aws_retry_strategy_new_exponential_backoff, libio), Ptr{aws_retry_strategy}, (AllocPtr, Ptr{aws_exponential_backoff_retry_options}), arg1, arg2)
end

function aws_retry_strategy_new_standard(arg1::AllocPtr, arg2::Ref{aws_standard_retry_options})
    ccall((:aws_retry_strategy_new_standard, libio), Ptr{aws_retry_strategy}, (AllocPtr, Ptr{aws_standard_retry_options}), arg1, arg2)
end

function aws_retry_strategy_new_no_retry(arg1::AllocPtr, arg2::Ptr{aws_no_retry_options})
    ccall((:aws_retry_strategy_new_no_retry, libio), Ptr{aws_retry_strategy}, (AllocPtr, Ptr{aws_no_retry_options}), arg1, arg2)
end

function aws_retry_strategy_release(arg1::Ptr{aws_retry_strategy})
    ccall((:aws_retry_strategy_release, libio), Cvoid, (Ptr{aws_retry_strategy},), arg1)
end

function http_init(arg1::AllocPtr)
    ccall((:aws_http_library_init, libhttp), Cvoid, (AllocPtr,), arg1)
end

function http_cleanup()
    ccall((:aws_http_library_clean_up, libhttp), Cvoid, ())
end

function auth_init(arg1::AllocPtr)
    ccall((:aws_auth_library_init, libauth), Cvoid, (AllocPtr,), arg1)
end

function auth_cleanup()
    ccall((:aws_auth_library_clean_up, libauth), Cvoid, ())
end

function event_loop_group_release(arg1::Ptr{aws_event_loop_group})
    ccall((:aws_event_loop_group_release, libio), Cvoid, (Ptr{aws_event_loop_group},), arg1)
end

function host_resolver_new_default(arg1::AllocPtr, arg2::Ref{aws_host_resolver_default_options})
    ccall((:aws_host_resolver_new_default, libio), Ptr{aws_host_resolver}, (AllocPtr, Ptr{aws_host_resolver_default_options}), arg1, arg2)
end

function host_resolver_release(arg1::Ptr{aws_host_resolver})
    ccall((:aws_host_resolver_release, libio), Cvoid, (Ptr{aws_host_resolver},), arg1)
end

function client_bootstrap_new(arg1::AllocPtr, arg2::Ref{aws_client_bootstrap_options})
    ccall((:aws_client_bootstrap_new, libio), Ptr{Lib.aws_client_bootstrap}, (AllocPtr, Ptr{aws_client_bootstrap_options}), arg1, arg2)
end

function client_bootstrap_release(arg1::Ptr{Lib.aws_client_bootstrap})
    ccall((:aws_client_bootstrap_release, libio), Cvoid, (Ptr{Lib.aws_client_bootstrap},), arg1)
end

function credentials_provider_new_static(arg1::AllocPtr, arg2::Ref{aws_credentials_provider_static_options})
    ccall((:aws_credentials_provider_new_static, libauth), Ptr{Lib.aws_credentials_provider}, (AllocPtr, Ptr{aws_credentials_provider_static_options}), arg1, arg2)
end

function credentials_provider_release(arg1::Ptr{Lib.aws_credentials_provider})
    ccall((:aws_credentials_provider_release, libauth), Ptr{Lib.aws_credentials_provider}, (Ptr{Lib.aws_credentials_provider},), arg1)
end

function http_headers_new(arg1::AllocPtr)
    ccall((:aws_http_headers_new, libhttp), Ptr{Lib.aws_http_headers}, (AllocPtr,), arg1)
end

function http_headers_add(arg1::Ptr{Lib.aws_http_headers}, arg2::ByteCursor, arg3::ByteCursor)
    ccall((:aws_http_headers_add, libhttp), Cint, (Ptr{Lib.aws_http_headers}, ByteCursor, ByteCursor), arg1, arg2, arg3)
end

function http_headers_release(arg1::Ptr{Lib.aws_http_headers})
    ccall((:aws_http_headers_release, libhttp), Cvoid, (Ptr{Lib.aws_http_headers},), arg1)
end

function http_message_new_request(arg1::AllocPtr)
    ccall((:aws_http_message_new_request, libhttp), Ptr{Lib.aws_http_message}, (AllocPtr,), arg1)
end

function http_message_set_method(arg1::Ptr{Lib.aws_http_message}, arg2::ByteCursor)
    ccall((:aws_http_message_set_request_method, libhttp), Cint, (Ptr{Lib.aws_http_message}, ByteCursor), arg1, arg2)
end

function http_message_set_path(arg1::Ptr{Lib.aws_http_message}, arg2::ByteCursor)
    ccall((:aws_http_message_set_request_path, libhttp), Cint, (Ptr{Lib.aws_http_message}, ByteCursor), arg1, arg2)
end

function http_message_get_headers(arg1::Ptr{Lib.aws_http_message})
    ccall((:aws_http_message_get_headers, libhttp), Ptr{Lib.aws_http_headers}, (Ptr{Lib.aws_http_message},), arg1)
end

function http_message_set_body_stream(arg1::Ptr{Lib.aws_http_message}, arg2::Ptr{Lib.aws_input_stream})
    ccall((:aws_http_message_set_body_stream, libhttp), Cvoid, (Ptr{Lib.aws_http_message}, Ptr{Lib.aws_input_stream}), arg1, arg2)
end

function http_message_release(arg1::Ptr{Lib.aws_http_message})
    ccall((:aws_http_message_release, libhttp), Ptr{Lib.aws_http_message}, (Ptr{Lib.aws_http_message},), arg1)
end

function s3_shim_make_request(arg1::AllocPtr, arg2::Ptr{Lib.aws_s3_client}, arg3::Ref{Lib.aws_s3_meta_request_options}, arg4::Ref{S3ShimResult})
    ccall((:s3_jl_make_request, libs3_jl_shim), Cint, (AllocPtr, Ptr{Lib.aws_s3_client}, Ptr{Lib.aws_s3_meta_request_options}, Ptr{S3ShimResult}), arg1, arg2, arg3, arg4)
end

function s3_shim_make_streaming_upload_request(arg1::AllocPtr, arg2::Ptr{Lib.aws_s3_client}, arg3::Ref{Lib.aws_s3_meta_request_options}, arg4::Ptr{Cvoid}, arg5::Ptr{Cvoid}, arg6::Csize_t, arg7::Ref{S3ShimResult})
    ccall((:s3_jl_make_streaming_upload_request, libs3_jl_shim), Cint, (AllocPtr, Ptr{Lib.aws_s3_client}, Ptr{Lib.aws_s3_meta_request_options}, Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Ptr{S3ShimResult}), arg1, arg2, arg3, arg4, arg5, arg6, arg7)
end

function s3_shim_result_clean(arg1::Ref{S3ShimResult})
    ccall((:s3_jl_result_clean_up, libs3_jl_shim), Cvoid, (Ptr{S3ShimResult},), arg1)
end

function aws_last_error()
    ccall((:aws_last_error, libcommon), Cint, ())
end

function input_stream_new_from_cursor(arg1::AllocPtr, arg2::Ref{ByteCursor})
    ccall((:aws_input_stream_new_from_cursor, libio), Ptr{Lib.aws_input_stream}, (AllocPtr, Ptr{ByteCursor}), arg1, arg2)
end

function input_stream_release(arg1::Ptr{Lib.aws_input_stream})
    ccall((:aws_input_stream_release, libio), Ptr{Lib.aws_input_stream}, (Ptr{Lib.aws_input_stream},), arg1)
end

function aws_error_str(code::Integer)
    unsafe_string(ccall((:aws_error_str, libcommon), Ptr{Cchar}, (Cint,), code))
end

const PREFIXES = ["aws_", "AWS_"]
for name in names(@__MODULE__; all = true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end
