#This is a testable documentation showing all the features.

include("..\\src\\Arceus.jl")

using .Arceus
using BenchmarkTools

#Traitpool must be defined at compile time.
println("Checkpoint!")

@traitpool "ABCDEF" begin
    @trait electro
    @trait flame #Defining trait without bits.
    @trait laser at 2 #Defining trait with a specified bit (from the right or least significant.)
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta at 16-32 begin #Subpool can be defined with a specified number of bits, but for a concrete subpool, the number of bits can be defined.
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 at 33-48 #Defining start and finish bits.
    @abstract_subpool reserve2 at 8 #Defining the size, but not the sub_trait.
end
println("Checkpoint2!")

#This will register the variable at compile time and construct a trait pool at runtime.
@make_traitpool Pokemon from "ABCDEF" begin
    @trait electro #Creating trait pool with the following traits.
    @trait flame
end

println("Checkpoint3!")
#Subpool also must be defined in the global scope.
@subpool "Biome" from "ABCDEF".reserve1.biome_preference begin
    @trait beach_preference
    @trait ice_preference
    @trait volcanic_preference
end
#Defining concrete subpool. 
@subpool "Meta" from "ABCDEF".meta

#=
@make_subpool "Biome" from biometraits <= Pokemon
@make_subpool "Meta" from metatraits <= Pokemon
@make_subpool "Biome" from biometraits2 begin
    @trait beach_preference
    @trait -ice_preference
    @trait volcanic_preference
end
=#
#This "registers" subpool.
#Usage...
#function x(biometraits3::get_trait_pool_type("Biome"))
#    @register_subpool "Biome" from biometraits3 #Since this is a subpool.
    #Use @register_traitpool for a non-subpool trait pool.
#end
#Or you can maybe use generated function to manipulate the type yourself (see the register_traitpool macro) but that comes with its own issue (world age issue).
#=
macro register_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool] # Remove this line if you're accepting trait pool type already.
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return
end

This does make it a bit difficult to use generics. Should be fine because each trait pool has different traits and could be incompatible anyway.

=#


#This joins the subpools to their parent traitpool (Presume parent, otherwise they write whatever bits they happen to occupy).
#This syntax is used for the sake of consistent syntax across the entire package.
#@join_subpools Pokemon begin
#    @subpool biometraits2
#    @subpool metatraits
#end



#You can modify and copy trait pools.

#copying needs its own macro too.
@copy_traitpool Pokemon => Pokemon2
@copy_traitpool Pokemon => Pokemon3
@copy_traitpool Pokemon => Pokemon4
@make_traitpool X from "ABCDEF"
@copy_traitpool Pokemon => X
#You can use copy_traitpool to existing trait pools too.

@settraits Pokemon2 begin
    @trait +electro 
    @trait +roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end

@addtraits Pokemon3 begin
    @trait electro 
    @trait roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end

@removetraits Pokemon4 begin
    @trait electro 
    @trait roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end



f1 = @lookup k "ABCDEF" begin
    out = 1.0
    if @hastrait k.electro
        out *= 2
    end
    if @hastrait k.flame
        out *= 1.5 
    end
    if @hastrait k.meta.earlygame
        out *= 1.2
    end
    return out
end
println(f1)
#If the variable is not registered, it is not seen in the module, the result is error finding variable of that name.
@register_variable f1
#Making lookup.
println(@macroexpand @make_lookup f1)
#We then can finally make the lookup function.
x_arr = @make_lookup f1
@btime lookup_val = $x_arr[$Pokemon]
lookup_val = x_arr[Pokemon]

println(lookup_val)