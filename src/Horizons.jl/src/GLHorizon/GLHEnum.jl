################################## Enumeration for GLH ##########################################
export GLHClearMode, GLH_COLOR_BITS, GLH_DEPTH_BITS, GLH_STENCIL_BITS

"""
	enum GLHClearMode
		 GLH_COLOR_BITS
		 GLH_DEPTH_BITS
		 GLH_STENCIL_BITS

This enum represent way in which OpenGL can clear the viewport, to use with `ClearScreen`
"""
@enum GLHClearMode begin
	GLH_COLOR_BITS
	GLH_DEPTH_BITS
	GLH_STENCIL_BITS
end

@enum GLHTextureFiltering begin
	GLH_LINEAR
	GLH_NEAREST
end

@enum GLHTextureWrapping begin
	GLH_REPEAT
	GLH_MIRRORED_REPEAT
	GLH_CLAMP_TO_EDGE
end

function _convert_texture_filtering(m::GLHTextureFiltering)
	if m == GLH_LINEAR
		return GL_LINEAR
	elseif m == GLH_NEAREST
		return GL_NEAREST
	end
end

function _to_gl_format(m::SDL_PixelFormatEnum)
	if m == SDL_PIXELFORMAT_RGBA8888
		return GL_RGBA
	else
		return GL_RGB
	end
end

function _convert_texture_wrapping(m::GLHTextureWrapping)
	if m == GLH_REPEAT
		return GL_REPEAT
	elseif m == GLH_MIRRORED_REPEAT
		return GL_MIRRORED_REPEAT
	elseif m == GLH_CLAMP_TO_EDGE
		return GL_CLAMP_TO_EDGE
	end
end

function _convert_clearmode(m::GLHClearMode)
	if m == GLH_COLOR_BITS
		return GL_COLOR_BUFFER_BIT
	elseif m == GLH_DEPTH_BITS
		return GL_DEPTH_BUFFER_BIT
	elseif m == GLH_STENCIL_BITS
		return GL_STENCIL_BUFFER_BIT
	end
end
