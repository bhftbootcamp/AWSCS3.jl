using Test
using AWSCS3

const S3_HOST       = get(ENV, "AWSCS3_TEST_HOST", "localhost:9000")
const S3_REGION     = get(ENV, "AWSCS3_TEST_REGION", "us-east-1")
const S3_ACCESS_KEY = get(ENV, "AWSCS3_TEST_ACCESS_KEY", "admin")
const S3_SECRET_KEY = get(ENV, "AWSCS3_TEST_SECRET_KEY", "admin123")
const TEST_BUCKET   = "awscs3-test-" * lowercase(join(rand('a':'z', 8)))

const RUN_INTEGRATION = get(ENV, "AWSCS3_RUN_INTEGRATION_TESTS", "false") == "true"

@testset verbose = true "AWSCS3.jl" begin

    @testset "Unit Tests" begin

        @testset "Config" begin
            cfg = S3Config(
                host = "s3.amazonaws.com",
                region = "us-east-1",
                access_key = "AKID",
                secret_key = "SECRET",
            )
            @test cfg.host == "s3.amazonaws.com"
            @test cfg.region == "us-east-1"
            @test cfg.user_agent == "AWSCS3.jl"
            @test cfg.connect_timeout_ms == 3000
            @test cfg.tls == true

            cfg2 = S3Config(
                host = "localhost:9000",
                region = "us-east-1",
                access_key = "AK",
                secret_key = "SK",
                tls = false,
                connect_timeout_ms = 5000,
            )
            @test cfg2.host == "localhost:9000"
            @test cfg2.tls == false
            @test cfg2.connect_timeout_ms == 5000

            buf = IOBuffer()
            show(buf, cfg)
            s = String(take!(buf))
            @test occursin("s3.amazonaws.com", s)
            @test occursin("***", s)
            @test !occursin("AKID", s)
            @test !occursin("SECRET", s)
        end

        @testset "Util" begin
            @test AWSCS3.Util.encode_uri_path("hello/world") == "hello/world"
            @test AWSCS3.Util.encode_uri_path("hello world") == "hello%20world"
            @test AWSCS3.Util.encode_uri_path("foo/bar baz") == "foo/bar%20baz"
            @test AWSCS3.Util.encode_uri_path("a+b=c") == "a%2Bb%3Dc"

            @test AWSCS3.Util.encode_query_component("hello world") == "hello%20world"
            @test AWSCS3.Util.encode_query_component("a/b") == "a%2Fb"
            @test AWSCS3.Util.encode_query_component("abc") == "abc"

            @test AWSCS3.Util.s3_path("mybucket") == "/mybucket"
            @test AWSCS3.Util.s3_path("mybucket", "mykey") == "/mybucket/mykey"
            @test AWSCS3.Util.s3_path("mybucket", "dir/file.txt") == "/mybucket/dir/file.txt"
            @test AWSCS3.Util.s3_path("mybucket", "key with spaces") == "/mybucket/key%20with%20spaces"

            hdrs = Pair{String,String}[]
            AWSCS3.Util.set_header!(hdrs, "Content-Type", "text/plain")
            @test length(hdrs) == 1
            @test hdrs[1] == ("content-type" => "text/plain")

            AWSCS3.Util.set_header!(hdrs, "Content-Type", "application/json")
            @test length(hdrs) == 1
            @test hdrs[1] == ("content-type" => "application/json")

            AWSCS3.Util.set_header!(hdrs, "X-Custom", "value")
            @test length(hdrs) == 2
            @test AWSCS3.Util.has_header(hdrs, "Content-Type") == true
            @test AWSCS3.Util.has_header(hdrs, "content-type") == true
            @test AWSCS3.Util.has_header(hdrs, "X-Missing") == false
            @test AWSCS3.Util.get_header(hdrs, "Content-Type") == "application/json"
            @test AWSCS3.Util.get_header(hdrs, "X-Missing") === nothing

            @test AWSCS3.Util.build_query_string(Pair{String,String}[]) == ""
            qs = AWSCS3.Util.build_query_string(["a" => "1", "b" => "hello world"])
            @test startswith(qs, "?")
            @test occursin("a=1", qs)
            @test occursin("b=hello%20world", qs)

            @test AWSCS3.Util.try_bytes_to_string(UInt8[]) === nothing
            @test AWSCS3.Util.try_bytes_to_string(Vector{UInt8}("hello")) == "hello"

            @test AWSCS3.Util.capture_xml_element("<Root><Name>test</Name></Root>", "Name") == "test"
            @test AWSCS3.Util.capture_xml_element("<Root><Other>x</Other></Root>", "Name") === nothing
            @test AWSCS3.Util.capture_xml_element("<Root><s3:Name>ns</s3:Name></Root>", "Name") == "ns"
            @test AWSCS3.Util.capture_xml_element("<Root><Name>&amp;foo</Name></Root>", "Name") == "&foo"

            @test AWSCS3.Util.decode_xml_entities("&amp;&lt;&gt;&quot;&apos;") == "&<>\"'"
            @test AWSCS3.Util.decode_xml_entities("&#65;") == "A"
            @test AWSCS3.Util.decode_xml_entities("&#x41;") == "A"
        end

        @testset "Parser" begin
            list_xml = """<?xml version="1.0" encoding="UTF-8"?>
            <ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <Buckets>
                    <Bucket><Name>bucket-a</Name></Bucket>
                    <Bucket><Name>bucket-b</Name></Bucket>
                </Buckets>
            </ListAllMyBucketsResult>"""
            names = AWSCS3.parse_bucket_names(Vector{UInt8}(list_xml))
            @test names == ["bucket-a", "bucket-b"]
            @test AWSCS3.parse_bucket_names(UInt8[]) == String[]

            objects_xml = """<?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <Contents>
                    <Key>file1.txt</Key>
                    <Size>100</Size>
                    <LastModified>2024-01-01T00:00:00Z</LastModified>
                    <ETag>"abc123"</ETag>
                </Contents>
                <Contents>
                    <Key>file2.txt</Key>
                    <Size>200</Size>
                    <LastModified>2024-01-02T00:00:00Z</LastModified>
                    <ETag>"def456"</ETag>
                </Contents>
            </ListBucketResult>"""
            objs = AWSCS3.parse_list_objects(Vector{UInt8}(objects_xml))
            @test length(objs) == 2
            @test objs[1].key == "file1.txt"
            @test objs[1].size == 100
            @test objs[1].etag == "abc123"
            @test objs[2].key == "file2.txt"
            @test objs[2].size == 200
            @test AWSCS3.parse_list_objects(UInt8[]) == S3Object[]

            detailed_xml = """<?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <IsTruncated>true</IsTruncated>
                <NextContinuationToken>tok123</NextContinuationToken>
                <Contents>
                    <Key>a.txt</Key><Size>10</Size>
                    <LastModified>2024-01-01T00:00:00Z</LastModified><ETag>"e1"</ETag>
                </Contents>
                <CommonPrefixes><Prefix>dir/</Prefix></CommonPrefixes>
            </ListBucketResult>"""
            result = AWSCS3.parse_list_objects_detailed(Vector{UInt8}(detailed_xml))
            @test result.is_truncated == true
            @test result.continuation_token == "tok123"
            @test length(result.objects) == 1
            @test result.objects[1].key == "a.txt"
            @test result.common_prefixes == ["dir/"]

            empty_result = AWSCS3.parse_list_objects_detailed(UInt8[])
            @test empty_result.is_truncated == false
            @test empty_result.continuation_token === nothing
            @test isempty(empty_result.objects)

            copy_xml = """<?xml version="1.0" encoding="UTF-8"?>
            <CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <ETag>"abc"</ETag>
                <LastModified>2024-06-01T12:00:00Z</LastModified>
            </CopyObjectResult>"""
            cr = AWSCS3.parse_copy_result(Vector{UInt8}(copy_xml))
            @test cr.etag == "abc"
            @test cr.last_modified == "2024-06-01T12:00:00Z"
            @test AWSCS3.parse_copy_result(UInt8[]) == S3CopyResult("", "")
        end

        @testset "Errors" begin
            @test AWSCS3.classify_error_type("AccessDenied", 403) == :access_denied
            @test AWSCS3.classify_error_type("NoSuchKey", 404) == :object_not_found
            @test AWSCS3.classify_error_type("NoSuchBucket", 404) == :bucket_not_found
            @test AWSCS3.classify_error_type("BucketAlreadyExists", 409) == :bucket_exists
            @test AWSCS3.classify_error_type("BucketNotEmpty", 409) == :bucket_not_empty
            @test AWSCS3.classify_error_type("InvalidAccessKeyId", 403) == :auth_error
            @test AWSCS3.classify_error_type("InternalError", 500) == :server_error
            @test AWSCS3.classify_error_type(nothing, 401) == :auth_error
            @test AWSCS3.classify_error_type(nothing, 403) == :access_denied
            @test AWSCS3.classify_error_type(nothing, 404) == :not_found
            @test AWSCS3.classify_error_type(nothing, 500) == :server_error
            @test AWSCS3.classify_error_type(nothing, 0) == :connection_error
            @test AWSCS3.classify_error_type(nothing, 999) == :unknown

            buf = IOBuffer()
            showerror(buf, S3Error("PutObject", 403, 0, "AccessDenied", "forbidden", "req1", "mybucket/key", UInt8[]))
            s = String(take!(buf))
            @test occursin("S3Error", s)
            @test occursin("PutObject", s)
            @test occursin("403", s)

            buf = IOBuffer()
            showerror(buf, S3BucketAlreadyExistsError("test-bucket"))
            s = String(take!(buf))
            @test occursin("test-bucket", s)
            @test occursin("already exists", s)

            buf = IOBuffer()
            showerror(buf, S3ObjectNotFoundError("bucket", "key", "GetObject"))
            s = String(take!(buf))
            @test occursin("key", s)
            @test occursin("bucket", s)

            buf = IOBuffer()
            showerror(buf, S3ConnectionError("localhost:9000", "connection refused"))
            s = String(take!(buf))
            @test occursin("localhost:9000", s)

            buf = IOBuffer()
            showerror(buf, S3ServerError("ListBuckets", 503, "Service Unavailable"))
            s = String(take!(buf))
            @test occursin("503", s)

            buf = IOBuffer()
            showerror(buf, S3AuthenticationError("PutObject", "bad key"))
            s = String(take!(buf))
            @test occursin("PutObject", s)

            buf = IOBuffer()
            showerror(buf, S3InvalidRequestError("Delete", "bad xml"))
            s = String(take!(buf))
            @test occursin("Delete", s)

            buf = IOBuffer()
            showerror(buf, S3BucketNotFoundError("gone", "HeadBucket"))
            s = String(take!(buf))
            @test occursin("gone", s)

            buf = IOBuffer()
            showerror(buf, S3BucketNotEmptyError("full"))
            s = String(take!(buf))
            @test occursin("full", s)

            buf = IOBuffer()
            showerror(buf, S3AccessDeniedError("GetObject", "mybucket/mykey", "Access Denied"))
            s = String(take!(buf))
            @test occursin("mybucket/mykey", s)

            @test AbstractS3Error <: Exception
            @test S3Error <: AbstractS3Error
            @test S3AccessDeniedError <: AbstractS3Error
            @test S3BucketAlreadyExistsError <: AbstractS3Error
            @test S3BucketNotFoundError <: AbstractS3Error
            @test S3BucketNotEmptyError <: AbstractS3Error
            @test S3ObjectNotFoundError <: AbstractS3Error
            @test S3InvalidRequestError <: AbstractS3Error
            @test S3ServerError <: AbstractS3Error
            @test S3ConnectionError <: AbstractS3Error
            @test S3AuthenticationError <: AbstractS3Error
        end

    end

    if !RUN_INTEGRATION
        @info "Skipping integration tests (set AWSCS3_RUN_INTEGRATION_TESTS=true with a running S3-compatible server to enable)"
    end

    RUN_INTEGRATION && @testset "Integration Tests" begin
        client = S3Client(;
            host = S3_HOST,
            region = S3_REGION,
            access_key = S3_ACCESS_KEY,
            secret_key = S3_SECRET_KEY,
            tls = false,
        )

        try
            @testset "Bucket Operations" begin
                @test bucket_exists(client, TEST_BUCKET) == false

                create_bucket(client, TEST_BUCKET)
                @test bucket_exists(client, TEST_BUCKET) == true

                create_bucket(client, TEST_BUCKET; ignore_existing=true)

                buckets = list_buckets(client)
                @test TEST_BUCKET in buckets

                @test bucket_exists(client, "awscs3-nonexistent-bucket-xyz-999") == false
            end

            @testset "Object Operations" begin
                put_object(client, TEST_BUCKET, "test-string.txt", "hello world")
                put_object(client, TEST_BUCKET, "test-bytes.bin", Vector{UInt8}("binary data"))

                @test object_exists(client, TEST_BUCKET, "test-string.txt") == true
                @test object_exists(client, TEST_BUCKET, "test-bytes.bin") == true
                @test object_exists(client, TEST_BUCKET, "nonexistent-key") == false

                body = get_object(client, TEST_BUCKET, "test-string.txt")
                @test String(body) == "hello world"

                body2 = get_object(client, TEST_BUCKET, "test-bytes.bin")
                @test String(body2) == "binary data"

                tmpfile = tempname()
                try
                    get_object(client, TEST_BUCKET, "test-string.txt", tmpfile)
                    @test isfile(tmpfile)
                    @test read(tmpfile, String) == "hello world"
                finally
                    isfile(tmpfile) && rm(tmpfile)
                end

                objs = list_objects(client, TEST_BUCKET)
                keys = [o.key for o in objs]
                @test "test-string.txt" in keys
                @test "test-bytes.bin" in keys

                result = list_objects_detailed(client, TEST_BUCKET)
                @test length(result.objects) >= 2
                detail_keys = [o.key for o in result.objects]
                @test "test-string.txt" in detail_keys
            end

            @testset "Copy & Delete" begin
                copy_result = copy_object(client, TEST_BUCKET, "test-string.txt",
                                          TEST_BUCKET, "test-copy.txt")
                @test !isempty(copy_result.etag)

                body = get_object(client, TEST_BUCKET, "test-copy.txt")
                @test String(body) == "hello world"

                delete_object(client, TEST_BUCKET, "test-copy.txt")
                @test object_exists(client, TEST_BUCKET, "test-copy.txt") == false
            end

            @testset "Metadata & Headers" begin
                put_object(client, TEST_BUCKET, "meta-test.txt", "meta content";
                           metadata=["custom-key" => "custom-value"])
                @test object_exists(client, TEST_BUCKET, "meta-test.txt") == true

                copy_object(client, TEST_BUCKET, "meta-test.txt",
                            TEST_BUCKET, "meta-copy.txt";
                            metadata=["new-key" => "new-value"])
                @test object_exists(client, TEST_BUCKET, "meta-copy.txt") == true

                delete_object(client, TEST_BUCKET, "meta-test.txt")
                delete_object(client, TEST_BUCKET, "meta-copy.txt")
            end

            @testset "Pagination" begin
                for i in 1:5
                    put_object(client, TEST_BUCKET, "page/item-$(lpad(i, 3, '0')).txt", "data $i")
                end

                result1 = list_objects_detailed(client, TEST_BUCKET; prefix="page/", max_keys=2)
                @test length(result1.objects) == 2
                @test result1.is_truncated == true
                @test result1.continuation_token !== nothing

                result2 = list_objects_detailed(client, TEST_BUCKET; prefix="page/",
                                                max_keys=2,
                                                continuation_token=result1.continuation_token)
                @test length(result2.objects) == 2

                all_objects = list_objects(client, TEST_BUCKET; prefix="page/")
                @test length(all_objects) == 5

                for i in 1:5
                    delete_object(client, TEST_BUCKET, "page/item-$(lpad(i, 3, '0')).txt")
                end
            end

            @testset "Prefix & Delimiter" begin
                put_object(client, TEST_BUCKET, "dir/a.txt", "a")
                put_object(client, TEST_BUCKET, "dir/b.txt", "b")
                put_object(client, TEST_BUCKET, "dir/sub/c.txt", "c")
                put_object(client, TEST_BUCKET, "other.txt", "o")

                prefix_objs = list_objects(client, TEST_BUCKET; prefix="dir/")
                prefix_keys = [o.key for o in prefix_objs]
                @test "dir/a.txt" in prefix_keys
                @test "dir/b.txt" in prefix_keys
                @test "dir/sub/c.txt" in prefix_keys
                @test !("other.txt" in prefix_keys)

                delim_result = list_objects_detailed(client, TEST_BUCKET; prefix="dir/", delimiter="/")
                delim_keys = [o.key for o in delim_result.objects]
                @test "dir/a.txt" in delim_keys
                @test "dir/b.txt" in delim_keys
                @test !("dir/sub/c.txt" in delim_keys)
                @test "dir/sub/" in delim_result.common_prefixes

                delete_object(client, TEST_BUCKET, "dir/a.txt")
                delete_object(client, TEST_BUCKET, "dir/b.txt")
                delete_object(client, TEST_BUCKET, "dir/sub/c.txt")
                delete_object(client, TEST_BUCKET, "other.txt")
            end

            @testset "Error Handling" begin
                @test_throws S3ObjectNotFoundError get_object(client, TEST_BUCKET, "nonexistent-key-xyz")

                put_object(client, TEST_BUCKET, "blocker.txt", "block")
                @test_throws AbstractS3Error delete_bucket(client, TEST_BUCKET)
                delete_object(client, TEST_BUCKET, "blocker.txt")

                @test_throws S3BucketAlreadyExistsError create_bucket(client, TEST_BUCKET)
            end

            @testset "Batch Delete" begin
                batch_keys = ["batch/$(i).txt" for i in 1:5]
                for k in batch_keys
                    put_object(client, TEST_BUCKET, k, k)
                end
                @test all(object_exists(client, TEST_BUCKET, k) for k in batch_keys)

                delete_objects(client, TEST_BUCKET, batch_keys)
                @test all(!object_exists(client, TEST_BUCKET, k) for k in batch_keys)

                delete_objects(client, TEST_BUCKET, String[])
            end

            @testset "Cleanup" begin
                put_object(client, TEST_BUCKET, "cleanup-1.txt", "1")
                put_object(client, TEST_BUCKET, "cleanup-2.txt", "2")

                delete_all_objects!(client, TEST_BUCKET)
                objs = list_objects(client, TEST_BUCKET)
                @test isempty(objs)

                delete_bucket(client, TEST_BUCKET)
                @test bucket_exists(client, TEST_BUCKET) == false
            end

            @testset "Context Manager" begin
                ctx_bucket = TEST_BUCKET * "-ctx"
                result = S3Client(;
                    host = S3_HOST,
                    region = S3_REGION,
                    access_key = S3_ACCESS_KEY,
                    secret_key = S3_SECRET_KEY,
                    tls = false,
                ) do c
                    create_bucket(c, ctx_bucket)
                    put_object(c, ctx_bucket, "ctx-key.txt", "ctx-data")
                    body = get_object(c, ctx_bucket, "ctx-key.txt")
                    delete_all_objects!(c, ctx_bucket)
                    delete_bucket(c, ctx_bucket)
                    return String(body)
                end
                @test result == "ctx-data"
            end

        finally
            try delete_all_objects!(client, TEST_BUCKET) catch end
            try delete_bucket(client, TEST_BUCKET) catch end
            try delete_all_objects!(client, TEST_BUCKET * "-ctx") catch end
            try delete_bucket(client, TEST_BUCKET * "-ctx") catch end
            shutdown!(client)
        end
    end
end
