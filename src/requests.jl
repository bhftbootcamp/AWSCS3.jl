using .Util: byte_cursor, to_bytes, assert_aws_ok

#__ request types

const DEFAULT_STREAM_UPLOAD_CHUNK_SIZE = 8 * 1024 * 1024

struct S3Request
    msg::Ptr{Libaws_c_s3.aws_http_message}
    headers::Ptr{Libaws_c_s3.aws_http_headers}
    body_stream::Ptr{Libaws_c_s3.aws_input_stream}
    pinned_buffers::Vector{Vector{UInt8}} # GC pinning for C pointers
    cursor_refs::Vector{Base.RefValue{ByteCursor}}
end

mutable struct StreamingUploadReadState
    source::IO
    callback_error::Union{Nothing,Any}
end

function _streaming_upload_read_cb(
    user_data::Ptr{Cvoid}, buffer::Ptr{UInt8}, capacity::Csize_t,
    eof_out::Ptr{Bool}, err_out::Ptr{Cint},
)::Csize_t
    state = unsafe_pointer_to_objref(user_data)::StreamingUploadReadState
    try
        cap = Int(capacity)
        dst = unsafe_wrap(Vector{UInt8}, buffer, cap; own = false)
        nread = readbytes!(state.source, dst, cap)
        unsafe_store!(eof_out, nread == 0)
        unsafe_store!(err_out, Cint(0))
        return Csize_t(nread)
    catch err
        state.callback_error = err
        unsafe_store!(eof_out, true)
        unsafe_store!(err_out, Cint(1))
        return Csize_t(0)
    end
end

const STREAMING_UPLOAD_READ_CB = @cfunction(
    _streaming_upload_read_cb,
    Csize_t,
    (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{Bool}, Ptr{Cint}),
)

#__ request building

function build_meta_request_options(;
    meta_type,
    operation_bytes::Vector{UInt8},
    signing_config_ptr,
    message,
    recv_path_cursor::ByteCursor = EMPTY_CURSOR,
    send_path_cursor::ByteCursor = EMPTY_CURSOR,
    fio_opts_ptr::Ptr{Libaws_c_s3.aws_s3_file_io_options} = Ptr{Libaws_c_s3.aws_s3_file_io_options}(C_NULL),
    send_using_async_writes::Bool = false,
)
    return Ref(Libaws_c_s3.aws_s3_meta_request_options(
        meta_type,
        byte_cursor(operation_bytes),
        signing_config_ptr,
        message,
        recv_path_cursor,
        Libaws_c_s3.AWS_S3_RECV_FILE_CREATE_OR_REPLACE,
        UInt64(0),
        false,
        send_path_cursor,
        fio_opts_ptr,
        Ptr{Libaws_c_s3.aws_async_input_stream}(C_NULL),
        send_using_async_writes,
        Ptr{Libaws_c_s3.aws_s3_checksum_config}(C_NULL),
        UInt64(0),
        false,
        UInt64(0),
        Ptr{Cvoid}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_headers_callback_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_receive_body_callback_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_receive_body_callback_ex_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_finish_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_shutdown_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_progress_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_telemetry_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_upload_review_fn}(C_NULL),
        Ptr{Libaws_c_s3.aws_uri}(C_NULL),
        Ptr{Libaws_c_s3.aws_s3_meta_request_resume_token}(C_NULL),
        Ptr{UInt64}(C_NULL),
        EMPTY_CURSOR,
        UInt32(0),
    ))
end

function build_s3_request(
    alloc;
    host::String,
    path::String,
    method::String,
    body::Vector{UInt8} = UInt8[],
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    user_agent_bytes::Vector{UInt8} = UInt8[],
)::S3Request
    msg = http_message_new_request(alloc)
    headers_ptr = http_message_get_headers(msg)
    pinned_buffers = Vector{Vector{UInt8}}()
    cursor_refs = Base.RefValue{ByteCursor}[]

    method_bytes = Vector{UInt8}(codeunits(method))
    push!(pinned_buffers, method_bytes)
    assert_aws_ok(
        http_message_set_method(msg, byte_cursor(method_bytes)),
        "aws_http_message_set_request_method",
    )

    path_bytes = Vector{UInt8}(codeunits(path))
    push!(pinned_buffers, path_bytes)
    assert_aws_ok(
        http_message_set_path(msg, byte_cursor(path_bytes)),
        "aws_http_message_set_request_path",
    )

    host_bytes = Vector{UInt8}(codeunits(host))
    push!(pinned_buffers, host_bytes)
    assert_aws_ok(
        http_headers_add(headers_ptr, byte_cursor("Host"), byte_cursor(host_bytes)),
        "aws_http_headers_add",
    )

    ua_bytes = isempty(user_agent_bytes) ? Vector{UInt8}(codeunits("AWSCS3.jl")) : user_agent_bytes
    push!(pinned_buffers, ua_bytes)
    assert_aws_ok(
        http_headers_add(headers_ptr, byte_cursor("User-Agent"), byte_cursor(ua_bytes)),
        "aws_http_headers_add",
    )

    for (name, value) in headers
        name_bytes = to_bytes(name)
        value_bytes = to_bytes(value)
        push!(pinned_buffers, name_bytes, value_bytes)
        assert_aws_ok(
            http_headers_add(headers_ptr, byte_cursor(name_bytes), byte_cursor(value_bytes)),
            "aws_http_headers_add",
        )
    end

    body_stream = Ptr{Libaws_c_s3.aws_input_stream}(C_NULL)
    if !isempty(body)
        push!(pinned_buffers, body)
        cursor_ref = Ref(byte_cursor(body))
        push!(cursor_refs, cursor_ref)
        body_stream = input_stream_new_from_cursor(alloc, cursor_ref)
        http_message_set_body_stream(msg, body_stream)
        len_bytes = Vector{UInt8}(codeunits(string(length(body))))
        push!(pinned_buffers, len_bytes)
        assert_aws_ok(
            http_headers_add(headers_ptr, byte_cursor("Content-Length"), byte_cursor(len_bytes)),
            "aws_http_headers_add",
        )
    end

    return S3Request(msg, headers_ptr, body_stream, pinned_buffers, cursor_refs)
end

function release_request!(req::S3Request)::Nothing
    req.body_stream != C_NULL && input_stream_release(req.body_stream)
    http_message_release(req.msg)
    return nothing
end

function copy_response_body!(
    res::Ref{S3ShimResult},
    body_sink::Union{Vector{UInt8},AbstractString},
)::Vector{UInt8}
    body = unsafe_wrap(Vector{UInt8}, res[].body.buffer, res[].body.len; own = false)
    if body_sink isa Vector{UInt8}
        resize!(body_sink, length(body))
        copyto!(body_sink, 1, body, 1, length(body))
        return body_sink
    end
    return copy(body)
end

#__ raw request execution

function execute_raw_request(
    client, signing_config_ptr, alloc;
    request::S3Request,
    meta_type,
    ctx::S3RequestContext,
    body_sink::Union{Vector{UInt8},AbstractString},
)::S3Response
    op_bytes = Vector{UInt8}(codeunits(ctx.operation))
    recv_path_bytes = UInt8[]
    recv_path_cursor = EMPTY_CURSOR
    if body_sink isa AbstractString && !isempty(body_sink)
        recv_path_bytes = Vector{UInt8}(codeunits(body_sink))
        recv_path_cursor = byte_cursor(recv_path_bytes)
    end
    opts = build_meta_request_options(;
        meta_type,
        operation_bytes = op_bytes,
        signing_config_ptr,
        message = request.msg,
        recv_path_cursor,
    )
    res = Ref(S3ShimResult(Libaws_c_s3.aws_byte_buf(0, Ptr{UInt8}(C_NULL), 0, Ptr{Libaws_c_s3.aws_allocator}(C_NULL)), 0, 0))
    pinned_buffers = request.pinned_buffers
    cursor_refs = request.cursor_refs
    code = GC.@preserve op_bytes opts request res pinned_buffers cursor_refs recv_path_bytes begin
        s3_shim_make_request(alloc, client, opts, res)
    end
    status = Int(res[].status)
    error_code = Int(res[].error_code)
    body_copy = code == 0 ? copy_response_body!(res, body_sink) : UInt8[]
    s3_shim_result_clean(res)
    code != 0 && throw(create_error_from_aws_code(ctx, code))
    return S3Response(status, error_code, body_copy)
end

function execute_raw_file_upload_request(
    client, signing_config_ptr, alloc;
    request::S3Request,
    meta_type,
    ctx::S3RequestContext,
    source_path::String,
)::S3Response
    op_bytes = Vector{UInt8}(codeunits(ctx.operation))
    send_path_bytes = Vector{UInt8}(codeunits(source_path))
    fio_opts = Ref(Libaws_c_s3.aws_s3_file_io_options(true, Cdouble(0), false))
    opts = build_meta_request_options(;
        meta_type,
        operation_bytes = op_bytes,
        signing_config_ptr,
        message = request.msg,
        send_path_cursor = byte_cursor(send_path_bytes),
        fio_opts_ptr = Base.unsafe_convert(Ptr{Libaws_c_s3.aws_s3_file_io_options}, fio_opts),
    )
    res = Ref(S3ShimResult(Libaws_c_s3.aws_byte_buf(0, Ptr{UInt8}(C_NULL), 0, Ptr{Libaws_c_s3.aws_allocator}(C_NULL)), 0, 0))
    pinned_buffers = request.pinned_buffers
    cursor_refs = request.cursor_refs
    code = GC.@preserve op_bytes opts request res pinned_buffers cursor_refs send_path_bytes fio_opts begin
        s3_shim_make_request(alloc, client, opts, res)
    end
    status = Int(res[].status)
    error_code = Int(res[].error_code)
    s3_shim_result_clean(res)
    code != 0 && throw(create_error_from_aws_code(ctx, code))
    return S3Response(status, error_code, UInt8[])
end

function execute_raw_streaming_upload_request(
    client, signing_config_ptr, alloc;
    request::S3Request,
    meta_type,
    ctx::S3RequestContext,
    body_source::IO,
    chunk_size::Int,
)::S3Response
    chunk_size > 0 || throw(ArgumentError("chunk_size must be greater than 0"))
    op_bytes = Vector{UInt8}(codeunits(ctx.operation))
    opts = build_meta_request_options(;
        meta_type,
        operation_bytes = op_bytes,
        signing_config_ptr,
        message = request.msg,
        send_using_async_writes = true,
    )
    res = Ref(S3ShimResult(Libaws_c_s3.aws_byte_buf(0, Ptr{UInt8}(C_NULL), 0, Ptr{Libaws_c_s3.aws_allocator}(C_NULL)), 0, 0))
    state = StreamingUploadReadState(body_source, nothing)
    pinned_buffers = request.pinned_buffers
    cursor_refs = request.cursor_refs
    code = GC.@preserve op_bytes opts request res state pinned_buffers cursor_refs begin
        s3_shim_make_streaming_upload_request(
            alloc,
            client,
            opts,
            STREAMING_UPLOAD_READ_CB,
            pointer_from_objref(state),
            Csize_t(chunk_size),
            res,
        )
    end
    status = Int(res[].status)
    error_code = Int(res[].error_code)
    s3_shim_result_clean(res)
    state.callback_error !== nothing && throw(state.callback_error)
    code != 0 && throw(create_error_from_aws_code(ctx, code))
    return S3Response(status, error_code, UInt8[])
end

#__ request execution

function _with_request(
    f::Function, client::S3Client;
    path::String,
    method::String,
    operation::String,
    body::Vector{UInt8} = UInt8[],
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    ok_status::Tuple{Vararg{Int}} = (200,),
    bucket::Union{Nothing,String} = nothing,
    key::Union{Nothing,String} = nothing,
)::S3Response
    client_ptr, signing_config_ptr, alloc = _acquire_request_access!(client)
    try
        ctx = S3RequestContext(operation, bucket, key, client.host)
        req = build_s3_request(alloc;
            host = client.host,
            path = path,
            method = method,
            body = body,
            headers = headers,
            user_agent_bytes = client.pinned.user_agent_bytes,
        )
        response = try
            f(client_ptr, signing_config_ptr, alloc, req, ctx)
        finally
            release_request!(req)
        end
        !(response.status in ok_status) && throw(create_error_from_response(ctx, response))
        return response
    finally
        _release_request_access!(client)
    end
end

function execute_request(
    client::S3Client;
    path::String,
    method::String,
    meta_type::Libaws_c_s3.aws_s3_meta_request_type,
    operation::String,
    body::Vector{UInt8} = UInt8[],
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    ok_status::Tuple{Vararg{Int}} = (200,),
    body_sink::Union{Vector{UInt8},AbstractString} = UInt8[],
    bucket::Union{Nothing,String} = nothing,
    key::Union{Nothing,String} = nothing,
)::S3Response
    return _with_request(client;
        path = path,
        method = method,
        operation = operation,
        body = body,
        headers = headers,
        ok_status = ok_status,
        bucket = bucket,
        key = key,
    ) do client_ptr, signing_config_ptr, alloc, req, ctx
        execute_raw_request(client_ptr, signing_config_ptr, alloc;
            request = req,
            meta_type = meta_type,
            ctx = ctx,
            body_sink = body_sink,
        )
    end
end

function execute_file_upload_request(
    client::S3Client;
    path::String,
    method::String,
    meta_type::Libaws_c_s3.aws_s3_meta_request_type,
    operation::String,
    source_path::String,
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    ok_status::Tuple{Vararg{Int}} = (200,),
    bucket::Union{Nothing,String} = nothing,
    key::Union{Nothing,String} = nothing,
)::S3Response
    return _with_request(client;
        path = path,
        method = method,
        operation = operation,
        headers = headers,
        ok_status = ok_status,
        bucket = bucket,
        key = key,
    ) do client_ptr, signing_config_ptr, alloc, req, ctx
        execute_raw_file_upload_request(client_ptr, signing_config_ptr, alloc;
            request = req,
            meta_type = meta_type,
            ctx = ctx,
            source_path = source_path,
        )
    end
end

function execute_streaming_upload_request(
    client::S3Client;
    path::String,
    method::String,
    meta_type::Libaws_c_s3.aws_s3_meta_request_type,
    operation::String,
    body_source::IO,
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    ok_status::Tuple{Vararg{Int}} = (200,),
    chunk_size::Int = DEFAULT_STREAM_UPLOAD_CHUNK_SIZE,
    bucket::Union{Nothing,String} = nothing,
    key::Union{Nothing,String} = nothing,
)::S3Response
    return _with_request(client;
        path = path,
        method = method,
        operation = operation,
        headers = headers,
        ok_status = ok_status,
        bucket = bucket,
        key = key,
    ) do client_ptr, signing_config_ptr, alloc, req, ctx
        execute_raw_streaming_upload_request(client_ptr, signing_config_ptr, alloc;
            request = req,
            meta_type = meta_type,
            ctx = ctx,
            body_source = body_source,
            chunk_size = chunk_size,
        )
    end
end
