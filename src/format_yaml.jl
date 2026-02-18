using OrderedCollections: OrderedDict
using YAML: YAML

function isyamlfile(path)
    file = last(splitpath(path))
    return endswith(file, ".yaml") || endswith(file, ".yml")
end

function format_yamls!(path::AbstractString)
    if isfile(path)
        format_yaml!(path)
        return nothing
    end
    @assert isdir(path) "Expected a directory path, got: $path"
    paths = filterdir(isyamlfile, path)
    format_yamls!(paths)
    return nothing
end
function format_yamls!(paths::AbstractVector{<:AbstractString})
    for path in paths
        format_yamls!(path)
    end
    return nothing
end

function format_yaml!(path::AbstractString)
    @assert isfile(path) "Expected a file path, got: $path"
    isyamlfile(path) || return nothing
    data = YAML.load_file(path; dicttype = OrderedDict{String, Any})
    YAML.write_file(path, data)
    return nothing
end
