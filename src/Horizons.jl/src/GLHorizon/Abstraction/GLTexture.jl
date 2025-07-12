## OpenGl Texture Abstraction

export glCreateTexture2D

"""
	struct GLTexData <: TextureData
		id :: UInt32
		path :: String
		dimension :: Int

This struct represent the necessary to create an OpenGL Texture, `id` is the id of the texture
`dimension` tell us if it's a 1D, 2D or 3D texture
"""
struct GLTexData <: TextureData
	id :: UInt32
	path :: String
	dimension :: Int
end

const GLTexture = Texture{GLTexData}

"""
	glCreateTexture2D(path::String)

Create a new 2D texture from an image at the given path.
"""
glCreateTexture2D(path::String,ws::GLHTextureWrapping=GLH_REPEAT,wt::GLHTextureWrapping=GLH_REPEAT,
			fmin::GLHTextureFiltering=GLH_NEAREST,fmax::GLHTextureFiltering=GLH_LINEAR;format=GL_RGBA,conv=false) = begin
	## We load the image with SDL
	img = LoadImage(path;conv=conv)

	# If the image loaded successfully
	if img != nothing

		# We get the image dimensions
		w,h = img.rect.w,img.rect.h
		fmi = _convert_texture_filtering(fmin)
		fma = _convert_texture_filtering(fmax)
		w1 = _convert_texture_wrapping(ws)
		w2 = _convert_texture_wrapping(wt)

		#form = _to_gl_format(SDL_PixelFormatEnum(unsafe_load(img.format).format))
		form = GL_RGBA

		# We get the image's pixels
		data = unsafe_load(GetSurfacePtr(img)).pixels

		# We initialize our texture ID container
		tex = UInt32[0]

		# We create the texture ID
		glGenTextures(1,tex)

		# And specify that it's a 2D texture
		glBindTexture(GL_TEXTURE_2D,tex[])

		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,w1)
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,w2)
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,fmi)
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,fma)

		# We create the texture itself
		glTexImage2D(GL_TEXTURE_2D,0,form,w,h,0,format,GL_UNSIGNED_BYTE,data)
		glGenerateMipmap(GL_TEXTURE_2D)

		# And we create an Horizon texture from all this
		tex_data = GLTexData(tex[],path,2)
		res = Texture{GLTexData}(path,(),w,h,tex_data)

		# We destroy the image
		DestroySurface(img)

		# and finally return the texture
		return res
	end
end

