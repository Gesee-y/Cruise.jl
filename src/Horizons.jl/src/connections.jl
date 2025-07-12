## This script will create the necessary to expressed connection between Vertex
###############################################################################

abstract type AbstractConnection end

## We first have the line

struct Line <: AbstractConnection
	data::NTuple{2,UInt32}

	## Constructors

	Line(a::Integer,b::Integer) = new((a,b))
end

## Then the Triangle

struct Tri <: AbstractConnection
	data::NTuple{3,Line}

	## Constructors

	function Tri(a::Integer,b::Integer,c::Integer)
		l1 = Line(a,b)
		l2 = Line(a,c)
		l3 = Line(b,c)

		new((l1,l2,l3))
	end
end

## And the faces

struct Face <: AbstractConnection
	data::NTuple{2,Tri}

	## Constructors

	Face(a::Integer,b::Integer,c::Integer) = Tri(a,b,c)
	function Face(a::Integer,b::Integer,c::Integer,d::Integer)
		t1 = Tri(a,b,c)
		t2 = Tri(a,c,d)

		new((t1,t2))
	end
end

## We need to be able to convert them to raw indices

to_array(l::Line) = UInt32[l.data[1],l.data[2]]

function to_array(t::Tri)
	data = t.data
	UInt32[data[1].data[1],data[1].data[2],data[2].data[2]]
end

function to_array(f::Face)
	data = f.data
	return append!(UInt32[],to_array(data[1]),to_array(data[2]))
end

Base.isequal(l1::Line,l2::Line) = (l1.data == l2.data)
Base.isequal(t1::Tri,t2::Tri) = (t1.data == t2.data)
Base.isequal(f1::Face,f2::Face) = (f1.data == f2.data)