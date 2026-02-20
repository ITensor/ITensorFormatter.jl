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
    isitensorpkg(path) ||
        error("Can't generate README: not an ITensor package directory: `$path`.")
    cd(joinpath(path, "docs")) do
        julia = Base.julia_cmd()
        code = """
        using Pkg: Pkg
        Pkg.instantiate()
        error()
        include("make_readme.jl")
        """
        cmd = `$(julia) --project=. --startup-file=no -e "$(code)"`
        cmd = setenv(
            cmd, "JULIA_LOAD_PATH" => "@:@stdlib", "JULIA_PKG_USE_CLI_GIT" => "true"
        )
        run(cmd)
        return nothing
    end
    return nothing
end
