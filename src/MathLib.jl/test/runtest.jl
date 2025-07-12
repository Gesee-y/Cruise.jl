############################################### Math Test #########################################

using Test
include("..\\src\\MathLib.jl")

## Vector Test

function compute(n)

	a = iVec3(1,2,6)
	b = iVec3(6,7,4)

	for _ = 1:n
		a = (a + b) + b
	end

	return a[1],a[2]
end

function test_vector()
	@time a = Vec2(1,3); b = Vec2(5, 7)
	
	@testset "Vector operations" begin
	    @test a + b == Vec2(6,10)
	end
end

function test_matrix()
	#@testset "Matrix calculation" begin
	    a = iMat4{Float32}(5)
	    b = iMat4{Float32}(7)
	    c = iMat4{Float32}(9)
	    d = iMat4{Float32}(10)

	    #println(a)
	    #@timev e = a*b

        time = 0
        N = 1000000
        for _ in 1:N
	        time += @elapsed a*b*c*d
	    end

	    println("$((time*10^6)/N) microseconds")
    #end
end

function test()
	@time c = compute(10^34)

	println(c)
end

#test()
test_matrix()
#test_vector()