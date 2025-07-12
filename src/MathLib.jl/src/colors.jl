## To manipulate easily Colors ##

# RGB Colors

const RGB    = Vec3{UInt8}
const iRGB   = iVec3{UInt8}
const fRGB   = Vec3{Float32}
const ifRGB  = iVec3{Float32}

# RGBA Colors
const RGBA   = Quat{UInt8}
const iRGBA  = iQuat{UInt8}
const fRGBA  = Quat{Float32}
const ifRGBA = iQuat{Float32}

## Color Constants ##

const RED    = iRGBA(255,0,0,255)
const GREEN  = iRGBA(0,255,0,255)
const BLUE   = iRGBA(0,0,255,255)

const WHITE  = iRGBA(255)
const BLACK  = iRGBA(0)
const GRAY   = iRGBA(127)