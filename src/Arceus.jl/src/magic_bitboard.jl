using Random

"""
    struct MagicBitboard 
        value::UInt
        magic::UInt
        shift::UInt

This struct represents a magic bitboard, used to accelerate lookup for entities.

## Constructor

    MagicBitboard(mask::UInt64, f, return_type::Type = Any; 
        shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())

This will construct a new magic bitboard and automatically fill it with the relevant data.
see `find_magic_bitboard` for more informations
"""
struct MagicBitboard{T}
    array::Vector{T}
    mask::UInt
    magic::UInt
    shift::UInt
    pext::Bool

    ## Constructors

    function MagicBitboard(mask::UInt64, magic, shift, f, return_type::Type = Any; 
        shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG(), PEXT=true)
        
        if PEXT
            data = fill_magic_bitboard(mask, magic, f, return_type, shift)
            new{return_type}(data, mask, magic, shift, true)
        else
            magic, shift = find_magic_bitboard(mask, f, return_type;
                shift_minimum=shift_minimum, guess_limits=guess_limits,rng=rng)

            data = fill_magic_bitboard(mask, magic, f, return_type, shift)
            new{return_type}(data, mask, magic, shift, false)
        end
    end

    function MagicBitboard(mask::UInt64, magic, shift, f, return_type::Type = Any)
        data = fill_magic_bitboard(mask, magic, f, return_type, shift, false)
        new{return_type}(data, mask, magic, shift, false)
    end
end

"""
    struct maskedBitsIterator
        mask::UInt64
        reverse_mask::UInt64

This struct serve as an iterator on a bit mask.
At each state, it returns the next bit at 1.

## Constructor

    maskedBitsIterator(mask::UInt64)

This will create a new iterator for the given `mask`
"""
struct maskedBitsIterator
    mask::UInt64
    reverse_mask::UInt64
    maskedBitsIterator(mask::UInt64) = new(mask,~mask)
    maskedBitsIterator(mask) = maskedBitsIterator(UInt64(mask))
end

"""
    iterate(X::maskedBitsIterator, state)

Efficiently iterates over all 1-bits in a bitboard (`X.mask`) using advanced bitwise operations.

# How it works:
- `reverse_mask` is the bitwise complement of the mask: it has 1s where the mask has 0s.
- On each iteration, we compute `ans = mask & ((state | reverse_mask) + 1)`, which directly gives the next 1-bit position in the mask, skipping all 0-bits.
- The algorithm stops when all 1-bits have been visited.

# Why does it work?
- `state | reverse_mask` sets all forbidden bits (those not in the mask) to 1, as well as all bits already visited (`state`).
- The increment (`+1`) operation automatically jumps to the next valid (1) bit in the mask.
- The final `& mask` keeps only the allowed bits.

# Example:
If `mask = 0b101` (bits 0 and 2 are 1), the iteration will yield 0b001 (1), then 0b100 (4), and then stop.

# Note:
This technique is common in chess engines or board game programming, where you need to quickly iterate over valid positions. Proper documentation is crucial to avoid confusion due to the advanced bitwise logic used here!
"""
Base.iterate(::maskedBitsIterator) = UInt64(0),UInt64(0)
function Base.iterate(X::maskedBitsIterator, state=0)
    ans = X.mask & ((state | X.reverse_mask) + 1)
    return ifelse(ans == 0, nothing, (ans, ans))
end

"""
    use_magic_bitboard(board::MagicBitboard, query::Integer)
       
This function will return an element of the magic bit board
"""
function use_magic_bitboard(cond::Bool,board::MagicBitboard{T}, query::Integer) where T
    func = cond ? PEXT_FUNC : get_lookup_index
    A::Vector{T} = board.array
    return @inbounds A[func(board, query)]
end
function use_magic_bitboard(::Val{false},board::MagicBitboard{T}, query::Integer) where T
    A::Vector{T} = board.array
    return @inbounds A[get_lookup_index(board, query)]
end
Base.getindex(board::MagicBitboard, query::Integer) = use_magic_bitboard(Val(board.pext),board, query)
Base.getindex(board::MagicBitboard, trait::TraitPool) = use_magic_bitboard(board.pext,board, getvalue(trait))

pext(board::MagicBitboard, query::Integer) = pext(convert(UInt,query), board.mask)
pext(board::MagicBitboard, query::UInt) = pext(query, board.mask)
fallback_pext(board::MagicBitboard, query::UInt) = fallback_pext(query, board.mask)

"""
    function get_lookup_index(board:: MagicBitboard, query::UInt64)

Given a bitboard, this can be used to lookup for the specific data requested.
"""
function get_lookup_index(board:: MagicBitboard, query::UInt64)
    return (((query&board.mask)*board.magic)>>board.shift)+1
end

"""
    struct DONTCARE 

Some place holder struct to indicate that an element of the bitboard is irrelevant for us.
"""
struct DONTCARE end;

"""
    magic_bitboard_range(mask)

Returns the last number which needs to be checked.
This loops from zero to that number. zero magic number, however, yields trivial result mapping all to the same value, and thus not need to be checked.
"""
function magic_bitboard_range(mask::Integer)
    #The last bit represents its 
    Big_interval=Int128(2)^64
    
    return UInt64(div(Big_interval,(mask&-mask))-1)
end


"""
    verify_magic_bitboard(answer_table,magic::UInt64, shift, return_type::Type)

This function verify the validity of magic bitboard.
It ensure that each trait's combination redirect us efficiently to an unique index.
"""
function verify_magic_bitboard(answer_table,magic::UInt64, shift::Integer, return_type::Type)
    #println("Verifying magic", magic)
    A = Vector{Union{return_type, DONTCARE}}(undef, 1<<(64-shift))
    for i in eachindex(A)
        A[i]= DONTCARE()
    end
    for (traits, ans) in answer_table
        index = ((traits*magic)>>shift)+1
        if (A[index] === DONTCARE())
            A[index] = ans
        elseif (A[index] != ans)
            return false
        end
    end
    return true
end

"""
    find_magic_bitboard(mask::UInt64, f, return_type::Type = Any;
        shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())

This function construct a magic bitboard with brute force.
This will try as many possible number as defined by `guess_limits` for the current `shift`.
If we find a magic number, before the current shift goes under the `shift_minimum`,
we return the magic number and the shift, else it will throw an error.
"""
function find_magic_bitboard(mask::UInt64, f, return_type::Type = Any; 
    shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())
    
    return get_magic(mask, f, return_type;
            shift_minimum=shift_minimum, guess_limits=guess_limits,rng=rng)
end
function _compute_magic_bitboard(mask::UInt64, f, return_type::Type = Any; 
    shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())

    answer_dict = Dict{UInt64, return_type}()
    #We get a hash table but not a perfect one so we need to do it again.

    # for each bits of the mask
    for i in maskedBitsIterator(mask)
        # get the returned value for him
        Temp::Union{return_type, DONTCARE} = f(i)

        # If the value is valid then we add it to our dictionnary
        if Temp !== DONTCARE()
            answer_dict[i] = Temp
        end
    end

    answer_table = collect(answer_dict)
    #Now, we need to find the perfect hash that solves this answer table.
    #Can change if needed.
    
    # Ok
    # We need to find the perfect magic number and shift for our answer table
    initial_shift = shift = 48
    limit = guess_limits
    guess = UInt64(0)
    while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
        guess = rand(rng,UInt64)&rand(rng,UInt64)&rand(rng,UInt64)
        limit -= 1

        ## If we guessed so much that we reach a limit
        if (limit <= 0)
            shift -= 1 # We modify the shift, which may increased necessary size
            if (shift < shift_minimum) # But if we already hut the minimum, then we stop
                error("Cannot find magic bitboard with sufficiently small size (indicated by shift_minimum).")
            end
            limit = guess_limits
        end
    end
    
    answer_guess = guess
    answer_shift = shift

    # This is triggered in the first run
    # We will thing finding if there is a solution for our answertable
    # with higher shift => a lower size
    if (shift == initial_shift)
        trying_to_shrink = true
        while trying_to_shrink
            answer_guess = guess
            answer_shift = shift
            shift += 1
            limit = guess_limits
            if (shift >= 64)
                break
            end
            limit = guess_limits
            
            # So here we will try a different guess at each iterations
            # if a given guess solve the answer table (genereate unique index for each trait combination)
            # We won (and with a minimal size)
            while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
                guess = rand(rng,UInt64)&rand(rng,UInt64)&rand(rng,UInt64)
                limit -= 1
                if (limit <= 0)
                    trying_to_shrink = false
                    break
                end
            end
        end
    end

    return answer_guess, answer_shift
    #You can construct later.
end

"""
    fill_magic_bitboard(mask::UInt64,magic, f, return_type::Type, shift)

This will fill a magic bitboard with the relevant data given by the function `f` for each trait.
"""
function fill_magic_bitboard(mask::UInt64,magic, f, return_type::Type, shift, PEXT=true)
    A = Vector{return_type}(undef, 1<<(64-shift))
    answer_table = Dict{UInt64, return_type}()
    for traits in maskedBitsIterator(mask)
        Temp::Union{return_type, DONTCARE} = f(traits)
        if Temp !== DONTCARE()
            ans = Temp
            index = PEXT ? PEXT_FUNC(traits,mask)-1 : ((traits*magic)>>shift)
            A[begin+index] = ans
        end
    end
    
    return A
end

#################################################### LEGACY ######################################################

function use_magic_bitboard(arr::AbstractVector, mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return @inbounds arr[get_lookup_index(mask, magic, shift, query)]
end

function get_lookup_index(mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return (((query&mask)*magic)>>shift)+1
end
