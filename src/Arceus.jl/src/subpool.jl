abstract type SubPool end

#=
Subpool
    implicit info::PoolDescriptor
    implicit parent_pool::Type{<:TraitPool}
end
=#

SUB_POOL_NAMES= Dict{String,Type{<:SubPool}}()
SUB_POOL_DESCRIPTORS = Dict{Type{<:SubPool}, PoolDescriptor}()
SUB_POOL_PARENTS = Dict{Type{<:SubPool}, Type{<:TraitPool}}()
SUB_POOL_TYPES = Dict{Symbol, Type{<:SubPool}}()
getvalue(trait::SubPool) = trait.value
setvalue(trait::SubPool, x::UInt64) = typeof(trait)(x)
function parse_subpool_source(x::Expr)
    @assert x.head == Symbol(".")
    a,b = parse_subpool_source(x.args[1])
    push!(b,x.args[2].value)
    return a,b
end

function parse_subpool_source(x::String)
    return x, Vector{Symbol}()
end


#=
mutable struct PoolDescriptor
    isAbstract::Bool
    start::Int
    finish::Int
    args::Dict{Symbol, Union{Int, PoolDescriptor}}

end
=#


#Name varname to be subpool of a pool or subpool walking down from parent.
macro subpool(subpool,word,source, traitsset::Expr)
    if word == KEYWORDS[:from]
        module_name = @__MODULE__
        #trait_pool_type = get_trait_pool_type(source.args[1])
        
        #println(traitsset|>dump)
        #Walk_trait in trait_pool_descriptor 
        trait_pool_name, trait_pool_walk = parse_subpool_source(source)
        trait_pool_type = get_trait_pool_type(trait_pool_name)
        trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
        trait_pool_walk, next_dest = trait_pool_walk[1:end-1], trait_pool_walk[end]
        Pool_gotten::PoolDescriptor = walk_trait_pool_descriptor(trait_pool_walk,trait_pool_descriptor)
        @assert Pool_gotten.isAbstract
        SIZE = Pool_gotten.finish-Pool_gotten.start+1
        #println(:($Pool_gotten))
        remove_line_number_node!(traitsset)
        parsed_traits = parse_traits_first_step(traitsset) 
        organized_traits = organize_traits(parsed_traits,SIZE)
        #println(format_traits(organized_traits,Pool_gotten.start,Pool_gotten.finish))
        Pool_gotten.args[next_dest] = y = format_traits(organized_traits,Pool_gotten.start,Pool_gotten.finish)
        #println(organized_traits)


        sub_pool_name = gensym()
        return esc(:(
            struct $sub_pool_name<:($module_name).SubPool
                value::UInt64
                $sub_pool_name() = new()
                $sub_pool_name(x) = new(x)
            end;
            ($module_name).SUB_POOL_NAMES[$subpool] = $sub_pool_name;
            ($module_name).SUB_POOL_DESCRIPTORS[$sub_pool_name] = $y;
            ($module_name).SUB_POOL_PARENTS[$sub_pool_name] = $trait_pool_type)
        )
        #We need to return the subpool information and type.

        #For abstract subpools.
        #To be finished... parsed traits should only take the amount of bits allocated.
    else
        error("Invalid keyword. Expected from, got $word.")
    end
end

macro subpool(subpool,word,source)
    if word == KEYWORDS[:from]
        module_name = @__MODULE__
        trait_pool_name, trait_pool_walk = parse_subpool_source(source)
        trait_pool_type = get_trait_pool_type(trait_pool_name)
        trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
        Pool_gotten::PoolDescriptor = walk_trait_pool_descriptor(trait_pool_walk,trait_pool_descriptor)

        sub_pool_name = gensym()
        return esc(:(
            struct $sub_pool_name<:($module_name).SubPool
                value::UInt64
                $sub_pool_name() = new()
                $sub_pool_name(x) = new(x)
            end;
            ($module_name).SUB_POOL_NAMES[$subpool] = $sub_pool_name;
            ($module_name).SUB_POOL_DESCRIPTORS[$sub_pool_name] = $Pool_gotten;
            ($module_name).SUB_POOL_PARENTS[$sub_pool_name] = $trait_pool_type)
        )
        #For normal subpools.
        #No need to alter the pool descriptor, but must return the subpool information and type.
    else
        error("Invalid keyword. Expected from, got $word.")
    end
end

macro make_subpool(variable,word,subpool)
    if word == KEYWORDS[:from]
        var_quot = Meta.quot(variable)
        subpool_struct = SUB_POOL_NAMES[subpool]
        module_name = @__MODULE__
        eval(:(($module_name).SUB_POOL_TYPES[$var_quot] = $subpool_struct))
        return esc(:($variable = $subpool_struct(0)))
    else
        error("Invalid keyword. Expected from, got $word.")
    end
end

macro make_subpool(variable,word,expr::Expr)
    if word == KEYWORDS[:from]
        if expr.head == :call
            @assert expr.args[1] == KEYWORDS[:parent] "Invalid keyword to make parent. Expected <=, got $(expr.args[1])"
            subpool, parent = expr.args[2], expr.args[3]
            pool_descriptor::PoolDescriptor = get_trait_pool_descriptor(parent)
            subpool_descriptor::PoolDescriptor = SUB_POOL_DESCRIPTORS[SUB_POOL_NAMES[subpool]]
            mask = reduce(Base.:|,UInt64(1).<<(collect(subpool_descriptor.start:subpool_descriptor.finish).-1);init=0)
            ans = quote
                @make_subpool $subpool $variable
                $variable = setvalue($variable, getvalue($parent)&$mask)
            end
            return esc(ans)
        elseif expr.head == :block
            ans = quote
                @make_subpool $subpool $variable
                @addtraits $variable $traits_set
            end
            return esc(ans)
        else
            error("Invalid syntax.")
        end
    else
        error("Invalid keyword. Expected from, got $word.")
    end
end

macro register_subpool(variable,word,subpool)
    if word == KEYWORDS[:from]
        var_quot = Meta.quot(variable)
        subpool_struct = SUB_POOL_NAMES[subpool]
        module_name = @__MODULE__
        eval(:(($module_name).SUB_POOL_TYPES[$var_quot] = $subpool_struct))
    else
        error("Invalid keyword. Expected from, got $word.")
    end
end

macro copy_subpool(expr)
    module_name = @__MODULE__
    if expr.args[1] == KEYWORDS[:to]
        variable1, variable2 = expr.args[2], expr.args[3]
        traitpool_struct = SUB_POOL_TYPES[variable1]
        var_quot = Meta.quot(variable2)
        eval(:(($module_name).SUB_POOL_TYPES[$var_quot] = $traitpool_struct))
        return esc(:($variable2 = $variable1))
    else
        error("Invalid syntax. Got $expr.\nExpected @copy_subpool var1 => var2.")
    end
end


function parse_subpools_join_individual_arg(subpool::Expr)
    @assert subpool.head == :macrocall
    @assert subpool.args[1] == Symbol("@subpool")
    return subpool.args[2]
end

function parse_subpools_join_args(subpools)
    @assert subpools.head == :block
    return [parse_subpools_join_individual_arg(x) for x in subpools.args]
end

macro join_subpools(base_pool, subpools)
    remove_line_number_node!(subpools)
    parsed_args = parse_subpools_join_args(subpools)
    #println(parsed_args)
    sub_pool_descriptors::Vector{PoolDescriptor} = [get_trait_pool_descriptor(i) for i in parsed_args]
    masks = [reduce(Base.:|,UInt64(1).<<(collect(x.start:x.finish).-1);init=0) for x in sub_pool_descriptors]
    mask::UInt64 = reduce(Base.:|,masks;init=0)
    #display(mask)
    answer = :(getvalue($base_pool)&~($mask))
    for i in parsed_args
        answer = :($answer |getvalue($i))
    end
    return esc(:($base_pool = setvalue($base_pool,$answer)))
    #error("Working in progress.")

end

