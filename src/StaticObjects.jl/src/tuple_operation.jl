## This script intend to provide some useful feature for tuple ##

"""
	append_tuple(tuple...)

Append a collection of tuple(and array but is more slow) one after another and return a tuple

# Example

```julia-repl

julia> a = (1,2,3,4)
(1,2,3,4)

julia> append_tuple(a,(5,6,7,8))
(1,2,3,4,5,6,7,8)

julia> append_tuple(a,1)
(1,2,3,4,1)

julia> append_tuple(a,[1,2,3],(1,2,3),34,(213,13))
(1,2,3,1,2,3,1,2,3,34,213,13)

```
"""
@generated function append_tuple(tuples...)
    Expr(:tuple, [:((tuples...)...)]...)
end

"""
	insert_tuple(tup::Tuple,val,idx::Int)

Insert in tup the element val at the index idx, it return that new tuple.
If val is container(array or tuple) the function will insert all his element in tup starting from idx.
If you want to insert the container, wrap it in another tuple (val,)

# Example

```julia-repl

julia> a = (1,2,4,5)
(1,2,4,5)

julia> insert_tuple(a,3,3)
(1,2,3,4,5)

julia> insert_tuple(a,(1,2,3),3)
(1,2,1,2,3,4,5)

julia> b = (6,7,8)
(6,7,8)

julia> insert_tuple(a,(b,),3)
(1,2,(6,7,8),4,5)
```

"""
insert_tuple(tup::Tuple,val,idx::Int) = append_tuple(tup[begin:idx-1],val,tup[idx:end])

@nospecialize
"""
	replace_tuple(tup::Tuple,val,idx::Int)

Replace in tup the element at the index idx with val, it return that new tuple.
If val is container(array or tuple) the function will remove the element at the index idx 
and insert all his element in tup starting from idx.
If you want to replace the element with the container, wrap it in another tuple (val,).

# Example

```julia-repl

julia> a = (1,2,4,5)
(1,2,4,5)

julia> replace_tuple(a,3,4)
(1,2,4,3)

julia> b = (6,7,8)
(6,7,8)

julia> replace_tuple(a,b,4)
(1,2,4,6,7,8)

julia> replace_tuple(a,(b,),4)
(1,2,4,(6,7,8))
```

"""
@inline replace_tuple(tup::Tuple,val,idx::Int) = append_tuple(tup[begin:idx-1],(val,),tup[idx+1:end])
@specialize

"""
	convert_tuple(T::Type,tup::Tuple)

convert the tuple to another tuple with all his element to type T

# Example

```julia-repl

julia> a = (1,2,3)
(1,2,3)

julia> convert_tuple(Float32,a)
(1.0f0,2.0f0,3.0f0)

```
"""
convert_tuple(T::Type,tup::Tuple) = convert.(T,tup)

"""
	fill_tuple(val,len::Int)

Create a tuple of length len with all his elements set to val. For a small len, the fill will be done 
recursively else iteratively.len should be greater or equal to 1.

# Example

```julia-repl

julia> fill_tuple(3,4)
(3,3,3,3)

```
"""
fill_tuple(val,len::Int) = rtuple(val, Val(len))

@generated function rtuple(x, ::Val{N}) where N
    Expr(:tuple, [:(x) for _ = 1:N]...)
end

@nospecialize
"""
	to_tuple(array::AbstractArray)

convert an abstract array to a tuple

# Example

```julia-repl

julia> a = [1,2,3]

julia> to_tuple(a)
(1,2,3)

"""
to_tuple(array) = append_tuple((),array)
@specialize

@nospecialize
"""
	tuple_prod(col,len)

A remake of the prod function which is more faster for stucture such as svec
col is the collection of element we want the prod of
len is the number of element to multiply
"""
@inline function tuple_prod(col,len)
	p = col[1]
	for i in 2:len
		p *= col[i]
	end
	return p
end
@specialize

"""
	flatten_range(r::AbstractUnitrange)

Convert an UnitRange to a tuple

# Example

```julia-repl

julia> a = 1:3
1:3

julia> flatten_range(a)
(1,2,3)
```
"""
flatten_range(r::AbstractUnitRange) = tuple(r...)