#######################################################################################################################
######################################################### OBJECTS #####################################################
#######################################################################################################################

export ObjectData
export Object, Object2D, Object3D
export RenderObject, DestroyObject

########################################################## CORE #######################################################

"""
    abstract type ObjectData

Supertype for all object data specifif to a backend.
When creating your own backend, you should create one of these object data to contain informations specific to your
backend.
"""
abstract type ObjectData end

"""
    struct Object{N}
        transform::Transform{N}
        rect::Rect{N}

A `N` dimensional object. 
- `Transform` is the relevant infomation of the object.
- `rect`: The part of the object to draw.    
"""
mutable struct Object{T,N}
    id::Int
    parentid::Int
    rect::Rect{Float32,N}
    transform::Transform{N}
    visible::Bool
    data::T

    ## Constructor
    
    Object{T,2}(pos::Vec2f,size::Vec2f) where T <: ObjectData = new{T,2}(0,0,Rect2Df(pos,size), Transform{2}(pos),true)
    Object{T,3}(pos::Vec3f,size::Vec3f) where T <: ObjectData = new{T,3}(0,0,Rect3Df(pos,size), Transform{3}(pos),true)
    Object{T,N}(pos::SVector{Float32, N},size::SVector{<:Number, N}) where {T <: ObjectData,N} = new{T,N}(0,0,
        Rect{Float32,N}(pos,size), Transform{N}(), true)
end

const Object2D{T} = Object{T,2}
const Object3D{T} = Object{T,3}

#################################################### FUNCTIONS ########################################################

"""
    RenderObject(b::AbstractRenderer, obj::Object, parent=nothing)

Generic function to draw an object.
Should be overloaded for custom rendere.
"""
RenderObject(b::AbstractRenderer, obj::Object, parent=nothing) = nothing

"""
    DestroyObject(r::AbstractRenderer,obj::Object)

Generic function to delete an object
Should be oveloaded when you will create your renderer
"""
DestroyObject(r::AbstractRenderer,obj::Object) = nothing