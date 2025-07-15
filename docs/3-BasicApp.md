# Cruise engine v0.1.0: Creating a basic app

We will now look at how to create a basic app with cruise.
We will not open a window now, just present the basic structure of a Cruise app.

Assuming you already installed the package, you first have to import it.

```julia
julia> using Cruise
```

Next we will create a new app, this is quite simple:

```julia
julia> app = CruiseApp()
```

Note that app is a [singleton]() and therefore, subsequent calls to `CruiseApp` will return the same instance.

Next we will create our [game loop]()

```julia
julia> @gameloop max_fps=60 app begin
           println("delta seconds: $(LOOP_VAR.delta_seconds)")
           # This simulate a 10s holdup before shutting down the app
           LOOP_VAR.frame_idx > 600 && shutdown!(app)
       end
```

There is a lot going on in this little chunk of code, let's break it down.
   
   - We first create a new game loop with `@gameloop`. This macro can take keyword arguments like `max_fps`(default is `60`) or `max_duration`(the maximum value of `LOOP_VAR.delta_seconds`, default is `0.3`). Then this macro take the `app` the loop is running for and the chunk of code to exeecute at each frame.
   - Next in the body of loop. We have access to the loop variable `LOOP_VAR` containing data about the current loop.
   it contains the following data:
      * `LOOP_VAR.last_frame_time_ns`: Contain the time in ns at which the last frame was executed.
      * `LOOP_VAR.frame_idx`: The id of the current frame, increase at each loop.
      * `LOOP_VAR.delta_seconds`: The time elapsed between the last frame and the current frame.
      * `LOOP_VAR.max_fps`: The maximum number of frame per seconds, this can be changed in the loop.
      * `LOOP_VAR.max_duration`: The maximum value that `LOOP_VAR.delta_seconds` can take.
   - Finally we have this line `shutdown!(app)`. This will shutdown the app, destroy every resource created and close the loop.

With this, You already have the basic knowledge to use Cruise. From now on, we will assume we are working in a file.