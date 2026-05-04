#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JULIA_BIN="${JULIA:-julia}"

cd "$PROJECT_DIR"

S3_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_s3_jll; print(aws_c_s3_jll.artifact_dir)")
COMMON_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_common_jll; print(aws_c_common_jll.artifact_dir)")
AUTH_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_auth_jll; print(aws_c_auth_jll.artifact_dir)")
HTTP_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_http_jll; print(aws_c_http_jll.artifact_dir)")
IO_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_io_jll; print(aws_c_io_jll.artifact_dir)")
CAL_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_cal_jll; print(aws_c_cal_jll.artifact_dir)")
COMPRESSION_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_compression_jll; print(aws_c_compression_jll.artifact_dir)")
SDKUTILS_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_c_sdkutils_jll; print(aws_c_sdkutils_jll.artifact_dir)")
CHECKSUMS_ARTIFACT=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "using aws_checksums_jll; print(aws_checksums_jll.artifact_dir)")
TARGET_ARCH=$("$JULIA_BIN" --project="$PROJECT_DIR" -e "print(Sys.ARCH)")

INCLUDE_PATHS="-I$S3_ARTIFACT/include \
-I$COMMON_ARTIFACT/include \
-I$AUTH_ARTIFACT/include \
-I$HTTP_ARTIFACT/include \
-I$IO_ARTIFACT/include \
-I$CAL_ARTIFACT/include \
-I$COMPRESSION_ARTIFACT/include \
-I$SDKUTILS_ARTIFACT/include \
-I$CHECKSUMS_ARTIFACT/include"

LIBRARY_PATHS="-L$S3_ARTIFACT/lib \
-L$COMMON_ARTIFACT/lib"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    LIB_EXT="so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    LIB_EXT="dylib"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    LIB_EXT="dll"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

LIB_NAME="libs3_jl_shim.${LIB_EXT}"

ARCH_FLAG=""
MAC_ARCH=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    case "$TARGET_ARCH" in
        aarch64)
            ARCH_FLAG="-arch arm64"
            MAC_ARCH="arm64"
            ;;
        x86_64)
            ARCH_FLAG="-arch x86_64"
            MAC_ARCH="x86_64"
            ;;
        *)
            echo "Unsupported macOS architecture: $TARGET_ARCH"
            exit 1
            ;;
    esac

    if command -v lipo >/dev/null 2>&1; then
        for lib in "$S3_ARTIFACT/lib/libaws-c-s3.${LIB_EXT}" "$COMMON_ARTIFACT/lib/libaws-c-common.${LIB_EXT}"; do
            if ! lipo -info "$lib" | grep -q "$MAC_ARCH"; then
                echo "Library $lib does not contain architecture slice $MAC_ARCH."
                echo "Run Julia for the same architecture as your installed JLLs (e.g. arm64 Julia on Apple Silicon) and retry."
                exit 1
            fi
        done
    fi
fi

CC_BIN=${CC:-cc}
CFLAGS=${CFLAGS:-}
LDFLAGS=${LDFLAGS:-}

cd "$SCRIPT_DIR"

# Create output directory
LIB_DIR="$SCRIPT_DIR/lib"
mkdir -p "$LIB_DIR"
OUTPUT_PATH="$LIB_DIR/$LIB_NAME"

echo "Building shim with $CC_BIN ${ARCH_FLAG:-} for Julia arch $TARGET_ARCH"
"$CC_BIN" -std=c11 -fPIC -shared ${ARCH_FLAG:+$ARCH_FLAG} $CFLAGS s3_shim.c \
$INCLUDE_PATHS \
$LIBRARY_PATHS \
-laws-c-s3 -laws-c-common $LDFLAGS \
-o "$OUTPUT_PATH"

echo "Successfully built $OUTPUT_PATH"
