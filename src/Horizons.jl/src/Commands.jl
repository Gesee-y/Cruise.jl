#######################################################################################################################
################################################# RENDERING COMMANDS ##################################################
#######################################################################################################################

export DrawPoint2D, DrawLine2D, DrawRect2D, DrawCircle2D

@commandaction ClearScreenCmd begin
	color::iRGBA
end

@commandaction DrawPoint2DCmd begin
	color::iRGBA
	pos::Vec2f
end

@commandaction DrawLine2DCmd begin
	color::iRGBA
	start::Vec2f
	stop::Vec2f
end

@commandaction DrawRect2DCmd begin
	color::iRGBA
	rect::Rect2Df
	filled::Bool
end

@commandaction DrawCircle2DCmd begin
	color::iRGBA
	center::Vec2f
	radius::Float32
	filled::Bool
end


function ClearScreen(ren::HRenderer, target, col, priority=99)
	cb = get_commandbuffer(ren)
    targetid = get_id(targetid)
	action = ClearScreenCmd(color)
	command = RenderCommand(targetid, priority, 0, action)

	q = CommandQuery(;target=targetid)
	iter = command_iterator(cb, q)
	foreach(empty!, iter)

	add_command!(cb,targetid,priority,0,command)
end

function DrawPoint2D(ren::HRenderer, target::AbstractResource, color, pos,priority=0;pass=:render)
	cb = get_commandbuffer(ren)
	action = DrawPoint2DCmd(color, pos)

	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end
DrawPoint2D(ren::HRenderer, color, pos,priority=0; pass=:render) = DrawPoint2D(ren, get_texture(ren.viewport.screen),
	color, pos, priority;pass=pass)

function DrawLine2D(ren::HRenderer, target, color, s, e,priority=0; pass=:render)
	cb = get_commandbuffer(ren)
	action = DrawLine2DCmd(color, s,e)
	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end
function DrawLine2D(ren::HRenderer, color, s, e,priority=0; pass=:render)
	cb = get_commandbuffer(ren)
	target = get_texture(ren.viewport.screen)
	action = DrawLine2DCmd(color, s,e)
	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end

function DrawRect2D(ren::HRenderer, target, color, rect, filled=true,priority=0; pass=:render)
	cb = get_commandbuffer(ren)
	action = DrawRect2DCmd(color, rect, filled)
	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end
function DrawRect2D(ren::HRenderer, color, rect, filled=true,priority=0; pass=:render)
	cb = get_commandbuffer(ren)
	target = get_texture(ren.viewport.screen)
	action = DrawRect2DCmd(color, rect, filled)
	add_command!(cb,get_id(target),priority,0, action;pass=pass)
end

DrawCircle2D(ren::HRenderer, color,center,radius;filled=false) = DrawCircle2D(ren, 
	get_texture(ren.viewport.screen), color, center, radius; filled=filled, pass=:render)
function DrawCircle2D(ren::HRenderer,target,color, center, radius,priority=0; filled::Bool=false, pass=:render)
	cb = get_commandbuffer(ren)
	action = DrawCircle2DCmd(color, center, radius, filled)

	add_command!(cb,get_id(target),priority,0, action;pass=pass) 
end