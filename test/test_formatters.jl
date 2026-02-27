using ITensorFormatter: format_imports!, format_project_tomls!, format_yamls!
using Test: @test, @testset

@testset "format_imports!" begin
    mktempdir() do dir
        path = joinpath(dir, "test.jl")
        write(path, "using Zebra: z\nusing Alpha: a\n")
        format_imports!(path)
        result = read(path, String)
        @test occursin("using Alpha: a", result)
        @test occursin("using Zebra: z", result)
        @test findfirst("Alpha", result) < findfirst("Zebra", result)
    end
end

@testset "format_yamls!" begin
    mktempdir() do dir
        path = joinpath(dir, "test.yaml")
        write(path, "b: 2\na: 1\n")
        format_yamls!(path)
        result = read(path, String)
        @test occursin("a: 1", result)
        @test occursin("b: 2", result)
    end
end

@testset "format_project_tomls!" begin
    mktempdir() do dir
        path = joinpath(dir, "Project.toml")
        write(path, "[compat]\nJulia = \"1.10.0\"\nFoo = \"1.2.0, 2.0.0\"\n")
        format_project_tomls!(path)
        result = read(path, String)
        @test occursin("Julia = \"1.10\"", result)
        @test occursin("Foo = \"1.2, 2\"", result)
    end

    mktempdir() do dir
        path = joinpath(dir, "Project.toml")
        write(
            path,
            """
            [deps]
            Zebra = "00000000-0000-0000-0000-000000000001"
            Alpha = "00000000-0000-0000-0000-000000000002"
            """
        )
        format_project_tomls!(path)
        result = read(path, String)
        @test !startswith(result, "\n")
        @test findfirst("Alpha", result) < findfirst("Zebra", result)
    end
end
