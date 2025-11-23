include("..\\src\\Cruise.jl")

using .Cruise
using BenchmarkTools

include("BenchTypes.jl")

function setup_plugin_benchmark(n)
	plugin = CRPlugin()
	for i in 1:n-1
		add_system!(plugin, Node{i}(); sort=false)
	end
	add_system!(plugin, Node{n}())

	return plugin
end

function setup_plugin_random_benchmark(n)
	plugin = CRPlugin()
	for i in 1:n-1
		add_system!(plugin, Node{i}(); sort=false)
	end
	add_system!(plugin, Node{n}())

	for i in 1:n
		for j in 1:n
			flip_coin() && add_dependency!(plugin, i, j)
		end
	end

	return plugin
end

function run_uniform_benchmarks(n)
	bench = @benchmarkable begin
		update!(plugin)
	end setup = (plugin = setup_plugin_benchmark($n))

	println("Benchmarking overhead for $n system in the plugin")
	tune!(bench)

	result = run(bench, seconds=10)
	println("Median time per system: $(time(median(result)) / n) ns")
	display(result)
end

function run_random_benchmarks(n)
	bench = @benchmarkable begin
		update!(plugin)
	end setup = (plugin = setup_plugin_random_benchmark($n))

	println("Benchmarking overhead for $n system in the plugin")
	tune!(bench)

	result = run(bench, seconds=10)
	println("Median time per system: $(time(median(result)) / n) ns")
	display(result)
end

#println("""----------------------------------------------------------------------------------------
#|                                                                                      |
#|               Plugin system Overhead for system with no dependencies                 |
#|                                                                                      |
#----------------------------------------------------------------------------------------""")
#for n in (1, 5, 10, 50, 100, 500, 1000)
#	run_uniform_benchmarks(n)
#end

println("""----------------------------------------------------------------------------------------
|                                                                                      |
|           Plugin system Overhead for system with random dependencies                 |
|                                                                                      |
----------------------------------------------------------------------------------------""")
for n in (1, 5, 10, 50, 100, 500, 1000)
	run_random_benchmarks(n)
end