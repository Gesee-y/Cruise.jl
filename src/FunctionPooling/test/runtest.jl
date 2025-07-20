include(joinpath("..","src","FunctionPooling.jl"))

using .FunctionPooling

pool = FunctionPool()

## Warming to avoid compilation overhead.
@pooledfunction pool function update(x::Int)
	x + 5
end

N = 1000 # Number of functions that will be created
total_memory = Sys.total_memory()

## Part 1: Standard Julia version
used_memory = (total_memory - Sys.free_memory())/(1024^2)

# We will generate `N` standard function and make sure they compile by calling them
for i in 1:N
	symb = gensym() # The name doesn't matter
	eval(quote function $symb(x::Int)
		x + 5
	end 
    $symb(1)
end)
end

# We call the GC so we free the unused memory.
GC.gc()

used_memory = (total_memory - Sys.free_memory())/(1024^2) - used_memory
println("Memory in use: $used_memory Mo")

## Part 2: Version with reused functions
GC.gc()
used_memory = (total_memory - Sys.free_memory())/(1024^2)

for i in 1:N
	symb = gensym()
	eval(quote @pooledfunction pool function $symb(x::Int)
		x + 5
	end
	$symb(1)
	free($pool,$symb)
end)
end

# We free the unused memory
GC.gc()
used_memory = (total_memory - Sys.free_memory())/(1024^2) - used_memory

println("Memory in use: $used_memory Mo")