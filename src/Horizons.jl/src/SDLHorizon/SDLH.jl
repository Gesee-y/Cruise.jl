############################################ The SDL Mode of Horizon #################################################

export SDLRender, ClearScreen, SetRenderTarget, CreateViewport, SetAlpha, SetAlphaBlendMode
export SetRenderScale, SetViewportPosition, ClearViewport, ClearTexture, SetScale

include("SDLObject.jl")

const SDLViewport = HViewport{SDLObjectData, 2}

"""
	struct SDLRender
		window :: Ptr{SDL_Window}
		renderer :: Ptr{SDL_Renderer}

A struct to represent the necessary for an SDL backend.
"""
struct SDLRenderData <: RendererData
	window::Ptr{SDL_Window}
	renderer::Ptr{SDL_Renderer}

	vsync::Bool
	accelerated::Bool

	# Constructors #

	function SDLRenderData(win,ren,accelerated,vsync)
		new(win,ren,vsync,accelerated)
	end
end

const SDLRender = HRenderer2D{SDLRenderData, SDLObjectData}

"""
	InitBackend(window::Ptr{SDL_Window};vsync=true,accelerated=true)

Initialize the SDL backend of Horizon, If everything went well then the `NOTIF_BACKEND_INITED`
will be emitted with the backend in question.
"""
function InitBackend(::Type{SDLRender},window::Ptr{SDL_Window};vsync=true,accelerated=true)
	flags = SDL_RENDERER_SOFTWARE

	# Will fall back to software render if enable to set accelerated render
	accelerated && (flags = SDL_RENDERER_ACCELERATED)

	# We set the vsync if `vsync = true`
	vsync && (flags = flags | SDL_RENDERER_PRESENTVSYNC)

	# We then create the renderer
	ren = SDL_CreateRenderer(window, -1, flags)

	# We check that there is no error after creating the renderer
	if C_NULL == ren

		# We get the error
		err = _get_SDL_Error()

		# And emit it as an error
		# because the renderer is the base of everything.
		HORIZON_ERROR.emit = ("Failed to initialize simple context for SDL2", err)
		return nothing
	end

	# If everything went well, then we create the SDLRender object
	renderer = SDLRender(SDLRenderData(window,ren,accelerated,vsync))
	# And emit a notification, so that every other system can know that the graphics have been inited.
	HORIZON_BACKEND_INITED.emit = renderer

	return renderer
end

"""
	ConvertAccess(::Type{SDLRender},a::TextureAccess)

This function make a correspondance between SDL_TextureAccess and Horizon TextureAccess
"""
function ConvertAccess(::Type{SDLRender},a::TextureAccess)
	if a == TEXTURE_STATIC
		return SDL_TEXTUREACCESS_STATIC
	elseif a == TEXTURE_STREAMING
		return SDL_TEXTUREACCESS_STREAMING
	elseif a == TEXTURE_TARGET
		return SDL_TEXTUREACCESS_TARGET
	end

	return nothing
end
ConvertAccess(::Type{SDLRender}, a::SDL_TextureAccess) = a

include("SDLTexture.jl")
include("Surfaces.jl")
include("Drawing.jl")
include("SDLShaders.jl")
include("SDLCommands.jl")
"""
	CreateViewport(r::SDLRender,w,h,x=0,y=0)

This function create a new Viewport for the renderer r.
Once the viewport created, it's now possible to use textures and surfaces
"""
function CreateViewport(r::SDLRender,w,h,x=0,y=0;scale=4)
	
	# We create a blank texture that will be the screen of the viewport
	# other texture will just be pasted on it.
	tex = BlankTexture(r,Int(floor(w/scale)),Int(floor(h/scale));x=x,y=y,access=TEXTURE_TARGET)

	# if no error happened while creating the texture
	if tex != nothing

		# We create a new viewport
		if !isdefined(r.viewport, :screen)
			r.viewport.screen = SDLObject(Vec2f(x,y),Vec2f(scale,scale))
			data = SDLObjectData(tex)
		    r.viewport.screen.data = data
		end

		# Then we set the viewport as the target for rendering
		SetRenderTarget(r)

		return 
	end
end

"""
	SetViewportPosition(r::SDLRender,x::Int,y::Int)

Set the position of the current viewport.
"""
SetViewportPosition(r::SDLRender,x::Int,y::Int) = begin
	v = r.viewport

	if !isdefined(v, :screen)
		return
	else
		get_texture(v.screen).rect.x = x
		get_texture(v.screen).rect.y = y
	end
end

"""
	SetViewportSize(r::SDLRender,w::Int,h::Int)

Set the size of the current viewport.
"""
SetViewportSize(r::SDLRender,w::Int,h::Int) = begin
	v = r.viewport

	if !isdefined(v, :screen)
		return
	else
		get_texture(v.screen).rect.w = w
		get_texture(v.screen).rect.h = h
	end
end

"""
	SwapViewport(r::SDLRender,v::SDLViewport)

Change the viewport of the SDLRender `r` to `v`. It returns the old viewport of `r`.
"""
function SwapViewport(r::SDLRender,v::SDLViewport)
	old_v = r.viewport[]
	r.viewport[] = v

	return old_v
end

"""
	SetRenderTarget(ren::SDLRender,viewport=true)

Set the renderer as the current render target. If viewport is true and the SDLRender `ren` have
a viewport, then the render target will be his viewport.

	SetRenderTarget(ren::SDLRender,t::SDLTexture)

Set the texture `t` as the current render target(meaning all operation will be done on it.)
"""
function SetRenderTarget(ren::SDLRender,viewport=true)
	v = ren.viewport

	if !isdefined(v, :screen) || !viewport
		SDL_SetRenderTarget(ren.data.renderer,C_NULL)
	else
		SetRenderTarget(ren,v)
	end
end
SetRenderTarget(ren::SDLRender,v::SDLViewport) = SetRenderTarget(ren,v.screen)
SetRenderTarget(ren::SDLRender,obj::SDLObject) = SetRenderTarget(ren,get_texture(obj))

function SetRenderTarget(ren::SDLRender,t::SDLTexture)
	target = _get_texture(t)
	if (0 != SDL_SetRenderTarget(ren.data.renderer,target))
		err = _get_SDL_Error()
		HORIZON_WARNING.emit = ("Failed to set texture $(t) as render target",err)
	end
end

"""
	SetAlphaBlendMode(r::SDLRender,mode=SDL_BLENDMODE_BLEND)

Use this function to set the alpha blend mode of the renderer `r`

	SetAlphaBlendMode(tex::SDLTexture,blending::SDL_BlendMode=SDL_BLENDMODE_BLEND)

Use this function to set the alpha blend mode of the texture tex.
"""
SetAlphaBlendMode(r::SDLRender,mode=SDL_BLENDMODE_BLEND) = SDL_SetRenderDrawBlendMode(r.data.renderer,mode)
SetAlphaBlendMode(tex::SDLTexture,blending::SDL_BlendMode=SDL_BLENDMODE_BLEND) = SDL_SetTextureBlendMode(_get_texture(tex),blending)

"""
	Modulate(tex::SDLTexture,r::Int,g::Int,b::Int,a::Int)

Will multiply the color of the texture `tex` with color component `r`,`g`,`b` and `a`
"""
Modulate(tex::SDLTexture,r::Int,g::Int,b::Int,a::Int) = begin 
	SDL_SetTextureColorMod(_get_texture(tex),r,g,b)
	SDL_SetTextureAlphaMod(_get_texture(tex),a)
end

"""
	SetRenderScale(r::SDLRender,x::Int,y::Int)

This function set the scale of the current render target. Can be useful for some zooming effect.
"""
SetRenderScale(r::SDLRender,x::Int,y::Int) = SDL_RenderSetScale(r.data.renderer,x,y) 
SetScale(obj::SDLObject,sx,sy) = (obj.rect.dimensions.x = sx; obj.rect.dimensions.y = sx)
SetScale(obj::SDLObject,s) = (obj.rect.dimensions.x = s; obj.rect.dimensions.y = s)

"""
	ClearScreen(ren::SDLRender)

This function is used to clear the renderer `ren`(removing everything that has been drawn on it).
"""
function ClearScreen(ren::SDLRender)

	# We first get the current target for rendering
	ta = SDL_GetRenderTarget(ren.data.renderer)

	# Then we set the target as the renderer
	SDL_SetRenderTarget(ren.data.renderer,C_NULL)

	# And we clear the renderer and check for error
	if 0 != SDL_RenderClear(ren.data.renderer)

		# We get error 
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to clear screen.", err)
	end

	# Finally we set back the render target to the previous target
	SDL_SetRenderTarget(ren.data.renderer,ta)
end

"""
	ClearViewport(ren::SDLRender,v::Viewport)

This function should be use to clear a viewport.
"""
function ClearViewport(ren::SDLRender)
	v = ren.viewport
	# We just clear the screen of the viewport
	isdefined(v, :screen) && ClearTexture(ren,get_texture(v.screen))
end

"""
	ClearTexture(ren::SDLRender,t::SDLTexture)

This function will clear all the content of an SDL Texture
"""
function ClearTexture(ren::SDLRender,t::SDLTexture)
	
	# We get the current target for render
	ta = SDL_GetRenderTarget(ren.data.renderer)

	# We first set the render target to the texture
	SetRenderTarget(ren,t)

	if 0 != SDL_RenderClear(ren.data.renderer)

		# We get error 
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to clear texture.", err)
	end

	# Finally we set back the render target to the previous target
	SDL_SetRenderTarget(ren.data.renderer,ta)
end

function RenderObject(r::SDLRender,obj::SDLObject; parent=nothing,viewport=true)
	tex = get_texture(obj)
	ro = obj.rect # getting the rect of the texture 
	rt = tex.rect
	
	rect = SDL_FRect(ro.x,ro.y,rt.w*ro.w,rt.h*ro.h)
	renderer = r.data.renderer
	ta = SDL_GetRenderTarget(renderer)

	isnothing(parent) ? SetRenderTarget(r,viewport) : SetRenderTarget(r, parent.data.texture)
	SDL_RenderCopyF(renderer,_get_texture(tex),C_NULL,Ref(rect))
	SDL_SetRenderTarget(renderer, ta)
end


"""
	UpdateRender(backend::SDLRender)

Use this function to make all the change done to the SDL backend visible.
"""
#=function UpdateRender(backend::SDLRender)

	# We start by setting the target to the renderer
	SDL_SetRenderTarget(backend.data.renderer,C_NULL)
	view = backend.viewport

	# If there is an active viewport
	if isdefined(view, :screen)

		# We update the viewport recursively
		_update_viewport(backend,view)

		# And we present the render
		SDL_RenderPresent(backend.data.renderer)
	end
	SetRenderTarget(backend)
end=#
PresentRender(backend::SDLRender) = SDL_RenderPresent(backend.data.renderer)

"""
	DestroyBackend(backend::SDLRender)

Use to destroy an SDLRender.
"""
function DestroyBackend(backend::SDLRender)
	v = backend.viewport[]

	# If there is a active viewport
	if isdefined(view, :screen)

		# We create an iterator to all textures in the viewport
		iter = tree_to_leaves(v.textures)

		# and destroy them all
		for node in iter
			DestroyObject(node[])
		end
	end

	# We then destroy the renderer 
 	SDL_DestroyRenderer(backend.data.renderer)

 	# And emit a signal to let other sub system know it,
 	HORIZON_BACKEND_DESTROYED.emit = backend
end

# ---------- Helpers ----------- #

# this function will update the main viewport
function _update_viewport(b::SDLRender,v::SDLViewport;par=v)

	# We get the root the tree of sub viewport
	subs = get_root(v.subview)

	# And iterate over his childs
	for n in get_children(subs)

		# we set the render target to the parent of the sub viewport
		SetRenderTarget(b,par)

		# We update the child recusively
		_update_viewport(b,n)
	end

	# We then update the texture of the current viewport
	_update_viewport_textures(b,v)

	# and the target to the renderer
	SDL_SetRenderTarget(b.data.renderer,C_NULL)

	# And render the main viewport
	_render_a_texture(b,v.screen)
	
end

# This function will update a sub viewport
function _update_viewport(b::SDLRender,node::Node;par=get_texture(node[]))
	
	# We just get the subviewport from the Node
	v = node[]

	# Then we iterate over the childrens of the node
	# So we update the sub viewport recursively
	for n in get_children(node)

		# We set the render target to the parent viewport 
		SetRenderTarget(b,par)

		# And update the child sub viewport
		_update_viewport(b,n;par=v)
	end

	# Then we update the textures of the sub viewport
	_update_viewport_textures(b,v)

	# and finally render his screen
	_render_a_texture(b,get_texture(v.screen))

	# Then we set back the target to the renderer
	SDL_SetRenderTarget(backend.data.renderer,C_NULL)
end

# this function will render the textures of a viewport
function _update_viewport_textures(b::SDLRender,v::SDLViewport)
	
	# We first set the viewport to the screen of the viewport
	SetRenderTarget(b,get_texture(v.screen))
	tree = v.objects

	# Then we iterate over the node in the root of the texture tree
	for ch in get_children(get_root(tree))

		# and render them
		# They will recursively render their childrens texture
		_render_texture(b,v,ch)
	end
end

# Transform real `v` into a valid Color value
_to_color_value(v::Real;type=:int) = (type == :int) ? min(max(zero(v),v),255) : min(max(zero(v),v),one(v))

# Get the last SDL Error
_get_SDL_Error() = unsafe_string(SDL_GetError())

precompile(_render_texture,(SDLRender,SDLTexture))
precompile(UpdateRender,(SDLRender,))
precompile(SetRenderTarget,(SDLRender,))
precompile(SetRenderTarget,(SDLRender,SDLTexture))