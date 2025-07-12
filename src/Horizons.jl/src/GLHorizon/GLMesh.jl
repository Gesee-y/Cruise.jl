################################ OpenGL Mesh Data #############################################

export GLMeshData, GLMesh
export glCreateMesh, DrawMesh, AddAttribute
export DEFAULT_VERT, DEFAULT_FRAG, DEFAULT_FRAG2

const DEFAULT_FRAG = "Shaders\\Default.frag"
const DEFAULT_FRAG2 = "Shaders\\Def2.frag"
const DEFAULT_VERT = "Shaders\\Default.vert"

mutable struct GLMeshData <: AbstractMeshData
	VAO :: Vector{GLuint}
	VBO :: Vector{GLuint}
	EBO :: Vector{GLuint}
	shader :: Union{Nothing,Shader}
	vertice_count :: Int
	use_ebo :: Bool

	# Constructors #

	GLMeshData(VAO,VBO,EBO,shader,count,use_ebo=true) = new(VAO,VBO,EBO,shader,count,use_ebo)
end

const GLMesh = Mesh{GLMeshData}

"""
	glCreateMesh(vertex::Vector{Vertex},indices,tex=[];mode=GL_STATIC_DRAW,shader=DefaultShader())

Use this function to create an OpenGL mesh from the data passed in arguments
"""
function glCreateMesh(vertex::Vector{Vertex},indices,tex=[];mode=GL_STATIC_DRAW,shader=DefaultShader())
	m = Mesh{GLMeshData}(vertex,indices,tex)
	objects = SetupMesh(mesh,mode;shader)
	m.data = GLMeshData(objects[1], objects[2], objects[3], objects[4], objects[5])

	return m
end
function glCreateMesh(m::GLMesh,tex=[];mode=GL_STATIC_DRAW,shader=DefaultShader())
	objects = SetupMesh(m,mode;shader=shader)
	m.data = GLMeshData(objects[1], objects[2], objects[3], objects[4], objects[5])

	return m
end

@noinline function DrawMesh(m::GLMesh)
	if m.data isa NoMeshData
		HORIZON_WARNING.emit = ("Failed to draw mesh. It has not been initialized or not correctly.","")
		return 
	end

	glBindVertexArray(m.data.VAO[])
	shader = m.data.shader

	if shader != nothing
		Use(shader)

		for i in eachindex(shader.samplers)
			glActiveTexture(GL_TEXTURE0 + (i-1))
			glBindTexture(GL_TEXTURE_2D,shader.samplers[i])
		end

		for i in Base.OneTo(length(shader.uniforms))
			SetUniform(shader,shader.uniforms.ky[i],shader.uniforms.vl[i])
		end

		if (m.data.use_ebo) glDrawElements(GL_TRIANGLES, length(m.indices), GL_UNSIGNED_INT, C_NULL)
		else glDrawArrays(GL_TRIANGLES,0,m.data.vertice_count)
		end
	end

	glBindVertexArray(0)
	#Stop(m.data.shader)
end

function SetupMesh(mesh::GLMesh,mode=GL_STATIC_DRAW;shader=DefaultShader())
	data = Float32[]
	count :: Int = 0

	cnt = 0

	for i in eachindex(mesh.vertex)
		v = mesh.vertex[i]

		# We set the Vertices of the mesh
		for i in 1:3
			push!(data,v.Position[i])
			count += 1
		end

		# We set the texture coordinate
		for i in 1:2
			push!(data,v.TexCoord[i])
		end

		# And we set the normals
		for i in 1:3
			push!(data,v.Normal[i])
		end

		if isassigned(mesh.extra,i)
			for attrib in mesh.extra[i]
				push!(data,attrib)
			end
			cnt += 1
		end
	end

	if cnt < length(mesh.extra) && cnt != 0
		HORIZON_ERROR.emit = ("There is an unsetted attribute. Set vertex attribute for all vertex.","")
		return
	end

	VAO  = GLuint[0]
	VBO  = GLuint[0]
	EBO  = GLuint[0]

	attribute_length = 8 + sum(getfield(_get_attribute(mesh),:vl))

	glGenVertexArrays(1,VAO)
	glGenBuffers(1,VBO)
	glGenBuffers(1,EBO)

	glBindVertexArray(VAO[])

	glBindBuffer(GL_ARRAY_BUFFER,VBO[])
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, mode)

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,EBO[])
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(mesh.indices), mesh.indices, mode)

	# We send the Vertex positions
	glVertexAttribPointer(VERTEX_ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, attribute_length*sizeof(Float32),C_NULL)
	glEnableVertexAttribArray(VERTEX_ATTRIB_POS)

	# We send the texture coordinate
	glVertexAttribPointer(TEXCOORD_ATTRIB_POS, 2, GL_FLOAT, GL_FALSE, attribute_length*sizeof(Float32),Ptr{Cvoid}(3*sizeof(GLfloat)))
	glEnableVertexAttribArray(TEXCOORD_ATTRIB_POS)

	# We send the normals
	glVertexAttribPointer(NORMAL_ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, attribute_length*sizeof(Float32),Ptr{Cvoid}(5*sizeof(GLfloat)))
	glEnableVertexAttribArray(NORMAL_ATTRIB_POS)

	att = _get_attribute(mesh)
	current_pos = 8

	for i in 1:length(att)
		l = att.vl[i]
		println(l)
		glVertexAttribPointer(i+2,l,GL_FLOAT,GL_FALSE,attribute_length*sizeof(Float32),Ptr{Cvoid}(current_pos*sizeof(GLfloat)))
		glEnableVertexAttribArray(i+2)
		current_pos += l
	end

	glBindVertexArray(0)

	return (VAO,VBO,EBO,shader,count)
end

"""
	AddAttribute(mesh::GLMesh,name::String,data::Tuple)

This function will add custom attribute to the GLMesh `mesh`. `name` is the name of the
attribute in the mesh Shader program.
"""
function AddAttribute(mesh::GLMesh,name::String,len::Int)
	attrib = _get_attribute(mesh)
	attrib[name] = len
end

DefaultShader() = Shader(DEFAULT_VERT, DEFAULT_FRAG)

to_tex_coord(::Type{GLMeshData},data::Tuple) = (data[1],-data[2]+1)

precompile(glCreateMesh,(GLMesh,))
precompile(glCreateMesh,(GLMesh,Shader))