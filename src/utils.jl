# Call `f(arg)`; if it throws, return `default`
function tryf(f, arg, default)
    return try
        f(arg)
    catch
        default
    end
end

function filterpaths!(f, files, paths; skipdirs = [".git"])
    for path in paths
        if isdir(path)
            filterdir!(f, files, path; skipdirs)
        elseif isfile(path)
            push!(files, path)
        else
            error("Input path is not a file or directory: `$path`.")
        end
    end
    return files
end
function filterpaths(f, paths; skipdirs = [".git"])
    files = String[]
    filterpaths!(f, files, paths; skipdirs)
    return files
end

# This is a generalization of `Runic.scandir!` which allows specifying the file filter
# function and directories to skip:
# https://github.com/fredrikekre/Runic.jl/blob/5254f9055ce8e513ceda135d3b71da8086a98111/src/main.jl#L33-L65
# Also it is related to `Base.walkdir`, which ideally we would use but that doesn't
# allow avoiding decending into skipped directories.
function filterdir(f, dir::AbstractString; skipdirs = [".git"])
    files = String[]
    filterdir!(f, files, dir; skipdirs)
    return files
end
function filterdir!(f, files, dir::AbstractString; skipdirs = [".git"])
    any(∈(skipdirs), splitpath(dir)) && return nothing
    tryf(isdir, dir, false) || return nothing
    dirs = String[]
    for name in tryf(readdir, dir, String[])
        path = joinpath(dir, name)
        if tryf(isdir, path, false)
            (name ∈ skipdirs) && continue
            push!(dirs, path)
        elseif (tryf(isfile, path, false) || tryf(islink, path, false)) &&
                tryf(f, path, false)
            push!(files, path)
        else
            # ignore
        end
    end
    for d in dirs
        filterdir!(f, files, d; skipdirs)
    end
    return
end
