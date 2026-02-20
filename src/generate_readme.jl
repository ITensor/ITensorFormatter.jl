function isitensorpkg(path::AbstractString)
    return isdir(path) &&
        isfile(joinpath(path, "Project.toml")) &&
        isdir(joinpath(path, "src")) &&
        isdir(joinpath(path, "test")) &&
        isdir(joinpath(path, "docs")) &&
        isfile(joinpath(path, "docs", "make_readme.jl"))
end

function generate_readmes!(paths::AbstractVector{<:AbstractString})
    for path in paths
        generate_readme!(path)
    end
    return nothing
end

function generate_readme!(path::AbstractString)
    if !isitensorpkg(path)
        @warn "Can't generate README: not an ITensor package directory: `$path`."
        return nothing
    end
    try
        cd(joinpath(path, "docs")) do
            julia = Base.julia_cmd()
            code = """
            using Pkg: Pkg
            # Install packages needed for "make_readme.jl".
            Pkg.instantiate(; io = devnull)
            include("make_readme.jl")
            """
            cmd = `$(julia) --project=. --startup-file=no -e "$(code)"`
            cmd = setenv(
                cmd, "JULIA_LOAD_PATH" => "@:@stdlib", "JULIA_PKG_USE_CLI_GIT" => "true"
            )
            run(cmd)
            return nothing
        end
    catch e
        @warn "Failed to generate README: $e"
    end
    return nothing
end
