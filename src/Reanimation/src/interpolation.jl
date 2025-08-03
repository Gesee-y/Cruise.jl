######################################################################################################################
#################################################### INTERPOLATIONS ##################################################
######################################################################################################################

######################################################### CORE #######################################################


@inline lerp(a,b,t) = a + (b-a)*t

@inline function cubic(a,b,ta,tb,t)
    t2 = t*t; t3 = t2*t
    h1 = 2t3-3t2+1
    h2 = -2t3+3t2
    h3 = t3-2t2+t
    h4 = t3-t2
    h1*a + h2*b + h3*ta + h4*tb
end

@inline function bezier(a,p1,p2,b,t)
    mt = 1-t
    mt^3*a + 3mt^2*t*p1 + 3mt*t^2*p2 + t^3*b
end

# vraie Catmull-Rom 4-points
@inline function catmull_rom(p0,p1,p2,p3,t, tension=0.5)
    t2 = t*t; t3 = t2*t
    f1 = -tension*t3 + 2tension*t2 - tension*t
    f2 = (2-tension)*t3 + (tension-3)*t2 + 1
    f3 = (tension-2)*t3 + (3-2tension)*t2 + tension*t
    f4 = tension*t3 - tension*t2
    f1*p0 + f2*p1 + f3*p2 + f4*p3
end
