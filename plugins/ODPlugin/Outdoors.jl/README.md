# Outdoors.jl  
 
[![Julia 1.9+](https://img.shields.io/badge/Julia-1.9%2B-purple.svg)](https://julialang.org)  

## Quick Start  

```julia  
using Pkg  
Pkg.add("Outdoors")  
using Outdoors  
```  

## Introduction  

In modern GUI applications, the ability to switch between multiple windowing APIs (e.g., [SDL2](https://www.libsdl.org), [GLFW](https://www.glfw.org)) while minimizing dependencies on specific libraries is critical.  

**Outdoors.jl** solves this by acting as an abstraction layer for window management. It decouples your application from underlying APIs and leverages [Notifyers.jl](https://github.com/Gesee-y/Notifyers.jl) for event-driven reactivity.  

### Why Outdoors?  

This package is part of a larger 2D/3D game engine project in Julia. Outdoors.jl serves as the **window and application manager**, ensuring engine independence from specific windowing APIs.  

## Installation  

**Stable release**:  
```julia  
julia> ]add Outdoors  
```  

**Development version**:  
```julia  
julia> ]add https://github.com/Gesee-y/Outdoors.jl.git  
```  

## Features  

- **API abstraction**: Unified interface for SDL2, GLFW, and more.  
- **Extensible**: Easily add new windowing APIs via a simple interface.  
- **Event-driven**: Subscribe to events (including API-specific errors) using `Notifyer` objects.  
- **Hierarchical windows**: Create subwindows across different APIs.  
- **Unified input handling**: Consistent input management for GLFW, SDL, and others.  

## Usage  

```julia  
using Outdoors  

# Handle errors  
Outdoors.connect(NOTIF_ERROR) do msg, err  
    error(msg * ": " * err)  
end  

# Track application exit  
const should_close = Ref(false)  
Outdoors.connect(NOTIF_QUIT_EVENT) do  
    should_close[] = true  
end  

# Initialize SDL-style windowing  
InitOutdoor(SDLStyle)  

# Create application context and window  
app = ODApp()  
win = CreateWindow(app, SDLStyle, "Outdoor Test", 640, 480)  

# Event loop  
while !should_close[]  
    GetEvents(win)  
    yield()  # Allow asynchronous processing  
end  

# Cleanup  
QuitWindow(win)  
QuitStyle(SDLStyle)  
```  

## License  

MIT. See [LICENSE](https://github.com/Gesee-y/Outdoors.jl/blob/main/LICENSE).  

## Contributing  

Contributions are welcome!  

1. [Fork the repository](https://github.com/Gesee-y/Outdoors.jl/fork).  
2. Create a feature branch:  
   ```bash  
   git checkout -b feat/new-style  
   ```  
3. Submit a pull request.  

**Examples of contributions**:  
- New windowing API integrations (e.g., X11, Wayland).  
- Performance improvements.  
- Bug fixes.  

## Bug Reports  

Report issues on the [GitHub repository](https://github.com/Gesee-y/Outdoors.jl/issues).  
