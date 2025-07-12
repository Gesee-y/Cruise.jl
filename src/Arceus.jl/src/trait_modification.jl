###################################################### Trait modif ###################################################

#To fix... get_trait_pool_descriptor for subpools too.

"""
    get_trait_pool_descriptor(variable)

Return the pool descriptor of a given variable if it has been registered with `@register_traitpool`
Else it will throw an error.
"""
function get_trait_pool_descriptor(variable)
    #error("Not fixed yet.")
    module_name = @__MODULE__
    if haskey(module_name.TRAIT_POOL_TYPES,variable)

        trait_pool_type = module_name.TRAIT_POOL_TYPES[variable]
        trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
    elseif haskey(module_name.SUB_POOL_TYPES,variable)
        sub_pool_type = module_name.SUB_POOL_TYPES[variable]
        trait_pool_descriptor = module_name.SUB_POOL_DESCRIPTORS[sub_pool_type]
    else
        error("Cannot find pool descriptor $variable.")
    end
    return trait_pool_descriptor
end

"""
    get_trait_pool_type(name)

Get the type of a trait pool from it's `name`.
"""
function get_trait_pool_type(name)
    if (haskey(TRAIT_POOL_NAMES,name))
        return TRAIT_POOL_NAMES[name]
    elseif (haskey(SUB_POOL_NAMES,name))
        return SUB_POOL_NAMES[name]
    else
        error("Cannot find trait pool type.")
    end
end

# This will create the expressions chain on which we will iterate
function parse_walk_chain(chain::Union{QuoteNode,Symbol})
    return [chain]
end
function parse_walk_chain(chain::Expr)
    @assert chain.head == Symbol(".") "Invalid expresion $chain. Should have head '.'"
    return vcat(parse_walk_chain(chain.args[1]),parse_walk_chain(chain.args[2].value))
end

# This seems to return the a parsed walking chain and the size of a trait
function parse_individual_trait_mod_arg(x,::Val{true})
    @assert x.head == :macrocall && x.args[1] == Symbol("@trait")
    value = 1
    to_walk = x.args[2]
    if length(x.args) > 2
        if x.args[3] == KEYWORDS[:dependance]
            value = x.args[4]
            to_walk = x.args[2]
        end
    end
    walking_chain = parse_walk_chain(to_walk)
    return (walking_chain,value)
end
function parse_individual_trait_mod_arg(x, ::Val{false})
    @assert (x.head == :macrocall && x.args[1] == Symbol("@trait")) "Invalid argument $x"
    x_args = x.args[2].args
    to_walk = x_args[2]
    value = nothing
    
    # Checking what to do.
    if x_args[1] == KEYWORDS[:add]
        value = 1
    elseif x_args[1] == KEYWORDS[:remove]
        value = 0
    elseif length(x.args) > 2
        if x.args[3] == KEYWORDS[:dependance]
            value = x.args[4]
            to_walk = x.args[2]
        end
    else
        error("Invalid syntax. Got $x.\nUse + to add ,- to remove and depend for dependances")
    end
    walking_chain = parse_walk_chain(to_walk)
    return (walking_chain,value)
end

struct traitsArguments
    settoones::Vector{Vector{Symbol}}
    settozeros::Vector{Vector{Symbol}}
    setdepending::Dict{Symbol,Vector{Vector{Symbol}}}
end

function parse_traits_mod_args(args, b=true)
    remove_line_number_node!(args)
    @assert args.head == :block "Invalid trait modification args. $args should be a block"
    v = Val(b)
    result = [parse_individual_trait_mod_arg(i,v) for i in args.args]
    Ones = [i[1] for i in result if i[2] == 1]
    Zeros =  [i[1] for i in result if i[2] == 0]
    Depending = Dict{Symbol,Vector{Vector{Symbol}}}()
    for x in result
        i,j = x
        if j isa Symbol
            if haskey(Depending, j)
                push!(Depending[j],i)
            else
                Depending[j] = [i]
            end
        end
    end
    return traitsArguments(Ones,Zeros,Depending)
end

# Process in a poolDescriptor and advance in a tree-way, going further at each walk
# Fix this to handle abstract trait pools.
function walk_trait_pool_descriptor(walk::Vector{Symbol}, trait_pool_descriptor::PoolDescriptor)
    for i in walk
        if hasproperty(trait_pool_descriptor, :args)
            trait_pool_descriptor = trait_pool_descriptor.args[i]
        else
            error("Cannot walk trait path $walk: $i not found in $trait_pool_descriptor.")
        end
    end
    return trait_pool_descriptor
end

"""
    @settrait var begin
       ...
    end

This will set the given trait to the value given.
`1` means activate
`0` means deactivate
A var name means "set this trait the same as this var"    
```
@traitpool "ABCDEF" begin
    @trait electro
    @trait flame
    @trait laser at 2
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta at 16-32 begin
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 at 33-48
    @abstract_subpool reserve2 at 8
end

@make_traitpool Pokemon from "ABCDEF" begin
    @trait electro
    @trait flame
end

@copy_traitpool Pokemon => X

@settraits Pokemon begin
    @trait -electro 
    @trait +roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end
```
"""
macro settraits(variable,args)
    
    # First we get the pool descripto from the variable name
    trait_pool_descriptor = get_trait_pool_descriptor(variable)

    # And then we parse the arguments (mostly a set of traits)
    parsed_args = parse_traits_mod_args(args, false)
    
    # We get all the traits needing to be set to 
    static_one_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
    
    # This will get us the mask of all the bits to set to one
    one_bits = reduce(Base.:|, UInt64(1).<<(static_one_bits.-1);init=0)
    static_zero_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settozeros]
    
    # This will get us the mask of all the bits to set to zero
    zero_bits = reduce(Base.:|, UInt64(1).<<(static_zero_bits.-1);init=0)

    # This contains the bits to set to one
    pullup_bits = :($one_bits)

    # We go through the depending var, getting the traits to add and to remove
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in dependent_value]
        current_bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1);init=0)
        zero_bits |= current_bits #Bits set to zero will initially set things to zero.
        pullup_bits = :($pullup_bits | ((getvalue($dependent_var))&($current_bits)))
    end

    # We first remove the bits with a simple AND and NOT
    base_bits = :(getvalue($variable)&~($zero_bits))

    # We finnaly combine the removed bits with the ones to add with a simple OR
    return esc(:($variable= setvalue($variable,($base_bits)|($pullup_bits))))
end

"""
    @addtraits var begin
        ...
    end

This will activate the given traits of the an instance of a traitpool `var`

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

@addtraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end

```
"""
macro addtraits(variable,args)

    trait_pool_descriptor, parsed_args, static_bits, bits = _get_trait_modification_data(variable, args)
    # We then just apply it with a OR to set these bits to one
    answer = :(getvalue($variable)|$bits)

    # We also set the bits of the dependent var to one
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in dependent_value]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1);init=0)
        answer = :($answer | ((getvalue($dependent_var))&($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
end

"""
    @removetraits var begin
        ...
    end

This will desactivate the given traits of the an instance of a traitpool `var`

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

@removetraits Pokemon begin
    @trait flame
end
```
"""
macro removetraits(variable, args)

    trait_pool_descriptor, parsed_args, static_bits, bits = _get_trait_modification_data(variable, args)    
    # Then we just do a bitwise AND between the variable value and the NOT of our mask
    answer = :(getvalue($variable)&~($bits))

    # We then also remove the depending traits
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in dependent_value]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1);init=0)
        answer = :($answer & ~((getvalue($dependent_var))&($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
end

"""
    @fliptraits var begin
        ...
    end

This will invert the state of the given traits of the an instance of a traitpool `var`.
activate become desactivate and deactivate become activate

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

@fliptraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end
```
"""
macro fliptraits(variable,args)

    trait_pool_descriptor, parsed_args, static_bits, bits = _get_trait_modification_data(variable, args)
    # We can then flip the current value of these bits with a bitwise XOR
    answer = :(getvalue($variable)⊻$bits)

    # And we do the same with the depending vars
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in dependent_value]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1);init=0)
        answer = :($answer | ((getvalue($dependent_var))⊻($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
end


function _get_trait_modification_data(variable, args)
    # We get the pool descriptor for this variable
    trait_pool_descriptor = get_trait_pool_descriptor(variable)

    # Then we get a trait argument struct containing the bits to set to one
    parsed_args = parse_traits_mod_args(args)

    # We then get the position of each of the traits to set to one
    static_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]

    # We create a mask that will serve to activate these traits
    bits = reduce(Base.:|, UInt64(1) .<< (static_bits .- 1);init=0)

    return (trait_pool_descriptor, parsed_args, static_bits, bits)
end

"""
    @printtraits var

Prints the status of all the existing traits, whether they are activated or desactivated.
"""
macro printtraits(var)
    value = getvalue(var)
    descriptor = get_trait_pool_descriptor(var)
    str = "Variable "*string(var)*" traits state:\n"
    for (name, d) in collect(descriptor.args)
        str*= _get_trait_activeness(value, name, d, 1)
    end
    
    return :(println($str))
end


function _get_trait_activeness(var::Integer, name::Symbol, value::Integer, depth=0)
    if var & (1 << (value - 1)) != 0
        return string(name)*" is enabled"
    else 
        return string(name)*" is disabled"
    end
end

function _get_trait_activeness(var::Integer, name::Symbol, value::PoolDescriptor, depth=1)
    str = String(name)*"\n"
    for (n, v) in collect(value.args)
        string *= ("\t"^depth)*_get_trait_activeness(var, n, v, depth+1)*"\n"
    end

    return string
end