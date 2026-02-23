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

        @compile_workload begin
            # Ideally we might use `ITensorPkgFormatter.main([tmp])` to include
            # precompilation of README generation, however it seems tricky to get that
            # working because of the file generation involved in that workflow.
            main([tmp])
        end
    finally
        rm(tmp; recursive = true, force = true)
    end
end
