## THIS IS JUST A PLACEHOLDER, THIS WELL BE REMOVED DURING RELEASE

export enable_plugin

function enable_plugin()
	eval(quote
		include(joinpath("RECSPlugin.jl","src","RECSPlugin.jl"))
		include(joinpath("SceneTreePlugin","src","SceneTreePlugin.jl"))
		include(joinpath("ODPlugin","src","ODPlugin.jl"))
		include(joinpath("HZPlugin.jl","src","HZPlugin.jl"))
    end)
end

enable_plugin()