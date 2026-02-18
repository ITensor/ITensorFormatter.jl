using TOML: TOML

isprojecttoml(path) = last(splitpath(path)) == "Project.toml"

function format_project_tomls!(path::AbstractString)
    if isfile(path)
        format_project_toml!(path)
        return nothing
    end
    @assert isdir(path) "Expected a directory path, got: $path"
    paths = filterdir(isprojecttoml, path)
    format_project_tomls!(paths)
    return nothing
end
function format_project_tomls!(paths::AbstractVector{<:AbstractString})
    for path in paths
        format_project_toml!(path)
    end
    return nothing
end

function format_project_toml!(path::AbstractString)
    @assert isfile(path) "Expected a file path, got: $path"
    isprojecttoml(path) || return nothing
    # This calls `strip_compat_trailing_zeros!(path)` internally.
    strip_compat_trailing_zeros!(path)
    return nothing
end

function sort_project_toml!(path::AbstractString)
    top_key_order = ["name", "uuid", "version", "authors"]
    table_order = [
        "workspace", "deps", "weakdeps", "extensions", "compat", "apps", "extras",
        "targets",
    ]
    is_table(x) = x isa AbstractDict
    raw = read(path, String)
    data = TOML.parse(raw)
    io = IOBuffer()
    scalar_keys = String[]
    for k in top_key_order
        haskey(data, k) && !is_table(data[k]) && push!(scalar_keys, k)
    end
    for k in sort(collect(keys(data)))
        !(k in scalar_keys) && !is_table(data[k]) && push!(scalar_keys, k)
    end
    for k in scalar_keys
        TOML.print(io, Dict(k => data[k]))
    end
    table_keys = String[]
    seen = Set{String}()
    for k in table_order
        if haskey(data, k) && is_table(data[k])
            push!(table_keys, k)
            push!(seen, k)
        end
    end
    for k in sort(collect(keys(data)))
        is_table(data[k]) && !(k in seen) && push!(table_keys, k)
    end
    for k in table_keys
        println(io)
        TOML.print(io, Dict(k => data[k]); sorted = true)
    end
    out = String(take!(io))
    endswith(out, "\n") || (out *= "\n")
    out == raw && return false
    write(path, out)
    return true
end

# Strip trailing `.0` segments from a single version string.
# E.g. `"1.10.0"` → `"1.10"`, `"4.0.0"` → `"4"`, `"1.2.3"` → `"1.2.3"`.
function strip_version_zeros(s::AbstractString)
    s = replace(s, r"\.0\.0$" => "")
    s = replace(s, r"\.0$" => "")
    return s
end

# Strip trailing `.0` or `.0.0` from version strings in `[compat]`.
# E.g. `"1.10.0"` → `"1.10"`, `"4.0.0"` → `"4"`. Returns `true` if the file changed.
function strip_compat_trailing_zeros!(path::AbstractString)
    data = TOML.parsefile(path)
    haskey(data, "compat") || return false
    changed = false
    for (pkg, val) in data["compat"]
        # Handle comma-separated version specs like "0.6.2, 0.7"
        parts = map(strip, split(val, ","))
        new_parts = map(strip_version_zeros, parts)
        new_val = join(new_parts, ", ")
        if new_val != val
            data["compat"][pkg] = new_val
            changed = true
        end
    end
    changed || return false
    open(path, "w") do io
        return TOML.print(io, data)
    end
    sort_project_toml!(path)
    return true
end
