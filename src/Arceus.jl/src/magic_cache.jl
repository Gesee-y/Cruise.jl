########################################################## Magic Caching ########################################################

const MAGIC_CACHE = Dict{UInt64, Tuple{UInt64, Int64}}()
const CSV_FILE = "magic_cache.csv"

"""
    load_cache()

Load the CSV cache to `MAGIC_CACHE`
"""
function load_cache()
    isfile(CSV_FILE) || return
    str = read(CSV_FILE, String)
    data = split.(split(str,"\n")[2:end-1], ",")

    for d in data
        mask = parse(UInt64, d[1])
        magic = parse(UInt64, d[2])
        shift = parse(Int64, d[3])
        MAGIC_CACHE[mask] = (magic, shift)
    end
end

"""
    save_cache()

Write the contents of `MAGIC_CACHE` in a CSV file.
"""
function save_cache()
    open(CSV_FILE, "w") do io
        println(io, "mask,magic,shift")
        for (mask, (magic, shift)) in collect(MAGIC_CACHE)
            println(io, "$(mask),$(magic),$(shift)")
        end
    end
end

"""
    get_magic(mask::UInt64, f::Function)

Return (magic, shift) from the cache or calculate it with `find_magic_bitboard` if not there.
"""
function get_magic(mask::UInt64, f::Function,return_type::Type = Any; 
        shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())

    if haskey(MAGIC_CACHE, mask)
        return MAGIC_CACHE[mask]
    else
        magic, shift = _compute_magic_bitboard(mask, f, return_type;
            shift_minimum=shift_minimum, guess_limits=guess_limits,rng=rng)
        MAGIC_CACHE[mask] = (magic, shift)
        save_cache()
        return magic, shift
    end
end

# Charger à l'initialisation
load_cache()
