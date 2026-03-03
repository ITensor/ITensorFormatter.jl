using Literate: Literate
using SafeTestsets: @safetestset
using Suppressor: @suppress

_pkgroot(pkg::Module) = pkgdir(pkg)
_pkgroot(pkg::AbstractString) = pkg

const GFM_ALERT_HEADER_MAP = Dict(
    "> [!CAUTION]" => "!!! danger",
    "> [!IMPORTANT]" => "!!! important",
    "> [!NOTE]" => "!!! note",
    "> [!TIP]" => "!!! tip",
    "> [!WARNING]" => "!!! warning"
)

function _gfm_alerts(content::AbstractString)
    lines = split(content, '\n')
    output = String[]
    in_alert = false
    for line in lines
        if haskey(GFM_ALERT_HEADER_MAP, line)
            push!(output, GFM_ALERT_HEADER_MAP[line])
            in_alert = true
        elseif in_alert && startswith(line, ">")
            if line == ">"
                push!(output, "")
            elseif startswith(line, "> ")
                push!(output, "    " * line[3:end])
            else
                push!(output, line)
            end
        else
            in_alert = false
            push!(output, line)
        end
    end
    return join(output, '\n')
end

function _ccq_logo_readme(content::AbstractString)
    include_ccq_logo = """
    <picture>
      <source media="(prefers-color-scheme: dark)" width="20%" srcset="docs/src/assets/CCQ-dark.png">
      <img alt="Flatiron Center for Computational Quantum Physics logo." width="20%" src="docs/src/assets/CCQ.png">
    </picture>
    """
    return replace(content, "{CCQ_LOGO}" => include_ccq_logo)
end

function _ccq_logo_index(content::AbstractString)
    include_ccq_logo = """
    ```@raw html
    <img class="display-light-only" src="assets/CCQ.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
    <img class="display-dark-only" src="assets/CCQ-dark.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
    ```
    """
    return replace(content, "{CCQ_LOGO}" => include_ccq_logo)
end

function make_readme!(
        pkg::Union{Module, AbstractString};
        inputfile = joinpath(_pkgroot(pkg), "examples", "README.jl"),
        outputdir = _pkgroot(pkg),
        flavor = Literate.CommonMarkFlavor(),
        name = "README",
        postprocess = _ccq_logo_readme
    )
    Literate.markdown(inputfile, outputdir; flavor, name, postprocess)
    return nothing
end

function make_index!(
        pkg::Union{Module, AbstractString};
        inputfile = joinpath(_pkgroot(pkg), "examples", "README.jl"),
        outputdir = joinpath(_pkgroot(pkg), "docs", "src"),
        flavor = Literate.DocumenterFlavor(),
        name = "index",
        postprocess = _gfm_alerts ∘ _ccq_logo_index
    )
    Literate.markdown(inputfile, outputdir; flavor, name, postprocess)
    return nothing
end

function isitensorpkg(path::AbstractString)
    return isdir(path) &&
        isfile(joinpath(path, "Project.toml")) &&
        isdir(joinpath(path, "src")) &&
        isdir(joinpath(path, "docs")) &&
        isfile(joinpath(path, "examples", "README.jl"))
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
        make_readme!(path)
        return nothing
    catch e
        @warn "Failed to generate README: $e"
    end
    return nothing
end

function _istestfile(path::AbstractString)
    fn = basename(path)
    return endswith(fn, ".jl") && startswith(basename(fn), "test_") &&
        !contains(fn, "setup")
end

function _isexamplefile(path::AbstractString)
    fn = basename(path)
    return endswith(fn, ".jl") && !endswith(fn, "_notest.jl") && !contains(fn, "setup")
end

function _group(; args = ARGS, env = ENV)
    pat = r"(?:--group=)(\w+)"
    arg_id = findfirst(contains(pat), args)
    return uppercase(
        if isnothing(arg_id)
            arg = get(env, "GROUP", "ALL")
            arg == "" ? "ALL" : arg
        else
            only(match(pat, args[arg_id]).captures)
        end
    )
end

function runtests(; testdir = @__DIR__, args = ARGS, env = ENV)
    group = _group(; args, env)
    @time begin
        for testgroup in filter(isdir, readdir(testdir; join = true))
            if group == "ALL" || group == uppercase(basename(testgroup))
                for filename in filter(_istestfile, readdir(testgroup; join = true))
                    @eval @safetestset $(basename(filename)) begin
                        include($filename)
                    end
                end
            end
        end

        for file in filter(_istestfile, readdir(testdir; join = true))
            (basename(file) == "runtests.jl") && continue
            @eval @safetestset $(basename(file)) begin
                include($file)
            end
        end

        examplepath = joinpath(testdir, "..", "examples")
        if isdir(examplepath)
            for (root, _, files) in walkdir(examplepath)
                contains(chopprefix(root, testdir), "setup") && continue
                for file in filter(_isexamplefile, files)
                    filename = joinpath(root, file)
                    @eval @safetestset $file begin
                        @suppress include($filename)
                    end
                end
            end
        end
    end
    return nothing
end
