module ITensorPkgFormatter

using ITensorFormatter: ITensorFormatter

function main(argv)
    ITensorFormatter.main(argv)
    paths = filter(!startswith("--"), argv)
    ITensorFormatter.generate_readme!(paths)
    return nothing
end

@static if isdefined(Base, Symbol("@main"))
    @main
end

end
