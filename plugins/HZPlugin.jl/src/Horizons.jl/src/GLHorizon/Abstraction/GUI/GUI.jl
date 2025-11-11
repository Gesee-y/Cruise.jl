"Implementation of a Dear IMGUI renderer/controller within B+, plus various helpers."
module GUI

# External dependencies
using Dates, Setfield
using CImGui, LibCImGui, GLFW, CSyntax, StructTypes

# B+ dependencies
using BplusCore; @using_bplus_core
using ..GL

# Needed for 'clipboard()' :(
using InteractiveUtils

# Define @bp_gui_assert and related stuff.
@make_toggleable_asserts bp_gui_

@decentralized_module_init

include("aliases.jl")
include("gui_service.jl")

include("simple_helpers.jl")
include("text.jl")
include("file_dialog.jl")

end # module