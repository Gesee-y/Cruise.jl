####################### Function to draw with the SDL Renderer ################################

export SetDrawColor, DrawPoint, DrawPoints, DrawLine, DrawLines, DrawRect, FillRect
export DrawRects, FillRects

"""
	SetDrawColor(ren::SDLRender,col)

Change the color of the SDLRender passed in parameters. `col` should be a vector of positive
Integer with at least 3 component (one for the red, the second for the green, the third for 
the blue and the last for transparency.)
"""
@inline function SetDrawColor(ren::SDLRender,@nospecialize(col))
	
	# We check if `col` have an alpha component, if not we assign it 255
	# else we map the alpha value to 0-255
	a = (length(col) < 4) ? 255 : _to_color_value(col[4])

	# Then ve get the other components
	r = _to_color_value(col[1]); g = _to_color_value(col[2]); b = _to_color_value(col[3])

	# We set the color of the drawing and check for error
	if 0 != SDL_SetRenderDrawColor(ren.renderer,r,g,b,a)

		# We get the error
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to set the color of the renderer $ren.",err)
	end
end

"""
	DrawPoint(ren::SDLRender,pos)

Draw a point on the backend `ren` at the given position `pos`. `pos` should be a container of
at least 2 elements.
"""
DrawPoint(ren::SDLRender,pos::HVec2{<:Integer}) = SDL_RenderDrawPoint(ren.renderer,pos.x,pos.y)
DrawPoint(ren::SDLRender,pos::HVec2{<:AbstractFloat}) = SDL_RenderDrawPointF(ren.renderer,pos.x,pos.y)
DrawPoint(ren::SDLRender,@nospecialize(pos)) = DrawPoint(ren,HVec2(pos[1],pos[2]))

"""
	DrawPoints(ren::SDLRender,positions;count=length(positions))

Use this function to draw a set of points on the backend `ren`. `positions` should be 
an array of container with the position of each point.

	DrawPoints(ren::SDLRender,positions...)

Draw all the points at the given positions on the backend `ren`. Each position should be 
a container with at least 2 elements.
"""
function DrawPoints(ren::SDLRender,positions;count=length(positions))
	
	# We pre-allocate an Vector to contain the points to draw
	arr = Vector{SDL_Point}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		pos = positions[i]

		# And create the SDL_Point and assign it in the array
		arr[i] = SDL_Point(pos[1],pos[2])
	end

	# Then we draw the points and check for error
	if 0 != SDL_RenderDrawPoints(ren.renderer, arr, count)

		# We get the error
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to draw points.",err)
	end
end
DrawPoints(ren::SDLRender,positions...) = DrawPoints(ren,positions)

"""
	DrawLine(ren::SDLRender,s,e)

Draw a line on the backend `ren`. `s` is where the line begin and `e` is where the line
end. Both should be container of Integer with at least 2 elements.
"""
function DrawLine(ren::SDLRender,s::HVec2{<:Integer},e::HVec2{<:Integer})
	SDL_RenderDrawLine(ren.renderer,s.x,s.y,e.x,e.y)
end
function DrawLine(ren::SDLRender,s::HVec2{<:AbstractFloat},e::HVec2{<:AbstractFloat})
	SDL_RenderDrawLineF(ren.renderer,s.x,s.y,e.x,e.y)
end
DrawLine(ren::SDLRender,s,e) = DrawLine(ren,HVec2(s[1],s[2]),HVec2(e[1],e[2]))

"""
	DrawLines(ren::SDLRender,points)

Draw lines by connecting the points passed in parameters. `points` should be 
an array of container with the position of each point.

	DrawLines(ren::SDLRender,points...)

Draw lines by connecting the points passed in parameters. Each point should be 
a container with at least 2 elements.
"""
function DrawLines(ren::SDLRender,points;count=length(points))
	
	# We pre-allocate a Vector to contain the points defining the lines
	arr = Vector{SDL_Point}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		pos = points[i]

		# And create the SDL_Point and put it in the array
		arr[i] = SDL_Point(pos[1],pos[2])
	end

	# Then we draw the lines
	SDL_RenderDrawLines(ren.renderer,arr,count)
end
DrawLines(ren::SDLRender,points...) = DrawLines(ren,points)

"""
	DrawRect(ren::SDLRender,data)

Draw a rectangle of the renderer `ren` with the given `data`. `data` should be an container
of 4 element, the 2 first are the position of the rectangle and the remaining data are 
respectively the width and the heigth of the rect
"""
function DrawRect(ren::SDLRender,@nospecialize(data))
	rect = SDL_Rect(data[1],data[2],data[3],data[4])

	SDL_RenderDrawRect(ren.renderer,Ref(rect))
end

"""
	FillRect(ren::SDLRender,data)

Draw a filled rectangle of the renderer `ren` with the given `data`. `data` should be an container
of 4 element, the 2 first are the position of the rectangle and the remaining data are 
respectively the width and the heigth of the rect
"""
function FillRect(ren::SDLRender,data)
	rect = SDL_Rect(data[1],data[2],data[3],data[4])

	SDL_RenderFillRect(ren.renderer,Ref(rect))
end

"""
	DrawRects(ren::SDLRender,datas;count=length(data))

Draw all the rectangle passed in `datas`.`datas` should be a container of container with at
least 4 elements.
"""
function DrawRects(ren::SDLRender,datas;count=length(datas))
	
	# We pre-allocate the Vector of SDL_Rect to contain the rects to draw
	arr = Vector{SDL_Rect}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		d = datas[i]

		# We create the rect
		rect = SDL_Rect(d[1],d[2],d[3],d[4])
		
		# and put it in the array
		arr[i] = rect
	end

	# We then draw the rects
	SDL_RenderDrawRects(ren.renderer,arr,count)
end

"""
	FillRects(ren::SDLRender,datas;count=length(data))

Draw all the filled rectangle passed in `datas`.`datas` should be a container of container with at
least 4 elements.
"""
function FillRects(ren::SDLRender,datas;count=length(datas))

	# We pre-allocate the Vector of SDL_Rect to contain the rects to draw
	arr = Vector{SDL_Rect}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		d = datas[i]

		# We create the rect
		rect = SDL_Rect(d[1],d[2],d[3],d[4])

		# and put it in the array
		arr[i] = rect
	end

	# We then draw the filled rects
	SDL_RenderFillRects(ren.renderer,arr,count)
end