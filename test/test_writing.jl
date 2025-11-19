Cruise.precise_sleep(v; sec=true) = nothing

@testset "Metadata parsing" begin
    key, val, idx = Cruise._get_meta("{speed:0.5}", 1)
    @test key == :speed
    @test val == "0.5"
    @test idx == 11

    @test_throws ErrorException Cruise._get_meta("{speed", 1)
    @test_throws ErrorException Cruise._get_meta("{speed:}", 1)
end

@testset "Metadata processing" begin
    meta = Dict(:pause => "0.2", :speed => "0.1")

    Cruise.process_all_metadata(Cruise.TextWriter(["Hi"], auto=true))
end

@testset "Process pause metadata" begin
    meta = Dict(:pause => "0.1")
    Cruise.process_metadata(meta, Val(:pause), "0.1")
    @test !haskey(meta, :pause)
end

@testset "Process speed metadata" begin
    meta = Dict(:speed => "0.2")
    Cruise.process_metadata(meta, Val(:speed), "0.2")  # ne supprime pas
    @test haskey(meta, :speed)
end

@testset "write_a_text prints text" begin
    writer = Cruise.TextWriter(["Hello."])

    io = IOBuffer()
    Cruise.write_a_text(writer, 1; io=io)

    @test String(take!(io)) == "Hello.\n"
end

@testset "write_a_text with metadata" begin
    writer = Cruise.TextWriter(["{speed:0.05}Hi"])

    io = IOBuffer()
    Cruise.write_a_text(writer, 1;io=io)

    @test writer.meta[:speed] == "0.05"
end

@testset "write_text sequencing" begin
    writer = Cruise.TextWriter(["A", "B"]; auto=true)

    io = IOBuffer()
    Cruise.write_text(writer;io=io)

    @test writer.current_index == 2
    @test writer.current_text == "B"
end
