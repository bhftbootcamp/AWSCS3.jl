using AWSCS3

BUCKET = "sdk-test-jl"

client = S3Client(
    host = get(ENV, "S3_HOST", "localhost:9000"),
    region = get(ENV, "S3_REGION", "us-east-1"),
    access_key = ENV["S3_ACCESS_KEY"],
    secret_key = ENV["S3_SECRET_KEY"],
    tls = false,
)

bucket_exists(client, BUCKET) || create_bucket(client, BUCKET)

put_object(client, BUCKET, "demo/hello.txt", "Hello, World!")
put_object(client, BUCKET, "demo/1mb.bin", rand(UInt8, 1_000_000))

body = get_object(client, BUCKET, "demo/hello.txt") |> String
@assert body == "Hello, World!"

objects = list_objects(client, BUCKET; prefix = "demo/")
@assert length(objects) == 2

copy_object(client, BUCKET, "demo/hello.txt", BUCKET, "demo/hello_copy.txt")

delete_all_objects!(client, BUCKET)
delete_bucket(client, BUCKET)

println("All operations passed!")

close(client)
