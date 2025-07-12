## We check the Outdoors module function correctly ##

include("..\\src\\Outdoors.jl")

using .Outdoors

Outdoors.connect(NOTIF_OUTDOOR_INITED) do
	println("Outdoor successfuly inited!")
	println()
end

Outdoors.connect(NOTIF_WINDOW_CREATED) do win
	sl = GetStyle(win)
	println("A new window named '$(sl.title)' have been created.")
end
Outdoors.connect(NOTIF_WINDOW_EXITTED) do win
	sl = GetStyle(win)
	println("The window named '$(sl.title)' have been exitted.")
end
Outdoors.connect(NOTIF_ERROR) do msg,err
	error(msg*err)
end

InitOutdoor(SDLStyle)
app = ODApp()

function One_window()
	win = CreateWindow(app,SDLStyle,"Outdoor Test",640,480)
	#Outdoors.Delay(3000)
	sleep(4)
	QuitWindow(win)
	sleep(1)
end

function multiple_window()
	win_array = Vector{SDLWindow}(undef,4)

	for i in eachindex(win_array)
		win_array[i] = CreateWindow(app,SDLStyle,"Outdoor Test$i",rand(320:640),rand(240:480))
		sleep(0.5)
	end

	for win in win_array
		QuitWindow(win)
		sleep(0.5)
	end
end

function FlagsTest()
	win = CreateWindow(SDLApp,"Outdoor Test",640,480;borderless=true)
	#Outdoors.Delay(3000)
	sleep(4)
	QuitWindow(win)
	sleep(1)
end

const Close = Ref(false)

Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

#=Outdoors.connect(NOTIF_KEYBOARD_INPUT) do win,key
	obj = key.key

	if key.just_pressed[]
		println("Key '$obj' just pressed.")
	elseif key.pressed
		println("Key '$obj' is pressed.")
	elseif key.released
		println("Key '$obj' have been released.")
	end
end=#

Outdoors.connect(NOTIF_WINDOW_EVENT) do win,type,w,h
	if type == Outdoors.WINDOW_RESIZED
		println("Resizing to $(w)x$h.")
		ResizeWindow(win,w,h)
	elseif type == Outdoors.WINDOW_MOVED
		println("Moving to $(w),$h.")
		RepositionWindow(win,w,h)
	elseif type == Outdoors.WINDOW_HAVE_FOCUS
		println("The mouse is in the window.")
	elseif type == Outdoors.WINDOW_LOSE_FOCUS
		println("The mouse exit the window.")
	elseif type == Outdoors.WINDOW_CLOSE
		println("closing.")
		QuitWindow(win)
	end
end

Outdoors.connect(NOTIF_MOUSE_BUTTON) do _, ev
	if ev.type isa LeftClick{1}
		println("Left click.")
	elseif ev.type isa LeftDoubleClick
		println("Left double click.")
	elseif ev.type isa RightClick{1}
		println("Right click.")
	elseif ev.type isa RightDoubleClick
		println("Right double click.")
	elseif ev.type isa MiddleClick
		println("Wheel click.")
	end
end

function EventsTest()
	win = CreateWindow(app,SDLStyle,"Outdoor Test",640,480)
	while !Close[]
		GetEvents(win)
		#println(GetMousePosition(SDLApp))
		yield()
	end
	QuitWindow(win)
end

function InputsTest()
	win = CreateWindow(app,SDLStyle,"Outdoor Test",640,480)
	println(win.id)

	@InputMap Shoot("Z","LeftClick",strength=1.0)
	moy = 0.0
	count = 0
	while !Close[]
		@time EventLoop(app)
		#println(dt)
		axis = GetAxis(win,"Wheel")
		motion = GetAxis(win,"MMotion")
		if motion.xrel != 0 || motion.yrel != 0
			println(motion)
		end
		if axis.ywheel != 0
			println(axis)
		end

		IsKeyJustPressed(win,Shoot) && println("Shooting")
		IsKeyPressed(win,"RIGHT") && println("Moving to the right.")
		#println(GetMousePosition(SDLApp))
		yield()
		sleep(1/90)
	end

	println("Eventloop Time : $(moy/count) seconds")
	@time QuitWindow(win)
end

function MultiInputsTest()
	win = CreateWindow(app,SDLStyle,"Outdoor Test",640,480)
	win2 = CreateWindow(app,SDLStyle,"Outdoor Test",240,560)
	win3 = CreateWindow(app,SDLStyle,"Outdoor Test",690,240)

	#@InputMap Shoot("Z","LeftClick",strength=1.0)
	moy = 0.0
	count = 0
	while !Close[]
		EventLoop(app)
		#println(dt)
		axis = GetAxis(win,"Wheel")
		println("Axis")
		@time motion = GetAxis(win2,"MMotion")
		
		if motion.xrel != 0 || motion.yrel != 0
			println(motion)
		end
		if axis.ywheel != 0
			println(axis)
		end

		println("just pressed")
		@time IsKeyJustPressed(win3,Shoot) && println("Shooting")
		println("pressed")
		@time IsKeyPressed(win,"RIGHT") && println("Moving to the right.")
		#println(GetMousePosition(SDLApp))
		yield()
		sleep(1/90)
	end

	println("Eventloop Time : $(moy/count) seconds")
	@time QuitWindow(win)
end

#One_window()
#multiple_window()
#EventsTest()
#InputsTest()
MultiInputsTest()
QuitStyle(SDLStyle)