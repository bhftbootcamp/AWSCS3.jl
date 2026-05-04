# API Reference

## Client

```@docs
S3Config
S3Client
Base.isopen(::S3Client)
shutdown!
```

## Operations

### Buckets

```@docs
create_bucket
delete_bucket
bucket_exists
list_buckets
set_bucket_versioning
```

### Objects

```@docs
put_object
get_object
delete_object
delete_objects
copy_object
object_exists
list_objects
list_objects_detailed
delete_all_objects!
```

## Result Types

```@docs
S3Object
S3ListResult
S3CopyResult
```

## Errors

```@docs
AbstractS3Error
S3Error
S3AccessDeniedError
S3BucketAlreadyExistsError
S3BucketNotFoundError
S3BucketNotEmptyError
S3ObjectNotFoundError
S3InvalidRequestError
S3ServerError
S3ConnectionError
S3AuthenticationError
```
