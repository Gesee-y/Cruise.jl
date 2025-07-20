

function KeyboardCallback(window::GLFW.Window, key::Integer, scancode::Integer, action::Integer, mods::Integer)
	win = GLFW_WINDOW_TO_ODWINDOW[window]
	inputs = get_keyboard_data(get_inputs_data(win))

	keyname = GLFW.GetKeyName(key, scancode)
	keyname === nothing && return

	keystr = String(keyname)
	state = get!(inputs, keystr) do
		KeyboardState(false, Ref(false), Ref(false))
	end

	if action == GLFW.PRESS
		if !state.pressed
			state.pressed = true
			state.just_pressed[] = true
		end
	elseif action == GLFW.RELEASE
        KeyboardEvent(id,key,false,false,true,just_released;Pkey=Pkey)
		if state.pressed
			state.pressed = false
			state.just_released[] = true
		end
	end
end

function MouseButtonCallback(window::GLFW.Window, button::Integer, action::Integer, mods::Integer)
	win = GLFW_WINDOW_TO_ODWINDOW[window]
	buttons = get_mousebutton_data(get_inputs_data(win))

	btnstr = "MOUSE$button"
	state = get!(buttons, btnstr) do
		MouseButtonState(false, Ref(false), Ref(false))
	end

	if action == GLFW.PRESS
		if !state.pressed
			state.pressed = true
			state.just_pressed[] = true
		end
	elseif action == GLFW.RELEASE
		if state.pressed
			state.pressed = false
			state.just_released[] = true
		end
	end
end

GLFW.SetKeyCallback(win_ptr, KeyboardCallback)
GLFW.SetMouseButtonCallback(win_ptr, MouseButtonCallback)

function GetEvents(::Type{GLFWStyle}, app::ODApp)
    GLFW.PollEvents()

    for win in values(app.Windows)
        HandleKeyboardInputs(win)
        HandleMouseEvents(win)
    end
end


function HandleKeyboardInputs(win::GLFWWindow)
    data = get_inputs_data(win)
    Inputs = get_keyboard_data(data)
    changed = false

    for key in 32:GLFW.KEY_LAST
        state = GLFW.GetKey(win.window, key)
        is_pressed = (state == GLFW.PRESS || state == GLFW.REPEAT)
        name = ConvertKey(GLFWStyle, key)

        prev = get(Inputs, name, KeyboardEvent(0, name, false, false, false, false))

        ev = KeyboardEvent(
            key, name,
            is_pressed && !prev.pressed,
            is_pressed,
            prev.pressed && !is_pressed,
            false;
            Pkey=name
        )

        Inputs[name] = ev
        changed |= (ev.just_pressed[] || ev.just_released[])
    end

    changed && (NOTIF_KEYBOARD_INPUT.emit = (win, Inputs))
end

function HandleMouseEvents(win::GLFWWindow)
    data = get_inputs_data(win)
    MouseButtons = get_mousebutton_data(data)

    x, y = GLFW.GetCursorPos(win.window)
    prev = get(get_axes_data(data), "MMotion", MouseMotionEvent(x, y, 0, 0))
    relx = x - prev.x
    rely = y - prev.y

    get_axes_data(data)["MMotion"] = MouseMotionEvent(x, y, relx, rely)
    NOTIF_MOUSE_MOTION.emit = (win, get_axes_data(data)["MMotion"])

    for (btn, name) in ((GLFW.MOUSE_BUTTON_LEFT, "LeftClick"),
                        (GLFW.MOUSE_BUTTON_RIGHT, "RightClick"),
                        (GLFW.MOUSE_BUTTON_MIDDLE, "MiddleClick"))

        pressed = GLFW.GetMouseButton(win.window, btn) == GLFW.PRESS
        prev = get(MouseButtons, name, MouseClickEvent(nothing, false, false, false, false))

        ev = MouseClickEvent(
            eval(Symbol(name)),
            !prev.pressed && pressed,
            pressed,
            prev.pressed && !pressed,
            !pressed
        )

        MouseButtons[name] = ev
        (ev.just_pressed[] || ev.just_released[]) && (NOTIF_MOUSE_BUTTON.emit = (win, ev))
    end
end


function _attach_glfw_callbacks(win::GLFWWindow)
    GLFW.SetWindowSizeCallback(win.window) do w, width, height
        ResizeWindow(win, width, height)
        NOTIF_WINDOW_EVENT.emit = (win, WINDOW_RESIZED, width, height)
    end

    GLFW.SetWindowPosCallback(win.window) do w, x, y
        RepositionWindow(win, x, y)
        NOTIF_WINDOW_EVENT.emit = (win, WINDOW_MOVED, x, y)
    end

    GLFW.SetWindowCloseCallback(win.window) do w
        NOTIF_WINDOW_EVENT.emit = (win, WINDOW_CLOSE)
    end

    GLFW.SetCursorEnterCallback(win.window) do w, entered
        if entered == 1
            NOTIF_WINDOW_EVENT.emit = (win, WINDOW_HAVE_FOCUS)
        else
            NOTIF_WINDOW_EVENT.emit = (win, WINDOW_LOSE_FOCUS)
        end
    end
end

function ConvertKey(::Type{GLFWStyle}, key::Integer; physical=false)
    if 65 ≤ key ≤ 90
        return Char(key)
    elseif 48 ≤ key ≤ 57
        return Char(key)
    elseif key == GLFW.KEY_SPACE
        return "SPACE"
    elseif key == GLFW.KEY_ESCAPE
        return "ESCAPE"
    elseif key == GLFW.KEY_LEFT
        return "LEFT"
    elseif key == GLFW.KEY_RIGHT
        return "RIGHT"
    elseif key == GLFW.KEY_UP
        return "UP"
    elseif key == GLFW.KEY_DOWN
        return "DOWN"
    else
        return "KEY_$key"
    end
end


function OnKeyCallback(_, key, scancode, action, mods)
	name = GLFW.GetKeyName(key, scancode)
	if name == nothing
		println("scancode $scancode ", action)
	else
		println("key $name ", action)
	end
end