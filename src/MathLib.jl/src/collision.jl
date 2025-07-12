## ++++++++++++++++++++++++++++++ Collision detection (TODO: Migrate this to the physics engine) +++++++++++++++++++++++++++ ##

function point_in_rect(p::Vector2D,r::Rect2D)
	condition1 = (r.x <= p.x <= (r.x+r.w))
	condition2 = (r.y <= p.y <= (r.y+r.h))

	return (condition1 && condition2)
end

function overlapping(r1::Rect2D, r2::Rect2D)
	return _overlap(r1.x, r2.x, r1.x+r1.w, r2.x+r2.w) && _overlap(r1.y, r2.y, r1.y+r1.h, r2.y+r2.h)
end

function overlapping(c::Circle, r::Rect2D)
	dv = c.center - get_center(r)
	ext = r.dimensions / 2
	closest_point = clamp(dv, -ext, ext)

	new_dv = closest_point - c.center

	return norm(new_dv) <= c.radius
end
overlapping(c1::Circle, c2::Circle) = norm(c1.center - c2.center) <= (c1.radius + c2.radius)


function intersection(r1::Rect2D,r2::Rect2D)
	tl = _is_the_leftmost(r1,r2) ? iVec2(r2.x,r2.y) : iVec2(r1.x,r1.y)
	br = _is_the_leftmost(r1,r2) ? iVec2(r1.x+r1.w,r1.y+r1.h) : iVec2(r2.x+r2.w,r2.y+r2.h)

	if (tl.x > br.x || tl.y > br.y) return nothing
	elseif (tl.x == br.x || tl.y == br.y)
		if (tl.x == br.x && tl.y == br.y)
			return tl
		end

		return Ray{Int,2}(tl,br)
	else
		return Rect2D(tl,br)
	end
end

_is_the_leftmost(r1::Rect2D,r2::Rect2D) = r1.x < r2.x
function _overlap(minA::Number, minB::Number, maxA::Number, maxB::Number)
	return (minA <= maxB && minB <= maxA);
end