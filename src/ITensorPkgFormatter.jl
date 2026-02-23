module ITensorPkgFormatter

using ITensorFormatter: ITensorFormatter
using Logging: Logging

"""
    ITensorPkgFormatter.main(argv)

Format ITensor Julia packages. This function first calls `ITensorFormatter.main(argv)` to format Julia source files, Project.toml, and YAML files, then generates README documentation for each provided ITensor package directory (by running `generate_readme!` in each directory's `docs/`).

This is typically invoked via the `itpkgfmt` CLI or `julia -m ITensorPkgFormatter`.

# Arguments

  - `argv`: Array of command-line arguments (paths and options).

# Behavior

  - All formatting options and help/version flags are forwarded to `ITensorFormatter.main`.
  - After formatting, for each path that is an ITensor package directory, a README is generated.

# Example

```julia-repl
julia> using ITensorPkgFormatter

julia> ITensorPkgFormatter.main(["MyPkg"])

```
"""
function main(argv)
    ITensorFormatter.main(argv)
    paths = filter(!startswith("--"), argv)
    Logging.with_logger(Logging.NullLogger()) do
        return ITensorFormatter.generate_readmes!(paths)
    end
    return nothing
end

@static if isdefined(Base, Symbol("@main"))
    @main
end

end
