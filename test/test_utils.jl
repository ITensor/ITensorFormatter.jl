using ITensorFormatter: filterdir, filterpaths
using Test: @test, @testset

@testset "filterdir and filterpaths" begin
    mktempdir() do dir
        # Create directory structure
        mkdir(joinpath(dir, ".git"))
        mkdir(joinpath(dir, "subdir"))
        touch(joinpath(dir, "a.jl"))
        touch(joinpath(dir, "b.txt"))
        touch(joinpath(dir, ".git", "hidden.jl"))
        touch(joinpath(dir, "subdir", "c.jl"))
        touch(joinpath(dir, "subdir", "d.txt"))

        # Only .jl files, skipping .git
        jlfiles = filterdir(x -> endswith(x, ".jl"), dir)
        @test all(endswith.(jlfiles, ".jl"))
        @test !any(contains.(jlfiles, ".git"))
        @test length(jlfiles) == 2  # a.jl, subdir/c.jl
        @test joinpath(dir, "a.jl") in jlfiles
        @test joinpath(dir, "subdir", "c.jl") in jlfiles

        # filterpaths with files and directories
        files = filterpaths(x -> endswith(x, ".jl"), [dir, joinpath(dir, "b.txt")])
        @test all(endswith.(files, ".jl"))
        @test joinpath(dir, "a.jl") in files
        @test joinpath(dir, "subdir", "c.jl") in files
    end
end
