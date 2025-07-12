######################## Manage texture for SDL rendering ###################################

#=
	Textures are the GPU accelerated form of SDL surfaces.
	Horizon implement them in a way that you can easily merge surface together with 
	a parent-child relation. In that way you can create some complex figure(or things like that.)
=#

export SDLTexture
export BlankTexture, CopyTo, CopyTexture
export StaticColor, StaticPosition

struct StaticColor{R,G,B,A} end
struct StaticPosition{X,Y} end

"""
	struct BlankData <: TextureData
		obj :: Ptr{SDL_Texture}
		access :: SDL_TextureAccess
		format :: Ptr{SDL_PixelFormat}

This struct is used to created BlankTexture.
"""
struct BlankData <: TextureData
	obj :: Ptr{SDL_Texture}
	access :: TextureAccess
	format :: SDL_PixelFormatEnum
end

"""
	struct ImageData <: TextureData
		obj :: Ptr{SDL_Texture}
		access :: TextureAccess
		format :: SDL_PixelFormatEnum

This struct represent the necessary to represent an image texture.
"""
struct ImageData <: TextureData
	obj :: Ptr{SDL_Texture}
	access :: TextureAccess
	format :: SDL_PixelFormatEnum
end

"""
	SDLTexture = Union{Texture{BlankData},Texture{ImageData}}

A Type that is a supertype of all the SDL Texture.
"""
const SDLTexture = Union{Texture{BlankData},Texture{ImageData}}

"""
	BlankTexture(ren::SDLRender,w,h;access=nothing,format=nothing,name=_generate_texture_name())

This function will create a new empty SDL texture.
"""
function BlankTexture(ren::SDLRender,w,h;x=0,y=0,access=TEXTURE_STREAMING,format=nothing,
			name=_generate_texture_name(),static = false)

	# We convert the Horizon Texture access into SDL Texture Access
	a = ConvertAccess(SDLRender,access)

	# We set the format
	f = (format === nothing) ? SDL_PIXELFORMAT_RGBA8888 : format
	
	# We create the SDL_Texture
	tex_ptr = SDL_CreateTexture(ren.renderer,f,a,w,h)

	# If the texture creation failed
	if (C_NULL == tex_ptr)
		# We throw an error, to avoid working with a nothing.
		err = _get_SDL_Error()
		HORIZON_ERROR.emit = ("Failed to create Texture.",err)

		return nothing
	end

	# The information for the blank texture
	data = BlankData(tex_ptr,access,f)

	# We finally construct the texture
	texture = Texture{BlankData}(name,(0,),w,h,data;x=x,y=y,static=static)

	return texture
end

"""
	CopyTo(ren::SDLRender,t::SDLTexture)

This function should be use to copy the content of a texture on a renderer which will make
it visible on the screen.

	CopyTo(ren::SDLRender,t::SDLTexture,t2::SDLTexture)

This function is to copy the content of a texture on another texture. The first texture is 
considered as the parent of the first one (so if the parent is not rendered then it will also
no be rendered)
"""
function CopyTo(b::SDLRender,t::SDLTexture)
	v = b.viewport[]

	# If there is a viewport in the renderer
	if v != nothing
		CopyTo(v,t) # We copy the texture in the viewport
	else
		# We throw a warning. you can get the warning back via 
		#`Horizon.connect(function_to_handle_warnings,HORIZON_WARNING)`
		HORIZON_WARNING.emit = ("Failed to copy texture to viewport."," There is no active viewport, create one with CreateViewport.")
	end
end
function CopyTo(b::SDLRender,t::SDLTexture,t2::SDLTexture)
	v = b.viewport[]

	# If there is a viewport in the renderer
	if v != nothing
		CopyTo(v,t,t2)
	else
		HORIZON_WARNING.emit = ("Failed to copy texture to viewport."," There is no active viewport, create one with CreateViewport.")
	end
end
function CopyTo(v::SDLViewport,t::SDLTexture)
	# We create a new node.
	# This node will be then added to the ObjectTree (or more exactly the TextureTree)
	# of the viewport.
	n = Node(t,t.name)
	add_child(v.textures,n)

	# We then set the id (which is also the index in the tree) of the texture `t`
	setfield!(t,:id,get_nodeidx(n)::Tuple{Int})

	return nothing
end
function CopyTo(v::SDLViewport,t::SDLTexture,t2::SDLTexture)
	# We first get the tree
	tree = getfield(v,:textures) :: ObjectTree

	# Then from it, we extract the node corresponding to the texture `t`
	t_node :: Node = get_node(get_root(tree),getfield(t,:id)::Tuple)

	# We create then the new node
	t2_node :: Node = Node(t2,t2.name)

	# and add it as a child of the texture
	add_child(t_node,t2_node;tree=tree)

	# Now we just have to set the id of the texture `t2`
	setfield!(t2,:id,get_nodeidx(n))

	return nothing
end

"""
	CopyTexture(r::SDLRender,t::SDLTexture;access=TEXTURE_STREAMING,format = SDL_PIXELFORMAT_RGBA8888,rect=C_NULL)

Copy the given texture `t` into a new texture with the given `access` and `format`, `rect` is the part of the 
texture to copy.
"""
function CopyTexture(r::SDLRender,t::SDLTexture;access=TEXTURE_STREAMING,format = SDL_PIXELFORMAT_RGBA8888,rect=C_NULL)
	
	# We first create an empty texture with the data passed as arguments
	t2 = BlankTexture(r,t.rect.w,t.rect.h;name=t.name*"copy",access=access,format = format)

	# If the creation of the texture was successful
	if t2 != nothing

		# Then we get the pixel table of the newly created texture
		pix = get_pixels(t2)

		# And we also get the pixels of the source texture `t`
		pixels = t.static.pixels

		# Then we assign to each pixel of `t2` the corresponding pixel of `t`
		for i in eachindex(pix)
			pix[i] = pixels[i]
		end

		# We finally then unlock the texture
		SDL_UnlockTexture(_get_texture(t2))

		return t2
	end

	return nothing
end

"""
	DestroyTexture(tex::SDLTexture)

Destroy the SDLTexture `tex` making it unusable(if you try, you will have a big jumpscare so
, my advice, once a texture destroyed, leave it be.). If the texture was the parent of another 
texture, then destroying the parent will make his childrens unrenderable (because they are no more 
in the texture tree).
"""
function DestroyTexture(v::SDLViewport,tex::SDLTexture)
	n = get_node(get_root(v.textures),tex.id) # We get the node of the texture in the tree

	remove_node(v.textures,n) # We then remove the node and his childrens
	SDL_DestroyTexture(_get_texture(tex)) # We destroy the texture
	HORIZON_TEXTURE_DESTROYED.emit = tex
end

# ---------- Helpers ------------ #

# This function render all the texture of a viewport in a recursive way.
# So that change in parents easily affect childs (We are talking about texture there.)
@inline function _render_texture(b::SDLRender,v::SDLViewport,node;par=node[])
	t = node[] # Just getting the texture
	if (t.renderable)

		# We have prefer tail recursivity there.
		# Meaning that instead of first rendering the parent and then his child on him
		# we first render his childs on him and then render the parent.
		for n in get_childrens(node)
			SetRenderTarget(b,par) # We set the parent as target for render
			_render_texture(b,v,n;par=t) # We then start our recursive loop
			# the loop will stop when we will have a childless node
		end

		_render_a_texture(b,t) # This function will render the current texture	
	end
	
	SetRenderTarget(b,v) # Then we set back the render target to the viewport after each recursion
	# (So, when child have all been rendered, they will set back the render target to the viewport 
	# so that their parent can be rendered on it.)
end

# This function serve to render a texture
function _render_a_texture(b::SDLRender,t::Texture)
	# This condition mean
	# if a texture is not static or the texture is static and have not been rendered yet
	if (!_is_static(t) || (_is_static(t) && !_is_rendered(t)))
		r = t.rect # getting the rect of the texture 
		rect = SDL_Rect(r.x,r.y,r.w,r.h)
		_set_rendered(t,true)
		SDL_RenderCopy(b.renderer,_get_texture(t),C_NULL,Ref(rect))
	end
end

_is_static(t::Texture) = getfield(getfield(t,:static),:static)
_is_rendered(t::Texture) = getfield(getfield(t,:static),:rendered)
_set_rendered(t::Texture,v::Bool) = setfield!(getfield(t,:static),:rendered,v)

# This function return all the useful information about a SDL_Texture.
function _get_texture_info(ptr::Ptr{SDL_Texture})
	w,h = Ref{Cint}(0),Ref{Cint}(0)
	f = Ref{UInt32}()
	a = Ref{Int32}()

	SDL_QueryTexture(ptr,f,a,w,h,)

	return w[],h[],SDL_PixelFormatEnum(f[]),SDL_TextureAccess(a[])
end
_generate_texture_name() = "Tex"
_get_texture(t::SDLTexture) = getfield(getfield(t,:data),:obj)

function _to_horizon_access(a)
	if a == SDL_TEXTUREACCESS_STATIC
		return TEXTURE_STATIC
	elseif a == SDL_TEXTUREACCESS_STREAMING
		return TEXTURE_STREAMING
	elseif a == SDL_TEXTUREACCESS_TARGET
		return TEXTURE_TARGET
	end

	return nothing
end