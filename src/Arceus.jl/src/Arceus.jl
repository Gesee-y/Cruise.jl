
module Arceus

    """
    abstract type TraitPool

    Abstract type defining a trait pool (created via `@traitpool`)
    """
    abstract type TraitPool end

    const KEYWORDS = Dict{Symbol, Symbol}(
        :position => :at,
        :add => :+,
        :remove => :-,
        :dependance => :depends,
        :parent => :<=,
        :to => :(=>),
        :from => :from,
        :magic_mode => :magic,
        :pext_mode => :pext,
    )

    include("llvm_op.jl")
    include("magic_cache.jl")
    include("magic_bitboard.jl")
    include("bits_allocation.jl") 
    include("trait_pool.jl") 
    include("trait_modification.jl") 
    include("trait_test.jl") 
    include("subpool.jl") 
    include("clear_context.jl")
    include("use_magic.jl")
    export @traitpool, @make_traitpool, @subpool, @make_subpool, @register_traitpool, @register_subpool, @join_subpools
    export @settraits, @addtraits, @removetraits, @fliptraits
    export @hastrait, @usetrait, @copy_traitpool, @copy_subpool
    export @lookup, @make_lookup, @register_variable, @get_lookup_value, @get_lookup_function, @get_lookup_index, @getmask

    export get_trait_pool_descriptor, get_trait_pool_type, getvalue, setvalue
    export find_magic_bitboard, verify_magic_bitboard, fill_magic_bitboard, magic_constructor
    export setstate, getstate, DONTCARE, maskedBitsIterator, use_magic_bitboard

end