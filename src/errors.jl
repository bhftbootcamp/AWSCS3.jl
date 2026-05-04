using .Util: try_bytes_to_string, capture_xml_element
using .Libaws_c_s3: aws_error_str

#__ exception types

"""
    AbstractS3Error <: Exception

Abstract base type for all S3-related exceptions.

Concrete subtypes:
- [`S3Error`](@ref): Generic S3 error response.
- [`S3AccessDeniedError`](@ref): Access denied (HTTP 403).
- [`S3BucketAlreadyExistsError`](@ref): Bucket already exists (HTTP 409).
- [`S3BucketNotFoundError`](@ref): Bucket not found (HTTP 404).
- [`S3BucketNotEmptyError`](@ref): Bucket is not empty (HTTP 409).
- [`S3ObjectNotFoundError`](@ref): Object not found (HTTP 404).
- [`S3InvalidRequestError`](@ref): Invalid request (HTTP 400).
- [`S3ServerError`](@ref): Server error (HTTP 5xx).
- [`S3ConnectionError`](@ref): Connection failure.
- [`S3AuthenticationError`](@ref): Authentication failure (HTTP 401/403).
"""
abstract type AbstractS3Error <: Exception end

"""
    S3Error <: AbstractS3Error

Represents a generic S3 error response when a more specific subtype is not applicable.

## Fields
- `operation::String`: Operation name.
- `status::Int`: HTTP status code, or `0` if unavailable.
- `error_code::Int`: AWS SDK error code, or `0`.
- `code::Union{Nothing,String}`: S3 error code.
- `message::String`: Human-readable error message.
- `request_id::Union{Nothing,String}`: Request ID from the service.
- `resource::Union{Nothing,String}`: Resource associated with the error.
- `raw_body::Vector{UInt8}`: Raw response body.
"""
struct S3Error <: AbstractS3Error
    operation::String
    status::Int
    error_code::Int
    code::Union{Nothing,String}
    message::String
    request_id::Union{Nothing,String}
    resource::Union{Nothing,String}
    raw_body::Vector{UInt8}
end

function Base.showerror(io::IO, err::S3Error)
    status_str = err.status > 0 ? " (HTTP $(err.status))" : ""
    code_str = err.code === nothing ? "" : "[$(err.code)] "
    print(io, "S3Error: ", err.operation, " failed", status_str, "\n  ", code_str, err.message)
    err.resource !== nothing && print(io, "\n  Resource: ", err.resource)
    err.request_id !== nothing && print(io, "\n  RequestId: ", err.request_id)
end

"""
    S3AccessDeniedError <: AbstractS3Error

Access denied while performing an operation on a resource.

## Fields
- `operation::String`: Operation name.
- `resource::String`: Resource path.
- `message::String`: Error message.
"""
struct S3AccessDeniedError <: AbstractS3Error
    operation::String
    resource::String
    message::String
end

function Base.showerror(io::IO, err::S3AccessDeniedError)
    print(io, "S3AccessDeniedError: Access denied for '", err.operation, "' on '", err.resource, "'\n  ", err.message)
end

"""
    S3BucketAlreadyExistsError <: AbstractS3Error

Bucket already exists.

## Fields
- `bucket::String`: Bucket name.
"""
struct S3BucketAlreadyExistsError <: AbstractS3Error
    bucket::String
end

function Base.showerror(io::IO, err::S3BucketAlreadyExistsError)
    print(io, "S3BucketAlreadyExistsError: Bucket '", err.bucket, "' already exists.")
end

"""
    S3BucketNotFoundError <: AbstractS3Error

Bucket was not found.

## Fields
- `bucket::String`: Bucket name.
- `operation::String`: Operation name.
"""
struct S3BucketNotFoundError <: AbstractS3Error
    bucket::String
    operation::String
end

function Base.showerror(io::IO, err::S3BucketNotFoundError)
    print(io, "S3BucketNotFoundError: Bucket '", err.bucket, "' does not exist.")
end

"""
    S3BucketNotEmptyError <: AbstractS3Error

Bucket is not empty.

## Fields
- `bucket::String`: Bucket name.
"""
struct S3BucketNotEmptyError <: AbstractS3Error
    bucket::String
end

function Base.showerror(io::IO, err::S3BucketNotEmptyError)
    print(io, "S3BucketNotEmptyError: Bucket '", err.bucket, "' is not empty.")
end

"""
    S3ObjectNotFoundError <: AbstractS3Error

Object was not found in a bucket.

## Fields
- `bucket::String`: Bucket name.
- `key::String`: Object key.
- `operation::String`: Operation name.
"""
struct S3ObjectNotFoundError <: AbstractS3Error
    bucket::String
    key::String
    operation::String
end

function Base.showerror(io::IO, err::S3ObjectNotFoundError)
    print(io, "S3ObjectNotFoundError: Object '", err.key, "' not found in bucket '", err.bucket, "'.")
end

"""
    S3InvalidRequestError <: AbstractS3Error

The request was rejected as invalid.

## Fields
- `operation::String`: Operation name.
- `message::String`: Error message.
"""
struct S3InvalidRequestError <: AbstractS3Error
    operation::String
    message::String
end

function Base.showerror(io::IO, err::S3InvalidRequestError)
    print(io, "S3InvalidRequestError: Invalid request for '", err.operation, "'\n  ", err.message)
end

"""
    S3ServerError <: AbstractS3Error

The server returned a 5xx error.

## Fields
- `operation::String`: Operation name.
- `status::Int`: HTTP status code.
- `message::String`: Error message.
"""
struct S3ServerError <: AbstractS3Error
    operation::String
    status::Int
    message::String
end

function Base.showerror(io::IO, err::S3ServerError)
    print(io, "S3ServerError: Server error (HTTP ", err.status, ") for '", err.operation, "'\n  ", err.message)
end

"""
    S3ConnectionError <: AbstractS3Error

Failed to connect to the S3 endpoint.

## Fields
- `host::String`: Endpoint hostname.
- `message::String`: Error message.
"""
struct S3ConnectionError <: AbstractS3Error
    host::String
    message::String
end

function Base.showerror(io::IO, err::S3ConnectionError)
    print(io, "S3ConnectionError: Failed to connect to '", err.host, "'\n  ", err.message)
end

"""
    S3AuthenticationError <: AbstractS3Error

Authentication failed for the request.

## Fields
- `operation::String`: Operation name.
- `message::String`: Error message.
"""
struct S3AuthenticationError <: AbstractS3Error
    operation::String
    message::String
end

function Base.showerror(io::IO, err::S3AuthenticationError)
    print(io, "S3AuthenticationError: Authentication failed for '", err.operation, "'\n  ", err.message)
end

#__ error classification

const HTTP_STATUS_MESSAGES = Dict{Int,String}(
    400 => "Bad request",
    401 => "Unauthorized",
    403 => "Access denied",
    404 => "Not found",
    405 => "Method not allowed",
    409 => "Conflict",
    412 => "Precondition failed",
    500 => "Internal server error",
    502 => "Bad gateway",
    503 => "Service unavailable",
    504 => "Gateway timeout",
)

const S3_ERROR_CODE_TYPES = Dict{String,Symbol}(
    "AccessDenied" => :access_denied,
    "AccountProblem" => :access_denied,
    "AllAccessDisabled" => :access_denied,
    "BucketAlreadyExists" => :bucket_exists,
    "BucketAlreadyOwnedByYou" => :bucket_exists,
    "BucketNotEmpty" => :bucket_not_empty,
    "NoSuchBucket" => :bucket_not_found,
    "NoSuchKey" => :object_not_found,
    "NoSuchVersion" => :object_not_found,
    "InvalidAccessKeyId" => :auth_error,
    "SignatureDoesNotMatch" => :auth_error,
    "InvalidSecurity" => :auth_error,
    "InvalidBucketName" => :invalid_request,
    "InvalidObjectName" => :invalid_request,
    "InvalidArgument" => :invalid_request,
    "MalformedXML" => :invalid_request,
    "InternalError" => :server_error,
    "ServiceUnavailable" => :server_error,
    "SlowDown" => :server_error,
)

struct S3ErrorResponse
    code::Union{Nothing,String}
    message::Union{Nothing,String}
    request_id::Union{Nothing,String}
    resource::Union{Nothing,String}
    raw_text::String
end

struct S3RequestContext
    operation::String
    bucket::Union{Nothing,String}
    key::Union{Nothing,String}
    host::String
end

S3RequestContext(operation::String, host::String) =
    S3RequestContext(operation, nothing, nothing, host)

S3RequestContext(operation::String, bucket::String, host::String) =
    S3RequestContext(operation, bucket, nothing, host)

struct S3Response
    status::Int
    error_code::Int
    body::Vector{UInt8}
end

function classify_error_type(code::Union{Nothing,String}, status::Int)::Symbol
    if code !== nothing
        err_type = get(S3_ERROR_CODE_TYPES, code, nothing)
        err_type !== nothing && return err_type
    end
    status == 401 && return :auth_error
    status == 403 && return :access_denied
    status == 404 && return :not_found
    status == 409 && return :conflict
    status in (400, 405, 412) && return :invalid_request
    status in (500, 502, 503, 504) && return :server_error
    status == 0 && return :connection_error
    return :unknown
end

#__ error construction

function parse_error_response(body::Vector{UInt8})::Union{Nothing,S3ErrorResponse}
    text = try_bytes_to_string(body)
    text === nothing && return nothing

    code = capture_xml_element(text, "Code")
    message = capture_xml_element(text, "Message")
    request_id = capture_xml_element(text, "RequestId")
    request_id === nothing && (request_id = capture_xml_element(text, "RequestID"))
    resource = capture_xml_element(text, "Resource")

    if code === nothing && message === nothing
        trimmed = strip(text)
        isempty(trimmed) && return nothing
        message = trimmed
    end

    return S3ErrorResponse(code, message, request_id, resource, text)
end

function create_error_from_aws_code(ctx::S3RequestContext, aws_error_code::Int)::AbstractS3Error
    message = aws_error_str(aws_error_code)
    aws_error_code != 0 && return S3ConnectionError(ctx.host, message)
    return S3Error(ctx.operation, 0, aws_error_code, nothing, message, nothing, nothing, UInt8[])
end

function create_error_from_response(ctx::S3RequestContext, response::S3Response)::AbstractS3Error
    parsed = parse_error_response(response.body)
    code = parsed !== nothing ? parsed.code : nothing
    message = determine_error_message(parsed, response)
    resource = determine_resource_string(ctx, parsed)
    err_type = classify_error_type(code, response.status)
    return create_typed_error(err_type, ctx, response, message, resource, code, parsed)
end

function determine_error_message(parsed::Union{Nothing,S3ErrorResponse}, response::S3Response)::String
    parsed !== nothing && parsed.message !== nothing && return parsed.message
    status_msg = get(HTTP_STATUS_MESSAGES, response.status, nothing)
    status_msg !== nothing && return status_msg
    response.error_code != 0 && return aws_error_str(response.error_code)
    parsed !== nothing && !isempty(strip(parsed.raw_text)) && return strip(parsed.raw_text)
    return "request_failed"
end

function determine_resource_string(ctx::S3RequestContext, parsed::Union{Nothing,S3ErrorResponse})::String
    parsed !== nothing && parsed.resource !== nothing && return parsed.resource
    ctx.key !== nothing && ctx.bucket !== nothing && return "$(ctx.bucket)/$(ctx.key)"
    ctx.bucket !== nothing && return ctx.bucket
    return "unknown"
end

function create_typed_error(
    err_type::Symbol, ctx::S3RequestContext, response::S3Response,
    message::String, resource::String, code::Union{Nothing,String},
    parsed::Union{Nothing,S3ErrorResponse},
)::AbstractS3Error
    err_type === :access_denied && return S3AccessDeniedError(ctx.operation, resource, message)
    err_type === :auth_error && return S3AuthenticationError(ctx.operation, message)
    err_type === :bucket_exists && ctx.bucket !== nothing && return S3BucketAlreadyExistsError(ctx.bucket)
    err_type === :bucket_not_empty && ctx.bucket !== nothing && return S3BucketNotEmptyError(ctx.bucket)
    err_type === :bucket_not_found && ctx.bucket !== nothing && return S3BucketNotFoundError(ctx.bucket, ctx.operation)
    err_type === :object_not_found && ctx.bucket !== nothing && ctx.key !== nothing && return S3ObjectNotFoundError(ctx.bucket, ctx.key, ctx.operation)

    if err_type === :not_found
        ctx.key !== nothing && ctx.bucket !== nothing && return S3ObjectNotFoundError(ctx.bucket, ctx.key, ctx.operation)
        ctx.bucket !== nothing && return S3BucketNotFoundError(ctx.bucket, ctx.operation)
    end

    if err_type === :conflict && ctx.bucket !== nothing
        ctx.operation in ("CreateBucket", "PutBucket") && return S3BucketAlreadyExistsError(ctx.bucket)
        ctx.operation in ("DeleteBucket", "RemoveBucket") && return S3BucketNotEmptyError(ctx.bucket)
    end

    err_type === :invalid_request && return S3InvalidRequestError(ctx.operation, message)
    err_type === :server_error && return S3ServerError(ctx.operation, response.status, message)
    err_type === :connection_error && return S3ConnectionError(ctx.host, message)

    request_id = parsed !== nothing ? parsed.request_id : nothing
    parsed_resource = parsed !== nothing ? parsed.resource : nothing
    return S3Error(
        ctx.operation, response.status, response.error_code, code, message,
        request_id, parsed_resource, copy(response.body),
    )
end
