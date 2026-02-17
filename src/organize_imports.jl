using JuliaSyntax: JuliaSyntax, @K_str, SyntaxNode, children, kind, parseall, span

function format_imports!(inputfiles::AbstractVector{<:AbstractString})
    for inputfile in inputfiles
        content = organize_import_blocks_file(inputfile)
        write(inputfile, content)
    end
    return nothing
end

is_using_or_import(x::SyntaxNode) = kind(x) === K"using" || kind(x) === K"import"

function find_using_or_import(x::SyntaxNode)
    if is_using_or_import(x)
        return x.parent
    elseif iszero(length(children(x)))
        return nothing
    else
        for child in children(x)
            result = find_using_or_import(child)
            isnothing(result) || return result
        end
        return nothing
    end
end

# JuliaSyntax nodes report (position, span) in *bytes*.
# Julia strings must be sliced using *valid string indices* (start bytes of UTF-8 chars).
#
# Convert a node's byte range into a safe `UnitRange` of valid string indices.
# (O(1): fix endpoints with `thisind`.)
function node_char_range(n::SyntaxNode, src::AbstractString)
    startb = n.position
    nspan = span(n)
    nspan <= 0 && return startb:(startb - 1) # empty range
    stopb = min(startb + nspan - 1, ncodeunits(src))
    return thisind(src, startb):thisind(src, stopb)
end

function organize_import_blocks_string(s::AbstractString)
    jst = parseall(SyntaxNode, String(s))
    return organize_import_blocks(jst)
end

function organize_import_blocks_file(f::AbstractString)
    return organize_import_blocks_string(read(f, String))
end

# Sort symbols, but keep the module self-reference (bare and all aliases) first if present
function sort_with_self_first(syms::Vector{String}, self::String)
    syms = unique(syms)
    selfs = self in syms ? [self] : String[]
    self_aliases = sort!(filter(s -> startswith(s, self * " as "), syms))
    rest = sort!(setdiff(syms, [selfs; self_aliases]))
    return [selfs; self_aliases; rest]
end

# Organize a single block of adjacent import/using statements
function organize_import_block(siblings::AbstractVector{<:SyntaxNode}, node_text)
    using_mods = Set{String}()
    using_syms = Dict{String, Vector{String}}()
    import_mods = Set{String}()
    import_syms = Dict{String, Vector{String}}()

    for s in siblings
        isusing = kind(s) === K"using"
        for a in children(s)
            if kind(a) === K":"
                a_args = children(a)
                mod = String(node_text(a_args[1]))
                set = get!(() -> String[], isusing ? using_syms : import_syms, mod)
                for i in 2:length(a_args)
                    push!(set, String(node_text(a_args[i])))
                end
            elseif kind(a) === K"." || kind(a) === K"importpath"
                push!(isusing ? using_mods : import_mods, String(node_text(a)))
            elseif !isusing && kind(a) === K"as"
                a_args = children(a)
                push!(
                    import_mods,
                    String(node_text(a_args[1])) * " as " * String(node_text(a_args[end]))
                )
            else
                error("Unexpected syntax in using/import statement.")
            end
        end
    end

    import_lines = String[]
    for m in import_mods
        push!(import_lines, "import " * m)
    end
    for (m, s) in import_syms
        push!(import_lines, "import " * m * ": " * join(sort_with_self_first(s, m), ", "))
    end
    using_lines = String[]
    for m in using_mods
        push!(using_lines, "using " * m)
    end
    for (m, s) in using_syms
        push!(using_lines, "using " * m * ": " * join(sort_with_self_first(s, m), ", "))
    end
    io = IOBuffer()
    if !isempty(import_lines)
        print(io, join(sort!(import_lines), "\n"))
    end
    if !isempty(import_lines) && !isempty(using_lines)
        print(io, "\n")
    end
    if !isempty(using_lines)
        print(io, join(sort!(using_lines), "\n"))
    end
    return String(take!(io))
end

function organize_import_blocks(input::SyntaxNode)
    # Keep a stable copy for slicing: node positions/spans refer to this text.
    src0 = JuliaSyntax.sourcetext(input)
    x = find_using_or_import(input)
    isnothing(x) && return src0
    child_nodes = children(x)
    # Find all groups of adjacent import/using statements
    groups = Vector{SyntaxNode}[]
    i = 1
    while i <= length(child_nodes)
        if is_using_or_import(child_nodes[i])
            group_start = i
            while i <= length(child_nodes) && is_using_or_import(child_nodes[i])
                i += 1
            end
            push!(groups, child_nodes[group_start:(i - 1)])
        else
            i += 1
        end
    end
    # Extract the source text of a node, trimming whitespace (Unicode-safe).
    # Always slice from src0 (stable offsets), not the rewritten `src`.
    node_text(n::SyntaxNode) = strip(src0[node_char_range(n, src0)])
    # Rewritten output source.
    src = src0
    # Process each group from right to left to preserve positions
    for siblings in reverse(groups)
        formatted = organize_import_block(siblings, node_text)
        # Compute splice bounds using src0 (node offsets), then splice into src.
        first_pos = first(node_char_range(first(siblings), src0))
        last_pos = last(node_char_range(last(siblings), src0))
        # Unicode-safe splice boundaries (never do ±1 on raw integer indices)
        before =
            first_pos == firstindex(src) ? "" :
            src[firstindex(src):prevind(src, first_pos)]
        after_start = nextind(src, last_pos)
        after = after_start > lastindex(src) ? "" : src[after_start:end]
        src = before * chomp(formatted) * after
    end
    return src
end
