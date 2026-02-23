using JuliaFormatter: JuliaFormatter
using Runic: Runic

isjlfile(path) = endswith(last(splitpath(path)), ".jl")

# JuliaFormatter options chosen to be compatible with Runic.
# JuliaFormatter handles line wrapping (which Runic doesn't do),
# then Runic runs last to canonicalize everything else.
const JULIAFORMATTER_OPTIONS = (
    style = JuliaFormatter.DefaultStyle(),
    indent = 4,
    margin = 92,
    always_for_in = true,
    for_in_replacement = "in",
    # Semantic transformations consistent with Runic
    always_use_return = true,
    # Ideally we would use `import_to_using = true`, however that changes the import
    # formatting, which requires reformatting imports again which is expensive without
    # a better solution besides running JuliaFormatter twice.
    import_to_using = false,
    pipe_to_function_call = true,
    short_to_long_function_def = true,
    long_to_short_function_def = false,
    conditional_to_if = true,
    short_circuit_to_if = false,
    # Whitespace options consistent with Runic
    whitespace_typedefs = true,
    whitespace_ops_in_indices = true,
    whitespace_in_kwargs = true,
    # Annotation/structural changes
    annotate_untyped_fields_with_any = true,
    format_docstrings = true,
    remove_extra_newlines = true,
    indent_submodule = true,
    separate_kwargs_with_semicolon = true,
    surround_whereop_typeparameters = true,
    disallow_single_arg_nesting = false,
    normalize_line_endings = "unix",
    # Line-wrapping-related options
    trailing_comma = false,
    join_lines_based_on_source = true,
    # Floating point formatting options
    trailing_zero = true,
)
function format_juliaformatter!(paths)
    JuliaFormatter.format(paths; JULIAFORMATTER_OPTIONS...)
    return nothing
end

function format_runic!(paths::AbstractVector{<:AbstractString})
    Runic.main(["--inplace"; paths])
    return nothing
end
format_runic!(path::AbstractString) = format_runic!([path])

const ITENSORFORMATTER_VERSION = pkgversion(@__MODULE__)

# Print a typical cli program help message
function print_help()
    io = stdout
    printstyled(io, "NAME"; bold = true)
    println(io)
    println(io, "       ITensorFormatter.main - format Julia source code")
    println(io)
    printstyled(io, "SYNOPSIS"; bold = true)
    println(io)
    println(io, "       julia -m ITensorFormatter [<options>] <path>...")
    println(io)
    printstyled(io, "DESCRIPTION"; bold = true)
    println(io)
    println(
        io, """
               `ITensorFormatter.main` (typically invoked as `julia -m ITensorFormatter`)
               formats Julia source code using the ITensorFormatter.jl formatter.
        """
    )
    printstyled(io, "OPTIONS"; bold = true)
    println(io)
    println(
        io, """
               <path>...
                   Input path(s) (files and/or directories) to process. For directories,
                   all files (recursively) with the '*.jl' suffix are used as input files.

               --help
                   Print this message.

               --version
                   Print ITensorFormatter and julia version information.

               --yaml
                   Also format YAML files (*.yml, *.yaml). Disabled by default.
        """
    )
    return
end

function print_version()
    print(stdout, "itfmt version ")
    print(stdout, ITENSORFORMATTER_VERSION)
    print(stdout, ", julia version ")
    print(stdout, VERSION)
    println(stdout)
    return
end

function process_args(argv)
    format = true
    format_yaml = false
    argv_options = filter(startswith("--"), argv)

    if "--help" in argv_options
        print_help()
        return (; paths = String[], format = false, format_yaml = false)
    elseif "--version" in argv_options
        print_version()
        return (; paths = String[], format = false, format_yaml = false)
    end

    format_yaml = "--yaml" ∈ argv_options
    unknown = setdiff(argv_options, ["--yaml"])
    !isempty(unknown) && error("Options not supported: `$unknown`.")

    paths = filter(x -> !startswith(x, "--"), argv)
    return (; paths, format, format_yaml)
end

"""
    ITensorFormatter.main(argv)

Format Julia source files. Primarily formats using Runic formatting, but additionally
organizes using/import statements by merging adjacent blocks, sorting modules and symbols,
and line-wrapping. Accepts file paths and directories as arguments.

# Examples

```julia-repl
julia> using ITensorFormatter: ITensorFormatter

julia> ITensorFormatter.main(["."]);

julia> ITensorFormatter.main(["file1.jl", "file2.jl"]);

```
"""
function main(argv)
    (; paths, format, format_yaml) = process_args(argv)
    !format && return 0
    isempty(paths) && return error("No input paths provided.")
    jlfiles = filterpaths(isjlfile, paths)
    yamlfiles = format_yaml ? filterpaths(isyamlfile, paths) : String[]
    projectomls = filterpaths(isprojecttoml, paths)
    # Pass 1: Organize import/using blocks
    format_imports!(jlfiles)
    # Pass 2: Format via JuliaFormatter
    format_juliaformatter!(jlfiles)
    # Pass 3: Canonicalize via Runic
    format_runic!(jlfiles)
    # Pass 4: Format Project.toml files
    format_project_tomls!(projectomls)
    # Pass 5: Format YAML files (optional)
    format_yaml && format_yamls!(yamlfiles)
    return 0
end

@static if isdefined(Base, Symbol("@main"))
    @main
end
