############################## Texture management for Horizon ################################

export HORIZON_TEXTURE_CREATED, HORIZON_TEXTURE_DESTROYED
export TextureData, TextureAccess, TEXTURE_STATIC, TEXTURE_STREAMING, TEXTURE_TARGET
export Texture, HRect, Color8, Color
export CreateTexture, DestroyTexture

@Notifyer HORIZON_TEXTURE_CREATED(ren,tex)
@Notifyer HORIZON_TEXTURE_DESTROYED(tex)

@enum TextureAccess begin
	TEXTURE_STATIC
	TEXTURE_STREAMING
	TEXTURE_TARGET
end

"""
	abstract type TextureData

This abstract type should be use to create struct with the purpose to add extra data to a
texture and help creating aliases.
"""
abstract type TextureData end

"""
	mutable struct Color8
		r :: Int
		g :: Int
		b :: Int
		a :: Int

A simple struct to represent a color
"""
struct Color8
	r :: Int
	g :: Int
	b :: Int
	a :: Int

	# Constructors #

	Color8(r,g,b,a) = new(floor(r),floor(g),floor(b),floor(a))
	Color8(col::Tuple) = new(col[1],col[2],col[3],col[4])
	Color8(arr::Vector) = new(arr[1], arr[2], arr[3], arr[4])
end

struct Color
	r :: Float32
	g :: Float32
	b :: Float32
	a :: Float32

	# Constructors #

	Color(r,g,b,a) = new(r,g,b,a)
	Color(col::Tuple) = new(col[1],col[2],col[3],col[4])
	Color(arr::Vector) = new(arr[1], arr[2], arr[3], arr[4])
end

Base.length(::Color8) = 4
Base.length(::Color) = 4
Base.getindex(c::Color8,i::Int) = getfield(c, fieldnames(Color8)[i])
Base.getindex(c::Color,i::Int) = getfield(c, fieldnames(Color)[i])

"""
	mutable struct StaticTextureInfo
		rendered :: Bool
		static :: Bool

Structure to keep informations for static texture.
"""
mutable struct StaticTextureInfo
	rendered :: Bool
	static :: Bool
	pixels :: Vector{UInt32}
	getted :: Bool

	# Constructors #

	StaticTextureInfo() = new(false,false,UInt32[],false)
	StaticTextureInfo(static) = new(static,false,UInt32[],false)
	StaticTextureInfo(static,w,h) = new(static,false,Vector{UInt32}(undef,w*h),false)
end

"""
	struct Texture{T <: TextureData}
		name :: String
		id :: Tuple
		rect :: HRect
		data :: T

This struct purpose is to contain texture's data. When creating your own type of texture
all you have to do is just defining his `TextureData` and add it in the `data` field.
"""
mutable struct Texture{T <: TextureData} <: AbstractResource
	id :: Int
	rect :: Rect2D{Float32}
	data :: T
	renderable :: Bool
	static :: StaticTextureInfo

	# Constructors #

	Texture{T}(w,h,data,renderable=true;x=0,y=0,static=false) where T <: TextureData = new{T}(0,Rect2Df(Vec2f(x,y),Vec2f(w,h)),data,renderable,StaticTextureInfo(static,w,h))
    Texture(w,h,data::T,renderable=true;x=0,y=0,static=false) where T <: TextureData = new{T}(0,Rect2Df(Vec2f(x,y),Vec2f(w,h)),data,renderable,StaticTextureInfo(static,w,h))

end

"""
	CreateTexture(ren::AbstractRenderer,w,h)

A function used to create a texture.
When creating your own style of renderer, you should create a dispatch of this function
and emit the notification `HORIZON_TEXTURE_CREATED`.
"""
function CreateTexture(ren::AbstractRenderer,w,h) end

"""
	ConvertAccess(::Type{AbstractRenderer},a::TextureAccess)

This function serve to make a correspondance between the horizon texture access and the 
texture access of your backend.
"""
ConvertAccess(::Type{AbstractRenderer},a::TextureAccess) = nothing

"""
	DestroyTexture(tex::Texture)

This function destroy the texture `tex`.
When creating your own style of renderer, you should create a dispatch of this function
and emit the notification `HORIZON_TEXTURE_DESTROYED`.
"""
function DestroyTexture(tex::Texture) end

get_name(::Texture) = :texture
get_id(t::Texture) = getfield(t,:id)