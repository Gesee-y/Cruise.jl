#################################### Abstraction of OpenGL ##########################################

#include("..\\..\\Utilities\\Maths\\MathLib.jl")

#=
	With an abstraction, it's will be more easier to derivate it to create GLH
	For this we just need to make the creation of GL data easy
=#

# The Vertex.

include("GLTexture.jl")
include("GLShaders.jl")
include("GLBuffers.jl")