############################################################################################################################
######################################################### PRIMITIVES ######################################################
############################################################################################################################
## Définition des primitives géométriques pour le moteur Horizons ##

module Primitives

using ..Horizons
using ..MathLib
using ..SDLH
using ..GLH
using ..Vertex
using ..Textures
using ..Drawing

export Primitive, RectPrim, CirclePrim, EllipsePrim, PolygonPrim, ConvexPolygonPrim, ThickLinePrim, ArcPrim
export RenderObject, DestroyObject

########################################################### Core ###########################################################

"""
    abstract type Primitive

Type abstrait pour toutes les primitives géométriques.
"""
abstract type Primitive end

"""
    struct RectPrim <: Primitive
        rect::Rect2Df
        transform::HTransform
        color::Color8
        filled::Bool
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant un rectangle.
- `rect`: Rectangle définissant la position et la taille.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `filled`: Si vrai, le rectangle est rempli.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct RectPrim <: Primitive
    rect::Rect2Df
    transform::HTransform
    color::Color8
    filled::Bool
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct CirclePrim <: Primitive
        center::HVec2{Float32}
        radius::Float32
        transform::HTransform
        color::Color8
        filled::Bool
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant un cercle.
- `center`: Centre du cercle.
- `radius`: Rayon du cercle.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `filled`: Si vrai, le cercle est rempli.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct CirclePrim <: Primitive
    center::HVec2{Float32}
    radius::Float32
    transform::HTransform
    color::Color8
    filled::Bool
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct EllipsePrim <: Primitive
        center::HVec2{Float32}
        rx::Float32
        ry::Float32
        transform::HTransform
        color::Color8
        filled::Bool
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant une ellipse.
- `center`: Centre de l’ellipse.
- `rx`: Rayon horizontal.
- `ry`: Rayon vertical.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `filled`: Si vrai, l’ellipse est remplie.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct EllipsePrim <: Primitive
    center::HVec2{Float32}
    rx::Float32
    ry::Float32
    transform::HTransform
    color::Color8
    filled::Bool
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct PolygonPrim <: Primitive
        center::HVec2{Float32}
        radius::Float32
        sides::Int
        transform::HTransform
        color::Color8
        filled::Bool
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant un polygone régulier.
- `center`: Centre du polygone.
- `radius`: Rayon du polygone.
- `sides`: Nombre de côtés.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `filled`: Si vrai, le polygone est rempli.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct PolygonPrim <: Primitive
    center::HVec2{Float32}
    radius::Float32
    sides::Int
    transform::HTransform
    color::Color8
    filled::Bool
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct ConvexPolygonPrim <: Primitive
        vertices::Vector{HVec2{Float32}}
        transform::HTransform
        color::Color8
        filled::Bool
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant un polygone convexe défini par des vertices.
- `vertices`: Liste des vertices du polygone.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `filled`: Si vrai, le polygone est rempli.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct ConvexPolygonPrim <: Primitive
    vertices::Vector{HVec2{Float32}}
    transform::HTransform
    color::Color8
    filled::Bool
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct ThickLinePrim <: Primitive
        start::HVec2{Float32}
        end::HVec2{Float32}
        thickness::Float32
        transform::HTransform
        color::Color8
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant une ligne épaisse.
- `start`: Point de départ de la ligne.
- `end`: Point d’arrivée de la ligne.
- `thickness`: Épaisseur de la ligne.
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct ThickLinePrim <: Primitive
    start::HVec2{Float32}
    stop::HVec2{Float32}
    thickness::Float32
    transform::Transform
    color::Color8
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

"""
    struct ArcPrim <: Primitive
        center::HVec2{Float32}
        radius::Float32
        start_angle::Float32
        end_angle::Float32
        transform::HTransform
        color::Color8
        mesh::Mesh{NoMeshData}
        texture::Union{Texture,Nothing}

Primitive représentant un arc de cercle.
- `center`: Centre de l’arc.
- `radius`: Rayon de l’arc.
- `start_angle`: Angle de départ (en radians).
- `end_angle`: Angle de fin (en radians).
- `transform`: Transformation (position, rotation, échelle).
- `color`: Couleur pour le rendu SDL.
- `mesh`: Maillage pour le rendu OpenGL.
- `texture`: Texture optionnelle pour le rendu.
"""
mutable struct ArcPrim <: Primitive
    center::HVec2{Float32}
    radius::Float32
    start_angle::Float32
    end_angle::Float32
    transform::HTransform
    color::Color8
    mesh::Mesh{NoMeshData}
    texture::Union{Texture,Nothing}
end

###################################################### Constructeurs ######################################################

"""
    RectPrim(pos::HVec2, size::HVec2; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive rectangle.
"""
function RectPrim(pos::HVec2, size::HVec2; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)
    mesh = Rectangle2D(NoMeshData, size.x, size.y, pos)
    RectPrim(Rect2Df(pos, size), HTransform(), color, filled, mesh, texture)
end

"""
    CirclePrim(center::HVec2, radius::Real; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive cercle.
"""
function CirclePrim(center::HVec2, radius::Real; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)
    # Approximation par un polygone à 32 côtés pour le rendu OpenGL
    mesh = Poly2D(NoMeshData, radius, center, 32)
    CirclePrim(center, Float32(radius), HTransform(), color, filled, mesh, texture)
end

"""
    EllipsePrim(center::HVec2, rx::Real, ry::Real; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive ellipse.
"""
function EllipsePrim(center::HVec2, rx::Real, ry::Real; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)
    # Approximation par un polygone à 32 côtés avec mise à l’échelle pour l’ellipse
    vertices = [HVec2(center.x + rx * cos(2 * pi * i / 32), center.y + ry * sin(2 * pi * i / 32)) for i in 1:32]
    mesh = ConvexePoly2D(NoMeshData, [Vertex((v.x, v.y, 0), (0.5, 0.5), (0, 0, 1)) for v in vertices])
    EllipsePrim(center, Float32(rx), Float32(ry), HTransform(), color, filled, mesh, texture)
end

"""
    PolygonPrim(center::HVec2, radius::Real, sides::Int; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive polygone régulier.
"""
function PolygonPrim(center::HVec2, radius::Real, sides::Int; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)
    @assert sides >= 3 "Polygon must have at least 3 sides"
    mesh = Poly2D(NoMeshData, radius, center, sides)
    PolygonPrim(center, Float32(radius), sides, HTransform(), color, filled, mesh, texture)
end

"""
    ConvexPolygonPrim(vertices::Vector{HVec2}; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive polygone convexe.
"""
function ConvexPolygonPrim(vertices::Vector{HVec2}; filled::Bool=true, color::Color8=Color8(255,255,255,255), texture=nothing)
    mesh = ConvexePoly2D(NoMeshData, [Vertex((v.x, v.y, 0), (0.5, 0.5), (0, 0, 1)) for v in vertices])
    ConvexPolygonPrim(vertices, HTransform(), color, filled, mesh, texture)
end

"""
    ThickLinePrim(start::HVec2, end::HVec2, thickness::Real; color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive ligne épaisse.
"""
function ThickLinePrim(start::HVec2, stop::HVec2, thickness::Real; color::Color8=Color8(255,255,255,255), texture=nothing)
    # Créer un rectangle pour représenter la ligne épaisse
    dir = stop - start
    len = norm(dir)
    if len == 0
        mesh = Mesh{NoMeshData}(Vertex[], UInt32[])
    else
        dir = dir / len
        perp = HVec2(-dir.y, dir.x)
        half_thickness = Float32(thickness / 2)
        p1 = start + perp * half_thickness
        p2 = start - perp * half_thickness
        p3 = stop + perp * half_thickness
        p4 = stop - perp * half_thickness
        vertices = [Vertex((v.x, v.y, 0), (0.5, 0.5), (0, 0, 1)) for v in [p1, p2, p4, p3]]
        mesh = Mesh{NoMeshData}(vertices, to_array(Face(0, 1, 2, 3)))
    end
    ThickLinePrim(start, stop, Float32(thickness), HTransform(), color, mesh, texture)
end

"""
    ArcPrim(center::HVec2, radius::Real, start_angle::Real, end_angle::Real; color::Color8=Color8(255,255,255,255), texture=nothing)

Crée une primitive arc.
"""
function ArcPrim(center::HVec2, radius::Real, start_angle::Real, end_angle::Real; color::Color8=Color8(255,255,255,255), texture=nothing)
    steps = max(20, round(Int, abs(end_angle - start_angle) * radius))
    vertices = [Vertex((center.x + radius * cos(start_angle + (end_angle - start_angle) * (i-1) / (steps-1)), 
                       center.y + radius * sin(start_angle + (end_angle - start_angle) * (i-1) / (steps-1)), 0), 
                       (0.5, 0.5), (0, 0, 1)) for i in 1:steps]
    indices = UInt32[]
    for i in 1:(steps-1)
        push!(indices, UInt32(i-1), UInt32(i))
    end
    mesh = Mesh{NoMeshData}(vertices, indices)
    ArcPrim(center, Float32(radius), Float32(start_angle), Float32(end_angle), HTransform(), color, mesh, texture)
end

###################################################### Fonctions de rendu #################################################

"""
    RenderObject(ren::SDLRender, prim::Primitive, parent=nothing)

Rendu d’une primitive avec SDLRender.
"""
function RenderObject(ren::SDLRender, prim::RectPrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    pos = prim.rect.position + HVec2(prim.transform.position.x, prim.transform.position.y)
    if prim.filled
        FillRect(ren, (pos.x, pos.y, prim.rect.size.x, prim.rect.size.y))
    else
        DrawRect(ren, (pos.x, pos.y, prim.rect.size.x, prim.rect.size.y))
    end
end

function RenderObject(ren::SDLRender, prim::CirclePrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    pos = prim.center + HVec2(prim.transform.position.x, prim.transform.position.y)
    if prim.filled
        FillCircle(ren, pos, prim.radius)
    else
        DrawCircle(ren, pos, prim.radius)
    end
end

function RenderObject(ren::SDLRender, prim::EllipsePrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    pos = prim.center + HVec2(prim.transform.position.x, prim.transform.position.y)
    if prim.filled
        FillEllipse(ren, pos, prim.rx, prim.ry)
    else
        DrawEllipse(ren, pos, prim.rx, prim.ry)
    end
end

function RenderObject(ren::SDLRender, prim::PolygonPrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    pos = prim.center + HVec2(prim.transform.position.x, prim.transform.position.y)
    if prim.filled
        FillPolygon(ren, pos, prim.radius, prim.sides)
    else
        DrawPolygon(ren, pos, prim.radius, prim.sides)
    end
end

function RenderObject(ren::SDLRender, prim::ConvexPolygonPrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    vertices = [v + HVec2(prim.transform.position.x, prim.transform.position.y) for v in prim.vertices]
    if prim.filled
        # Triangulation simple pour le rendu
        for i in 2:(length(vertices)-1)
            DrawLine(ren, vertices[1], vertices[i])
            DrawLine(ren, vertices[i], vertices[i+1])
            DrawLine(ren, vertices[1], vertices[i+1])
        end
    else
        DrawLines(ren, vertices, count=length(vertices))
        DrawLine(ren, vertices[end], vertices[1])
    end
end

function RenderObject(ren::SDLRender, prim::ThickLinePrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    start = prim.start + HVec2(prim.transform.position.x, prim.transform.position.y)
    end_pos = prim.end + HVec2(prim.transform.position.x, prim.transform.position.y)
    DrawThickLine(ren, start, end_pos, prim.thickness)
end

function RenderObject(ren::SDLRender, prim::ArcPrim, parent=nothing)
    SetDrawColor(ren, prim.color)
    pos = prim.center + HVec2(prim.transform.position.x, prim.transform.position.y)
    DrawArc(ren, pos, prim.radius, prim.start_angle, prim.end_angle)
end

"""
    RenderObject(ren::GLRender, prim::Primitive, parent=nothing)

Rendu d’une primitive avec GLRender.
"""
function RenderObject(ren::GLRender, prim::Primitive, parent=nothing)
    # Appliquer la transformation
    transform = prim.transform
    model_matrix = HMat4{Float32}(
        transform.scale.x, 0, 0, transform.position.x,
        0, transform.scale.y, 0, transform.position.y,
        0, 0, transform.scale.z, transform.position.z,
        0, 0, 0, 1
    )
    glUniformMatrix4fv(glGetUniformLocation(ren.program, "model"), 1, GL_FALSE, Array(model_matrix))
    
    # Lier la texture si présente
    if prim.texture !== nothing
        glBindTexture(GL_TEXTURE_2D, prim.texture.id[1])
    end
    
    # Rendre le maillage
    glBindVertexArray(getfield(prim.mesh.data, :vao))
    if prim isa ArcPrim
        glDrawArrays(GL_LINE_STRIP, 0, length(prim.mesh.vertex))
    else
        glDrawElements(GL_TRIANGLES, length(prim.mesh.indices), GL_UNSIGNED_INT, C_NULL)
    end
    glBindVertexArray(0)
    if prim.texture !== nothing
        glBindTexture(GL_TEXTURE_2D, 0)
    end
end

"""
    DestroyObject(ren::AbstractRenderer, prim::Primitive)

Détruit une primitive et ses ressources associées.
"""
function DestroyObject(ren::AbstractRenderer, prim::Primitive)
    if prim.texture !== nothing
        DestroyTexture(prim.texture)
    end
    if ren isa GLRender
        vao = getfield(prim.mesh.data, :vao, nothing)
        vbo = getfield(prim.mesh.data, :vbo, nothing)
        ebo = getfield(prim.mesh.data, :ebo, nothing)
        if vao !== nothing
            glDeleteVertexArrays(1, Ref(vao))
        end
        if vbo !== nothing
            glDeleteBuffers(1, Ref(vbo))
        end
        if ebo !== nothing
            glDeleteBuffers(1, Ref(ebo))
        end
    end
end

end