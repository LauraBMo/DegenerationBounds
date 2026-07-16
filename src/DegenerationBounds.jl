module DegenerationBounds

import SurfaceDegeneration as SD
using Symbolics, SymbolicUtils
using JuMP, HiGHS

include("SymbolicsToJuMP.jl")

# If linear constraints, we can use a linear programming solver, like HiGHS or GLPK.
# using HiGHS
# model = Model(HiGHS.Optimizer)

# using GLPK
# model = Model(GLPK.Optimizer)
# ipopt = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
# optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt)
# model = Model(Ipopt.Optimizer)

function build_model(conditions, optimizer, symvars)
    model = Model(optimizer)
    set_silent(model)

    @variable(model, xx[1:length(symvars)] .>= 0) # Maybe >=1; Int???
    # @variable(model, xx[1:n] .>= 0, Int) # Maybe >=1; Int???
    to_model = varsdict(symvars, xx)

    ### model, bounds=to_model.(conditions)
    bounds = to_model.(conditions)
    unique!(bounds)
    filter!(!iszero, bounds)
    for P in bounds
        # println(P)
        @constraint(model, P >= 0)
    end
    JuMP.all_constraints(model; include_variable_in_set_constraints=true)
    return model, to_model
end

function minBound(conditions, obj, symvars;
                  optimizer=HiGHS.Optimizer, linear=true)

    model, to_model = build_model(conditions, optimizer, symvars)

    if linear
        @objective(model, Min, to_model(obj)) # Minimize d.
    else
        @NLobjective(model, Min, to_model(obj)) # Minimize d/m.
    end
    optimize!(model)
    out = objective_value(model)
    println("In given region, a minimum value of $(obj) is: $(out)") 
    return out
end

NefBound(DD, args...; kwarg...) =
    minBound(SD.NefConditions(DD), args...; kwarg...)

## TODO TODO
function EffMax(DD, i, new, symvars;
                optimizer=HiGHS.Optimizer, linear=true)
    # new = d-NefBound(DD)*m (homo) # Temporary constraint that
    # forces a (-1)-curve to intersect negatively.
    model, to_model = build_model(SD.NefConditions(DD), optimizer, symvars)

    @constraint(model, to_model(new) <= 0) 
    # if linear
    #     obj(D) = @objective(model, Max, to_model(D * bundle(component)))
    # else
    #     obj(D) = @NLobjective(model, Max, to_model(D * bundle(component)))
    # end
    B = SD.bundle(DD[i])
    for D in SD.EffCone(DD[i])
        @objective(model, Max, to_model(D * B))
        # If negative, the curve splits
        optimize!(model)
        println("For $D the maximum value of the intersection is: ", objective_value(model))
    end
end

# model = Model(HiGHS.Optimizer)
# model = Model(Ipopt.Optimizer)
# set_silent(model)

# n = length(allvars)
# @variable(model, xx[1:n] .>= 0, Int) # Maybe >=1???
# @objective(model, Min, xx[1]/xx[2]) # Minimize d/m. If we set m=1, it would be a linear problem and we could use HiGHS or GLPK. 


# ## get_coeffs, newvars, F, DD
# ispoly(L) = (Symbolics.degree(SD.deg(L)) > 0)
# mybundles = SD.bundlesthat(ispoly, DD)

# mycoeff(P, x) = Symbolics.value(Symbolics.coeff(Symbolics.expand(P), x)) # Si fixem m=1, caldria també el terme independent
# myget_coeffs(P, vars = allvars) =
#     SD.intfy!([mycoeff(P, x) for x in vars]) 

# mynefness = [DD[0].bundle] .* SD.NefCone(SD.surface(DD[0]))
# append!(mynefness, [DD[1].bundle] .* SD.NefCone(SD.surface(DD[1])))
# append!(mynefness, [DD[2].bundle] .* SD.NefCone(SD.surface(DD[2])))

# polys = SD.get_conditions(mynefness, xx, myget_coeffs)
# unique!(polys)

# for P in polys
#     @constraint(model, P >= 0)
# end

# JuMP.all_constraints(model; include_variable_in_set_constraints = true)

# optimize!(model)
# sol = value.(xx)
# sol[1]/sol[2] # This is the minimum value of d/m in this degeneration, ie, 3.


# # La optimització de d/m podria ser una funció de la llibreria, que agafi un DD i retorni el mínim valor de d/m.
# # Crec que millor treballar amb m=1 i optimització lineal, amb un solver que treballi sobre els enters.

# # Ara bé, si d/m és 3, això forçarà alguna (-1)-corba a intersecar negativament.

# # This is a temporary constraint that forces a (-1)-curve to intersect negatively.
# @constraint(model, xx[1] - 3*xx[2] <= 0)

# for C in SD.EffCone(SD.surface(DD[0]))
#     intersection = C * DD[0].bundle
#     poly = SD.get_conditions((intersection,), xx, myget_coeffs)[1]
#     @NLobjective(model, Max, poly) # If negative, the curve splits
#     optimize!(model)
#     println("For curve $C, the maximum value of the intersection is: ", objective_value(model))
# end


end
