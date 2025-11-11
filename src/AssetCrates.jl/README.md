# Crates.jl: Asset manager

Crates.jl is an asset manager. Long story short, it loads resources (files, images, sounds) for you, manage their lifecycle and let you reuse them as many time as you want. You can then safely free all the resource easily.

## Installation

```julia
julia> ]add Crates
```

For the development version

```julia
julia> ]add https://github.com/Gesee-y/Crates.jl
```

## Features

- **Resources loading**:
  * Files
  * Sounds: ogg, wav, etc.
  * Images: png, gif, jpg.
  * Meshes: Work in progress
- **Resources reuse**: Resource are only loaded one time and reused until they are destroyed
- **Resource cleanup**: Once your program is done, you can easily cleanup all allocated resources

## Example

```julia
using Crates

manager = CrateManager()
img = load(manager,ImageCrate, "img.png") # Return an ImageCrate with the pixel table and the format
# Any subsequent call to load for this image will just reuse the existing instance

# Call Destroy(manager, img) to delete the image
# Call DestroyAllCrates!(manager) to free all resources
```

## License

This package is given under the MIT License.

## Bug report

Feel free to open an issue if you encounter any bug.