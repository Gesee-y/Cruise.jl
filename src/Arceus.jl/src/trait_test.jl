
"""
    @hastrait var.trait

Return whether the variable `var` has the given `trait`

## Example

```julia

@traitpool "ABCDEF" begin
    @trait electro
    @trait flame
    @trait laser 2
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta 16-32 begin
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 33-48
    @abstract_subpool reserve2 8
end

@make_traitpool "ABCDEF" Pokemon begin
    @trait electro
    @trait flame
end

@hastrait Pokemon.flame
"""
macro hastrait(expression)
    #println(parse_walk_chain(expression))
    Temp = parse_walk_chain(expression)
    varname = Temp[1]
    walk = Temp[2:end]
    trait_pool_descriptor = get_trait_pool_descriptor(varname)
    traitnum = walk_trait_pool_descriptor(walk,trait_pool_descriptor)
    trait_bit = UInt64(1)<<(traitnum-1)
    return esc(:(!iszero(getvalue($varname)&($trait_bit))))
end

macro usetrait(expression)
    return nothing
end
