# Horizons.jl: A 2D/3D Game Rendering Engine for Julia

While several rendering libraries exist in the Julia ecosystem, none are designed with **game rendering** in mind.

**Horizons.jl** is a modular and backend-agnostic rendering engine optimized for 2D and 3D game development.  
It provides high-performance abstractions for real-time rendering, scene management, and custom shaders — all with a clean, command-buffer-driven API.

---

## Installation

```julia
julia> ]add Horizons
# or for the development version
julia> ]add https://github.com/Gesee-y/Horizons.jl
```

---

## Features

### Architecture

* **Command Buffer Pipeline**: Rendering commands are recorded and batched before dispatch, enabling backend-independent optimization and minimal draw overhead.
* **Multi-Backend**:

  * **SDL** (software, CPU shaders)
  * **OpenGL** (in progress)

### Scene & Drawing

* **Drawable Object Hierarchy**: Each object can be a child of another, enabling grouped transforms and hierarchical updates.
* **Automatic Culling**: Offscreen objects are ignored automatically to save performance.
* **2D/3D Support**: Unified pipeline for both 2D sprites and 3D meshes.

### Shaders

* **Cross-Backend Shader System**: Write shaders once and run them on any backend, even on CPU for SDL.
* **Custom Shader Support**: Hook into the pipeline to define your own rendering effects.

---

## Example

See the [`examples/`](https://github.com/Gesee-y/Horizons.jl/tree/main/examples) folder for more.

---

## License

This package is licensed under the MIT License.
