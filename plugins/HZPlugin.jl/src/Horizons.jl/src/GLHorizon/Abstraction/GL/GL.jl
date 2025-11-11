"A light wrapper around OpenGL"
module GL

# External dependencies
using Setfield, TupleTools, MacroTools, StructTypes
using ImageIO, FixedPointNumbers, ColorTypes, FileIO
using GLFW, CSyntax

# B+ dependencies
using BplusCore; @using_bplus_core
using ..ModernGLbp

@decentralized_module_init

include("version.jl")
include("utils.jl")
include("debugging.jl")

include("sync.jl")
include("handles.jl")
include("depth_stencil.jl")
include("blending.jl")
include("data.jl")

include("service.jl")
include("context.jl")
include("resource.jl")

include("buffers/buffer.jl")
include("buffers/layout_macros.jl")
include("buffers/vertices.jl")
include("buffers/mesh.jl")

include("textures/format.jl")
include("textures/sampling.jl")
include("textures/data.jl")
include("textures/cube.jl")
include("textures/views.jl")
include("textures/view_debugging.jl")
include("textures/texture.jl")

include("targets/target_buffer.jl")
include("targets/target_output.jl")
include("targets/target.jl")

include("program.jl")
include("drawing.jl")

end # module