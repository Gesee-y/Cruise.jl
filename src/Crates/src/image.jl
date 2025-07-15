#######################################################################################################################
################################################### ASSETS IMPORTER ###################################################
#######################################################################################################################

export ImageCrate

######################################################### CORE ########################################################

struct ImageCrate <: AbstractCrate
	obj::Ptr{SDL_Surface}
	pixels::Ptr{Cvoid}
	format::Ptr{SDL_PixelFormat}
	width::Int
	height::Int
	depth::Float32
end

###################################################### FUNCTIONS ######################################################

"""
    Load(::Type{ImageCrate}, path::String,extension::Symbol, args...)

Load a new image crate athe given `path` for a file with the given `extension`.
`args` is some additional data to load the image.
"""
Load(::Type{ImageCrate}, path::String, arg...) = LoadImage(path,arg...)

"""
	LoadImage(path::String)

Load the image at the given `path` and return it on the form of a Surface. You can then use 
`ToTexture` to transform it into a texture and render it.
"""
function LoadImage(path::String,format=SDL_PIXELFORMAT_RGBA8888,conv=false)
	
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
	s = ImageCrate(sur,surf.pixels,surf.format,surf.w,surf.h,surf.pitch/surf.w)

	# and return it.
	return s
end

"""
    Destroy(img::ImageCrate)

This will destroy the image create `img`.
If you try to use it after it was destroyed, you will get an error
"""
function Destroy(img::ImageCrate)
	SDL_FreeSurface(img.obj)
	SDL_FreeFormat(img.format)
end