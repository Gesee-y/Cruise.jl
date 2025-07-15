##  Blocks of temporary GUI state  ##

"
Nests some GUI code within a window.
Extra arguments get passed directly into `CImGui.Begin()`.
Returns the output of your code block, or `nothing` if the UI was culled.
"
function gui_window(to_do, args...; kw_args...)::Optional
    is_open = CImGui.Begin(args..., kw_args...)
    try
        if is_open
            return to_do()
        end
    finally
        CImGui.End()
    end

    return nothing
end

"
Executes some GUI code with a different item width.

See: https://pixtur.github.io/mkdocs-for-imgui/site/api-imgui/ImGui--Dear-ImGui-end-user/#PushItemWidth

* >0.0f: width in pixels
* <0.0f: align xx pixels to the right of window (so -1.0f always align width to the right side)
* ==0.0f: default to ~⅔ of windows width
"
function gui_with_item_width(to_do, width::Real)
    CImGui.PushItemWidth(Float32(width))
    try
        return to_do()
    finally
        CImGui.PopItemWidth()
    end
end


function gui_with_indentation(to_do, width::Optional{Real} = nothing)
    CImGui.Indent(@optional(exists(width), width))
    try
        return to_do()
    finally
        CImGui.Unindent()
    end
end

function gui_with_padding(to_do, padding...)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, padding...)
    try
        return to_do()
    finally
        CImGui.PopStyleVar()
    end
end

function gui_with_clip_rect(to_do,
                            rect::Box2Df, intersect_with_current_rect::Bool,
                            draw_list::Optional{Ptr{LibCImGui.ImDrawList}} = nothing
                            #TODO: Param for using world space (call different CImGui func)
                            )
    CImGui.PushClipRect(@optional(exists(draw_list), draw_list),
                        CImGui.ImVec2(min_inclusive(rect)...),
                        CImGui.ImVec2(max_exclusive(rect)...),
                        intersect_with_current_rect)
    try
        return to_do()
    finally
        CImGui.PopClipRect()
    end
end

function gui_with_font(to_do, font::Ptr)
    CImGui.PushFont(font)
    try
        return to_do()
    finally
        CImGui.PopFont()
    end
end
function gui_with_font(to_do, font_idx::Integer)
    font_singleton = unsafe_load(CImGui.GetIO().Fonts)
    font_list::CImGui.ImVector_ImFontPtr = unsafe_load(font_singleton.Fonts)
    font::Ptr{CImGui.ImFont} = unsafe_load(font_list.Data, font_idx)
    return gui_with_font(to_do, font)
end

"
Executes some GUI code without allowing the user to tab to different widgets
  (so tabs get inserted into text editors).
"
function gui_with_unescaped_tabbing(to_do)
    CImGui.PushAllowKeyboardFocus(false)
    try
        return to_do()
    finally
        CImGui.PopAllowKeyboardFocus()
    end
end

"
Executes some GUI code with the given ID data (ptr, String, Integer, or begin + end Strings)
  pushed onto the stack.
"
function gui_with_nested_id(to_do, values...)
    CImGui.PushID(values...)
    to_do()
    CImGui.PopID()
end

"
Executes some GUI within a fold (what Dear ImGUI calls a 'tree node').
If it's open, returns the output of your lambda; otherwise returns `nothing`.
"
function gui_within_fold(to_do, label)
    is_visible::Bool = CImGui.TreeNode(label)
    if is_visible
        try
            return to_do()
        finally
            CImGui.TreePop()
        end
    end

    return nothing
end

"Executes some GUI with a different 'style color'."
function gui_with_style_color(to_do,
                              index::CImGui.LibCImGui.ImGuiCol_,
                              color::Union{Integer, CImGui.ImVec4})
    CImGui.PushStyleColor(index, color)
    to_do()
    CImGui.PopStyleColor()
end

"
Groups widgets together for placement within larger layouts
    (such as a vertical group within a horizontal line).
"
function gui_within_group(to_do)
    CImGui.BeginGroup()
    try
        return to_do()
    finally
        CImGui.EndGroup()
    end
end

"""
Defines a set of tabs, and the contents underneath each.
Within this block you can create new tab views as follows:

````
gui_tab_views("Tab1") do
    # GUI code for the tab's contents
end
gui_tab_views("Tab2") do
    # GUI code for the other tab's contents
end
````
"""
function gui_tab_views(to_do, label, flags = CImGui.LibCImGui.ImGuiTabBarFlags_None)
    if CImGui.BeginTabBar(label, flags)
        try
            return to_do()
        finally
            CImGui.EndTabBar()
        end
    else
        return nothing
    end
end
"Defines one tab, as part of a tab bar (see `gui_tab_views()`). Returns whether the tab view was open."
function gui_tab_item(to_do, label, flags = CImGui.LibCImGui.ImGuiTabItemFlags_None)
    if CImGui.BeginTabItem(label, C_NULL, flags)
        try
            to_do()
            return true
        finally
            CImGui.EndTabItem()
        end
    else
        return false
    end
end

"
Groups a GUI together into a smaller window.
Returns the output of 'to_do()', or `nothing` if the window is closed.
"
function gui_within_child_window(to_do, id, size, flags=0)::Optional
    is_open = CImGui.BeginChildFrame(id, size, flags)
    try
        if is_open
            return to_do()
        end
    finally
        CImGui.EndChildFrame()
    end

    return nothing
end

export gui_with_item_width, gui_with_indentation, gui_with_clip_rect, gui_with_padding,
       gui_with_unescaped_tabbing, gui_with_style_color, gui_with_font, gui_with_nested_id,
       gui_window, gui_within_fold, gui_within_group, gui_tab_views, gui_tab_item, gui_within_child_window
#


##  Custom editors  ##

"Edits a vector with spherical coordinates; returns its new value."
function gui_spherical_vector( label, vec::v3f
                               ;
                               stays_normalized::Bool = false,
                               fallback_yaw::Ref{Float32} = Ref(zero(Float32))
                             )::v3f
    radius = vlength(vec)
    vec /= radius

    yawpitch = Float32.((atan(vec.y, vec.x), acos(vec.z)))
    # Keep the editor stable when it reaches a straight-up or straight-down vector.
    if yawpitch[2] in (Float32(-π), Float32(π))
        yawpitch = (fallback_yaw[], yawpitch[2])
    else
        fallback_yaw[] = yawpitch[1]
    end

    if stays_normalized
        # Remove floating-point error in the previous length calculation.
        radius = one(Float32)
    else
        # Provide an editor for the radius.
        @c CImGui.InputFloat("$label Length", &radius)
        CImGui.SameLine()
    end

    # Show two sliders, but with different ranges so we can't use CImGui.SliderFloat2().
    yaw, pitch = yawpitch
    content_width = CImGui.GetContentRegionAvailWidth()
    CImGui.SetNextItemWidth(content_width * 0.4)
    @c CImGui.SliderFloat("##Yaw", &yaw, -π, π)
    CImGui.SameLine()
    CImGui.SetNextItemWidth(content_width * 0.4)
    gui_with_nested_id("Slider 2") do
        @c CImGui.SliderFloat(label, &pitch, 0, π - 0.00001)
    end
    yawpitch = (yaw, pitch)

    # Convert back to cartesian coordinates.
    pitch_sincos = sincos(yawpitch[2])
    vec_2d = v2f(sincos(yawpitch[1])).yx * pitch_sincos[1]
    vec_z = pitch_sincos[2]
    return radius * vappend(vec_2d, vec_z)
end

export gui_spherical_vector


##  Small helper functions  ##

"
Sizes the next CImGui window in terms of a percentage of the actual window's size,
  optionally with a pixel-space border padding it inwards.
"
function gui_next_window_space(uv_space::Box2Df,
                               min_and_max_pixel_border::v2i = zero(v2i),
                               min_only_pixel_border::v2i = zero(v2i)
                               ;
                               window_size::v2i = get_window_size(get_context()))
    # Remove the padding from the reported window size.
    window_size -= min_and_max_pixel_border * v2i(2, 2)
    window_size -= min_only_pixel_border
    w_size::v2f = window_size * size(uv_space)

    # Add the padding to the calculated position.
    pos::v2f = (window_size * min_inclusive(uv_space)) +
               convert(v2f, min_only_pixel_border + min_and_max_pixel_border)

    CImGui.SetNextWindowPos(CImGui.ImVec2(pos...))
    CImGui.SetNextWindowSize(CImGui.ImVec2(w_size...))
end
"Sizes the next CImGui window in terms of a pixel rectangle"
function gui_next_window_space(pixel_space::Box2Di; window_size::v2i = get_window_size(get_context()))
    CImGui.SetNextWindowPos(CImGui.ImVec2(min_inclusive(pixel_space)...))
    CImGui.SetNextWindowSize(CImGui.ImVec2(size(pixel_space...)))
end

export gui_next_window_space