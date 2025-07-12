############################ OpenGL Shaders Abstraction ##############################################

export Shader
export AddTexture, RemoveTexture, GetShaderUniform, SetShaderUniform

const Time_uniform = "Time"

function sleep_ns_shaders(t::Integer;sec=true)
	factor = sec ? 10 ^ 9 : 1
    t = UInt(t) * factor
    
    t1 = time_ns()
    while true
        if time_ns() - t1 >= t
            break
        end
        yield()
    end
end

mutable struct Shader
	const ID :: UInt32
	active :: Bool
	start :: Float64
	samplers :: Vector{UInt32}
	uniforms :: HDict{String,Any}

	# Constructor #
	function Shader(vertex_path::String,fragment_path::String)
		vertexCode :: String = ""
		fragmentCode :: String = ""

		try
			vertex_file = open(vertex_path,"r")
			fragment_file = open(fragment_path,"r")

			vertexCode = _glsl_version_string() * _default_layout() * read(vertex_file,String)
			fragmentCode = _glsl_version_string() * _default_frag() * _default_uniform() * read(fragment_file,String)

			close(vertex_file)
			close(fragment_file)
		catch e
			error("Failed to open files at $vertex_path and $fragment_path")
		end

		vertex :: GLuint = 0
		fragment :: GLuint = 0

		# We start creating the first shader
		# The vertex shader.
		vertex = glCreateShader(GL_VERTEX_SHADER)::GLuint
		glShaderSource(vertex, 1, convert(Ptr{UInt8}, pointer([convert(Ptr{GLchar}, pointer(vertexCode))])),C_NULL)
		glCompileShader(vertex)

		# We check if the shader was successfuly created
		if !isvalidShader(vertex)

			# if not we get the error
			log = getInfoLog(vertex)

			# and throw it as a warning
			HORIZON_WARNING.emit = ("Failed to compile vertex shader.",log)

			return nothing
		end

		# We create the fragment shader
		fragment = glCreateShader(GL_FRAGMENT_SHADER)::GLuint
		glShaderSource(fragment, 1, convert(Ptr{UInt8}, pointer([convert(Ptr{GLchar}, pointer(fragmentCode))])),C_NULL)
		glCompileShader(fragment)

		# We check that the fragment shader was successfuly created
		if !isvalidShader(fragment)

			# if not we get the error
			log = getInfoLog(fragment)

			# And throw it as a warning
			HORIZON_WARNING.emit = ("Failed to compile fragment shader.",log)

			# The shader creation failed so we no more need the vertex shader.
			glDeleteShader(vertex)

			return nothing
		end

		# We start creating the shader program
		id = glCreateProgram()
		glAttachShader(id,vertex)
		glAttachShader(id,fragment)
		glLinkProgram(id)

		# We check that the shader program was successfully created
		if !isvalidProgram(id)

			# if not we get the error
			log = getInfoLog(program)

			# And throw it as a warning
			HORIZON_WARNING.emit = ("Failed to link shader program.",log)

			# We delete the shader since the process failed
			glDeleteShader(vertex)
			glDeleteShader(fragment)

			return nothing
		end

		# We no more need these shaders
		glDeleteShader(vertex)
		glDeleteShader(fragment)

		uniforms = HDict{String,Any}()
		uniforms["Time"] = time()

		# We create the shader object at last
		new(id,false,time(),UInt32[],uniforms)
	end
end

AddTexture(s::Shader,t::UInt32) = push!(s.samplers,t)
AddTexture(s::Shader,t::GLTexture) = push!(s.samplers,t.data.id)
RemoveTexture(s::Shader,i::Int) = deleteat!(s.samplers,i)

# To activate the shader
function Use(obj::Shader)
	
	# We first active the shader
	glUseProgram(obj.ID)

	# We need a hold up before using shaders in raw.
	# So that tiny hold up is necessary for all the shaders to activate
	# Don't worry, the hold up just last 1 ns
	sleep_ns_shaders(1;sec=false)

	# Now if the shader have not been activate yet
	if !obj.active

		# we active the shader
		obj.active = true

		# We create an anonymous function that will set the predefined uniforms
		
		f = _ -> while obj.active
			SetUniform(obj,Time_uniform,time()-obj.start)
			yield()
		end

		# And then call that function in parallel
		errormonitor(Threads.@spawn f(1))

	end
end
Stop(obj::Shader) = (glUseProgram(0);obj.active=false)

SetShaderUniform(s::Shader,name::String,@nospecialize(v)) = (getfield(s,:uniforms)[name] = v)
GetShaderUniform(s::Shader,name::String) = getfield(s,:uniforms)[name]

# To set uniforms
SetUniform(obj::Shader,name::String,value::Bool) = glUniform1i(get_uniform(obj.ID, name), Int(value))
SetUniform(obj::Shader,name::String,value::AbstractFloat) = glUniform1f(get_uniform(obj.ID, name), value)
SetUniform(obj::Shader,name::String,value::Integer) = glUniform1i(get_uniform(obj.ID, name), value)
SetUniform(obj::Shader,name::String,value::NTuple{16,AbstractFloat}) = glUniformMatrix4fv(get_uniform(obj.ID, name),1,GL_FALSE,Float32[value...])

function get_uniform(id,name)

	# OpenGL silently remove unused uniform
	# so check bug there will be more like a trap
	res = glGetUniformLocation(id,name)

	return res
end

#=
SetUniform(obj::Shader,name::String,value::Main.GLMaths.Mat4;
		transpose=GL_TRUE,count=1) = glUniformMatrix4fv(glGetUniformLocation(obj.ID,name),count,transpose
				,Main.GLMaths.ptr_value(value))
SetUniform(obj::Shader,name::String,value::Main.GLMaths.Vec3) = glUniform3f(glGetUniformLocation(obj.ID,name),
		value.x,value.y,value.z)
SetUniform(obj::Shader,name::String,value::Main.GLMaths.Vec4) = glUniform4f(glGetUniformLocation(obj.ID,name),
		value.x,value.y,value.z,value.w)
=#

# Check Shader
function isvalidShader(shader)
	success = GLint[0]
	glGetShaderiv(shader, GL_COMPILE_STATUS, success)
	success[] == GL_TRUE
end

# Check Program
function isvalidProgram(program)
	success = GLint[0]
	glGetProgramiv(program, GL_LINK_STATUS, success)
	success[] == GL_TRUE
end

function getInfoLog(obj::GLuint)
	# Return the info log for obj, whether it be a shader or a program.
	isShader = glIsShader(obj)
	getiv = isShader == GL_TRUE ? glGetShaderiv : glGetProgramiv
	getInfo = isShader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog
	
	# Get the maximum possible length for the descriptive error message
	len = GLint[0]
	getiv(obj, GL_INFO_LOG_LENGTH, len)
	maxlength = len[]
	# Return the text of the message if there is any
	if maxlength > 0
		buffer = zeros(GLchar, maxlength)
		sizei = GLsizei[0]
		getInfo(obj, maxlength, sizei, buffer)
		len = sizei[]
		unsafe_string(pointer(buffer), len)
	else
		""
	end
end

function _default_uniform()
	
	# Here we provide the user with some predefined uniform
	# So that he can make beautiful graphics without to much problem
	"""
		uniform float $Time_uniform;
	"""
end

function _default_frag()
	"""
		in vec2 TexCoords;
		in vec3 Normal;
		out vec4 FragColor;
	"""
end

function _default_layout()
	
	# We take care of the layout
	# So no need to define them you self
	# Question : Would it be good if the fragment shader can access the vertex ?
	# We will leave this choice to the user
	# If he wanna send data from the Vertex shader to the Fragment shader,
	# he just use VERTEX_DATA

	"""
		layout (location = $VERTEX_ATTRIB_POS) 
		in vec3 VERTEX;
		layout (location = $TEXCOORD_ATTRIB_POS)
		in vec2 TEXCOORDS;
		layout (location = $NORMAL_ATTRIB_POS)
		in vec3 NORMAL;

		out vec2 TexCoords;
		out vec3 Normal;
	"""
end