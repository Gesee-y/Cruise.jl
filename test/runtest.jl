include(joinpath("..", "src", "Cruise.jl"))

using .Cruise
using Test

include("test_temp_storage.jl")
include("test_cr_subject.jl")
include("test_gameloop.jl")

## HelloCruise!!()