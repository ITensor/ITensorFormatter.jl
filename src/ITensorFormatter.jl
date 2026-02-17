module ITensorFormatter

if VERSION >= v"1.11.0-DEV.469"
    let str = "public main"
        eval(Meta.parse(str))
    end
end

include("organize_imports.jl")
include("main.jl")

end
