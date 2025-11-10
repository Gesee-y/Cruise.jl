
@testset "CRSubject Observer Pattern" begin
    @testset "Basic construction" begin
        s = CRSubject(10)
        @test s.value == 10
        @test isempty(s.observers)
        @test s[] == 10
    end

    @testset "Connect and Notify" begin
        s = CRSubject(0)
        called = Ref(0)

        f = connect(v -> called[] = v, s)
        @test f isa Function
        @test length(s.observers) == 1

        s[] = 42
        notify!(s)
        @test called[] == 42
    end

    @testset "Multiple observers" begin
        s = CRSubject("init")
        log = String[]
        connect(v -> push!(log, "obs1:$v"), s)
        connect(v -> push!(log, "obs2:$v"),s)
        s[] = "changed"
        notify!(s)
        @test length(log) == 2
        @test all(occursin("changed", msg) for msg in log)
    end

    @testset "Disconnect" begin
        s = CRSubject(0)
        calls = Ref(0)

        f1 = connect(_ -> calls[] += 1, s)
        f2 = connect(_ -> calls[] += 1, s)
        @test length(s.observers) == 2

        disconnect(s, f1)
        @test length(s.observers) == 1

        notify!(s)
        @test calls[] == 1  # only f2 was called

        disconnect(s, f2)
        @test isempty(s.observers)

        notify!(s) # should do nothing
        @test calls[] == 1
    end

    @testset "Edge cases" begin
        s = CRSubject(100)

        # Disconnect a non-registered observer
        dummy = x -> nothing
        disconnect(s, dummy) # should not error
        @test length(s.observers) == 0

        # Notify with no observers should not crash
        notify!(s)
        @test true

        # Test reassignment
        s[] = 200
        @test s[] == 200
    end

    @testset "Chained modifications inside observer" begin
        s = CRSubject(1)
        f1 = connect(v -> s[] = v + 1, s)
        f2 = connect(v -> s[] = v * 2, s)
        # Important: test that notify runs sequentially and doesn't skip
        notify!(s)
        # After first: s[] becomes 2, after second: s[] becomes 4
        @test s[] == 4
    end
end
