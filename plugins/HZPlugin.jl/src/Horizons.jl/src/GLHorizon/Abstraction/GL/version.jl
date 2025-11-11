const OGL_MAJOR_VERSION = 4
const OGL_MINOR_VERSION = 6

# "Different ways an OpenGL extension can be supported"
@bp_enum(ExtensionMode,
    # The extension must exist, or there will be an error
    require,
    # The extension should be added, otherwise there will be a warning
    prefer,
    # The extension should be added if available
    enable
)

"A requested OpenGL extension"
struct ExtensionRequest
    name::String
    mode::E_ExtensionMode

    # If the GLSL code to invoke this extension is abnormal, specify it here.
    glsl_override::Optional{String}

    ExtensionRequest(name, mode, override = nothing) = new(name, mode, override)
end

extension_glsl(r::ExtensionRequest)::String = if exists(r.glsl_override)
    r.glsl_override
elseif r.mode in (ExtensionMode.require, ExtensionMode.enable)
    "#extension $(r.name) : $(r.mode)"
elseif r.mode == ExtensionMode.prefer
    "#extension $(r.name) : warn"
else
    error("Unhandled case: ", r.mode)
end


"The core OpenGL extensions recommended for B+"
const OGL_RECOMMENDED_EXTENSIONS = (
    ExtensionRequest(
        "GL_ARB_bindless_texture",
        ExtensionMode.require
    ),

    # For seamless bindless cubemaps:
    ExtensionRequest(
        "GL_ARB_seamless_cubemap_per_texture",
        ExtensionMode.prefer,
        "" # No GLSL code needed
    ),

    # For native 64-bit integer types (otherwise you need to use uint2):
    ExtensionRequest(
        "GL_ARB_gpu_shader_int64",
        ExtensionMode.enable
    )
)


"Generates the top of a B+ shader, including `#version` and `#extension` statements"
glsl_header(extensions::Vector{ExtensionRequest}) = string(
    "#version $(OGL_MAJOR_VERSION)$(OGL_MINOR_VERSION)0 \n",
    (string(extension_glsl(e), "\n") for e in extensions)...,
    "#line 1\n"
)

export ExtensionRequest, ExtensionMode, E_ExtensionMode, OGL_RECOMMENDED_EXTENSIONS