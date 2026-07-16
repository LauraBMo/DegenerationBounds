
"""
    symbolics_to_jump(p, symvars, jumpvars)

Translate a Symbolics.jl expression `p` (polynomial in `symvars`, from
`@variables`) into the corresponding JuMP expression, by substituting each
`symvars[i]` with `jumpvars[i]` — typically a `VariableRef` from
`@variable(model, xx[1:k])`, but any JuMP expression works too.

How it works: walk `p`'s tree via `iscall`/`operation`/`arguments`, and at each node call `operation(node)` on the *already-translated* arguments.
Once a leaf becomes a JuMP object, every `+`, `-`, `*`, `^` above it dispatches to JuMP's own operator overloads.

Degree matters for what you can solve afterwards: total degree ≤ 2 produces
a `QuadExpr` (any QP solver handles it); degree ≥ 3 produces a
`GenericNonlinearExpr` (needs a nonlinear solver, e.g. Ipopt).
"""
function symbolics_to(p, symvars, jumpvars)
    vars_dict = Dict(Symbolics.unwrap.(symvars) .=> jumpvars)
    return _to_jump(Symbolics.unwrap(p), vars_dict)
end

varsdict(symvars, jumpvars) = p -> symbolics_to(p, symvars, jumpvars)

function _to_jump(e, vars::Dict)
    if !SymbolicUtils.iscall(e)
        e isa Number && return e   # plain numeric literals pass through
        # SymbolicUtils wraps numeric literals arising from operations
        SymbolicUtils.isconst(e) && return SymbolicUtils.unwrap_const(e)
        haskey(vars, e) && return vars[e]
        error("symbolics_to_jump: no substitution provided for `$e`. " *
              "Either it's missing from `symvars`/`jumpvars`, or it's meant " *
              "to be a fixed numeric parameter — substitute its value.")
    end
    op = SymbolicUtils.operation(e)
    args = SymbolicUtils.arguments(e)
    return op(map(a -> _to_jump(a, vars), args)...)
end

# --- If you're building purely on SymbolicUtils.jl (no Symbolics.jl) -----
# Drop the `Symbolics.unwrap` calls entirely — bare SymbolicUtils terms
# aren't wrapped in `Num`.
#
#   symbolics_to_jump_raw(p, vars, jumpvars) = _to_jump(p, vars, jumpvars)
