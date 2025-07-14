## This contains all the data structure necessary for the rest ##
include("tuple_operation.jl")

# Function starting with a _ are helper function and won't be exported

@enum MatrixOrdering begin
	COLUMN_MAJOR
	ROW_MAJOR
end

"""
	matrix_ordering()

Return the current ordering use for static array(row major or column major).
You can change ordering by redefining to another ordering with one of the value of the **MatrixOdering** Enumaration.

# Example

```julia-repl

julia> matrix_ordering()
MatrixOrdering.COLUMN_MAJOR

julia> matrix_ordering() = ROW_MAJOR # We redefine the ordering.
```
"""
matrix_ordering() = COLUMN_MAJOR

# Here we will check that the argument passed to the SArray match together
# meaning that the product of the dimension should be equal to the number of element, etc.
function _check_argument(D::Type{Tuple{V}},N::Int,L::Int) where V
	nDim = 1
	DLen = V # if any of the argument in D is 0 or negative the result will probably also be zero or negative

	L < 0 && throw(ArgumentError("Can't take negative length $L."))
	N < 0 && throw(ArgumentError("Can't take negative dimensionality $N."))

	if nDim != N || DLen != L
		throw(DimensionMismatch("The argument does not fit together. Correct dimension are D is $V, 
			N is $nDim and L is $DLen ($DLen elements.)"))
	end
end
function _check_argument(D::Type{Tuple{V1,V2}},N::Int,L::Int) where {V1,V2}
    nDim = 2
	DLen = V1*V2 # if any of the argument in D is 0 or negative the result will probably also be zero or negative

	L < 0 && throw(ArgumentError("Can't take negative length $L."))
	N < 0 && throw(ArgumentError("Can't take negative dimensionality $N."))

	if nDim != N || DLen != L
		throw(DimensionMismatch("The argument does not fit together. Correct dimension are D is ($V1,$V2), 
			N is $nDim and L is $DLen ($DLen elements.)"))
	end
end
function _check_argument(D::Type,N::Int,L::Int)
	Dim = D.parameters
	nDim = length(Dim)
	DLen = tuple_prod(Dim,nDim) # if any of the argument in D is 0 or negative the result will probably also be zero or negative

	L < 0 && throw(ArgumentError("Can't take negative length $L."))
	N < 0 && throw(ArgumentError("Can't take negative dimensionality $N."))

	if nDim != N || DLen != L
		throw(DimensionMismatch("The argument does not fit together. Correct dimension are D is $Dim, 
			N is $nDim and L is $DLen ($DLen elements.)"))
	end
end

"""
	AbstractSArray{T <: Any ,D <: Tuple ,N} <: AbstractArray{T,N}

Base type for all static array object. T is the type of the Data in the static array, D is the dimension 
of the array, N is the number of dimension.

From this are derived the following types:

	StaticScalar{T} = AbstractSArray{T,Tuple{},0,1}
	StaticVector{T,N} = AbstractSArray{T,Tuple{N},1}
	StaticMatrix{T,N,M} = AbstractSArray{T,Tuple{N,M},2}
"""

abstract type AbstractSArray{T <: Any ,D <: Tuple ,N} <: AbstractArray{T,N} end

struct FilledArray{T}
	val::T
end

const StaticScalar{T} = AbstractSArray{T,Tuple{},0}
const StaticVector{T,L} = AbstractSArray{T,Tuple{L},1}
const StaticMatrix{T,M,N} = AbstractSArray{T,Tuple{M,N},2}
const StaticSquareMatrix{T,M} = StaticMatrix{T,M,M}

"""
	mutable struct SArray{T<:Any,D<:Tuple,N,L} <: AbstractSArray{T,D,N}

A base struct for the static array object where T is the type of the Data in the static array, D is the dimension 
of the array(Should be passed on this form Tuple{...}), N is the number of dimension 
and L is the number of element of the array(It's why it's a static array , because it have a fixed, known length).

we can construct it the following ways:
	
	SArray{T,D,N,L}(elt::T...)

Will construct a static Array with all the element passed in parameters(Note that all element should have the same 
type.)

	SArray{T,D,N,L}(data::NTuple{N,T})

Construct the static array from an NTuple.

	SArray{T,D,N,L}(data::NTuple{N,Any})

Convert the data to type T and construct the static array.

	SArray{T,D,N,L}(::UndefInitializer)

Create a static array with all the element set to undef

	SArray{T,D,N,L}(elt::Union{Missing,Nothing})

Create a static array fill with nothing of missing, the type T should be able to hold these missing/nothing
nothing/missing <: T e.g: Union{Int,Nothing} or Union{Int,Missing}

	SArray{T,D,N,L}(elt)

Create a mutable static array fill with the value elt converted to the type T

	SArray{T,D,N,L}(array::AbstractArray)

create a mutable static array from an existing array. The length and dimensionality of the array should 
match the parameters passed to the static array constructor.
"""
mutable struct SArray{T <: Any,D <: Tuple,N,L} <: AbstractSArray{T,D,N}
	data :: NTuple{L,T}

	## Constructors ##

	# Construct for a set of elements
	@nospecialize
	function SArray{T,D,N,L}(elts::Vararg{T,L}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(elts)
	end

	function SArray{T,D,N,L}(elts::Vararg{Any,L}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(convert_tuple(T,elts))
	end

	function SArray{T,D,N,L}(elts::NTuple{L,T}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(elts)
	end

	function SArray{T,D,N,L}(elts::NTuple{L,Any}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(convert_tuple(T,elts))
	end

	# Construct from a function or Initializer
	Base.@propagate_inbounds function SArray{T,D,N,L}(::UndefInitializer) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}()
	end

	function SArray{T,D,N,L}(elt::T) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(fill_tuple(elt,L))
	end

	function SArray{T,D,N,L}(elt::AbstractArray{T,N}) where{T <: Any,D <: Tuple,N,L}
		length(elt) != L && throw(DimensionMismatch("The array does not have the same length as L($L) passed in parameters"))
		
		@boundscheck _check_argument(D,N,L)
		return new{T,D,N,L}(Tuple(elt))
	end

	function SArray{T,D,N,L}(elt::AbstractArray{Any,N}) where{T <: Any,D <: Tuple,N,L}
		length(elt) != L && throw(DimensionMismatch("The array does not have the same length as L($L) passed in parameters"))
		elt = Tuple(elt)
		elt = convert.(T,elt)

		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(elt)
	end

	function SArray{T,D,N,L}(elt::Any) where{T <: Any,D <: Tuple,N,L}
		elt = convert(T,elt)
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(fill_tuple(elt,L))
	end
	function SArray{T,D,N,L}(elt::T) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(fill_tuple(elt,L))
	end
	@specialize
end

"""
	SScalar{T} <: StaticScalar{T}

It's an alias for SArray{T,Tuple{},0,1}. Create a static scalar (0-dimensional array)
"""
const SScalar{T} = SArray{T,Tuple{},0,1}

"""
	SVector{T,L} <: StaticVector{T,L}

It's an alias for SArray{T,Tuple{L},1,L}. Create a static vector (1-dimensional array)
"""
const SVector{T,L} = SArray{T,Tuple{L},1,L}

"""
	SMatrix{T,M,N,L} <: StaticMatrix{T,M,N}

It's an alias for SArray{T,Tuple{M,N},2,L}. Create a static matrix (2-dimensional array)
N is the number of column, M is the number of row
"""
const SMatrix{T,M,N,L} = SArray{T,Tuple{M,N},2,L}

"""
	SSquareMatrix{T,M,L} <: StaticMatrix{T,M,M}

It's an alias for SMatrix{T,M,M,L} that represent square matrix
"""
const SSquareMatrix{T,M,L} = SMatrix{T,M,M,L}

"""
	struct iSArray{T<:Any,D<:Tuple,N,L} <: AbstractSArray{T,D,N}

The immutable counterpart of SArray where T is the type of the Data in the static array, D is the dimension 
of the array(Should be passed on this form Tuple{(...)}), N is the number of dimension 
and L is the number of element of the array(It's why it's a static array , because it have a fixed, known length).

we can construct it the following ways:
	
	iSArray{T,D,N,L}(elt::T...)

Will construct an immutable static Array with all the element passed in parameters(Note that all element should have the same 
type.)

	iSArray{T,D,N,L}(data::NTuple{N,T})

Construct the immutable static array from an NTuple.

	iSArray{T,D,N,L}(data::NTuple{N,Any})

Convert the data to type T and construct the immutable static array.

	iSArray{T,D,N,L}(::UndefInitializer)

Create an immutable static array with all the element set to undef

	iSArray{T,D,N,L}(elt::Union{Missing,Nothing})

Create an immutable static array fill with nothing or missing, the type T should be able to hold these missing/nothing
nothing/missing <: T e.g: Union{Int,Nothing} or Union{Int,Missing}

	iSArray{T,D,N,L}(elt)

Create an immutable static array fill with the value elt converted to the type T

	iSArray{T,D,N,L}(array::AbstractArray)

create an immutable static array from an existing array. The length and dimensionality of the array should 
match the parameters passed to the static array constructor.
"""
struct iSArray{T <: Any,D <: Tuple,N,L} <: AbstractSArray{T,D,N}
	data :: NTuple{L,T}

	## Constructors ##

	# Construct for a set of elements
	function iSArray{T,D,N,L}(elts::Vararg{T,L}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(elts)
	end

	function iSArray{T,D,N,L}(elts::Vararg{Any,L}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(convert_tuple(T,elts))
	end

	# Construct from an NTuple
	function iSArray{T,D,N,L}(elts::NTuple{L,T}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(elts)
	end

	function iSArray{T,D,N,L}(elts::NTuple{L,Any}) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(convert_tuple(T,elts))
	end

	# Construct from a function or Initializer
	@nospecialize
	Base.@propagate_inbounds function iSArray{T,D,N,L}(::UndefInitializer) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}()
	end
	@specialize

	function iSArray{T,D,N,L}(elt::T) where{T <: Any,D <: Tuple,N,L}
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(fill_tuple(elt,L))
	end

	function iSArray{T,D,N,L}(elt::Array{T,N}) where{T <: Any,D <: Tuple,N,L}
		length(elt) != L && throw(DimensionMismatch("The array does not have the same length as L($L) passed in parameters"))
		
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(Tuple(elt))
	end

	function iSArray{T,D,N,L}(elt::Array{Any,N}) where{T <: Any,D <: Tuple,N,L}
		length(elt) != L && throw(DimensionMismatch("The array does not have the same length as L($L) passed in parameters"))
		elt = Tuple(elt)
		elt = convert.(T,elt)

		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(elt)
	end

	function iSArray{T,D,N,L}(elt::Any) where{T <: Any,D <: Tuple,N,L}
		elt = convert(T,elt)
		@boundscheck _check_argument(D,N,L)
		new{T,D,N,L}(fill_tuple(elt,L))
	end
end

"""
	iSScalar{T} <: StaticScalar{T}

It's an alias for iSArray{T,Tuple{()},0,1}. Create an immutable static scalar (0-dimensional array)
"""
const iSScalar{T} = iSArray{T,Tuple{()},0,1}

"""
	iSVector{T,L} <: StaticVector{T,L}

It's an alias for iSArray{T,Tuple{(L)},1,L}. Create an immutable static vector (1-dimensional array)
"""
const iSVector{T,L} = iSArray{T,Tuple{L},1,L}

"""
	iSMatrix{T,M,N,L} <: iStaticMatrix{T,M,N}

It's an alias for iSArray{T,Tuple{(M,N)},2,L}. Create an immutable static matrix (2-dimensional array)
"""
const iSMatrix{T,M,N,L} = iSArray{T,Tuple{M,N},2,L}

"""
	iSSquareMatrix{T,M,L} <: StaticMatrix{T,M,M}

It's an alias for SMatrix{T,M,M,L} that represent an immutable square matrix
"""
const iSSquareMatrix{T,M,L} = iSMatrix{T,M,M,L}

Tuple(A::SArray) = getfield(A,:data)
Tuple(A::iSArray) = getfield(A,:data)

"""
	make_immutable(A::SArray)

Transform a mutable static array into an immutable static array

# Example

```julia-repl

julia> a = SVector{String,2}("yay","yo")
["yay","yo"]

julia> typeof(a)
SVector{String,2}

julia> b = make_immutable(a)

julia> typeof(b)
iSVector{String,2}
"""
make_immutable(A::SArray{T,D,N,L}) where{T <: Any, D <: Tuple, N, L} = iSArray{T,D,N,L}(getfield(A,:data))

"""
	make_mutable(A::iSArray)

Transform an immutable static array into an mutable static array

# Example

```julia-repl

julia> a = iSVector{String,2}("yay","yo")
["yay","yo"]

julia> typeof(a)
iSVector{String,2}

julia> b = make_mutable(a)

julia> typeof(b)
SVector{String,2}
"""
make_mutable(A::iSArray{T,D,N,L}) where{T <: Any, D <: Tuple, N, L} = SArray{T,D,N,L}(getfield(A,:data))

promote_rule(::Type{FilledArray{T}}, S::Type) where T = promote_type(T,S)