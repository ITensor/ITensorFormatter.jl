module ITensorFormatter

if VERSION >= v"1.11.0-DEV.469"
    let str = "public ITensorPkgFormatter, generate_readme!, generate_readmes!, main, make_index!, make_readme!, runtests"
        eval(Meta.parse(str))
    end
end

include("utils.jl")
include("format_imports.jl")
include("format_yaml.jl")
include("format_project_toml.jl")
include("main.jl")
include("generate_readme.jl")
include("ITensorPkgFormatter.jl")
include("precompile_workload.jl")

end
