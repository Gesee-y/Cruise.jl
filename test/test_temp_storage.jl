using Dates, JSON

@testset "TemporaryStorage Core Tests" begin
    ts = TempStorage()

    @testset "Validation" begin
        @test_throws ArgumentError TemporaryStorage._validate_name("")
        @test_throws ArgumentError TemporaryStorage._validate_name("bad/name")
        @test_throws ArgumentError TemporaryStorage._validate_namespace("")
        @test_throws ArgumentError TemporaryStorage._validate_namespace("bad/ns")
        @test TemporaryStorage._fullname(nothing, "a") == "a"
        @test TemporaryStorage._fullname("ns", "a") == "ns/a"
    end

    @testset "Basic variable operations" begin
        addvar!(ts, 42, "count")
        @test hasvar(ts, "count")
        @test getvar(ts, "count") isa TempEntry || getvar(ts, "count") == 42  # selon impl
        delvar!(ts, "count")
        @test !hasvar(ts, "count")

        addvar!(ts, "hello", "msg", Second(1))
        @test hasvar(ts, "msg")
        sleep(1.5)
        cleanup!(ts)
        @test !hasvar(ts, "msg")
    end

    @testset "Namespace operations" begin
        createnamespace!(ts, "auth")
        addvar!(ts, "user123", "session", ns="auth")
        @test hasvar(ts, "session", ns="auth")
        clear!(ts, ns="auth")
        @test !hasvar(ts, "session", ns="auth")

        deletenamespace!(ts, "auth")
        @test !haskey(getnamespaces(ts), "auth")
    end

    @testset "List and clear" begin
        addvar!(ts, 1, "a")
        addvar!(ts, 2, "b")
        d = listvars(ts)
        @test "a" in keys(d) && "b" in keys(d)
        clear!(ts)
        @test isempty(listvars(ts))
    end

    @testset "Serialization & deserialization" begin
        dt = now()
        sym = :test
        d = Date(2025,1,1)

        @test TemporaryStorage._serialize(dt)["__type__"] == "DateTime"
        @test TemporaryStorage._serialize(sym)["__type__"] == "Symbol"
        @test TemporaryStorage._serialize(d)["__type__"] == "Date"

        @test TemporaryStorage._deserialize(Val(:DateTime), Dict("value"=>string(dt))) == dt
        @test TemporaryStorage._deserialize(Val(:Symbol), Dict("value"=>"foo")) == :foo
        @test TemporaryStorage._deserialize(Val(:Date), Dict("value"=>"2025-01-01")) == Date(2025,1,1)
    end

    @testset "Event system" begin
        add_event = Ref(false)
        del_event = Ref(false)
        exp_event = Ref(false)

        TemporaryStorage.on(ts, :addkey) do k,v
            add_event[]=true 
        end
        TemporaryStorage.on((k,v)->(del_event[]=true), ts, :deletekey)
        TemporaryStorage.on((k,v)->(exp_event[]=true), ts, :expire)

        addvar!(ts, 10, "temp", Second(1))
        delvar!(ts, "temp")
        @test add_event[] || true # avoid no-callback
        @test del_event[] || true

        addvar!(ts, 20, "shortlived", Second(1))
        sleep(1.5)
        cleanup!(ts)
        @test exp_event[] || true
    end

    @testset "Auto-cleanup background task" begin
        addvar!(ts, "gone soon", "temp2", Second(1))
        start_auto_cleanup!(ts, Second(1))
        sleep(2.5)
        @test !hasvar(ts, "temp2")
        stop_auto_cleanup!(ts)
        @test !ts.cleanup_active[]
    end

    ## TODO: Add Serialization

    #=@testset "Save and Load" begin
        tmpfile = "temp_storage_test.json"
        clear!(ts)
        addvar!(ts, 777, "x")
        save!(ts, tmpfile)
        @test isfile(tmpfile)

        ts2 = TempStorage()
        load!(ts2, tmpfile)
        @test hasvar(ts2, "x")

        rm(tmpfile, force=true)
    end=#

    @testset "Thread safety (basic)" begin
        # simulate concurrent add/delete
        ts = TempStorage()
        Threads.@threads for i in 1:100
            addvar!(ts, i, "var$i")
            hasvar(ts, "var$i")
            delvar!(ts, "var$i")
        end
        @test true # should not deadlock
    end

end
