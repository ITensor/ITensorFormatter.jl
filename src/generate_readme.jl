using Literate: Literate

function isitensorpkg(path::AbstractString)
    return isdir(path) &&
        isfile(joinpath(path, "Project.toml")) &&
        isdir(joinpath(path, "src")) &&
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
            include("make_readme.jl")
            return nothing
        end
    catch e
        @warn "Failed to generate README: $e"
    end
    return nothing
end
