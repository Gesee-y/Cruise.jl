#######################################################################################################################
######################################################## SDL COMMANDS #################################################
#######################################################################################################################

export ApplySDLShader

const MAX_TEXTUREID = 2^16

@commandaction ApplySDLShaderCmd begin
	shader::SDLShader
end

function ApplySDLShader(ren::SDLRender, target, shader::SDLShader, priority=0; pass=:postprocess)
	cb = get_commandbuffer(ren)
	action = ApplySDLShaderCmd(shader)
	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end

function execute_command(ren::SDLRender, targetid, caller, commands::Vector{ApplySDLShaderCmd})
	target = get_resourcefromid(ren, targetid)
    for cmd in commands
        ProcessPixels(cmd.shader,target;ren=ren)
    end
end

function execute_command(ren::SDLRender, targetid, caller, commands::Vector{DrawPoint2DCmd})
	target = get_resourcefromid(ren, targetid)
    SetRenderTarget(ren, target)

    results = Dict{iRGBA, Vector{SDL_FPoint}}()

    for c in commands
    	col = c.color
    	if haskey(results, col)
			push!(results[col],SDL_FPoint(c.pos...))
		else
			results[col] = SDL_FPoint[SDL_FPoint(c.pos...)]
		end
	end

	for color in keys(results)
		points = results[color]
		SetDrawColor(ren,color)
		SDL_RenderDrawPointsF(ren.data.renderer, points, length(points))
	end
end
function execute_command(ren::SDLRender, targetid, caller, commands::Vector{DrawLine2DCmd})
	target = get_resourcefromid(ren, targetid)
    SetRenderTarget(ren, target)
    prev = nothing
    for c in commands
    	col = c.color
    	prev != col && SetDrawColor(ren,col)
    	SDL_RenderDrawLineF(ren.data.renderer, c.start..., c.stop...)
    	prev = col
	end
end
function execute_command(ren::SDLRender, targetid, caller, commands::Vector{DrawRect2DCmd})
	target = get_resourcefromid(ren, targetid)
	SetRenderTarget(ren, target)

    results = Dict{iRGBA, Vector{SDL_FRect}}()
    filled = Dict{iRGBA, Vector{SDL_FRect}}()
    for c in commands
    	col = c.color
    	r = c.rect
    	dict = c.filled ? filled : results
    	if haskey(dict, col)
			push!(dict[col],SDL_FRect(r.origin...,r.dimensions...))
		else
			dict[col] = SDL_FRect[SDL_FRect(r.origin...,r.dimensions...)]
		end
	end

	for color in keys(results)
		rects = results[color]
		SetDrawColor(ren,color)
		SDL_RenderDrawRectsF(ren.data.renderer, rects, length(rects))
	end
	for color in keys(filled)
		rects = filled[color]
		SetDrawColor(ren,color)
		SDL_RenderFillRectsF(ren.data.renderer, rects, length(rects))
	end
end
function execute_command(ren::SDLRender, targetid, caller, commands::Vector{DrawCircle2DCmd})
	target = get_resourcefromid(ren, targetid)
	SetRenderTarget(ren, target)

    results = Dict{iRGBA, Vector{DrawCircle2DCmd}}()
    for c in commands
    	col = c.color
    	if haskey(results, col)
			push!(results[col],c)
		else
			results[col] = DrawCircle2DCmd[c]
		end
	end

	for color in keys(results)
		cmd = results[color]
		SetDrawColor(ren,color)
		for c in cmd
		    draw_a_circle(ren, c.center, c.radius,c.filled)
		end
	end
end

function draw_a_circle(ren::SDLRender, center, radius,filled)
	# Algorithme de Bresenham pour les cercles
    x0, y0 = center.x, center.y
    x = radius
    y = 0
    err = 0
    
    while x >= y
        if filled
            # Dessiner des lignes horizontales pour remplir
            SDL_RenderDrawLineF(ren.data.renderer, x0 - x, y0 + y, x0 + x, y0 + y)
            SDL_RenderDrawLineF(ren.data.renderer, x0 - x, y0 - y, x0 + x, y0 - y)
            SDL_RenderDrawLineF(ren.data.renderer, x0 - y, y0 + x, x0 + y, y0 + x)
            SDL_RenderDrawLineF(ren.data.renderer, x0 - y, y0 - x, x0 + y, y0 - x)
        else
            # Dessiner les points du contour
            SDL_RenderDrawPointsF(ren.data.renderer,
            	SDL_FPoint[SDL_FPoint(x0 + x, y0 + y),SDL_FPoint(x0 - x, y0 + y),SDL_FPoint(x0 + x, y0 - y),
            	    SDL_FPoint(x0 - x, y0 - y),SDL_FPoint(x0 + y, y0 + x),SDL_FPoint(x0 - y, y0 + x),
            	    SDL_FPoint(x0 + y, y0 - x),SDL_FPoint(x0 - y, y0 - x)]
            )
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