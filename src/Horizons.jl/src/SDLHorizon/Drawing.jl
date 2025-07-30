####################### Function to draw with the SDL Renderer ################################

export SetDrawColor, DrawPoint, DrawPoints, DrawLine, DrawLines, DrawRect, DrawRectF, FillRect
export DrawRects, FillRects, FillRectsF, DrawRectsF, FillRectF
export DrawCircle, FillCircle, DrawPolygon, FillPolygon, DrawEllipse, FillEllipse, DrawArc, DrawThickLine

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
	if 0 != SDL_SetRenderDrawColor(ren.data.renderer,r,g,b,a)

		# We get the error
		err = _get_SDL_Error()

		# And throw it as a warning
		HORIZON_WARNING.emit = ("Failed to set the color of the renderer $ren.",err)
	end
end
@inline function SetDrawColor(ren::SDLRender,col::Color8)
	
	# We set the color of the drawing and check for error
	if 0 != SDL_SetRenderDrawColor(ren.data.renderer,col.r,col.g,col.b,col.a)

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
DrawPoint(ren::SDLRender,pos::Vector2D{<:Integer}) = SDL_RenderDrawPoint(ren.data.renderer,pos.x,pos.y)
DrawPoint(ren::SDLRender,pos::Vector2D{<:AbstractFloat}) = SDL_RenderDrawPointF(ren.data.renderer,pos.x,pos.y)
DrawPoint(ren::SDLRender,@nospecialize(pos)) = DrawPoint(ren,Vector2D(pos[1],pos[2]))

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
	@inbounds for i in Base.OneTo(count)
		pos = positions[i]

		# And create the SDL_Point and assign it in the array
		arr[i] = SDL_Point(pos[1],pos[2])
	end

	# Then we draw the points and check for error
	if 0 != SDL_RenderDrawPoints(ren.data.renderer, arr, count)

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
function DrawLine(ren::SDLRender,s::Vector2D{<:Integer},e::Vector2D{<:Integer})
	SDL_RenderDrawLine(ren.data.renderer,s.x,s.y,e.x,e.y)
end
function DrawLine(ren::SDLRender,s::Vector2D{<:AbstractFloat},e::Vector2D{<:AbstractFloat})
	SDL_RenderDrawLineF(ren.data.renderer,s.x,s.y,e.x,e.y)
end
DrawLine(ren::SDLRender,s,e) = DrawLine(ren,Vec2f(s[1],s[2]),Vec2f(e[1],e[2]))

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
	SDL_RenderDrawLines(ren.data.renderer,arr,count)
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

	SDL_RenderDrawRect(ren.data.renderer,Ref(rect))
end
function DrawRectF(ren::SDLRender,@nospecialize(data))
	rect = SDL_FRect(data[1],data[2],data[3],data[4])

	SDL_RenderDrawRectF(ren.data.renderer,Ref(rect))
end
function DrawRect(ren::SDLRender, r::Rect2D{<:Integer})
	rect = SDL_Rect(data[1],data[2],data[3],data[4])

	SDL_RenderDrawRect(ren.data.renderer,Ref(rect))
end
function DrawRect(ren::SDLRender, r::Rect2D{<:AbstractFloat})
	rect = SDL_FRect(data[1],data[2],data[3],data[4])

	SDL_RenderDrawRectF(ren.data.renderer,Ref(rect))
end

"""
	FillRect(ren::SDLRender,data)

Draw a filled rectangle of the renderer `ren` with the given `data`. `data` should be an container
of 4 element, the 2 first are the position of the rectangle and the remaining data are 
respectively the width and the heigth of the rect
"""
function FillRect(ren::SDLRender,data)
	rect = SDL_Rect(data[1],data[2],data[3],data[4])

	SDL_RenderFillRect(ren.data.renderer,Ref(rect))
end
function FillRectF(ren::SDLRender,data)
	rect = SDL_FRect(data[1],data[2],data[3],data[4])

	SDL_RenderFillRectF(ren.data.renderer,Ref(rect))
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
	SDL_RenderDrawRects(ren.data.renderer,arr,count)
end
function DrawRectsF(ren::SDLRender,datas;count=length(datas))
	
	# We pre-allocate the Vector of SDL_Rect to contain the rects to draw
	arr = Vector{SDL_FRect}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		d = datas[i]

		# We create the rect
		rect = SDL_FRect(d[1],d[2],d[3],d[4])
		
		# and put it in the array
		arr[i] = rect
	end

	# We then draw the rects
	SDL_RenderDrawRectsF(ren.data.renderer,arr,count)
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
	SDL_RenderFillRects(ren.data.renderer,arr,count)
end
function FillRectsF(ren::SDLRender,datas;count=length(datas))

	# We pre-allocate the Vector of SDL_Rect to contain the rects to draw
	arr = Vector{SDL_FRect}(undef,count)

	# We iterate from 1 to count
	for i in Base.OneTo(count)
		d = datas[i]

		# We create the rect
		rect = SDL_FRect(d[1],d[2],d[3],d[4])

		# and put it in the array
		arr[i] = rect
	end

	# We then draw the filled rects
	SDL_RenderFillRectsF(ren.data.renderer,arr,count)
end

"""
    DrawCircle(ren::SDLRender, center, radius; filled=false)

Draw a circle on the renderer `ren` with center at `center` (Vector2D) and radius `radius`.
If `filled` is true, the circle is filled; otherwise, only the outline is drawn.
"""
DrawCircle(ren::SDLRender, center, radius) = DrawCircle(ren, Vector2D(center[1], center[2]), radius)
function DrawCircle(ren::SDLRender, center::Vector2D{T}, radius::T; filled::Bool=false) where T<:Integer
    # Algorithme de Bresenham pour les cercles
    x0, y0 = center.x, center.y
    x = radius
    y = 0
    err = 0

    while x >= y
        if filled
            # Dessiner des lignes horizontales pour remplir
            DrawLine2D(ren, Vec2f(x0 - x, y0 + y), Vec2f(x0 + x, y0 + y))
            DrawLine2D(ren, Vec2f(x0 - x, y0 - y), Vec2f(x0 + x, y0 - y))
            DrawLine2D(ren, Vec2f(x0 - y, y0 + x), Vec2f(x0 + y, y0 + x))
            DrawLine2D(ren, Vec2f(x0 - y, y0 - x), Vec2f(x0 + y, y0 - x))
        else
            # Dessiner les points du contour
            DrawPoint2D(ren, Vec2f(x0 + x, y0 + y))
            DrawPoint2D(ren, Vec2f(x0 - x, y0 + y))
            DrawPoint2D(ren, Vec2f(x0 + x, y0 - y))
            DrawPoint2D(ren, Vec2f(x0 - x, y0 - y))
            DrawPoint2D(ren, Vec2f(x0 + y, y0 + x))
            DrawPoint2D(ren, Vec2f(x0 - y, y0 + x))
            DrawPoint2D(ren, Vec2f(x0 + y, y0 - x))
            DrawPoint2D(ren, Vec2f(x0 - y, y0 - x))
        end

        if err <= 0
            y += 1
            err += 2*y + 1
        end
        if err > 0
            x -= 1
            err -= 2*x + 1
        end
    end
end

function DrawCircle(ren::SDLRender, center::Vector2D{T}, radius::T; filled::Bool=false) where T<:AbstractFloat
    # Version flottante pour SDL_RenderDrawPointF
    x0, y0 = center.x, center.y
    x = radius
    y = 0.0
    err = 0.0

    while x >= y
        if filled
            DrawLine(ren, Vec2f(x0 - x, y0 + y), Vec2f(x0 + x, y0 + y))
            DrawLine(ren, Vec2f(x0 - x, y0 - y), Vec2f(x0 + x, y0 - y))
            DrawLine(ren, Vec2f(x0 - y, y0 + x), Vec2f(x0 + y, y0 + x))
            DrawLine(ren, Vec2f(x0 - y, y0 - x), Vec2f(x0 + y, y0 - x))
        else
            DrawPoint(ren, Vec2f(x0 + x, y0 + y))
            DrawPoint(ren, Vec2f(x0 - x, y0 + y))
            DrawPoint(ren, Vec2f(x0 + x, y0 - y))
            DrawPoint(ren, Vec2f(x0 - x, y0 - y))
            DrawPoint(ren, Vec2f(x0 + y, y0 + x))
            DrawPoint(ren, Vec2f(x0 - y, y0 + x))
            DrawPoint(ren, Vec2f(x0 + y, y0 - x))
            DrawPoint(ren, Vec2f(x0 - y, y0 - x))
        end

        if err <= 0
            y += 1.0
            err += 2*y + 1
        end
        if err > 0
            x -= 1.0
            err -= 2*x + 1
        end
    end
end

"""
    FillCircle(ren::SDLRender, center, radius)

Convenience function to draw a filled circle.
"""
FillCircle(ren::SDLRender, center::Vector2D, radius) = DrawCircle(ren, center, radius; filled=true)
FillCircle(ren::SDLRender, center, radius) = DrawCircle(ren, Vec2f(center[1], center[2]), radius; filled=true)

"""
    DrawPolygon(ren::SDLRender, center, radius, sides; filled=false)

Draw a regular polygon with `sides` sides, centered at `center` (Vector2D) with radius `radius`.
If `filled` is true, the polygon is filled using a scanline approach.
"""
function DrawPolygon(ren::SDLRender, center::Vector2D{T}, radius::T, sides::Int; filled::Bool=false) where T<:Union{Integer,AbstractFloat}
    @assert sides >= 3 "Polygon must have at least 3 sides"
    points = Vector{Vector2D{T}}(undef, sides)
    for i in 1:sides
        angle = 2 * pi * (i - 1) / sides
        points[i] = Vector2D{T}(center.x + radius * cos(angle), center.y + radius * sin(angle))
    end

    if filled
        # Triangulation simple pour le remplissage (approche fan triangulation)
        for i in 2:(sides-1)
            DrawLine(ren, points[1], points[i])
            DrawLine(ren, points[i], points[i+1])
            DrawLine(ren, points[1], points[i+1])
        end
        DrawLine(ren, points[1], points[sides])
    else
        # Dessiner le contour
        DrawLines(ren, points, count=sides)
        # Fermer le polygone
        DrawLine(ren, points[sides], points[1])
    end
end

"""
    FillPolygon(ren::SDLRender, center, radius, sides)

Convenience function to draw a filled regular polygon.
"""
FillPolygon(ren::SDLRender, center::Vector2D, radius, sides) = DrawPolygon(ren, center, radius, sides; filled=true)

"""
    DrawEllipse(ren::SDLRender, center, rx, ry; filled=false)

Draw an ellipse centered at `center` (Vector2D) with horizontal radius `rx` and vertical radius `ry`.
If `filled` is true, the ellipse is filled.
"""
function DrawEllipse(ren::SDLRender, center::Vector2D{T}, rx::T, ry::T; filled::Bool=false) where T<:Union{Integer,AbstractFloat}
    x0, y0 = center.x, center.y
    steps = max(50, round(Int, 2 * pi * max(rx, ry))) # Nombre de points pour l'approximation
    points = Vector{Vector2D{T}}(undef, steps)
    for i in 1:steps
        theta = 2 * pi * (i - 1) / steps
        points[i] = Vector2D{T}(x0 + rx * cos(theta), y0 + ry * sin(theta))
    end

    if filled
        # Triangulation simple pour le remplissage
        for i in 2:(steps-1)
            DrawLine(ren, points[1], points[i])
            DrawLine(ren, points[i], points[i+1])
            DrawLine(ren, points[1], points[i+1])
        end
        DrawLine(ren, points[1], points[steps])
    else
        # Dessiner le contour
        DrawLines(ren, points, count=steps)
        DrawLine(ren, points[steps], points[1])
    end
end

"""
    FillEllipse(ren::SDLRender, center, rx, ry)

Convenience function to draw a filled ellipse.
"""
FillEllipse(ren::SDLRender, center::Vector2D, rx, ry) = DrawEllipse(ren, center, rx, ry; filled=true)

"""
    DrawArc(ren::SDLRender, center, radius, start_angle, end_angle)

Draw an arc of a circle centered at `center` (Vector2D) with radius `radius`, from `start_angle` to `end_angle` (in radians).
"""
function DrawArc(ren::SDLRender, center::Vector2D{T}, radius::T, start_angle::Real, end_angle::Real) where T<:Union{Integer,AbstractFloat}
    steps = max(20, round(Int, abs(end_angle - start_angle) * radius)) # Ajuster la résolution
    points = Vector{Vector2D{T}}(undef, steps)
    for i in 1:steps
        theta = start_angle + (end_angle - start_angle) * (i - 1) / (steps - 1)
        points[i] = Vector2D{T}(center.x + radius * cos(theta), center.y + radius * sin(theta))
    end
    DrawLines(ren, points, count=steps)
end

"""
    DrawThickLine(ren::SDLRender, start, end, thickness)

Draw a line from `start` to `end` (Vector2D) with specified `thickness`.
"""
function DrawThickLine(ren::SDLRender, start::Vector2D{T}, stop::Vector2D{T}, thickness::T) where T<:Union{Integer,AbstractFloat}
    # Calculer la direction de la ligne
    dir = stop - start
    len = norm(dir)
    if len == 0
        return
    end
    dir = dir / len
    # Vecteur perpendiculaire pour l'épaisseur
    perp = Vector2D{T}(-dir.y, dir.x)
    half_thickness = thickness / 2

    # Définir les quatre coins du rectangle représentant la ligne épaisse
    p1 = start + perp * half_thickness
    p2 = start - perp * half_thickness
    p3 = stop + perp * half_thickness
    p4 = stop - perp * half_thickness

    # Dessiner un polygone rempli
    DrawPolygon(ren, Vector2D{T}(0, 0), 0, 4; filled=true, points=[p1, p2, p4, p3])
end