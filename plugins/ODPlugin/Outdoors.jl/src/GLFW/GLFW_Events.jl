## Event management with GLFW ##

using GLFW

function RegisterGLFWCallbacks(app::GLFWWindow)
    window = GetStyle(app).window
    
    # Window position callback
    GLFW.SetWindowPosCallback(window, (win, x, y) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        RepositionWindow(od_win, x, y)
        NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_MOVED, x, y)
    end)

    # Window size callback
    GLFW.SetWindowSizeCallback(window, (win, w, h) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        ResizeWindow(od_win, w, h)
        NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_RESIZED, w, h)
    end)

    # Window close callback
    GLFW.SetWindowCloseCallback(window, (win) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_CLOSE)
    end)

    # Window focus callback
    GLFW.SetWindowFocusCallback(window, (win, focused) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        if focused
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_HAVE_FOCUS)
        else
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_LOSE_FOCUS)
        end
    end)

    # Window iconify callback
    GLFW.SetWindowIconifyCallback(window, (win, iconified) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        if iconified
            MinimizeWindow(od_win)
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_MINIMIZED)
        else
            RestoreWindow(od_win)
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_RESTORED)
        end
    end)

    # Window maximize callback
    GLFW.SetWindowMaximizeCallback(window, (win, maximized) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        if maximized
            MaximizeWindow(od_win)
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_MAXIMIZED)
        else
            RestoreWindow(od_win)
            NOTIF_WINDOW_EVENT.emit = (od_win, WINDOW_RESTORED)
        end
    end)

    # Scroll callback
    GLFW.SetScrollCallback(window, (win, xoffset, yoffset) -> begin
        od_win = GLFW_WINDOW_TO_ODWINDOW[win]
        GLFW_WINDOW_TO_SCROLL[win] = ScrollData(xoffset, yoffset)
    end)
end

"""
    GetEvents(::Type{GLFWStyle}, app::ODApp)

This function gets all the events for the GLFW style of window.
It manages different inputs and delivers them as notifications.
"""
function GetEvents(::Type{GLFWStyle}, app::ODApp)
    kb = 0; mm = 0; mw = 0; mb = 0; ev_count = 0

    GLFW.PollEvents()

    for win in values(app.Windows)
        if GetStyle(win) isa GLFWStyle
            mb += HandleMouseEvents(win)
            mm += HandleMouseMotionEvents(win)
            mw += HandleMouseWheelEvents(win)
            kb += HandleKeyboardInputs(win)
            ev_count += IsQuitEvent(win)
        end
    end

    return ev_count
end

function IsQuitEvent(app::GLFWWindow)
    if GLFW.WindowShouldClose(GetStyle(app).window)
        NOTIF_QUIT_EVENT.emit
        return 1
    end
    return 0
end

function HandleKeyboardInputs(app::GLFWWindow)
    window = GetStyle(app)
    glfw_win = window.window
    data = get_inputs_data(app)
    Inputs = get_keyboard_data(data)
    count = 0

    for keycode in GLFW.KEY_SPACE:GLFW.KEY_LAST
        key = ConvertKey(GLFWStyle, keycode)
        state = GLFW.GetKey(glfw_win, keycode)
        
        if state == GLFW.PRESS
            just_pressed = haskey(Inputs, key) ? (!Inputs[key].pressed) : true
            if just_pressed
                key_ev = KeyboardEvent(keycode, key, true, true, false, false)
                Inputs[key] = key_ev
                NOTIF_KEYBOARD_INPUT.emit = (app, key_ev)
                _update_keyboard_count(get_inputs_state(app))
                count += 1
            end
        elseif state == GLFW.RELEASE
            if haskey(Inputs, key) && Inputs[key].pressed
                just_released = Inputs[key].pressed
                key_ev = KeyboardEvent(keycode, key, false, false, true, just_released)
                Inputs[key] = key_ev
                NOTIF_KEYBOARD_INPUT.emit = (app, key_ev)
                _update_keyboard_count(get_inputs_state(app))
                count += 1
            end
        end
    end

    return count
end

function HandleMouseEvents(app::GLFWWindow)
    window = GetStyle(app)
    glfw_win = window.window
    data = get_inputs_data(app)
    MouseButtons = get_mousebutton_data(data)
    count = 0

    for (button, name, click_type) in [
        (GLFW.MOUSE_BUTTON_LEFT, "LeftClick", LeftClick),
        (GLFW.MOUSE_BUTTON_RIGHT, "RightClick", RightClick),
        (GLFW.MOUSE_BUTTON_MIDDLE, "MiddleClick", MiddleClick)
    ]
        state = GLFW.GetMouseButton(glfw_win, button)
        if state == GLFW.PRESS
            just_pressed = haskey(MouseButtons, name) ? (!MouseButtons[name].pressed) : true
            if just_pressed
                ev = MouseClickEvent(click_type{1}(), just_pressed, true, false, false)
                MouseButtons[name] = ev
                NOTIF_MOUSE_BUTTON.emit = (app, ev)
                _update_mousebutton_count(get_inputs_state(app))
                count += 1
            end
        elseif state == GLFW.RELEASE
            if haskey(MouseButtons, name) && MouseButtons[name].pressed
                just_released = MouseButtons[name].pressed
                ev = MouseClickEvent(click_type{1}(), false, false, just_released, true)
                MouseButtons[name] = ev
                NOTIF_MOUSE_BUTTON.emit = (app, ev)
                _update_mousebutton_count(get_inputs_state(app))
                count += 1
            end
        end
    end

    return count
end

function HandleMouseMotionEvents(app::GLFWWindow)
    window = GetStyle(app)
    glfw_win = window.window
    data = get_inputs_data(app)
    Axes = get_axes_data(data)

    x, y = GLFW.GetCursorPos(glfw_win)
    x = round(Int, x)
    y = round(Int, y)

    prev_motion = haskey(Axes, "MMotion") ? Axes["MMotion"] : MouseMotionEvent(0,0,0,0)
    xrel = x - prev_motion.x
    yrel = y - prev_motion.y

    if xrel != 0 || yrel != 0
        ev = MouseMotionEvent(x, y, xrel, yrel)
        Axes["MMotion"] = ev
        NOTIF_MOUSE_MOTION.emit = (app, ev)
        _update_mousemotion_count(get_inputs_state(app))
        return 1
    end

    return 0
end

function HandleMouseWheelEvents(app::GLFWWindow)
    # GLFW doesn't provide direct wheel event access in the same way as SDL
    # We'll need to set up a callback for scroll events if not already done
    window = GetStyle(app)
    glfw_win = window.window
    data = get_inputs_data(app)
    Axes = get_axes_data(data)

    # This is a simplified version since GLFW uses callbacks for scroll
    # We'll assume a callback has stored the latest scroll data
    x, y = 0, 0  # These would come from a scroll callback
    if x != 0 || y != 0
        ev = MouseWheelEvent(x, y)
        Axes["Wheel"] = ev
        NOTIF_MOUSE_WHEEL.emit = (app, ev)
        _update_mousewheel_count(get_inputs_state(app))
        return 1
    end

    return 0
end

function ConvertKey(::Type{GLFWStyle}, key; physical=false)
    key_string = string(GLFW.GetKeyName(key, 0))
    return uppercase(key_string == "" ? string(key) : key_string)
end

function GetMousePosition(::Type{GLFWStyle}, app::GLFWWindow)
    window = GetStyle(app)
    x, y = GLFW.GetCursorPos(window.window)
    return round(Int, x), round(Int, y)
end

"""
    ConvertKey(::Type{GLFWStyle}, key; physical=false)

Converts a GLFW key code to a normalized string matching SDL's key format.
When physical=true, uses scancode for physical key representation.
"""
function ConvertKey(::Type{GLFWStyle}, key; physical=false)
    if physical
        # Use scancode for physical key layout
        scancode = GLFW.GetKeyScancode(key)
        key_name = GLFW.GetKeyName(key, scancode)
        key_string = key_name !== nothing ? string(key_name) : string(key)
        # Normalize to match SDL physical key format (e.g., "SCANCODE_A" -> "A")
        if startswith(key_string, "KEY_") || startswith(key_string, "SCANCODE_")
            key_string = uppercase(key_string[findfirst('_', key_string)+1:end])
        else
            key_string = uppercase(key_string)
        end
    else
        # Logical key conversion
        key_name = GLFW.GetKeyName(key, 0)
        if key_name !== nothing
            key_string = uppercase(string(key_name))
        else
            # Fallback to key code string, removing GLFW prefix
            key_string = string(key)
            if startswith(key_string, "KEY_")
                key_string = uppercase(key_string[5:end])
            else
                key_string = uppercase(key_string)
            end
        end
    end

    # Additional normalization to match SDL format
    key_string = replace(key_string, "LEFT_" => "")
    key_string = replace(key_string, "RIGHT_" => "")
    key_string = replace(key_string, "KP_" => "NUMPAD_")  # Match SDL's numpad naming
    key_string = replace(key_string, "SEMICOLON" => ";")
    key_string = replace(key_string, "COMMA" => ",")
    key_string = replace(key_string, "PERIOD" => ".")
    key_string = replace(key_string, "SLASH" => "/")
    key_string = replace(key_string, "BACKSPACE" => "BACK")
    key_string = replace(key_string, "RETURN" => "ENTER")
    key_string = replace(key_string, "GRAVE" => "`")
    key_string = replace(key_string, "MINUS" => "-")
    key_string = replace(key_string, "EQUALS" => "=")

    return key_string
end