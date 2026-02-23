using PrecompileTools: @compile_workload, @setup_workload

@setup_workload begin
    tmp = mktempdir()
    try
        # Make tmp look like an ITensor package dir (so generate_readme! runs)
        for d in ("src", "docs", "examples")
            mkpath(joinpath(tmp, d))
        end

        # Minimal files so the formatter has something to do
        write(joinpath(tmp, "src", "Example.jl"), "module Example\nx=1\nend\n")
        write(joinpath(tmp, "config.yaml"), "a: 1\nb: 2\n")
        write(
            joinpath(tmp, "Project.toml"),
            "name = \"Example\"\nuuid = \"00000000-0000-0000-0000-000000000000\"\nversion = \"0.1.0\"\n"
        )

        # Copy the package's real docs/make_readme.jl into tmp/docs/
        pkgroot = pkgdir(@__MODULE__)  # ITensorFormatter package root
        cp(
            joinpath(pkgroot, "docs", "make_readme.jl"),
            joinpath(tmp, "docs", "make_readme.jl");
            force = true
        )

        # Provide tmp/examples/README.jl for Literate to convert -> tmp/README.md
        cp(
            joinpath(pkgroot, "examples", "README.jl"),
            joinpath(tmp, "examples", "README.jl");
            force = true
        )

        @compile_workload begin
            main([tmp])
            # ITensorPkgFormatter.main([tmp])
        end
    finally
        rm(tmp; recursive = true, force = true)
    end
end
