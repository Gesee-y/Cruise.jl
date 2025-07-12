############################## Shader like function for SDL ################################

export ProcessPixels, ProcessPixelTable, SetPixels

"""
	ProcessPixels(f,t::SDLTexture;rect=C_NULL)

This function let you process each pixel of a texture like with OpenGL shader (but may be a 
slower because your calculation will be done with the CPU instead of th GPU.).`f` is the 
function that will process each pixel, this function should accept as first parameter a tuple of 
unsigned integer that will be the pixel color and as second parameter a tuple of integer 
that will be the position of the pixel. your function should return a `Color8` or a `Color` struct.
`t` is the texture you want to modify the pixels; `rect` is the part of the pixel you want to modify
should be a `HRect`.
"""
function ProcessPixels(f,t::SDLTexture,extra=();rect=C_NULL)
	# We first get the pixels of the texture `t`
	pixels = get_pixels(t;rect=rect,unlock=false)

	# We allocate the format contained in the data of the texture
	format = SDL_AllocFormat(t.data.format)

	# Checking the format have been correctly created
	if (C_NULL == format)
		err = _get_SDL_Error()
		HORIZON_WARNING.emit = ("Error while allocating format to process pixels.", err)

		# We unlock the texture, so that we can still use it for other things
		SDL_UnlockTexture(_get_texture(t))
		return nothing
	end

	# A bunch of information for the processing loop
	w = t.rect.w; h = t.rect.h
	rect != C_NULL && (w = rect.w, h = rect.h)
	r = Ref{UInt8}(0) # red component
	g = Ref{UInt8}(0) # green component
	b = Ref{UInt8}(0) # blue component
	a = Ref{UInt8}(0) # alpha component
	
	# The processing loop, the core of the shader like behaviour
	for i in Base.OneTo(w)
		x = (i)/(h) # We choose to map the position to 0-1, no matter the original size of the texture
		for j in Base.OneTo(h)
			# The index of the current pixels
			idx = i+w*(j-1)
			y = (j)/(h) # We choose to map the position to 0-1, no matter the original size of the texture

			# We get the different components of the texture
			# and store them in the Refs declared above
			SDL_GetRGBA(pixels[idx],format,r,g,b,a)

			# We then create the object that will be passed as arguments to the function `f`
			color = (r[],g[],b[],a[])
			position = (x,y)


			# We then call the function passed as arguments to the function
			result = f(color,position,extra) # extra is the information the user passed to ProcessPixels
			result = _rearrange_color(result) # We then make sure the result is in the range 0-255

			# We can finally assign the color to the pixels
			resulting_pixel = SDL_MapRGBA(format,result.r,result.g,result.b,result.a)
			pixels[idx] = resulting_pixel
		end
	end

	# Once the loop finished, we no longer need the format object
	SDL_FreeFormat(format)

	# And we can finally unlock the texture
	SDL_UnlockTexture(_get_texture(t))
end
@noinline function ProcessPixels(f,s::Surface,extra=())
	# We first get the pixels of the surface `s`
	pixels = get_pixels(s;unlock=false)

	# We get the pointer to the SDL_Surface, will used to unlock the texture
	surf_ptr = GetSurfacePtr(s)

	w = s.rect.w; h = s.rect.h
	r = Ref{UInt8}(0) # red component
	g = Ref{UInt8}(0) # green component
	b = Ref{UInt8}(0) # blue component
	a = Ref{UInt8}(0) # alpha component

	# The Processing Loop.
	for i in Base.OneTo(w)
		x = (i)/(h) # We choose to map the position to 0-1, no matter the original size of the texture
		for j in Base.OneTo(h)
			# The index of the current pixel (since the pixels are in a Vector not a Matrix)
			idx = i+w*(j-1)

			y = (j)/(h) # We choose to map the position to 0-1, no matter the original size of the texture

			current_pixel = pixels[idx]

			# We store the different componet of the pixel in our Refs declared above
			SDL_GetRGBA(current_pixel,s.format,r,g,b,a)

			# We then create the object that will be passed as arguments to the function `f`
			color = (r[],g[],b[],a[])
			position = (x,y)

			# Storing the result of the function.
			result = f(color,position,extra)
			result = _rearrange_color(result)

			resulting_pixel = SDL_MapRGBA(s.format,result.r,result.g,result.b,result.a)
			pixels[idx] = resulting_pixel
		end
	end

	# We finally unlock the texture
	# Note that this function have less error check than the one for texture
	SDL_UnlockSurface(surf_ptr)
end

"""
	ProcessPixelTable(f,w,h,format::Ptr{SDL_PixelFormat},extra=();pix=nothing)

The purpose of this function is to create a pixel table. For this you can create that pixel 
table from nothing (`pix = nothing`) or from an existing pixel table (`pix = your_pixels`)
`f` is the function you want to apply to create the new pixels. If you create the table from nothing
then the function will take for each pass a color of (0,0,0,0), but if you specify the pixel table
then each pixel (on the form of a UInt32) will be separate in component following the given `format`.
Since pixel table are Vectors, not Matrix, you need to specify a width `w` and a height `h`. This will 
make it easier to just put your new pixels to a texture with the corresponding dimension.

	ProcessPixelTable(f,w,h,form::SDL_PixelFormatEnum,extra=();pix=nothing)

Do the same thing as above, but with the difference that you just have to pass a format enumeration
instead of a pointer.
"""
function ProcessPixelTable(f,w,h,format::Ptr{SDL_PixelFormat},extra=();pix=nothing)
	
	# Depending of if pixel is assigned
	# We decide if we should create a new array or use `pix`
	pixels = pix == nothing ? Array{UInt32}(undef,w*h) : pix

	# Our regular color container Refs
	r = Ref{UInt8}(0); g = Ref{UInt8}(0)
	b = Ref{UInt8}(0); a = Ref{UInt8}(0)

	# The Process Loop
	for i in Base.OneTo(w)
		x = (i)/(h) # If you have read above, I think you understand what this does
		for j in Base.OneTo(h)
			idx = i+w*(j-1)
			y = (j)/(h)# If you have read above, I think you understand what this does

			# Now a little trick
			# We have set all the color containers to Refs to 0
			# So, if a pixel table have not been specified
			# then we will just use the these 0
			#else will fill them will value of the corresponding component.
			(pix != nothing) ? SDL_GetRGBA(pixels[idx],format,r,g,b,a) : nothing

			# We then create the object that will be passed as arguments to the function `f`
			color = (r[],g[],b[],a[])
			position = (x,y)

			# Storing the result of the function.
			result = f(color,position,extra)
			result = _rearrange_color(result)

			pixels[idx] = SDL_MapRGBA(format,result.r,result.g,result.b,result.a)
		end
	end

	# Your pixels are ready
	return pixels
end
function ProcessPixelTable(f,w,h,form::SDL_PixelFormatEnum,extra=();pix=nothing)

	# We start by allocating the correct format
	format = SDL_AllocFormat(form)

	# And check if an error happened
	if (C_NULL == format)
		err = _get_SDL_Error()
		HORIZON_WARNING.emit = ("Error while allocating format to process pixels.", err)
		return nothing
	end

	# Then we process the pixels
	pixels = ProcessPixelTable(f,w,h,format,extra;pix=pix)
	
	# and free the format
	SDL_FreeFormat(format)

	return pixels
end

"""
	ProcessPixelsSurface(f,w,h,form,extra=();pix=nothing)

This function create a pixel table from nothing of from a given `pix` like `ProcessPixelTable`.
Once the table processed, it create a new surface out of it.
"""
function ProcessPixelsSurface(f,w,h,form,extra=();pix=nothing)
	
	# Creating the pixel table
	pixels = ProcessPixelTable(f,w,h,form,extra;pix)
	
	# and checking that no error happened during the process
	if pixels != nothing

		# We then create a surface of the new pixels
		surf = SDL_CreateRGBSurfaceWithFormatFrom(pixels,w,h,32,w*sizeof(UInt32),form)

		# We check that no error happened while creatin the surface
		if (C_NULL == surf)
			# if an error happened
			# We get it
			err = _get_SDL_Error()

			# And throw it as a warning.
			HORIZON_WARNING.emit = ("Failed to create new surface.", err)
			return nothing
		end

		# We create the new Surface object
		s = Surface(surf,w,h)

		# And return it
		return s
	end

	return nothing
end

"""
	SetPixels(t::SDLTexture,pixels;rect=C_NULL)

This function set the pixels of a texture. meaning that if you possess a pixel table that can 
match the texture dimension, then you just use this function to make the texture use these pixels.
"""
function SetPixels(t::SDLTexture,pixels;rect=C_NULL)
	SDL_UpdateTexture(_get_texture(t),rect,pixels,sizeof(UInt32)*t.rect.w)
end

"""
	get_pixels(t::SDLTexture;rect=C_NULL,unlock=false)

Return the pixels of a SDLTexture `t`, `rect` is the part of the texture you want to get as a 
`HRect`. if `rect = C_NULL` then the pixels of all the texture will be getted. if `unlock` is `true`
then the texture will be unlocked afterward (meaning you can use it for anything.) but if 
`unlock` is false, then you will have to unlock the texture manually(but you will be able to
process his pixels.)

	get_pixels(s::Surface;unlock=false)

Do the same as `get_pixels(t::SDLTexture;rect=C_NULL,unlock=false)` but with Surfaces.
"""
function get_pixels(t::SDLTexture;rect=C_NULL,unlock=false)
	
	# We start by initializing the rect(the surface we want to get the pixels)
	rect != C_NULL && (rect = SDL_Rect(rect.x,rect.y,rect.w,rect.h))

	# Then we create the necessary variable
	pixels_ref = Ref{Ptr{Cvoid}}() # Will conatain a pointer to the pixels
	pitch = Ref{Cint}(0) # Will contain the pitch of the texture

	# Then we Lock the Texture and check that no error happened
	if (0 != SDL_LockTexture(_get_texture(t),rect,pixels_ref,pitch))
		
		# We get the error
		err= _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to get texture $t pixels.",err)
		return nothing
	end

	# We check if we have already get the pixels of the texture
	# Because SDL allow that we get the pixels of a texture only one time
	if !t.static.getted
		ptr :: Ptr{UInt32} = pixels_ref[] # We then convert the Ptr{Cvoid} to a Ptr{UInt32}(or Ptr{Cuint})
		
		# Get the pixels from the pointer
		pixels = unsafe_wrap(Array,ptr,t.rect.w*t.rect.h)
		
		# Mark that we have get the pixels
		t.static.getted = true

		# and assign it some where in the texture
		t.static.pixels = pixels

		# If `unlock` have been passed as true, we unlock the texture
		unlock && SDL_UnlockTexture(_get_texture(t))

		# And finally return the pixels
		return pixels
	else
		# The texture have already been getted one time.

		# If `unlock` have been passed as true, we unlock the texture
		unlock && SDL_UnlockTexture(_get_texture(t))

		# And return the pixels contained in the texture
		return t.static.pixels
	end
end
function get_pixels(s::Surface;unlock=false)
	# For surface it's a bit more easy
	# We don't need extra checks because the pixels can be get freely

	# We get the SDL_Surface object from the Surface `s`
	surf_ptr = GetSurfacePtr(s)

	# We lock the texture and check if an error happened
	if (0 != SDL_LockSurface(surf_ptr))

		# We get the error
		err= _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to get surface $s pixels.",err)
		return nothing
	end

	# We then convert the Ptr{Cvoid} to a Ptr{UInt32}(or Ptr{Cuint})
	src :: Ptr{UInt32} = s.pixels

	# And get the pixels from the pointer
	pixels = unsafe_wrap(Array,src,s.rect.w*s.rect.h)

	# If `unlock` have been passed as true, we unlock the texture
	unlock && SDL_UnlockSurface(surf_ptr)

	# And we return the pixels
	return pixels
end

"""
	_rearrange_color(c::Color8)

Create a Color8 object with the value of `c` all mapped fro 0 to 255

	_rearrange_color(c::Color)

Do the same as above.
"""
_rearrange_color(c::Color8) = begin
	r = floor(_to_color_value(c.r))
	g = floor(_to_color_value(c.g))
	b = floor(_to_color_value(c.b))
	a = floor(_to_color_value(c.a))

	return Color8(r,g,b,a)
end
_rearrange_color(c::Color) = begin
	r = floor(_to_color_value(c.r;type=:float) * 255)
	g = floor(_to_color_value(c.g;type=:float) * 255)
	b = floor(_to_color_value(c.b;type=:float) * 255)
	a = floor(_to_color_value(c.a;type=:float) * 255)

	return Color8(r,g,b,a)
end

"""
	identity_shader(::StaticColor{R,G,B,A},_,_)

A SDL shader that does nothing. he return the color passed in inputs
"""
function identity_shader(color,_,_)
	return Color8(color...)
end