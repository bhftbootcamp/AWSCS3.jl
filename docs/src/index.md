# AWSCS3.jl

AWSCS3 is a lightweight, high-performance Julia client for S3-compatible object storage (AWS S3, etc.). Built on the [AWS C SDK](https://github.com/awslabs/aws-c-s3) for maximum throughput.

## Installation

If you haven't installed our [local registry](https://github.com/bhftbootcamp/Green) yet, do that first:

```
] registry add https://github.com/bhftbootcamp/Green.git
```

To install AWSCS3, simply use the Julia package manager:

```julia
] add AWSCS3
```

## Usage

Here is a basic example of working with an S3-compatible service:

```julia
using AWSCS3

client = S3Client(
    host = "s3.amazonaws.com",
    region = "us-east-1",
    access_key = ENV["AWS_ACCESS_KEY_ID"],
    secret_key = ENV["AWS_SECRET_ACCESS_KEY"],
)

bucket_exists(client, "my-bucket") || create_bucket(client, "my-bucket")

put_object(client, "my-bucket", "demo/hello.txt", "Hello, World!")
put_object(client, "my-bucket", "demo/data.bin", UInt8[0x01, 0x02, 0x03, 0x04])

body = get_object(client, "my-bucket", "demo/hello.txt") |> String

for obj in list_objects(client, "my-bucket"; prefix = "demo/")
    println("$(obj.key) ($(obj.size) bytes)")
end

copy_object(client, "my-bucket", "demo/hello.txt", "my-bucket", "demo/hello_copy.txt")
delete_objects(client, "my-bucket", ["demo/hello.txt", "demo/hello_copy.txt", "demo/data.bin"])

close(client)
```

### Using S3Config

You can also create a client from a configuration struct:

```julia
using AWSCS3

cfg = S3Config(
    host = "localhost:9000",
    region = "us-east-1",
    access_key = "admin",
    secret_key = "admin123",
    tls = false,
)

client = S3Client(cfg)

# ... use client ...

shutdown!(client)
```

### Do-block pattern

The do-block pattern automatically shuts down the client when the block exits:

```julia
using AWSCS3

S3Client(
    host = "localhost:9000",
    region = "us-east-1",
    access_key = "admin",
    secret_key = "admin123",
    tls = false,
) do client
    create_bucket(client, "my-bucket")
    put_object(client, "my-bucket", "key.txt", "value")
    body = get_object(client, "my-bucket", "key.txt") |> String
end
```

### Pagination

Use [`list_objects_detailed`](@ref) for paginated listings:

```julia
result = list_objects_detailed(client, "my-bucket"; max_keys = 100)

for obj in result.objects
    println("$(obj.key) ($(obj.size) bytes)")
end

if result.is_truncated
    next_page = list_objects_detailed(
        client, "my-bucket";
        max_keys = 100,
        continuation_token = result.continuation_token,
    )
end
```

### Error handling

All operations throw [`AbstractS3Error`](@ref) subtypes on failure:

```julia
try
    get_object(client, "my-bucket", "nonexistent-key")
catch e::S3ObjectNotFoundError
    println("Object '$(e.key)' not found in bucket '$(e.bucket)'")
end
```
