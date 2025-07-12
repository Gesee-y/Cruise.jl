############################### Horizon OpenGL Backend #########################################

export GLRender
export SetGLViewport

include("GLHEnum.jl")

const VERTEX_ATTRIB_POS = 0
const TEXCOORD_ATTRIB_POS = 1
const NORMAL_ATTRIB_POS = 2

"""
	abstract type GLRenderWindowData

Abstract type that serve to create new context holder data for openGL.
OpenGL is just a specification, it's not bounded to any API so that is why we need to 
keep the data about the context creator separate from the OpenGL data
"""
abstract type GLRenderWindowData end

struct SDLData <: GLRenderWindowData
	window :: Ptr{SDL_Window}
	context :: Ptr{Cvoid}
	type :: Symbol
end

"""
	mutable struct GLRender
		data :: GLRenderWindowData
		vsync::Bool
		glsl_version::String
		info :: Dict

OpenGl renderer. This is used to keep some informations about the current OpenGL context.
`data` keep informations about the window, `vsync` indicate if the vertical synchronisation
is enabled or not, `glsl_version` is the version of GLSL and `info` contain the following
informations:
		:glsl_version   => The Version of GLSL,
	    :gl_version     => The version of OpenGL,
	    :gl_vendor	    => The graphic card manufacturer,
	    :gl_renderer	=> The renderer,
	    :gl_extensions  => The available extensions
"""
mutable struct GLRender
	data :: GLRenderWindowData
	vsync::Bool
	glsl_version::String
	info :: Dict
end

include("Abstraction\\GLAbstraction.jl")
include("GLMesh.jl")

"""
	InitBackend(window::Ptr{SDL_Window};vsync=true)

Initialize the OpenGL backend of Horizon, If everything went well then the `NOTIF_BACKEND_INITED`
will be emitted with the backend in question.
"""
function InitBackend(::Type{GLRender},window::Ptr{SDL_Window},w,h;vsync=true)
	# We initialize the OpenGL context.
	context = _initGL(window, vsync)

	# We check that there is no error after creating the renderer
	if nothing != context
	
		# If everything went well, then we create the SDLRender object
		glsl_version = _get_glsl_version()

		# We create the data about the context holder
		data = SDLData(window, context, :SDL)
		renderer = GLRender(data, vsync, glsl_version,_get_opengl_info())

		viewport = glViewport(0,0,w,h)

		# And emit a notification, so that every other system can know that the graphics have been inited.
		HORIZON_BACKEND_INITED.emit = renderer

		return renderer
	end
end

"""
	SetGLViewport(x,y,w,h)

This function will set the current OpenGL viewport.
Since OpenGL is just a state machine. there is no need to pass the renderer as argument.
"""
SetGLViewport(x,y,w,h) = glViewport(x,y,w,h)

"""
	ClearScreen(::Type{GLRender},color)

This function will clear the OpenGL viewport.
`color` can be any container of number. The only restriction is that it should have at least 4 elements
"""
function ClearScreen(::Type{GLRender},color;mode::GLHClearMode=GLH_COLOR_BITS)
	glClearColor(color[1], color[2], color[3], color[4])
	glClear(_convert_clearmode(mode) | _convert_clearmode(GLH_DEPTH_BITS))
end

"""
	UpdateRender(backend::GLRender)

Use this function to update the render of OpenGL
"""
function UpdateRender(backend::GLRender)
	
	# We check the context to corretly update the window
	if _get_context_type(backend) == :SDL

		# We update GL context in an SDL style
		SDL_GL_SwapWindow(_get_window(backend))
	end
end

"""
	DestroyBackend(backend::GLRender)

Useless to destroy the OpenGL backend, It will be destroyed when the window will terminate
I just put this function for the pleasure of declaring a function.
"""
DestroyBackend(backend::GLRender) = nothing

# -------------------------------------- Helpers ------------------------------------------#

# This not so tiny function will initialize )penGL
function _initGL(gWindow::Ptr{SDL_Window}, vsync=true)

    # Initialization flag
    success = true

    # Use OpenGL 3.1
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3)
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 1)
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)

    # Create context
    gContext = SDL_GL_CreateContext( gWindow )

    # We check that the OpenGL context have been created.
    if( gContext == C_NULL )

    	# We get the error
    	err = _get_SDL_Error()

    	# And throw it as an error
    	HORIZON_ERROR.emit = ("Failed to initialize OpenGL.",err)
    	return nothing
    end

    # Enable Vsync

    if vsync
	    if( SDL_GL_SetSwapInterval(1) < 0 )
	    	
	    	# We get the error
    		err = _get_SDL_Error()

    		# And throw it as an error
    		HORIZON_WARNING.emit = ("Unable to set VSync for OpenGL.",err)
	    end
	end

	return gContext
end

function _get_glsl_version()
	# We get the glsl version data with glGetString
	# Load it and split the result first at '.' and then with ' '
	glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])

	# If the result is a valid GLSL version
	if length(glsl) >= 2

		# We transform the resulting data into a version string using `VersionNumber`
		glsl = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
		GLSL_VERSION = string(glsl.major) * rpad(string(glsl.minor),2,"0")
	else

		# We throw the error
		# Since we don't really know the cause of this error all we can do is to ask someone
		# to report the bug.
		HORIZON_ERROR.emit("Unknow glsl version string. Please report this bug.",glsl)
		return nothing
	end
	_glsl_version_string() = "#version $GLSL_VERSION core"

	return GLSL_VERSION
end

_glsl_version_string() = ""

function _get_opengl_info()
	
	# Getting the version of glsl
	glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])
	
	# getting the version of OpenGL
	glv = split(unsafe_string(glGetString(GL_VERSION)), ['.', ' '])
	
	if length(glv) >= 2
		glv = VersionNumber(parse(Int, glv[1]), parse(Int, glv[2]))
	else
		HORIZON_ERROR.emit = ("Unexpected version number string. Please report this bug! OpenGL version string: $(glv)","")
		return nothing
	end
	
	dict = Dict{Symbol,Any}(
	    :glsl_version   => glsl,
	    :gl_version     => glv,
	    :gl_vendor	    => unsafe_string(glGetString(GL_VENDOR)),
	    :gl_renderer	=> unsafe_string(glGetString(GL_RENDERER)),
	    :gl_extensions  => split(unsafe_string(glGetString(GL_EXTENSIONS))),
	)

	return dict
end

_get_context_type(r::GLRender) = getfield(getfield(r,:data),:type)
_get_context(r::GLRender) = getfield(getfield(r,:data),:context)
_get_window(r::GLRender) = getfield(getfield(r,:data),:window)

function glCheckError(actionName="")
	message = glErrorMessage()
	if length(message) > 0
		HORIZON_WARNING.emit = (actionName,message)
		return true
	end

	return false
end