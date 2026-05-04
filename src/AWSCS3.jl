module AWSCS3

include("libaws_c_s3.jl")
using .Libaws_c_s3

include("Util.jl")
using .Util

include("errors.jl")
include("client.jl")
include("requests.jl")
include("operations.jl")

#__ Client

export S3Client,
    S3Config,
    shutdown!

#__ Operations

export bucket_exists,
    list_buckets,
    list_objects,
    list_objects_detailed,
    get_object,
    put_object,
    copy_object,
    delete_object,
    delete_objects,
    create_bucket,
    delete_bucket,
    delete_all_objects!,
    set_bucket_versioning,
    object_exists

#__ Result types

export S3Object,
    S3ListResult,
    S3CopyResult

#__ Errors

export AbstractS3Error,
    S3Error,
    S3AccessDeniedError,
    S3BucketAlreadyExistsError,
    S3BucketNotFoundError,
    S3BucketNotEmptyError,
    S3ObjectNotFoundError,
    S3InvalidRequestError,
    S3ServerError,
    S3ConnectionError,
    S3AuthenticationError

end
