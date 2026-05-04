#include <aws/s3/s3_client.h>
#include <aws/common/condition_variable.h>
#include <aws/common/error.h>
#include <aws/common/mutex.h>
#include <aws/common/byte_buf.h>

struct s3_jl_result {
    struct aws_byte_buf body;
    int status;
    int error_code;
};

struct s3_jl_ctx {
    struct s3_jl_result *res;
    struct aws_mutex mutex;
    struct aws_condition_variable cv;
    bool done;
    bool writer_ready;
};

typedef size_t (*s3_jl_stream_read_cb_fn)(
    void *user_data,
    uint8_t *buffer,
    size_t capacity,
    bool *out_eof,
    int *out_error_code);

static int s3_jl_body_cb(
    struct aws_s3_meta_request *meta_request,
    const struct aws_byte_cursor *body,
    uint64_t range_start,
    void *user_data) {

    (void)meta_request;
    (void)range_start;

    struct s3_jl_ctx *ctx = (struct s3_jl_ctx *)user_data;
    aws_mutex_lock(&ctx->mutex);
    aws_byte_buf_append_dynamic(&ctx->res->body, body);
    aws_mutex_unlock(&ctx->mutex);
    return AWS_OP_SUCCESS;
}

static void s3_jl_finish_cb(
    struct aws_s3_meta_request *meta_request,
    const struct aws_s3_meta_request_result *result,
    void *user_data) {

    (void)meta_request;
    struct s3_jl_ctx *ctx = (struct s3_jl_ctx *)user_data;
    aws_mutex_lock(&ctx->mutex);
    ctx->res->status = result->response_status;
    ctx->res->error_code = result->error_code;
    ctx->done = true;
    aws_condition_variable_notify_one(&ctx->cv);
    aws_mutex_unlock(&ctx->mutex);
}

static void s3_jl_wake_writer_cb(void *user_data) {
    struct s3_jl_ctx *ctx = (struct s3_jl_ctx *)user_data;
    aws_mutex_lock(&ctx->mutex);
    ctx->writer_ready = true;
    aws_condition_variable_notify_one(&ctx->cv);
    aws_mutex_unlock(&ctx->mutex);
}

static void s3_jl_wait_for_finish(struct s3_jl_ctx *ctx) {
    aws_mutex_lock(&ctx->mutex);
    while (!ctx->done) {
        aws_condition_variable_wait(&ctx->cv, &ctx->mutex);
    }
    aws_mutex_unlock(&ctx->mutex);
}

AWS_S3_API
int s3_jl_make_request(
    struct aws_allocator *allocator,
    struct aws_s3_client *client,
    struct aws_s3_meta_request_options *options,
    struct s3_jl_result *out_result) {

    if (out_result) {
        out_result->body = (struct aws_byte_buf){0};
        out_result->status = 0;
        out_result->error_code = 0;
    }
    if (!allocator || !client || !options || !out_result) {
        return aws_raise_error(AWS_ERROR_INVALID_ARGUMENT);
    }

    struct s3_jl_ctx ctx;
    ctx.res = out_result;
    ctx.done = false;
    ctx.writer_ready = false;
    aws_mutex_init(&ctx.mutex);
    aws_condition_variable_init(&ctx.cv);

    aws_byte_buf_init(&out_result->body, allocator, 0);

    if (options->recv_filepath.len == 0) {
        options->body_callback = s3_jl_body_cb;
        options->body_callback_ex = NULL;
    } else {
        options->body_callback = NULL;
        options->body_callback_ex = NULL;
    }
    options->finish_callback = s3_jl_finish_cb;
    options->user_data = &ctx;

    struct aws_s3_meta_request *meta = aws_s3_client_make_meta_request(client, options);
    if (!meta) {
        int err = aws_last_error();
        aws_condition_variable_clean_up(&ctx.cv);
        aws_mutex_clean_up(&ctx.mutex);
        return err;
    }

    s3_jl_wait_for_finish(&ctx);

    aws_s3_meta_request_release(meta);
    aws_condition_variable_clean_up(&ctx.cv);
    aws_mutex_clean_up(&ctx.mutex);
    return AWS_ERROR_SUCCESS;
}

AWS_S3_API
int s3_jl_make_streaming_upload_request(
    struct aws_allocator *allocator,
    struct aws_s3_client *client,
    struct aws_s3_meta_request_options *options,
    s3_jl_stream_read_cb_fn read_cb,
    void *read_user_data,
    size_t chunk_size,
    struct s3_jl_result *out_result) {

    if (out_result) {
        out_result->body = (struct aws_byte_buf){0};
        out_result->status = 0;
        out_result->error_code = 0;
    }
    if (!allocator || !client || !options || !read_cb || chunk_size == 0 || !out_result) {
        return aws_raise_error(AWS_ERROR_INVALID_ARGUMENT);
    }

    struct s3_jl_ctx ctx;
    ctx.res = out_result;
    ctx.done = false;
    ctx.writer_ready = false;
    aws_mutex_init(&ctx.mutex);
    aws_condition_variable_init(&ctx.cv);

    aws_byte_buf_init(&out_result->body, allocator, 0);

    options->body_callback = NULL;
    options->body_callback_ex = NULL;
    options->send_using_async_writes = true;
    options->finish_callback = s3_jl_finish_cb;
    options->user_data = &ctx;

    struct aws_s3_meta_request *meta = aws_s3_client_make_meta_request(client, options);
    if (!meta) {
        int err = aws_last_error();
        aws_condition_variable_clean_up(&ctx.cv);
        aws_mutex_clean_up(&ctx.mutex);
        return err;
    }

    uint8_t *chunk = aws_mem_acquire(allocator, chunk_size);
    if (!chunk) {
        int err = aws_last_error();
        aws_s3_meta_request_cancel(meta);
        s3_jl_wait_for_finish(&ctx);
        aws_s3_meta_request_release(meta);
        aws_condition_variable_clean_up(&ctx.cv);
        aws_mutex_clean_up(&ctx.mutex);
        return err;
    }

    int stream_err = AWS_ERROR_SUCCESS;
    bool sent_eof = false;
    while (!sent_eof) {
        bool chunk_eof = false;
        int read_err = AWS_ERROR_SUCCESS;
        size_t chunk_len = read_cb(read_user_data, chunk, chunk_size, &chunk_eof, &read_err);
        if (read_err != AWS_ERROR_SUCCESS) {
            stream_err = read_err;
            break;
        }

        size_t written = 0;
        while (written < chunk_len || (chunk_eof && written == chunk_len)) {
            bool write_eof = chunk_eof && (written == chunk_len);
            struct aws_byte_cursor cursor = aws_byte_cursor_from_array(chunk + written, chunk_len - written);
            struct aws_s3_meta_request_poll_write_result write_result =
                aws_s3_meta_request_poll_write(meta, cursor, write_eof, s3_jl_wake_writer_cb, &ctx);

            if (write_result.error_code != AWS_ERROR_SUCCESS) {
                stream_err = write_result.error_code;
                break;
            }
            if (write_result.bytes_processed > (chunk_len - written)) {
                stream_err = aws_raise_error(AWS_ERROR_INVALID_STATE);
                break;
            }

            size_t before_write = written;
            written += write_result.bytes_processed;

            if (!write_result.is_pending && write_result.bytes_processed == 0 && !write_eof) {
                stream_err = aws_raise_error(AWS_ERROR_INVALID_STATE);
                break;
            }

            if (write_result.is_pending) {
                aws_mutex_lock(&ctx.mutex);
                while (!ctx.writer_ready && !ctx.done) {
                    aws_condition_variable_wait(&ctx.cv, &ctx.mutex);
                }
                bool done = ctx.done;
                ctx.writer_ready = false;
                aws_mutex_unlock(&ctx.mutex);
                if (done) {
                    sent_eof = true;
                    break;
                }
            }

            if (write_eof && before_write == written && !write_result.is_pending) {
                break;
            }
        }

        if (stream_err != AWS_ERROR_SUCCESS) {
            break;
        }
        if (chunk_eof) {
            sent_eof = true;
        }
    }

    if (stream_err != AWS_ERROR_SUCCESS) {
        aws_s3_meta_request_cancel(meta);
    }

    s3_jl_wait_for_finish(&ctx);
    aws_mem_release(allocator, chunk);
    aws_s3_meta_request_release(meta);
    aws_condition_variable_clean_up(&ctx.cv);
    aws_mutex_clean_up(&ctx.mutex);

    if (stream_err != AWS_ERROR_SUCCESS) {
        return stream_err;
    }
    return AWS_ERROR_SUCCESS;
}

AWS_S3_API
void s3_jl_result_clean_up(struct s3_jl_result *result) {
    if (result) {
        aws_byte_buf_clean_up(&result->body);
    }
}
