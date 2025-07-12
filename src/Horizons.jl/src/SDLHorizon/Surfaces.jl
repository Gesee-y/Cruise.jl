## Surfaces for the SDL rendering ##

export Surface
export DestroySurface, GetSurfacePtr, FillRect, BlitSurface, LoadImage, ToTexture, SurfaceToTexture

#=
	Surfaces are the CPU based textures. They are slower than textures but have the 
	advantage to be especially well suited for modification per pixels.
=#

mutable struct Surface
	obj :: Ptr{SDL_Surface}
	rect :: HRect
	depth :: Int
	mask :: Nothing # for now
	clip :: HRect
	pixels :: Ptr{Cvoid}
	format :: Ptr{SDL_PixelFormat}

	# Constructors #

	function Surface(w,h,d,clip=HRect(0,0,0,0);masks=nothing,flags=0)

		# We create te surface
		surf = _create_surface(w,h,d,masks)

		# If no error happened while creating the surface
		if (surf != nothing)

			# We get the surface object
			ss = unsafe_load(surf)

			# And use it to create the Surface
			return new(surf,HRect(w,h,0,0),d,masks,ss.pixels,ss.format)
		end
	end
	function Surface(surf,w,h,d,clip=HRect(0,0,0,0);masks=nothing)

		# We get the surface object
		ss = unsafe_load(surf)

		# And use it to create the Surface
		new(surf,HRect(w,h,0,0),d,masks,clip,ss.pixels,ss.format)
	end
end

"""
	FillRect(s::Surface,rect::HRect,color)

This function draw a filled rect on a surface and is the only drawing operation that 
can be done on surface.`rect` is the size an position of the rect see `HRect`. `color` 
should be a container of integer with at least 3 elements.
"""
function FillRect(s::Surface,rect::HRect,color)
	
	# Getting the SDL_Surface pointed
	surf = GetSurfacePtr(s)

	# Converting the HRect into an SDL_Rect
	r = SDL_Rect(rect.x,r.y,rect.w,rect.h)

	# And getting the color of the rect
 	c = SDL_MapRGB(surf.format,color[1],color[2],color[3])

 	# We then draw the filled rectangle
 	SDL_FillRect(surf,Ref(r),c)
end

"""
	BlitSurface(s1::Surface,s2::Surface,srcrect=C_NULL,dstrect=HRect(0,0,0,0))

Use this function to copy the content of the Surface `s1` on the Surface `s2`. `srcrect` is
the rect representing the part of the image to copy it should be an `HRect`. `dstrect` is 
the where that content should be copied (since Surface don't do resizing, only the position 
is important.)
"""
function BlitSurface(s1::Surface,s2::Surface,srcrect=C_NULL,dstrect=HRect(0,0,0,0))
	
	# If the source rect is not a Null pointer (C_NULL)
	# We convert it into an SDL_Rect
	(srcrect != C_NULL) && (srcrect = SDL_Rect(srcrect.x, srcrect.y, srcrect.w, srcrect.h))
	
	# We also convert the destination rect into an SDL_Rect
	dst = SDL_Rect(dstrect.x, dstrect.y, 0, 0)

	# We finally fuse the surface
	SDL_BlitSurface(GetSurfacePtr(s1), Ref(srcrect), GetSurfacePtr(2), Ref(dst))
end

"""
	ToTexture(ren::SDLRender,s::Surface;destroy=true,name="surf")

This function create a texture from a surface for the renderer `ren`. if `destroy` is true
then after the conversion, the surface `s` will be destroyed.
"""
function ToTexture(ren::SDLRender,s::Surface;destroy=true,name="surf",access=TEXTURE_STREAMING)
	
	# We get the pixels of the Surface `s`
	pixels = get_pixels(s)

	# And Create a new SDL_Texture from the surface
	tex = SDL_CreateTextureFromSurface(ren.renderer,GetSurfacePtr(s))
	
	# Checking if an error happened while creating the SDL_Texture
	if (C_NULL == tex)

		# We get the error
		err = _get_SDL_Error()

		# And emit it as a warning
		HORIZON_WARNING.emit = ("Failed to create texture from surface.",err)
		return nothing
	end

	# If destroy is true then we destrot the surface `s`
	destroy && DestroySurface(s)

	# We get the information about the newly created texture
	info = _get_texture_info(tex)

	# And create the ImageData Informations
	data = ImageData(tex,_to_horizon_access(info[4]),info[3])

	# We then create the texture
	texture = Texture{ImageData}(name,(1,),s.rect.w, s.rect.h,data,true)
	
	# Assign the pixels of the surface in his static informations
	texture.static.pixels = pixels

	# And return it
	return texture
end

"""
	SurfaceToTexture(ren::SDLRender,s::Surface;x=0,y=0,access=TEXTURE_STREAMING,format=nothing,
			name=_generate_texture_name(),static = false)

This function convert a surface to a texture.
"""
function SurfaceToTexture(ren::SDLRender,s::Surface;x=0,y=0,access=TEXTURE_STREAMING,format=nothing,
			name=_generate_texture_name(),static = false)
	
	# We first get the pixels of the surface
	pix = get_pixels(s)

	# And create a new BlankTexture, It will receive the pixel of the surface `s`
	tex = BlankTexture(ren,s.rect.w,s.rect.h;x=x,y=y,access=access,format=format,name=name)
	
	# If the texture was successfuly created
	if tex != nothing

		# Variable to contain the different color component
		# We don't create them in the shader processing because it will mean to
		# create new Ref for each pass which can use a great amount of memory
		# For big images
		r,g,b,a = Ref{UInt8}(0),Ref{UInt8}(0),Ref{UInt8}(0),Ref{UInt8}(0)

		# We then apply the shader copy_pixels to the BlankTexture
		# with as extra parameters the pixels of the surface, his width and is heigth
		# And the Refs to the different color components.
		ProcessPixels(copy_pixels,tex,(pix,s.rect.w,s.rect.h,s.format,r,g,b,a))

		# We return the texture after the process
		return tex
	end

	return nothing
end

"""
	ConvertFormat(s::Surface,f)

This function create a new surface with the data of `s` but with the given format `f`. 
"""
function ConvertFormat(s::Surface,f)

	# We convert the format of the SDL_Surface contained in `s`
	# It will return a new surface with the format specified as `f`
 	surf = SDL_ConvertSurfaceFormat(GetSurfacePtr(s),f,0)

 	# We check if the conversion failed
 	if (C_NULL == surf)

 		# We get the error
 		err = _get_SDL_Error()

 		# And throw it as a warning
 		HORIZON_WARNING.emit = ("Failed to convert surface format.", err)
 		return nothing
 	end

 	# We then create the Surface object
 	Ns = Surface(surf,s.rect.w,s.rect.h)
 	
 	# And return it
 	return Ns
end

"""
	LoadImage(path::String)

Load the image at the given `path` and return it on the form of a Surface. You can then use 
`ToTexture` to transform it into a texture and render it.
"""
function LoadImage(path::String;format=SDL_PIXELFORMAT_RGBA8888,conv=false)
	
	# We create the surface from the path to the image
	su = IMG_Load(path)

	# Check if an error happened
	if (C_NULL == su) 

		# For image loading , we know that the only possible error is that the image
		# was not found. but maybe the can be another error, who know?

		# So we get the error
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to load image at $path.",err) 
		return nothing
	end

	# We then load the SDL_Surface pointer
	# We will use it to get informations
	surf = unsafe_load(su)

	# We convert the format of the image to `format`
	sur = conv ? SDL_ConvertSurfaceFormat(su,format,0) : su

	# We then create the Surface object
	s = Surface(sur,surf.w,surf.h,surf.pitch/surf.w)

	# and return it.
	return s
end

"""
	DestroySurface(s::Surface)

Use this function to destroy an SDL Surface.
"""
DestroySurface(s::Surface) = SDL_FreeSurface(GetSurfacePtr(s))

"""
	GetSurfacePtr(s::Surface)

Return the pointer to the SDL_Surface object of the surface `s`
"""
GetSurfacePtr(s::Surface) = getfield(s,:obj)

# --------------- Helpers ----------------- #

"""
	_create_surface(w,h,d,masks=nothing)

This function create a new SDL_Surface from the given arguments
"""
function _create_surface(w,h,d,masks=nothing)
	
	# We create the SDL_Surface
	surf = SDL_CreateSurface(0,w,h,d,0,0,0,0)

	# Check if an error happened while creating the SDL_Surface
	if (C_NULL == surf)

		# We get the error
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to create surface.",err)
		return nothing
	end

	# We then return the SDL_Surface pointer
	return surf
end

# A shader used to copy pixels
copy_pixels(_,position,info) = begin
	
	# We fetch the Refs to the color components
	r,g,b,a = info[5],info[6],info[7],info[8]

	# The pixels of the object to copy
	pix = info[1]

	# The width of the object
	w = info[2]

	# his height
	h = info[3]

	# and his format.
	f = info[4]

	# From it we deduce the index of the pixels
	x = Int(position[1] * w)
	y = Int(position[2] * h)

	# And get the components of the pixel
	SDL_GetRGBA(pix[x + (y-1)*(w)],f,r,g,b,a)

	# We then just return the components.
	return Color8(r[],g[],b[],a[])
end