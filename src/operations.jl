using Base64: base64encode
using .Util: byte_cursor, try_bytes_to_string, capture_xml_element, _escape_xml_text,
             s3_path, to_bytes, build_query_string, build_list_params, set_header!, has_header

#__ result types

"""
    S3Object

S3 object metadata returned by list operations.

## Fields
- `key::String`: Object key.
- `size::Int`: Object size in bytes.
- `last_modified::String`: Last modification timestamp.
- `etag::String`: Entity tag.
"""
struct S3Object
    key::String
    size::Int
    last_modified::String
    etag::String
end

"""
    S3ListResult

Result from [`list_objects_detailed`](@ref) with pagination info.

## Fields
- `objects::Vector{S3Object}`: Listed objects.
- `common_prefixes::Vector{String}`: Common prefixes when using a delimiter.
- `is_truncated::Bool`: Whether more results are available.
- `continuation_token::Union{Nothing,String}`: Token for the next page.
"""
struct S3ListResult
    objects::Vector{S3Object}
    common_prefixes::Vector{String}
    is_truncated::Bool
    continuation_token::Union{Nothing,String}
end

"""
    S3CopyResult

Result from [`copy_object`](@ref).

## Fields
- `etag::String`: Entity tag of copied object.
- `last_modified::String`: Last modification timestamp.
"""
struct S3CopyResult
    etag::String
    last_modified::String
end

#__ type aliases

const S3DeleteError = @NamedTuple{key::Union{Nothing,String}, code::Union{Nothing,String}, message::Union{Nothing,String}}

#__ XML parsing

function parse_bucket_names(body::Vector{UInt8})::Vector{String}
    text = try_bytes_to_string(body)
    text === nothing && return String[]
    names = String[]
    for m in eachmatch(r"<(?:[\w-]+:)?Name\b[^>]*>\s*([^<]+?)\s*</(?:[\w-]+:)?Name>"s, text)
        push!(names, m.captures[1])
    end
    return names
end

function parse_list_objects_text(text::AbstractString)::Vector{S3Object}
    objects = S3Object[]
    for m in eachmatch(r"<(?:[\w-]+:)?Contents\b[^>]*>\s*(.*?)\s*</(?:[\w-]+:)?Contents>"s, text)
        content = m.captures[1]
        key = capture_xml_element(content, "Key")
        size_str = capture_xml_element(content, "Size")
        last_modified = capture_xml_element(content, "LastModified")
        etag = capture_xml_element(content, "ETag")

        if key !== nothing
            push!(objects, S3Object(
                key,
                size_str !== nothing ? parse(Int, size_str) : 0,
                something(last_modified, ""),
                etag !== nothing ? replace(etag, "\"" => "") : "",
            ))
        end
    end

    return objects
end

function parse_list_objects(body::Vector{UInt8})::Vector{S3Object}
    text = try_bytes_to_string(body)
    text === nothing && return S3Object[]
    return parse_list_objects_text(text)
end

function parse_list_objects_detailed(body::Vector{UInt8})::S3ListResult
    text = try_bytes_to_string(body)
    text === nothing && return S3ListResult(S3Object[], String[], false, nothing)
    objects = parse_list_objects_text(text)

    common_prefixes = String[]
    for m in eachmatch(r"<(?:[\w-]+:)?CommonPrefixes\b[^>]*>.*?<(?:[\w-]+:)?Prefix\b[^>]*>\s*([^<]+?)\s*</(?:[\w-]+:)?Prefix>.*?</(?:[\w-]+:)?CommonPrefixes>"s, text)
        push!(common_prefixes, m.captures[1])
    end

    is_truncated = occursin(r"<(?:[\w-]+:)?IsTruncated\b[^>]*>\s*true\s*</(?:[\w-]+:)?IsTruncated>"i, text)
    next_token = capture_xml_element(text, "NextContinuationToken")

    return S3ListResult(objects, common_prefixes, is_truncated, next_token)
end

function parse_copy_result(body::Vector{UInt8})::S3CopyResult
    text = try_bytes_to_string(body)
    text === nothing && return S3CopyResult("", "")
    etag = capture_xml_element(text, "ETag")
    last_modified = capture_xml_element(text, "LastModified")
    return S3CopyResult(
        etag !== nothing ? replace(etag, "\"" => "") : "",
        something(last_modified, ""),
    )
end

function _parse_delete_objects_errors(body::Vector{UInt8})::Vector{S3DeleteError}
    text = try_bytes_to_string(body)
    text === nothing && return S3DeleteError[]

    errors = S3DeleteError[]
    for m in eachmatch(r"<(?:[\w-]+:)?Error\b[^>]*>\s*(.*?)\s*</(?:[\w-]+:)?Error>"s, text)
        content = m.captures[1]
        push!(errors, (
            key = capture_xml_element(content, "Key"),
            code = capture_xml_element(content, "Code"),
            message = capture_xml_element(content, "Message"),
        ))
    end
    return errors
end

#__ helpers

function _prepare_headers(
    headers::Vector{Pair{String,String}},
    metadata::Vector{Pair{String,String}},
)::Vector{Pair{String,String}}
    result = copy(headers)
    for (k, v) in metadata
        set_header!(result, "x-amz-meta-$(lowercase(k))", v)
    end
    return result
end

#__ bucket operations

"""
    create_bucket(client::S3Client, bucket::String; ignore_existing::Bool = false)

Create a bucket.
When `ignore_existing` is `true`, an existing bucket is treated as success.
"""
function create_bucket(client::S3Client, bucket::String; ignore_existing::Bool = false)::Nothing
    ok_status = ignore_existing ? (200, 204, 409) : (200, 204)
    execute_request(
        client;
        path = s3_path(bucket),
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "CreateBucket",
        ok_status = ok_status,
        bucket = bucket,
    )
    return nothing
end

"""
    delete_bucket(client::S3Client, bucket::String; force::Bool = false)

Delete a bucket.
When `force` is `true`, all objects are deleted first via [`delete_all_objects!`](@ref).
"""
function delete_bucket(client::S3Client, bucket::String; force::Bool = false)::Nothing
    force && delete_all_objects!(client, bucket)
    execute_request(
        client;
        path = s3_path(bucket),
        method = "DELETE",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "DeleteBucket",
        ok_status = (204, 200),
        bucket = bucket,
    )
    return nothing
end

const DELETE_OBJECTS_MAX_KEYS = 1000

"""
    delete_all_objects!(client::S3Client, bucket::String)

Delete all objects in a bucket using batched multi-object delete requests.
"""
function delete_all_objects!(client::S3Client, bucket::String)::Nothing
    token = ""
    while true
        result = list_objects_detailed(
            client, bucket;
            continuation_token = token,
            max_keys = DELETE_OBJECTS_MAX_KEYS,
        )
        keys = [obj.key for obj in result.objects]
        for batch in Iterators.partition(keys, DELETE_OBJECTS_MAX_KEYS)
            _delete_objects_batch!(client, bucket, collect(batch))
        end
        result.is_truncated || break
        token = something(result.continuation_token, "")
        isempty(token) && break
    end
    return nothing
end

function _build_delete_objects_body(keys::Vector{String}; quiet::Bool = true)::Vector{UInt8}
    io = IOBuffer()
    print(io, "<Delete xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">")
    for key in keys
        print(io, "<Object><Key>")
        print(io, _escape_xml_text(key))
        print(io, "</Key></Object>")
    end
    quiet && print(io, "<Quiet>true</Quiet>")
    print(io, "</Delete>")
    return Vector{UInt8}(take!(io))
end

function _throw_delete_objects_error(
    client::S3Client,
    bucket::String,
    response::S3Response,
    errors::Vector{S3DeleteError},
)::Nothing
    first_error = first(errors)
    message = something(first_error.message, "DeleteObjects failed")
    if length(errors) > 1
        message *= " (plus $(length(errors) - 1) additional object errors)"
    end

    ctx = if first_error.key === nothing
        S3RequestContext("DeleteObjects", bucket, client.host)
    else
        S3RequestContext("DeleteObjects", bucket, first_error.key, client.host)
    end
    resource = first_error.key === nothing ? bucket : string(bucket, "/", first_error.key)
    err_type = classify_error_type(first_error.code, response.status)
    throw(create_typed_error(err_type, ctx, response, message, resource, first_error.code, nothing))
end

function _delete_objects_batch!(client::S3Client, bucket::String, keys::Vector{String})::Nothing
    isempty(keys) && return nothing
    body = _build_delete_objects_body(keys)
    content_md5 = _compute_content_md5(body)
    response = execute_request(
        client;
        path = s3_path(bucket) * "?delete",
        method = "POST",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "DeleteObjects",
        body = body,
        headers = ["content-type" => "application/xml", "content-md5" => content_md5],
        ok_status = (200,),
        bucket = bucket,
    )
    errors = _parse_delete_objects_errors(response.body)
    !isempty(errors) && _throw_delete_objects_error(client, bucket, response, errors)
    return nothing
end

function _compute_content_md5(body::Vector{UInt8})::String
    alloc = default_allocator()
    digest = zeros(UInt8, 16)
    input = Ref(byte_cursor(body))
    output = Ref(Libaws_c_s3.aws_byte_buf(
        Csize_t(0), pointer(digest), Csize_t(length(digest)), alloc,
    ))
    code = GC.@preserve body digest input output begin
        ccall(
            (:aws_md5_compute, Libaws_c_s3.aws_c_cal_jll.libaws_c_cal),
            Cint,
            (
                Ptr{Libaws_c_s3.aws_allocator},
                Ptr{Libaws_c_s3.aws_byte_cursor},
                Ptr{Libaws_c_s3.aws_byte_buf},
                Csize_t,
            ),
            alloc,
            input,
            output,
            Csize_t(0),
        )
    end
    code != 0 && error("aws_md5_compute failed: $(Libaws_c_s3.aws_last_error())")
    return base64encode(@view digest[1:Int(output[].len)])
end

"""
    bucket_exists(client::S3Client, bucket::String) -> Bool

Check whether a bucket exists.
"""
function bucket_exists(client::S3Client, bucket::String)::Bool
    response = execute_request(
        client;
        path = s3_path(bucket),
        method = "HEAD",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "BucketExists",
        ok_status = (200, 301, 302, 307, 404),
        bucket = bucket,
    )
    return response.status != 404
end

"""
    list_buckets(client::S3Client) -> Vector{String}

List all bucket names accessible by the client.
"""
function list_buckets(client::S3Client)::Vector{String}
    response = execute_request(
        client;
        path = "/",
        method = "GET",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "ListBuckets",
        ok_status = (200,),
    )
    return parse_bucket_names(response.body)
end

"""
    set_bucket_versioning(client::S3Client, bucket::String; enabled::Bool = true)

Enable or suspend versioning for a bucket.
"""
function set_bucket_versioning(client::S3Client, bucket::String; enabled::Bool = true)::Nothing
    status_str = enabled ? "Enabled" : "Suspended"
    body = """<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>$(status_str)</Status></VersioningConfiguration>"""
    body_bytes = Vector{UInt8}(codeunits(body))
    execute_request(
        client;
        path = s3_path(bucket) * "?versioning",
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "PutBucketVersioning",
        body = body_bytes,
        headers = ["content-type" => "application/xml"],
        ok_status = (200, 204),
        bucket = bucket,
    )
    return nothing
end

#__ object operations

"""
    put_object(client::S3Client, bucket::String, key::String, body; headers = [], metadata = [])

Upload an object to `bucket` under `key`.
The `body` can be a `String`, `Vector{UInt8}`, `IOStream`, or any `IO`.

## Keyword Arguments
- `headers`: Additional HTTP headers.
- `metadata`: User-defined metadata stored as `x-amz-meta-<key>`.
"""
function put_object(
    client::S3Client, bucket::String, key::String, body::String;
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    metadata::Vector{Pair{String,String}} = Pair{String,String}[],
)::Nothing
    return put_object(client, bucket, key, to_bytes(body); headers = headers, metadata = metadata)
end

function _extract_iostream_file_path(name::String)::Union{Nothing,String}
    file_prefix = "<file "
    if startswith(name, file_prefix) && endswith(name, ">")
        return name[length(file_prefix)+1:end-1]
    end

    fd_prefix = "<fd "
    if startswith(name, fd_prefix) && endswith(name, ">")
        fd_text = strip(name[length(fd_prefix)+1:end-1])
        fd = try
            parse(Int, fd_text)
        catch
            return nothing
        end
        for fd_root in ("/proc/self/fd", "/dev/fd")
            fd_link = string(fd_root, "/", fd)
            path = try
                readlink(fd_link)
            catch
                nothing
            end
            path !== nothing && return path
        end
        return nothing
    end

    if !startswith(name, "<")
        return name
    end
    return nothing
end

function _require_iostream_file_path(source::IOStream)::String
    name = getproperty(source, :name)
    name isa String || throw(ArgumentError("IOStream must expose a file name to use file-path upload"))
    path = _extract_iostream_file_path(name)
    path === nothing && throw(ArgumentError("IOStream is not file-backed; use the IO streaming overload instead"))
    return path
end

function put_object(
    client::S3Client, bucket::String, key::String, body::Vector{UInt8};
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    metadata::Vector{Pair{String,String}} = Pair{String,String}[],
)::Nothing
    hdrs = _prepare_headers(headers, metadata)
    execute_request(
        client;
        path = s3_path(bucket, key),
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_PUT_OBJECT,
        operation = "PutObject",
        body = body,
        headers = hdrs,
        ok_status = (200,),
        bucket = bucket,
        key = key,
    )
    return nothing
end

function put_object(
    client::S3Client, bucket::String, key::String, source::IOStream;
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    metadata::Vector{Pair{String,String}} = Pair{String,String}[],
)::Nothing
    hdrs = _prepare_headers(headers, metadata)
    source_path = _require_iostream_file_path(source)
    execute_file_upload_request(
        client;
        path = s3_path(bucket, key),
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_PUT_OBJECT,
        operation = "PutObject",
        source_path = source_path,
        headers = hdrs,
        ok_status = (200,),
        bucket = bucket,
        key = key,
    )
    return nothing
end

function put_object(
    client::S3Client, bucket::String, key::String, source::IO;
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    metadata::Vector{Pair{String,String}} = Pair{String,String}[],
    chunk_size::Int = DEFAULT_STREAM_UPLOAD_CHUNK_SIZE,
)::Nothing
    hdrs = _prepare_headers(headers, metadata)
    execute_streaming_upload_request(
        client;
        path = s3_path(bucket, key),
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_PUT_OBJECT,
        operation = "PutObject",
        body_source = source,
        headers = hdrs,
        ok_status = (200,),
        chunk_size = chunk_size,
        bucket = bucket,
        key = key,
    )
    return nothing
end

"""
    get_object(client::S3Client, bucket::String, key::String) -> Vector{UInt8}
    get_object(client::S3Client, bucket::String, key::String, dest_path::AbstractString)

Download an object.
Returns the body as bytes, or saves it to a file at `dest_path`.
"""
function get_object(client::S3Client, bucket::String, key::String)::Vector{UInt8}
    response = execute_request(
        client;
        path = s3_path(bucket, key),
        method = "GET",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_GET_OBJECT,
        operation = "GetObject",
        ok_status = (200,),
        bucket = bucket,
        key = key,
    )
    return response.body
end

function get_object(client::S3Client, bucket::String, key::String, dest_path::AbstractString)::Nothing
    execute_request(
        client;
        path = s3_path(bucket, key),
        method = "GET",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_GET_OBJECT,
        operation = "GetObject",
        ok_status = (200,),
        body_sink = dest_path,
        bucket = bucket,
        key = key,
    )
    return nothing
end

"""
    delete_object(client::S3Client, bucket::String, key::String; version_id = nothing)

Delete an object.
Pass `version_id` to delete a specific version when versioning is enabled.
"""
function delete_object(
    client::S3Client, bucket::String, key::String;
    version_id::Union{Nothing,String} = nothing,
)::Nothing
    path = s3_path(bucket, key)
    if version_id !== nothing
        path *= build_query_string(["versionId" => version_id])
    end
    execute_request(
        client;
        path = path,
        method = "DELETE",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "DeleteObject",
        ok_status = (204, 200),
        bucket = bucket,
        key = key,
    )
    return nothing
end

"""
    delete_objects(client::S3Client, bucket::String, keys::Vector{String})

Delete a list of objects from `bucket` using S3's batched `DeleteObjects` API.
Keys are split into batches of up to $(DELETE_OBJECTS_MAX_KEYS) per request.
Throws on the first per-object failure reported by the service.
"""
function delete_objects(client::S3Client, bucket::String, keys::Vector{String})::Nothing
    for batch in Iterators.partition(keys, DELETE_OBJECTS_MAX_KEYS)
        _delete_objects_batch!(client, bucket, collect(batch))
    end
    return nothing
end

"""
    copy_object(client, src_bucket, src_key, dest_bucket, dest_key; kwargs...) -> S3CopyResult

Copy an object from `src_bucket/src_key` to `dest_bucket/dest_key`.

## Keyword Arguments
- `src_version_id`: Copy a specific source version.
- `headers`: Additional HTTP headers.
- `metadata`: User-defined metadata to set on the destination object.
"""
function copy_object(
    client::S3Client, src_bucket::String, src_key::String,
    dest_bucket::String, dest_key::String;
    src_version_id::Union{Nothing,String} = nothing,
    headers::Vector{Pair{String,String}} = Pair{String,String}[],
    metadata::Vector{Pair{String,String}} = Pair{String,String}[],
)::S3CopyResult
    copy_source = s3_path(src_bucket, src_key)
    if src_version_id !== nothing
        copy_source *= build_query_string(["versionId" => src_version_id])
    end

    hdrs = _prepare_headers(headers, metadata)
    if (!isempty(metadata) || any(startswith(lowercase(k), "x-amz-meta-") for (k, _) in hdrs)) &&
       !has_header(hdrs, "x-amz-metadata-directive")
        set_header!(hdrs, "x-amz-metadata-directive", "REPLACE")
    end
    set_header!(hdrs, "x-amz-copy-source", copy_source)

    response = execute_request(
        client;
        path = s3_path(dest_bucket, dest_key),
        method = "PUT",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "CopyObject",
        headers = hdrs,
        ok_status = (200, 201),
        bucket = src_bucket,
        key = src_key,
    )
    return parse_copy_result(response.body)
end

"""
    object_exists(client::S3Client, bucket::String, key::String) -> Bool

Check whether an object exists.
"""
function object_exists(client::S3Client, bucket::String, key::String)::Bool
    response = execute_request(
        client;
        path = s3_path(bucket, key),
        method = "HEAD",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "HeadObject",
        ok_status = (200, 404),
        bucket = bucket,
        key = key,
    )
    return response.status == 200
end

"""
    list_objects(client::S3Client, bucket::String; kwargs...) -> Vector{S3Object}

List objects in a bucket.

## Keyword Arguments
- `prefix`: Restrict results to keys with this prefix.
- `delimiter`: Group keys by delimiter to return common prefixes.
- `continuation_token`: Token from a previous listing to continue.
- `max_keys`: Maximum number of keys to return.
"""
function list_objects(
    client::S3Client, bucket::String;
    prefix::String = "",
    delimiter::String = "",
    continuation_token::String = "",
    max_keys::Union{Nothing,Int} = nothing,
)::Vector{S3Object}
    params = build_list_params(;
        prefix = prefix,
        delimiter = delimiter,
        continuation_token = continuation_token,
        max_keys = max_keys,
    )
    path = s3_path(bucket) * build_query_string(params)
    response = execute_request(
        client;
        path = path,
        method = "GET",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "ListObjectsV2",
        ok_status = (200,),
        bucket = bucket,
    )
    return parse_list_objects(response.body)
end

"""
    list_objects_detailed(client::S3Client, bucket::String; kwargs...) -> S3ListResult

List objects with pagination info.

## Keyword Arguments
- `prefix`: Restrict results to keys with this prefix.
- `delimiter`: Group keys by delimiter to return common prefixes.
- `continuation_token`: Token from a previous listing to continue.
- `max_keys`: Maximum number of keys to return.
"""
function list_objects_detailed(
    client::S3Client, bucket::String;
    prefix::String = "",
    delimiter::String = "",
    continuation_token::String = "",
    max_keys::Union{Nothing,Int} = nothing,
)::S3ListResult
    params = build_list_params(;
        prefix = prefix,
        delimiter = delimiter,
        continuation_token = continuation_token,
        max_keys = max_keys,
    )
    path = s3_path(bucket) * build_query_string(params)
    response = execute_request(
        client;
        path = path,
        method = "GET",
        meta_type = Libaws_c_s3.AWS_S3_META_REQUEST_TYPE_DEFAULT,
        operation = "ListObjectsV2",
        ok_status = (200,),
        bucket = bucket,
    )
    return parse_list_objects_detailed(response.body)
end
