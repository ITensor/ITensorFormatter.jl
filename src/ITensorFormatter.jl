module ITensorFormatter

if VERSION >= v"1.11.0-DEV.469"
    let str = "public main"
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

end
