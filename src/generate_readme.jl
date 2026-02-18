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
        cmd = `$(julia) --project=. --startup-file=no make_readme.jl`
        # `setenv` is needed so that Julia properly see the local package environment
        # (otherwise it can't seem to load packages).
        run(setenv(cmd, "JULIA_LOAD_PATH" => ":"))
        return nothing
    end
    return nothing
end
