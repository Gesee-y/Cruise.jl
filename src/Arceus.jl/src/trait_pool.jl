########################################################### Trait Pool ######################################################

const TRAIT_POOL_NAMES= Dict{String,Type{<:TraitPool}}()
const TRAIT_POOL_DESCRIPTORS = Dict{Type{<:TraitPool}, PoolDescriptor}()
const TRAIT_POOL_TYPES = Dict{Symbol, Type{<:TraitPool}}()

getvalue(trait::TraitPool) = trait.value
setvalue(trait::TraitPool, x::UInt64) = typeof(trait)(x)

# Ensuring no one try these
macro trait(x...)
    return :(error("Trait is not executable outside of a @traitpool.")) 
end

macro subpool(x...)
    return :(error("Subpool is not executable outside of a @traitpool.")) 
end

macro abstract_subpool(x...)
    return :(error("Abstract subpool is not executable outside of a @traitpool.")) 
end

"""
    @traitpool name begin
       ...
    end

Define a new trait pool with the given name. In the begin block, you should define your traits and subpools

## Example

```julia

@traitpool "ABCDEF" begin
    @trait electro # Create a trait with a dynamic position
    @trait flame
    @trait laser at 2 # Define a trait with a fixed position ( the 2nd bit)
    @subpool roles begin # a new subpool with a dynamic position. This one will take 2 bits
        @trait attacker
        @trait support
        
    end
    @subpool meta at 16-32 begin # a new pool with a fixed size and position
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 at 33-48 # Abstract pool with undefined traits, going from 33 to 48
    @abstract_subpool reserve2 at 8 # this one just have a size of 8 bits, no fixed position
end
```
"""
macro traitpool(x,y)
    y = parse_traits(y)
    trait_pool_name = gensym()
    module_name = @__MODULE__

    return esc(:(
        struct $trait_pool_name<:($module_name).TraitPool
            value::UInt64
            $trait_pool_name() = new()
            $trait_pool_name(x) = new(x)
        end;
        ($module_name).TRAIT_POOL_NAMES[$x] = $trait_pool_name;
        ($module_name).TRAIT_POOL_DESCRIPTORS[$trait_pool_name] = $y)
    )
    
end

"""
    @make_traitpool traitpool var

Generate a new empty trait pool from `traitpool` and store it in `var`.

    @make_traitpool traitpool var begin
        ...
    end

This will generate a new trait pool from `traitpool` and assign it to `var` 
which will contains the pool traits and subpools defined in the begin block

## Example

```julia

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

#This will register the variable at compile time and construct a trait pool at runtime.
@make_traitpool "ABCDEF" Pokemon begin
    @trait electro #Creating trait pool with the following traits.
    @trait flame
end
```
"""
macro make_traitpool(variable, word, traitpool)
    if word == KEYWORDS[:from]
        var_quot = Meta.quot(variable)
        traitpool_struct = TRAIT_POOL_NAMES[traitpool]
        module_name = @__MODULE__
        eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
        return esc(:($variable = $traitpool_struct(0)))
    else
        error("Invalid syntax. Got $ex.\nExpected @make_traitpool traitpool from var_name.")
    end
end
macro make_traitpool(variable,word,traitpool,traits_set)
    if word == KEYWORDS[:from]
        ans = quote
            @make_traitpool $variable from $traitpool
            @addtraits $variable $traits_set
            
        end
        return esc(ans)
    else
        error("Invalid syntax. Got $ex.\nExpected @make_traitpool traitpool from var_name begin ... end.")
    end
end

"""
    @register_traitpool traitpool variable

Register the `variable` to directly get it's `traitpool`.
Deprecated in favour of `@register_variable`
"""
macro register_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool]
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return
end

"""
    @copy_traitpool var1 => var2

Copy the `var1`'s traits pool to the `var2` and register it
"""
macro copy_traitpool(expr)
    module_name = @__MODULE__
    if expr.args[1] == KEYWORDS[:to]
        variable1, variable2 = expr.args[2], expr.args[3]
        traitpool_struct = TRAIT_POOL_TYPES[variable1]
        var_quot = Meta.quot(variable2)
        eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
        return esc(:($variable2 = $variable1))
    else
        error("Invalid syntax. Got $ex.\nExpected @copy_traitpool var1 => var2")
    end
end

#End of part 1... defining traits.