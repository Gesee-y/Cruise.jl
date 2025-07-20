######################################################################################################################
################################################### COLLISION GRID ###################################################
######################################################################################################################

export CollisionGrid, ProcessObjects

######################################################## CORE ########################################################

const BIT_WIDTH = 5 # The number of bits allocated for a given data
const DEFAULT_MASK = (UInt64(1) << BIT_WIDTH) - 1 # The default mask to get a particular data

struct CollisionGrid{N,L}
	mask::UInt # The lookup mask for the bitboard
	size::NTuple{2,Int} # The size of the world to skip offscreen entities
	zones::SMatrix{Vector,N,N,L} # Our Vector of zones
	bitboard::MagicBitboard # The bitboard (see `Arceus.jl`)

	# Constructor

	function CollisionGrid{N}(size) where N
		mask = UInt(2)^(BIT_WIDTH*4)-1 # We get our look up mask, a serie of 1
		zones = SMatrix{Vector,N,N,L}(undef)
		for i in eachindex(zones)
			zones[i] = Vector{Any}()
		end

		new{N,N*N}(mask, (size[1], size[2]), zones, MagicBitboard(mask,0,0, MakeRoute, Vector{Int}))
	end
end

##################################################### FUNCTIONS ######################################################

"""
    ProcessObjects(grid::CollisionGrid, obj::Vector)

Resolve collision for a given set of entities `obj`.
This will first collect the plausible collisions using a 2D grib based on bitboards for fast repartitions.
"""
function ProcessObjects(grid::CollisionGrid, obj::Vector)
	empty!.(grid.zones)
	for o in obj
		SetInZone(grid, o)
	end

	zones = filter(v -> length(v) > 1, grid.zones)
	for zone in zones
		# The collision resolution
	end
end

"""
    SetInZone(grid::CollisionGrid{N,L}, obj::AbstractBody)

This automatically route the object `obj` to the correct grids cells using bitboard lookup, making this function
super fast.
"""
function SetInZone(grid::CollisionGrid{N,L}, obj::AbstractBody) where {N,L}
	xs,xe = obj.rect.x, obj.rect.x + obj.rect.w
	ys,ye = obj.rect.y, obj.rect.y + obj.rect.h
	size = 1 << BIT_WIDTH # The size of our mask

	x_start, x_end = _map_to_range(xs,1:size,grid.size[1]), _map_to_range(xe,1:size,grid.size[1])
	y_start, y_end = _map_to_range(ys,1:size,grid.size[2]), _map_to_range(ye,1:size,grid.size[2])

    !(0 ≤ x_start ≤ 31 && 0 ≤ x_end ≤ 31 && 0 ≤ y_start ≤ 31 && 0 ≤ y_end ≤ 31) && return

	traits = to_bit_boundingbox(x_start,x_end,y_start,y_end)
	zones = grid.bitboard[traits]
    
    data = grid.zones.data
	for i in zones
		push!(data[i], obj)
	end
end

# Create the bounding box of the object but as a collection of bits
to_bit_boundingbox(x_start, x_end, y_start, y_end;size=BIT_WIDTH) = (y_end << size*3) | (y_start << size*2) | (x_end << size) | (x_start)

"""
    MakeRoute(x::UInt64;size=BIT_WIDTH)

This is our lookup function, it takes a bit bounding box as input and output all the zones he is in.
Using magic bitboard, foreach possible bounding box, a collection of zones are directly mapped to it
"""
function MakeRoute(x::UInt64;size=BIT_WIDTH)
	# We collect our data just by decoding them from `x`.
	# I guess it's not so hard to understand.
	# We first use the mask to put to zero all irrelevants data with a AND
	# Then if necessary we use shift to put the data at their correct position, 
	# this remove the offset we added to them in `to_bit_boundingbox`
	x_start, x_end = (x & DEFAULT_MASK) + 1, ((x & (DEFAULT_MASK << size)) >> size) + 1
	y_start, y_end = ((x & (DEFAULT_MASK << size*2)) >> size*2) + 1, ((x & (DEFAULT_MASK << size*3)) >> size*3) + 1

    result::Vector{NTuple{2,Int}} = NTuple{2,Int}[]
    size = 1 << BIT_WIDTH # Faster than doing 2^BIT_WIDTH
	
	for i in x_start:x_end
		for j in y_start:y_end
			push!(result, _compute_coordinate((i,j),(size,size)))
		end
	end

	return result
end

function _map_to_range(x,r,M)
	t = x/M
	v = Int(floor(t*r[end]))

	return v
end

_compute_coordinate((i, j), (width, height)) = (j - 1) * width + i
