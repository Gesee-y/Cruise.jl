#######################################################################################################################
################################################### SDL OBJECTS #######################################################
#######################################################################################################################

export get_texture, SDLObjectData

#######################################################################################################################

"""
	struct SDLTextureData <: TextureData
		obj :: Ptr{SDL_Texture}
		access :: SDL_TextureAccess
		format :: Ptr{SDL_PixelFormat}

This struct is used to created BlankTexture.
"""
struct SDLTextureData <: TextureData
	obj :: Ptr{SDL_Texture}
	access :: TextureAccess
	format :: SDL_PixelFormatEnum
end

"""
	SDLTexture = Union{Texture{BlankData},Texture{ImageData}}

A Type that is a supertype of all the SDL Texture.
"""
const SDLTexture = Texture{SDLTextureData}


struct SDLObjectData <: ObjectData
	texture::SDLTexture
end

const SDLObject = Object2D{SDLObjectData}

#######################################################################################################################

Object(pos::Vec2f, size::Vec2f, texture::SDLTexture) = begin
    obj = SDLObject(pos, size)
    obj.data = SDLObjectData(texture)
    return obj
end
DestroyObject(obj::SDLObject) = SDL_DestroyTexture(_get_texture(obj.data.texture))

get_texture(obj::SDLObject) = obj.data.texture