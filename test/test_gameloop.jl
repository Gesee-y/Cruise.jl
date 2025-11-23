
mutable struct Counter{T} 
    c::T
end

app = CruiseApp()

pl1 = CRPlugin()
pl2 = CRPlugin()
counter1 = Counter{Int}(0)
counter2 = Counter{Float64}(0)
add_system!(pl1, counter1)
add_system!(pl2, counter2)

Cruise.awake!(n::CRPluginNode{<:Counter}) = (n.obj.c = 0)
Cruise.update!(n::CRPluginNode{<:Counter}) = (n.obj.c += 1)
Cruise.shutdown!(n::CRPluginNode{<:Counter}) = (n.obj.c)

merge_plugin!(app, pl1)
merge_plugin!(app, pl2)

@testset "GameLoop struct" begin
    gl = GameLoop()
    @test gl.last_frame_time_ns == 0
    @test gl.frame_idx == 0
    @test gl.delta_seconds == 0f0
    @test gl.max_fps == 60
    @test gl.max_frame_duration == 0.5f0

    gl2 = GameLoop(max_fps=30, max_frame_duration=1.0f0)
    @test gl2.max_fps == 30
    @test gl2.max_frame_duration == 1.0f0
end

@testset "@gameloop macro basic execution" begin

    counter = Ref(0)

    @gameloop max_fps=120 max_duration=0.25 begin
        counter[] += 1
        counter[] >= 3 && shutdown!()
    end

    @test counter1.c == counter2.c == 3

    @test counter1.c > 0
    @test counter2.c > 0
end

@testset "@gameloop default arguments" begin
    cnt = Ref(0)

    @gameloop begin
        cnt[] += 1
        cnt[] >= 2 && shutdown!()
    end

    @test cnt[] == 2
end

@testset "@gameloop invalid keyword" begin
    err = nothing
    try
        macroexpand(Main, :( @gameloop wrongkw=10 app begin end ))
    catch e
        err = e
    end
    @test err isa ErrorException
    @test occursin("Unknow keyword", sprint(showerror, err))
end

@testset "Timing correctness" begin
    counter = Ref(0)
    deltas = Float32[]

    @gameloop max_fps=30 begin
        counter[] += 1
        push!(deltas, LOOP_VAR.delta_seconds)
        counter[] >= 3 && shutdown!()
    end

    @test all(0f0 .< deltas .<= LOOP_VAR_REF[].max_frame_duration)
    @test length(deltas) == 3
end

@testset "GameLoop progression" begin
    frame_indices = Int[]

    @gameloop max_fps=10 begin
        push!(frame_indices, LOOP_VAR.frame_idx)
        LOOP_VAR.frame_idx >= 2 && shutdown!()
    end

    @test frame_indices == [0, 1, 2]
end
