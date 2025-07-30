#####################################################################################################################
######################################################## SHADERS ####################################################
#####################################################################################################################

export BrightnessContrastShader, InvertColorsShader, SepiaShader, GaussianBlurShader, EdgeDetectionShader
export VignetteShader, RippleShader, ChromaKeyShader

"""
    mutable struct BrightnessShader <: SDLShader
        brightness::Float32
        contrast::Float32

Adjust brightness and contrast of the pixel.
- brightness > 1 increases brightness, < 1 decreases it.
- contrast > 1 increases contrast, < 1 decreases it.
"""
mutable struct BrightnessShader <: SDLShader
    brightness::Float32
    contrast::Float32
end

"""
    struct InvertColorsShader <: SDLShader

Invert the colors of the pixel.
"""
struct InvertColorsShader <: SDLShader end

"""
    struct SepiaShader <: SDLShader

Apply a sepia tone to the pixel.
"""
struct SepiaShader <: SDLShader end

"""
    mutable struct GaussianBlurShader <: SDLShader
        radius::Float32
        sigma::Float32
        data::ShaderPixelData

Apply a Gaussian blur to the pixel.
"""
mutable struct GaussianBlurShader <: SDLShader
    radius::Float32
    sigma::Float32
    data::ShaderPixelData
end
need_pixeldata(shader::GaussianBlurShader) = :data

"""
    mutable struct EdgeDetectionShader <: SDLShader
        data::ShaderPixelData

Apply edge detection using a Sobel filter.
"""
mutable struct EdgeDetectionShader <: SDLShader
    data::ShaderPixelData
end
need_pixeldata(shader::EdgeDetectionShader) = :data

"""
    mutable struct VignetteShader <: SDLShader
        strength::Float32
        radius::Float32

Apply a vignette effect, darkening the edges.
"""
mutable struct VignetteShader <: SDLShader
    strength::Float32
    radius::Float32
end

"""
    mutable struct RippleShader <: SDLShader
        amplitude::Float32
        frequency::Float32
        speed::Float32
        time::Float32
        data::ShaderPixelData

Apply a ripple distortion effect.
"""
mutable struct RippleShader <: SDLShader
    amplitude::Float32
    frequency::Float32
    speed::Float32
    time::Float32
    data::ShaderPixelData
end
need_pixeldata(shader::RippleShader) = :data

"""
    mutable struct ChromaKeyShader <: SDLShader
        target_color::NTuple{3,UInt8}
        threshold::Float32
        replacement_color::NTuple{4,UInt8}

Replace a specific color with transparency or another color.
- target_color: NTuple{3,UInt8} (RGB) to replace.
- threshold: Float32, tolerance for color matching.
- replacement_color: NTuple{4,UInt8} (RGBA) or nothing for transparency.
"""
mutable struct ChromaKeyShader <: SDLShader
    target_color::NTuple{3,UInt8}
    threshold::Float32
    replacement_color::NTuple{4,UInt8}
end

"""
    mutable struct ChromaticAberrationShader <: SDLShader
        offset_x::Float32
        offset_y::Float32
        intensity::Float32
        data::ShaderPixelData

Apply a chromatic aberration effect by offsetting the RGB channels.
- offset_x, offset_y: Pixel offset for red and blue channels relative to green.
- intensity: Strength of the effect (0.0 to 1.0).
"""
mutable struct ChromaticAberrationShader <: SDLShader
    offset_x::Float32
    offset_y::Float32
    intensity::Float32
    data::ShaderPixelData
end
need_pixeldata(shader::ChromaticAberrationShader) = :data

"""
    mutable struct CRTDistortionShader <: SDLShader
        curvature::Float32
        scanline_strength::Float32
        scanline_frequency::Float32
        data::ShaderPixelData

Apply a CRT distortion effect with curvature and scanlines.
- curvature: Amount of screen curvature (0.0 to 0.5).
- scanline_strength: Intensity of scanlines (0.0 to 1.0).
- scanline_frequency: Frequency of scanlines.
"""
mutable struct CRTDistortionShader <: SDLShader
    curvature::Float32
    scanline_strength::Float32
    scanline_frequency::Float32
    data::ShaderPixelData

    ## Constructor

    CRTDistortionShader(c,ss,sf) = new(c,ss,sf)
end
need_pixeldata(shader::CRTDistortionShader) = :data

"""
    mutable struct GlitchEffectShader <: SDLShader
        time::Float32
        shake_intensity::Float32
        block_size::Float32
        block_shift::Float32
        data::ShaderPixelData

Apply a glitch effect with screen shake and block displacement.
- time: Animation time for dynamic effects.
- shake_intensity: Intensity of screen shake (pixels).
- block_size: Size of displaced pixel blocks.
- block_shift: Maximum block displacement (pixels).
"""
mutable struct GlitchEffectShader <: SDLShader
    time::Float32
    shake_intensity::Float32
    block_size::Float32
    block_shift::Float32
    data::ShaderPixelData
end
need_pixeldata(shader::GlitchEffectShader) = :data

function (b::BrightnessShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    r, g, b, a = color
    brightness, contrast = b.brightness, b.contrast

    # Ajuster la luminosité et le contraste
    r = clamp(round(Int, (r * brightness - 128) * contrast + 128), 0, 255)
    g = clamp(round(Int, (g * brightness - 128) * contrast + 128), 0, 255)
    b = clamp(round(Int, (b * brightness - 128) * contrast + 128), 0, 255)

    return Color8(r, g, b, a)
end

function (::InvertColorsShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    r, g, b, a = color
    return Color8(255 - r, 255 - g, 255 - b, a)
end

function (::SepiaShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    r, g, b, a = color
    # Sepia conversion formula
    r_out = clamp(round(Int, r * 0.393 + g * 0.769 + b * 0.189), 0, 255)
    g_out = clamp(round(Int, r * 0.349 + g * 0.686 + b * 0.168), 0, 255)
    b_out = clamp(round(Int, r * 0.272 + g * 0.534 + b * 0.131), 0, 255)
    return Color8(r_out, g_out, b_out, a)
end

function (shader::GaussianBlurShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    pixels, w, h, format = shader.pixels, shader.data.size, shader.data.format 
    x, y = round(Int, pos[1] * w), round(Int, pos[2] * h)
    radius, sigma = shader.radius, shader.sigma
    r_sum, g_sum, b_sum, a_sum = 0.0, 0.0, 0.0, 0.0
    weight_sum = 0.0

    # gaussian kernel
    for ky in -radius:radius
        for kx in -radius:radius
            px, py = x + kx, y + ky
            if 1 <= px <= w && 1 <= py <= h
                idx = (py - 1) * w + px
                weight = exp(-Float32(kx^2 + ky^2) / (2 * sigma^2)) / (2 * pi * sigma^2)
                r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
                SDL_GetRGBA(pixels[idx], format, r_ref, g_ref, b_ref, a_ref)
                r_sum += r_ref[] * weight
                g_sum += g_ref[] * weight
                b_sum += b_ref[] * weight
                a_sum += a_ref[] * weight
                weight_sum += weight
            end
        end
    end

    r = clamp(round(Int, r_sum / weight_sum), 0, 255)
    g = clamp(round(Int, g_sum / weight_sum), 0, 255)
    b = clamp(round(Int, b_sum / weight_sum), 0, 255)
    a = clamp(round(Int, a_sum / weight_sum), 0, 255)
    return Color8(r, g, b, a)
end

function (::EdgeDetectionShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    pixels, w, h, format = shader.data.pixels, shader.data.size, shader.data.format
    x, y = round(Int, pos[1] * w), round(Int, pos[2] * h)
    if x <= 1 || x >= w || y <= 1 || y >= h
        return Color8(color...)
    end

    # Sobel kernel
    sobel_x = [-1 0 1; -2 0 2; -1 0 1]
    sobel_y = [-1 -2 -1; 0 0 0; 1 2 1]
    gx, gy = 0.0, 0.0

    for ky in -1:1
        for kx in -1:1
            px, py = x + kx, y + ky
            idx = (py - 1) * w + px
            r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
            SDL_GetRGBA(pixels[idx], format, r_ref, g_ref, b_ref, a_ref)
            intensity = (r_ref[] + g_ref[] + b_ref[]) / 3.0
            gx += sobel_x[ky + 2, kx + 2] * intensity
            gy += sobel_y[ky + 2, kx + 2] * intensity
        end
    end

    edge = clamp(round(Int, sqrt(gx^2 + gy^2)), 0, 255)
    return Color8(edge, edge, edge, color[4])
end

function (shader::VignetteShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    r, g, b, a = color
    strength, radius = shader.strength, shader.radius
    x, y = pos
    # Distance from the center (0.5, 0.5)
    dist = sqrt((x - 0.5)^2 + (y - 0.5)^2)
    factor = clamp(1.0 - strength * (dist / radius), 0.0, 1.0)
    r = clamp(round(Int, r * factor), 0, 255)
    g = clamp(round(Int, g * factor), 0, 255)
    b = clamp(round(Int, b * factor), 0, 255)
    return Color8(r, g, b, a)
end

function (shader::RippleShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    x, y = pos
    pixels, w, h, format = shader.data.pixels, shader.data.size, shader.data.format
    amplitude, frequency, speed, time = shader.amplitude, shader.frequency, shader.speed, shader.time
    # Calculate distortion
    dist = sqrt((x - 0.5)^2 + (y - 0.5)^2)
    offset = amplitude * sin(frequency * dist - speed * time)
    new_x = clamp(round(Int, (x + offset) * w), 1, w)
    new_y = clamp(round(Int, (y + offset) * h), 1, h)
    idx = (new_y - 1) * w + new_x
    r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
    SDL_GetRGBA(pixels[idx], format, r_ref, g_ref, b_ref, a_ref)
    return Color8(r_ref[], g_ref[], b_ref[], a_ref[])
end

function (shader::ChromaKeyShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    r, g, b, a = color
    target_color, threshold, replacement_color = shader.target_color, color.threshold, color.replacement_color
    tr, tg, tb = target_color
    # Calculate color distance
    dist = sqrt((r - tr)^2 + (g - tg)^2 + (b - tb)^2)
    if dist <= threshold
        if replacement_color === nothing
            return Color8(r, g, b, 0) # Transparent
        else
            return Color8(replacement_color...)
        end
    end
    return Color8(r, g, b, a)
end

export ChromaticAberrationShader, CRTDistortionShader, GlitchEffectShader

function (shader::ChromaticAberrationShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    pixels, w, h, format = shader.data.pixels, shader.data.size, shader.data.format
    x, y = round(Int, pos[1] * w), round(Int, pos[2] * h)
    offset_x, offset_y, intensity = shader.offset_x, shader.offset_y, shader.intensity
    r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)

    # Récupérer le canal rouge avec un décalage
    rx, ry = clamp(x + round(Int, offset_x), 1, w), clamp(y + round(Int, offset_y), 1, h)
    r_idx = (ry - 1) * w + rx
    SDL_GetRGBA(pixels[r_idx], format, r_ref, g_ref, b_ref, a_ref)
    r = r_ref[]

    # Canal vert sans décalage
    g = color[2]

    # Récupérer le canal bleu avec un décalage opposé
    bx, by = clamp(x - round(Int, offset_x), 1, w), clamp(y - round(Int, offset_y), 1, h)
    b_idx = (by - 1) * w + bx
    SDL_GetRGBA(pixels[b_idx], format, r_ref, g_ref, b_ref, a_ref)
    b = b_ref[]

    # Mélanger avec l'intensité
    r = clamp(round(Int, r * intensity + color[1] * (1 - intensity)), 0, 255)
    g = clamp(round(Int, g * intensity + color[2] * (1 - intensity)), 0, 255)
    b = clamp(round(Int, b * intensity + color[3] * (1 - intensity)), 0, 255)
    a = color[4]

    return Color8(r, g, b, a)
end

const CRTr_ref = Ref{UInt8}(0)
const CRTg_ref = Ref{UInt8}(0)
const CRTb_ref = Ref{UInt8}(0)
const CRTa_ref = Ref{UInt8}(0)
function (shader::CRTDistortionShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    x, y = pos
    pixels, (w, h), format = shader.data.pixels, shader.data.size, shader.data.format
    curvature, scanline_strength, scanline_frequency = shader.curvature, shader.scanline_strength, shader.scanline_frequency

    # Appliquer une distorsion de type CRT (courbure)
    center_x, center_y = 0.5, 0.5
    dx, dy = x - center_x, y - center_y
    dist = sqrt(dx^2 + dy^2)
    max_dist = sqrt(0.5^2 + 0.5^2)
    distortion = 1.0 + curvature * (dist / max_dist)^2
    new_x = clamp(center_x + dx / distortion, 0.0, 1.0)
    new_y = clamp(center_y + dy / distortion, 0.0, 1.0)

    # Échantillonner le pixel à la position déformée
    px, py = round(Int, new_x * w), round(Int, new_y * h)
    px, py = clamp(px, 1, w), clamp(py, 1, h)
    idx = (py - 1) * w + px
    SDL_GetRGBA(pixels[idx], format, CRTr_ref, CRTg_ref, CRTb_ref, CRTa_ref)

    # Appliquer les scanlines
    scanline_factor = 1.0 - scanline_strength * (sin(new_y * h * scanline_frequency * pi) + 1.0) / 2.0
    r = clamp(round(Int, CRTr_ref[] * scanline_factor), 0, 255)
    g = clamp(round(Int, CRTg_ref[] * scanline_factor), 0, 255)
    b = clamp(round(Int, CRTb_ref[] * scanline_factor), 0, 255)
    a = CRTa_ref[]

    return Color8(r, g, b, a)
end

function (shader::GlitchEffectShader)(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    pixels, w, h, format = shader.data.pixels, shader.data.size, shader.data.format
    x, y = round(Int, pos[1] * w), round(Int, pos[2] * h)
    time, shake_intensity, block_size, block_shift = shader.time, shader.shake_intensity, shader.block_size, shader.block_shift

    # Appliquer un tremblement global
    shake_x = round(Int, shake_intensity * sin(time * 5.0))
    shake_y = round(Int, shake_intensity * cos(time * 5.0))
    px, py = clamp(x + shake_x, 1, w), clamp(y + shake_y, 1, h)

    # Déplacer des blocs de pixels
    block_x = div(x - 1, round(Int, block_size)) * round(Int, block_size)
    block_y = div(y - 1, round(Int, block_size)) * round(Int, block_size)
    block_offset_x = round(Int, block_shift * sin(time + block_x * 0.1))
    block_offset_y = round(Int, block_shift * cos(time + block_y * 0.1))
    px = clamp(px + block_offset_x, 1, w)
    py = clamp(py + block_offset_y, 1, h)

    # Add random artefacts
    if rand() < 0.01 # 1% chance per pixel
        return Color8(rand(UInt8), rand(UInt8), rand(UInt8), color[4])
    end

    # Échantillonner le pixel à la position modifiée
    idx = (py - 1) * w + px
    r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
    SDL_GetRGBA(pixels[idx], format, r_ref, g_ref, b_ref, a_ref)
    return Color8(r_ref[], g_ref[], b_ref[], a_ref[])
end

const kernel = [
        1 2 1;
        2 4 2;
        1 2 1
    ] ./ 16

function BloomShader(color::NTuple{4,UInt8}, pos::NTuple{2,Float64})
    pixels, w, h, format = shader.data.pixels, shader.data.size, shader.data.format

    x, y = round(Int, pos[1] * w), round(Int, pos[2] * h)
    r_acc = 0.0
    g_acc = 0.0
    b_acc = 0.0
    a_acc = 0.0

    for dy in -1:1, dx in -1:1
        nx = clamp(x + dx, 1, w)
        ny = clamp(y + dy, 1, h)
        idx = (ny - 1) * w + nx
        r_ref, g_ref, b_ref, a_ref = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
        SDL_GetRGBA(pixels[idx], format, r_ref, g_ref, b_ref, a_ref)
        weight = kernel[dy+2, dx+2]
        r_acc += r_ref[] * weight
        g_acc += g_ref[] * weight
        b_acc += b_ref[] * weight
        a_acc += a_ref[] * weight
    end

    # Ajout du pixel original (pour conserver détail)
    r_orig, g_orig, b_orig, a_orig = color
    r_final = clamp(UInt8(r_acc) + r_orig, 0, 255)
    g_final = clamp(UInt8(g_acc) + g_orig, 0, 255)
    b_final = clamp(UInt8(b_acc) + b_orig, 0, 255)
    a_final = clamp(UInt8(a_acc) + a_orig, 0, 255)

    return Color8(r_final, g_final, b_final, a_final)
end

"""
    heat_distortion_shader(color::NTuple{4,UInt8}, pos::NTuple{2,Float64}, extra)

Applya a heat distorsion to a texture
"""
function heat_distortion_shader(color::NTuple{4,UInt8}, pos::NTuple{2,Float64}, extra)
    t, amplitude, frequency = extra
    x, y = pos
    offset = sin(y * frequency + t) * amplitude
    r = UInt8(clamp(color[1] + offset, 0, 255))
    g = UInt8(clamp(color[2] + offset, 0, 255))
    b = UInt8(clamp(color[3] + offset, 0, 255))
    return (r, g, b, color[4])
end
