############################### OpenGL Buffers Abstraction ######################################

# This function have a generic purpose.
# It can generate any object
function glGenOne(glGenFn,type)
	id = GLuint[0]
	glGenFn(1, id)

	# If an error happened, we exit the process
	# But don't know why, but this function has a bug and stop the whole program for nothing
	(glCheckError("generating $type"))
	
	return id
end

# Let's generate a buffers
glGenBuffer() = glGenOne(glGenBuffers,"buffer")
glGenVertexArray() = glGenOne(glGenVertexArrays, "array")
glGenTexture() = glGenOne(glGenTextures,"texture")

# Let's generate a buffers
GenBuffer!(ref) = glGenBuffers(1,ref)
BindArrayBuffer!(ref) = glBindBuffer(GL_ARRAY_BUFFER,ref[])

# Now we should pass our data to the GPU
# For this we need to know the size and other thing
#PutData(type,size,d)

function glErrorMessage()
# Return a string representing the current OpenGL error flag, or the empty string if there's no error.
	err = glGetError()
	err == GL_NO_ERROR ? "" :
	err == GL_INVALID_ENUM ? "GL_INVALID_ENUM: An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_VALUE ? "GL_INVALID_VALUE: A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION: The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION: The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY: There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded." : "Unknown OpenGL error with error code $err."
end