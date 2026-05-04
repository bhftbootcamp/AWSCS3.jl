# AWSCS3.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bhftbootcamp.github.io/AWSCS3.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bhftbootcamp.github.io/AWSCS3.jl/dev/)
[![Build Status](https://github.com/bhftbootcamp/AWSCS3.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/bhftbootcamp/AWSCS3.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/bhftbootcamp/AWSCS3.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bhftbootcamp/AWSCS3.jl)
[![Registry](https://img.shields.io/badge/registry-Green-green)](https://github.com/bhftbootcamp/Green)

AWSCS3 is a lightweight, high-performance Julia client for S3-compatible object storage (AWS S3, etc.). Built on the AWS C SDK for maximum throughput.

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

Let's look at some of the most used cases

```julia
using AWSCS3

client = S3Client(
    host = "my_host",
    region = "us-east-1",
    access_key = ENV["S3_ACCESS_KEY"],
    secret_key = ENV["S3_SECRET_KEY"],
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

## Useful Links

- [AWS C S3](https://github.com/awslabs/aws-c-s3) – underlying C library for S3 operations.

Prebuilt binaries are downloaded automatically during installation. If a binary is not available for your platform, you can build the shim library from source:

```bash
bash deps/build_shim.sh
```

## Contributing

Contributions to AWSCS3 are welcome! If you encounter a bug, have a feature request, or would like to contribute code, please open an issue or a pull request on GitHub.
