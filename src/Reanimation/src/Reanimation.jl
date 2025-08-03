###########################################################################################################################################
############################################################## ANIMATION SYSTEM ###########################################################
###########################################################################################################################################

"""
    module Reanimation

A complete animation system.
Provide keyframing, curves, animations graph and per-pixel animations
"""
module Reanimation

include("keyframe.jl")
include("transition.jl")
include("binding.jl")
include("frame.jl")
include("animation.jl")
include("layer.jl")
include("player.jl")
include("track.jl")

end # module