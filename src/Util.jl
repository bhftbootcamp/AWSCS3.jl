module Util

using ..Libaws_c_s3: ByteCursor, aws_last_error, aws_error_str
using Printf

export byte_cursor, to_bytes, assert_nonnull, assert_aws_ok
export is_unreserved_byte, encode_uri_path, encode_query_component, s3_path
export set_header!, has_header, get_header
export build_query_string, build_list_params
export try_bytes_to_string, capture_xml_element, decode_xml_entities

#__ bytes

function try_bytes_to_string(body::Vector{UInt8})::Union{Nothing,String}
    isempty(body) && return nothing
    try
        return String(copy(body))
    catch
        return nothing
    end
end

byte_cursor(s::String)::ByteCursor = ByteCursor(length(codeunits(s)), pointer(codeunits(s)))
byte_cursor(v::Vector{UInt8})::ByteCursor = ByteCursor(length(v), pointer(v))

to_bytes(body::Vector{UInt8})::Vector{UInt8} = body
to_bytes(body::String)::Vector{UInt8} = Vector{UInt8}(codeunits(body))

function assert_nonnull(ptr, name::String)
    if ptr == C_NULL
        code = aws_last_error()
        error("$(name) returned NULL: $(code) $(aws_error_str(code))")
    end
    return ptr
end

function assert_aws_ok(code::Integer, name::String)::Nothing
    if code != 0
        err = aws_last_error()
        error("$(name) failed: $(err) $(aws_error_str(err))")
    end
    return nothing
end

#__ XML

function decode_xml_entities(text::AbstractString)::String
    decoded = replace(text,
        "&quot;" => "\"",
        "&apos;" => "'",
        "&lt;" => "<",
        "&gt;" => ">",
        "&amp;" => "&",
    )
    decoded = replace(decoded, r"&#x[0-9A-Fa-f]+;" => s -> begin
        hex = s[4:end-1]
        string(Char(parse(Int, hex, base = 16)))
    end)
    decoded = replace(decoded, r"&#\d+;" => s -> begin
        dec = s[3:end-1]
        string(Char(parse(Int, dec)))
    end)
    return decoded
end

function capture_xml_element(text::AbstractString, tag::AbstractString)::Union{Nothing,String}
    patterns = (
        Regex("<(?:[\\w-]+:)?$(tag)\\b[^>]*>\\s*([^<]+?)\\s*</(?:[\\w-]+:)?$(tag)>", "s"),
        Regex("<$(tag)\\b[^>]*>\\s*([^<]+?)\\s*</$(tag)>", "s"),
    )
    for pat in patterns
        m = match(pat, text)
        if m !== nothing
            return decode_xml_entities(strip(m.captures[1]))
        end
    end
    return nothing
end

function _escape_xml_text(text::AbstractString)::String
    escaped = replace(text, "&" => "&amp;")
    escaped = replace(escaped, "<" => "&lt;")
    escaped = replace(escaped, ">" => "&gt;")
    escaped = replace(escaped, "\"" => "&quot;")
    escaped = replace(escaped, "'" => "&apos;")
    return escaped
end

#__ URI encoding

function is_unreserved_byte(b::UInt8)::Bool
    return (b >= 0x41 && b <= 0x5a) ||
           (b >= 0x61 && b <= 0x7a) ||
           (b >= 0x30 && b <= 0x39) ||
           b in (0x2d, 0x2e, 0x5f, 0x7e)
end

function encode_uri_path(key::String)::String
    buf = IOBuffer()
    for b in codeunits(key)
        if b == 0x2f || is_unreserved_byte(b)
            write(buf, b)
        else
            @printf(buf, "%%%02X", b)
        end
    end
    return String(take!(buf))
end

function encode_query_component(value::String)::String
    buf = IOBuffer()
    for b in codeunits(value)
        if is_unreserved_byte(b)
            write(buf, b)
        else
            @printf(buf, "%%%02X", b)
        end
    end
    return String(take!(buf))
end

function s3_path(bucket::String, key::String = "")::String
    encoded_key = isempty(key) ? "" : encode_uri_path(key)
    return string("/", bucket, isempty(encoded_key) ? "" : "/", encoded_key)
end

#__ headers

function set_header!(headers::Vector{Pair{String,String}}, name::String, value::String)::Vector{Pair{String,String}}
    name_lower = lowercase(name)
    for i in eachindex(headers)
        if first(headers[i]) == name_lower
            headers[i] = name_lower => value
            return headers
        end
    end
    push!(headers, name_lower => value)
    return headers
end

function has_header(headers::Vector{Pair{String,String}}, name::String)::Bool
    name_lower = lowercase(name)
    for (k, _) in headers
        k == name_lower && return true
    end
    return false
end

function get_header(headers::Vector{Pair{String,String}}, name::String)::Union{Nothing,String}
    name_lower = lowercase(name)
    for (k, v) in headers
        k == name_lower && return v
    end
    return nothing
end

#__ query

function build_query_string(params::Vector{Pair{String,String}})::String
    isempty(params) && return ""
    encoded = (string(encode_query_component(k), "=", encode_query_component(v)) for (k, v) in params)
    return "?" * join(encoded, "&")
end

function build_list_params(;
    prefix::String,
    delimiter::String,
    continuation_token::String,
    max_keys::Union{Nothing,Int},
)::Vector{Pair{String,String}}
    params = Pair{String,String}["list-type" => "2"]
    !isempty(prefix) && push!(params, "prefix" => prefix)
    !isempty(delimiter) && push!(params, "delimiter" => delimiter)
    !isempty(continuation_token) && push!(params, "continuation-token" => continuation_token)
    max_keys !== nothing && push!(params, "max-keys" => string(max_keys))
    return params
end

end
