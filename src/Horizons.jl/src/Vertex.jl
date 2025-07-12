################################## Vertex Management ############################################

export AbstractMeshData, AbstractTranformation
export NoMeshData, HTransform, Vertex, Mesh
export Rectangle2D, Poly2D, ConvexePoly2D, SetAttribute

include("connections.jl")

#=
	Vertex are the set of 3 things
	* Vertices : the position of a point
	* Texture coordinate : represent own the texture should be mapped for a given vertice
	* Normal : Representing the normal vector of the vertices

	Now how do we represent Vertex ?
	Do we use a special container ?

	We need to be able to move vertices, so they must be mutable and since vertex are only
	mean to be passed to OpenGL, an we should not forget that vertices modifications are mostly done
	int the vertex shader. We pass the vertices to OpenGL only 1(ONE) time so they can easily be 
	immutable. The same apply for Normals and texture coordinate.
=#

abstract type AbstractMeshData end
abstract type AbstractTranformation end

struct NoMeshData <: AbstractMeshData end

struct HTransform <: AbstractTranformation
	position :: Vec3{Float32}
	rotation :: Vec3{Float32}
	scale :: Vec3{Float32}

	# Constructors #

	HTransform() = new(Vec3{Float32}(0,0,0),Vec3{Float32}(0,0,0),Vec3{Float32}(1,1,1))
end

AbstractContainer = Union{Tuple,AbstractArray}

"""
	struct Vertex
		Position :: iVec3{Float32}
		TexCoord :: iVec2{Float32}
		Normal :: iVec3{Float32}

This struct represent a Vertex represented by a position, texture coordinate and normal

# Constructor #

	Vertex(pos::AbstractContainer,tex::AbstractContainer,nor::AbstractContainer)

This will create a vertex. `AbstractContainer` is `Union{Tuple,AbstractArray}` So you can pass
anything that belong to this type.

	Vertex(x1::Real,y1::Real,z1::Real,x2::Real,y2::Real,x3::Real,y3::Real,z3::Real)

You create a vertex by passing the coordinate of every conponent manually
`x1`,`y1`,`z1` are the position of the vertex
`x2`,`y2` are the texture coordinate of the vertex
`x3`,`y3`,`z3` are the coordinate of the normal of the vertex. 
"""
struct Vertex
	Position :: iVec3{Float32}
	TexCoord :: iVec2{Float32}
	Normal :: iVec3{Float32}

	# Constructors #

	function Vertex(pos::AbstractContainer,tex::AbstractContainer,nor::AbstractContainer)
		Position = iVec3{Float32}(pos[1],pos[2],pos[3])
		TexCoord = iVec2{Float32}(tex[1],tex[2])
		Normal = iVec3{Float32}(nor[1],nor[2],nor[3])

		new(Position,TexCoord,Normal)
	end

	function Vertex(x1::Real,y1::Real,z1::Real,x2::Real,y2::Real,x3::Real,y3::Real,z3::Real)
		Position = iVec3{Float32}(x1,y1,z1)
		TexCoord = iVec2{Float32}(x2,y2)
		Normal = iVec3{Float32}(x3,y3,z3)

		new(Position,TexCoord,Normal)
	end
end

# Yay, We have Vertex but one vertex will not make anything.
# Only an aggregation of vertex make a `Mesh`.
"""
	mutable struct Mesh
		vertex :: Vector{Vertex}
		indices :: Vector{UInt32}
		texture :: Vector
		visible :: Bool
		data :: AbstractMeshData
		attribute :: HDict{String,Int}
		extra :: Vector{Tuple}

This struct represent a Mesh.
This object is not intended to be create manually
The `data` field of the mesh represent data that are specific to an API to render the mesh
so these data are highly portable. and you just have to plug them on a mesh to create
a new renderable mesh
"""
mutable struct Mesh{T<:AbstractMeshData}
	vertex :: Vector{Vertex}
	indices :: Vector{UInt32}
	texture :: Vector{Any} # Feature not available yet
	visible :: Bool
	tranform :: AbstractTranformation
	data :: AbstractMeshData
	attribute :: HDict{String,Int}
	extra :: Vector{Tuple}

	# Constructors #

	function Mesh{T}(v::Vector{Vertex},ind::Vector{UInt32},tex=[],
				visible=true;data=NoMeshData(),tranform = HTransform()) where T <: AbstractMeshData
		extra = Vector{Tuple}(undef,length(v))
		new{T}(v,ind,tex,visible,tranform,data,HDict{String,Int}(),extra)
	end
end

# Now we got a mesh, But we can derive some good thing from it
# First we should know, What make a mesh
# Can we modify it ?
# I think yes so we will start with primitives

# Rect
"""
	Rectangle2D(x::Real,y::Real,w::Real,h::Real,data=NoMeshData();depth=0)

This function will create a rect2D primitive. useful for images in 2D world
"""
Rectangle2D(T::Type{<:AbstractMeshData},w::Real,h::Real,@nospecialize(pos),data::AbstractMeshData=NoMeshData()) = Rectangle2D(T,w,h,HVec3(pos),data)
function Rectangle2D(T::Type{<:AbstractMeshData},w::Real,h::Real,pos::HVec3,data::AbstractMeshData=NoMeshData())

	# We set up the vertices of the primitives
	v1 = Vertex((pos.x,pos.y,pos.z),to_tex_coord(T,(0,0)),(0,0,1))
	v2 = Vertex((w+pos.x,pos.y,pos.z),to_tex_coord(T,(1,0)),(0,0,1))
	v3 = Vertex((w+pos.x,h+pos.y,pos.z),to_tex_coord(T,(1,1)),(0,0,1))
	v4 = Vertex((pos.x,h+pos.y,pos.z),to_tex_coord(T,(0,1)),(0,0,1))

	indices = to_array(Face(0,1,2,3))

	mesh = Mesh{T}([v1,v2,v3,v4],indices;data=data)
end

"""
	Poly2D(T::Type{<:AbstractMeshData},size::Real,pos,side::Int=4,data=NoMeshData())

This function will generate a polygon mesh of type `T` at the position `pos` which can be
any container that can be indexed and should have 3 elements. `size` is the size of the
polygon and `side` is the number of side of the polygon.
"""
Poly2D(T::Type{<:AbstractMeshData},size::Real,@nospecialize(pos),side::Int=4,data=NoMeshData()) = Poly2D(T,size,HVec3(pos),side,data)
function Poly2D(T::Type{<:AbstractMeshData},size::Real,center::HVec3,side::Int=4,data=NoMeshData())

	# We set up the vertices of the primitives
	Vert = Vector{Vertex}(undef,side+1)
	Vert[1] = Vertex(Tuple(center),(0.5,0.5),(0,0,1))
	for i in Base.OneTo(side)

		# We start by getting the angle of the current position
		ang = ((2pi/side)*i)+pi/2

		#And get his 2D cartesian coordinate via polar coordinate
		coord = ToCartesian(PolarCoord(size,ang))
		pos = (coord.components[1]+center.x,coord.components[2]+center.y,center.z)
		tex = (coord.components[1],-coord.components[2]+1)

		Vert[i+1] = Vertex(pos,tex,(0,0,1))
	end

	indices = _generate_regular_polygon_indices(side)
	mesh = Mesh{T}(Vert,indices;data=data)
end

"""
	ConvexePoly2D(T::Type{<:AbstractMeshData},vert::Vector{Vertex})

This function will create a new mesh of type `T` with the given Vector of Vertex `vert`
"""
function ConvexePoly2D(T::Type{<:AbstractMeshData},vert::Vector{Vertex})
	indices = _generate_indices(vert)
	mesh = Mesh{T}(Vert,indices;data=data)
end

"""
	SetAttribute(m::Mesh,n::Int,data::Tuple)

This function will set the attribute of the `n`-th vertex of the mesh `m`.
if you have many attribute, you should pass them all in the tuple `data`.
Before passing attribute, make sure you create it with `AddAttribute(m::Mesh,name::String,len::Int)`
"""
SetAttribute(m::Mesh,n::Int,data::Tuple) = (getfield(m,:extra)[n] = convert.(Float32,data))

## Since we want to generate the indices of a regular polygon
# The function is much simpler
function _generate_regular_polygon_indices(side::Int)
	indices = Vector{UInt32}(undef,side*3)

	# We iset th
	indices[1] = 0
	indices[2] = 1
	indices[3] = 2

	for i in 2:side-1
		idx = i*3-2
		indices[idx] = 0
		indices[idx+1] = i
		indices[idx+2] = i+1
	end

	indices[side*3-2] = 0
	indices[side*3-1] = side
	indices[side*3] = 1

	return indices
end

function _generate_indices(vert::Vector{Vertex},offset=-1)

	# We get the index of all the vertices
	index = eachindex(vert)

	# We initialise our indices container
	indices = UInt32[]

	# The number ot vertices
	l = length(vert)

	# The number of triangle of the resulting mesh
	tri_num = length(vert) - 2

	# The number of face of the resulting mesh
	face_num = div(tri_num,2)

	for i in Base.OneTo(face_num)
		
		# We first get the number of available points
		point = _found_unconnected_points(index,indices)

		# Then we take the first point in the available one
		idxs = _found_nearest_face(vert,index,point[1])

		# and finally we append it to the indices array
		append!(indices,to_array(idx))
	end

	# This loop is in the case there should be a triangle in the mesh
	for i in Base.OneTo(tri_num%2)

		# We get the available point(probably just one point)
		point = _found_unconnected_points(index,indices)

		# The we find the nearest triangle
		idxs = _found_nearest_tri(vert,index,point[1])

		# and append it in the indices array
		append!(indices,to_array(idx))
	end

	return indices
end

## This function will find the points that have not been yet connected.
function _found_unconnected_points(index::Vector{Int},indices::Vector{UInt32})
	point = UInt32[]

	for i in index
		if !(i in indices)
			push!(point,i)
		end
	end

	return point
end

function _found_nearest_face(v::Vector{Vertex},index::Vector{Int},k::Int;offset=-1)

	current_nearest = UInt32[typemax(UInt32),typemax(UInt32),typemax(UInt32)]
	current_dist = Float64[Inf,Inf,Inf]
	p = v[k]

	for i in index
		if i != k
			dist = vnorm(v[i].Position - p.Position)
			
			if dist < current_dist[1]
				current_dist[1] = dist
				current_nearest[1] = UInt32(i+offset)
			elseif dist < current_dist[2]
				current_dist[2] = dist
				current_nearest[2] = UInt32(i+offset)
			elseif dist < current_dist[3]
				current_dist[3] = dist
				current_nearest[3] = UInt32(i+offset)
			end
		end
	end

	return Face(k-1,current_nearest[1],current_nearest[2],current_nearest[3])
end

function _found_nearest_tri(v::Vector{Vertex},index::Vector{Int},k::Int;offset=-1)

	current_nearest = UInt32[typemax(UInt32),typemax(UInt32)]
	current_dist = Float64[Inf,Inf]
	p = v[k]

	for i in index
		if i != k
			dist = vnorm(v[i].Position - p.Position)
			
			if dist < current_dist[1]
				current_dist[1] = dist
				current_nearest[1] = UInt32(i+offset)
			elseif dist < current_dist[2]
				current_dist[2] = dist
				current_nearest[2] = UInt32(i+offset)
			end
		end
	end

	return Tri(k-1,current_nearest[1],current_nearest[2])
end

_get_attribute(mesh::Mesh) = getfield(mesh,:attribute)
_get_data(m::Mesh) = getfield(m,:data)