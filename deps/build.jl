using TOML
using EasyCurl

const RELEASE_BASE_URL = "https://github.com/bhftbootcamp/AWSCS3.jl/releases/download"

lib_name() = Sys.iswindows() ? "libs3_jl_shim.dll" :
             Sys.isapple()   ? "libs3_jl_shim.dylib" : "libs3_jl_shim.so"

function platform_tag()
    if Sys.islinux()
        if Sys.ARCH === :x86_64
            return "linux-x86_64"
        elseif Sys.ARCH === :aarch64
            return "linux-aarch64"
        else
            error("Unsupported Linux architecture: $(Sys.ARCH)")
        end
    elseif Sys.isapple()
        return Sys.ARCH === :aarch64 ? "macos-aarch64" : "macos-x86_64"
    elseif Sys.iswindows()
        return "windows-x86_64"
    else
        error("Unsupported platform: $(Sys.KERNEL)")
    end
end

platform_pretty() = Sys.islinux()   ? "Linux" :
                    Sys.isapple()   ? "macOS" :
                    Sys.iswindows() ? "Windows" : string(Sys.KERNEL)

julia_minor() = "$(VERSION.major).$(VERSION.minor)"

function project_version(pkg_dir::AbstractString)
    toml = TOML.parsefile(joinpath(pkg_dir, "Project.toml"))
    v = get(toml, "version", nothing)
    v isa String || error("Project.toml has no valid `version` entry")
    return v
end

function try_download_release(pkg_dir::String, lib_path::String)
    tarbin = Sys.which("tar")
    if tarbin === nothing
        @warn "`tar` not found on PATH; cannot extract downloaded archive" platform=platform_pretty()
        return false
    end
    ver  = project_version(pkg_dir)
    plat = platform_tag()
    jver = julia_minor()
    url  = "$RELEASE_BASE_URL/v$ver/$plat-julia$jver.tar.gz"
    @info "Downloading pre-built binary" url
    tmp = tempname() * ".tar.gz"
    try
        resp = http_request("GET", url; read_timeout=30, connect_timeout=10)
        if http_status(resp) != 200
            @warn "Pre-built binary not available" status=http_status(resp) version=ver platform=plat julia=jver
            return false
        end
        mkpath(dirname(lib_path))
        write(tmp, http_body(resp))
        run(`$tarbin -xzf $tmp -C $(dirname(lib_path))`)
        isfile(lib_path) && return true
        @warn "Archive extracted but expected library not found" lib_path
        return false
    catch e
        @warn "Download or extraction failed" url exception=(e, catch_backtrace())
        return false
    finally
        rm(tmp; force=true)
    end
end

function try_build_local(pkg_dir::String, lib_path::String)
    build_script = joinpath(pkg_dir, "deps", "build_shim.sh")
    isfile(build_script) || return false
    bash = get(ENV, "BASH", Sys.which("bash"))
    if bash === nothing
        @warn "bash not found; cannot run build script"
        return false
    end
    load_path = join(["@", "@v#.#", "@stdlib"], Sys.iswindows() ? ";" : ":")
    try
        withenv("JULIA_PKG_PRECOMPILE_AUTO" => "0", "JULIA_LOAD_PATH" => load_path) do
            run(`$(Base.julia_cmd()) --project=$pkg_dir -e 'import Pkg; Pkg.instantiate()'`)
        end
        cd(dirname(build_script)) do
            withenv("JULIA_PROJECT" => pkg_dir, "JULIA_LOAD_PATH" => load_path) do
                run(`$bash $build_script`)
            end
        end
        isfile(lib_path) && (@info "Built from source" lib_path; return true)
    catch e
        @warn "Build from source failed" exception=(e, catch_backtrace())
    end
    return false
end

function main()
    pkg_dir  = dirname(@__DIR__)
    lib_path = joinpath(pkg_dir, "deps", "lib", lib_name())

    isfile(lib_path) && (@info "Library already present" lib_path; return)

    try_download_release(pkg_dir, lib_path) && return
    try_build_local(pkg_dir, lib_path) && return

    plat = platform_pretty()
    tag  = platform_tag()
    jver = julia_minor()
    error("""
    Could not locate $(lib_name()) for $plat (Julia $jver).

    Tried:
    1) Existing file:  $lib_path
    2) GitHub release: $RELEASE_BASE_URL/v<version>/$tag-julia$jver.tar.gz
    3) Local build via deps/build_shim.sh

    To resolve, either:
    - place a prebuilt $(lib_name()) into deps/lib/
    - or build manually:
        bash deps/build_shim.sh
    """)
end

main()
