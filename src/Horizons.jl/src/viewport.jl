#######################################################################################################################
####################################################### VIEWPORT ######################################################
#######################################################################################################################

export AddObject, AddChildObject

######################################################### CORE ########################################################

mutable struct HViewport{T,N}
	objects::ObjectTree
	subview::ObjectTree
	screen::Object{T,N}

	# Constructors #

	HViewport{T,N}(screen) where {T <: ObjectData, N} = new{T,N}(ObjectTree(),ObjectTree(),screen)
    HViewport{T,N}() where {T <: ObjectData, N} = new{T,N}(ObjectTree(),ObjectTree())
end

###################################################### FUNCTIONS ######################################################

"""
	CreateViewport(r::AbstractRenderer,args...)

Generic function to create a new viewport.
When Creating your own style of viewport, you should overload this function.
"""
CreateViewport(r::AbstractRenderer,args...) = nothing

"""
	SetViewportPosition(r::SDLRender,x::Int,y::Int)

Set the position of the current viewport.
"""
SetViewportPosition(v::HViewport,x::Int,y::Int) = begin
	v.screen.rect.x = x
	v.screen.rect.y = y
end

"""
	SetViewportSize(r::SDLRender,w::Int,h::Int)

Set the size of the current viewport.
"""
SetViewportSize(v::HViewport,w::Int,h::Int) = begin
	v.screen.rect.w = w
	v.screen.rect.h = h
end

"""
	SwapScreen(r::SDLRender,v::SDLViewport)

Change the screen of a viewport 
"""
function SwapScreen(v::HViewport{T,N},nscreen::Object{T,N}) where {T <: ObjectData, N}
	oscreen = isdefined(v, :screen) ? v.screen : nothing
	v.screen = nscreen

	return oscreen
end

function AddObject(v::HViewport{T}, obj::Object{T,N}) where {T <: ObjectData, N}
	node = Node(obj)
	add_child(v.objects, node)
	obj.id = get_nodeidx(node)
end
function AddChildObject(parent::Object{T,N}, obj::Object{T,N}) where {T <: ObjectData, N}
	node = Node(obj)
	tree = get_tree(parent)
	p = get_node(tree,parent.id)
	add_child(p,node)
	obj.id = get_nodeidx(node)
end

function RenderViewport(r::AbstractRenderer,v::HViewport)
	RenderObject(r, v.screen)
	root = get_children(get_root(v.objects))

	for child in children
		RenderObjects(child[];parent=v.screen)
	end
end

function RenderObjects(r::AbstractRenderer,node::Node{Object2D}, parent=nothing;limit_x=640, limit_y=480)
	obj = node[]
	pos = obj.transform.position
	size = obj.rect.size

	culling_cond_x = (0 <= pos.x + size.x && pos.x <= limit_x)
	culling_cond_y = (0 <= pos.y + size.y && pos.y <= limit_y)

	if culling_cond_x && culling_cond_y
		children = get_children(node)
		for child in children
			RenderObjects(r,child,obj;limit_x=limit_x,limit_y=limit_y)
		end
	end

	RenderObject(r, obj, parent)
end

function DestroyViewport(r::AbstractRenderer, v::HViewport)
	DestroyObject(r,v.screen)
	for obj in v.objects.objects
		DestroyObject(r,obj[])
	end
end