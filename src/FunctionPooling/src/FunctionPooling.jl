#######################################################################################################################
################################################### FUNCTION POOLING ##################################################
#######################################################################################################################

"""
    module FunctionPooling

Julia has alway suffered from a well known issue: functions doesn't get garbage collected.
Even if a function is no more used, it stay in memory because Julia has no clear way to know when a function is unused.
So this package propose to pool function in order to reuse them instead of creating new one.
This package works with methods. When you reuse a function, to override the old method to create a new function.
"""
module FunctionPooling

export FunctionObject, FunctionPool
export @pooledfunction
export getfunc, getfield, free

"""
    struct FunctionObject <: Function
		id::Int
		name::Symbol
		func::Function
		pool::WeakRef

This struct is a reusable function instance.
- `id`: It's the position of the function object in the pool.
- `name`: It's the name of the reusable function. It's used to override his methods.
- `func`: It's the actual function that will be reused.
- `pool`: A weak reference to the central pool object.
"""
mutable struct FunctionObject <: Function
	const id::Int
	const name::Symbol
	const func::Function

	## Constructor

	function FunctionObject(id, name, func)
		obj = new(id, name, func)
		return obj
	end
end

"""
    mutable struct FunctionPool
		pool::Vector{FunctionObject}
		free::Vector{Int}

This object manage pooling.
- `pool`: The list of all the function object existing in the pool
- `free`: THe list of the functions ready to be reused.

## Constructor

    FunctionPool()

Will construct a new empty pool for functions.
"""
mutable struct FunctionPool
	pool::Vector{FunctionObject}
	free::Vector{Int}

	## Constructors

	FunctionPool() = new(FunctionObject[], Int[])
end

"""
    @pooledfunction pool function ... end

This create or reuse a function.
IF there is a function ready to be reused, this will override his method.
If there is no available function, then a new one is created.
This is also compatible with `@generated` functions.
"""
macro pooledfunction(p, func)
	func = QuoteNode(func)
	pool = esc(p)
	return quote
		id = 1
		nm = :()
		func = $func
		old = func.args[1].args[1]
		if isempty($pool.free)
			nm = gensym()
			id = length($pool.pool)+1
			func.args[1].args[1] = nm

			fn = eval(func)
			obj = FunctionObject(id, nm, fn)
			push!($pool.pool,obj)
			$__module__.eval(Expr(:(=),old,obj))

			return obj
		else
			id = pop!($pool.free)
			nm = $pool.pool[id].name
		end

		func.args[1].args[1] = nm

		fn = eval(func)
		obj = $pool.pool[id]
		eval(Expr(:(=),old,obj))
	end
end

#################################################### Functions ########################################################

(f::FunctionObject)(args...) = f.func(args...)
getfunc(f::FunctionObject) = getfield(f, :func)
getname(f::FunctionObject) = getfield(f, :name)

"""
    free(f::FunctionObject)

This mark a pooled function as reusable
"""
free(pool,f::FunctionObject) = begin
    push!(pool.free, f.id)
end

end # module