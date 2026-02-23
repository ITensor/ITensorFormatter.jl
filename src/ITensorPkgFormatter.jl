module ITensorPkgFormatter

using ITensorFormatter: ITensorFormatter
using Logging: Logging

"""
$(ITensorFormatter.help_markdown())
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
