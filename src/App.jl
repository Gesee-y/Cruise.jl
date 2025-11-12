###########################################################################################################################
#################################################### CRUISE APP ###########################################################
###########################################################################################################################

export CruiseApp
export awake!, run!, shutdown!
export on, off, merge_plugin!
export init_appstyle, context, instance

####################################################### CORE ##############################################################

@Notifyer ON_CRUISE_STARTUP()

"""
    mutable struct CruiseApp
		const inst::ODApp
		const plugins::Dict{Symbol, CRPlugin}
		const manager::CrateManager
		inited_style::Vector{Type{<:AbstractStyle}}
		windows::Dict{Int,CRWindow}
		running::Bool

Represent the boss app manager of the whole program.
- inst: The windows manager from Outdoors.jl
- plugins: A Dict that map a loop phase to a system graph.
- manager: Manage the assets. Comes from AssetCrates.jl
- inited_style: The alread initialized window style. They are kept so that we can properly clean everything at the end.
- windows: Maps the windows id to the instance in cruise
- running: Whether the app has already started.

## Constructor

    CruiseApp()

Will create a new global instance of a CruiseApp. Note that a program can only have one Cruise app.
The next call to CruiseApp will return the same object.
"""
mutable struct CruiseApp
	const plugins::Dict{Symbol, CRPlugin}
	const manager::CrateManager
	running::Bool
end

const app = Ref{CruiseApp}()
const app_lock = ReentrantLock()

## Constructor
function CruiseApp()
	global app
	global app_lock
	lock(app_lock)
	if !isassigned(app)
	    app[] = CruiseApp(Dict{Symbol, CRPlugin}(:preupdate => CRPlugin(), :postupdate => CRPlugin()), 
	    	CrateManager(), false)
	end
	unlock(app_lock)
	return app[]	
end

##################################################### FUNCTIONS ##########################################################

"""
    awake!(a::CruiseApp)

Initialize the CruiseApp and all his plugins.

    awake!(sg::CRPlugin)

Initialize all the systems in the given CRPlugin.
"""
function awake!()
    a = CruiseApp() 
	a.running = true
	for sg in values(a.plugins)
		awake!(sg)
	end

	ON_CRUISE_STARTUP.emit
end
awake!(sg::CRPlugin) = smap!(awake!, sg)
awake!(n::CRPluginNode) = (n.status[] = PLUGIN_OK)

"""
    update!(a::CruiseApp)

Update for the current frame the CruiseApp and all his plugins.

    update!(sg::CRPlugin)

Update for the current frame all the systems in the given CRPlugin.
"""
function update!()
    a = CruiseApp() 
	for sg in values(a.plugins)
		update!(sg)
	end
end
update!(a::CruiseApp, phase::Symbol) = update!(a.plugins[phase])
update!(sg::CRPlugin) = pmap!(update!, sg)
update!(n::CRPluginNode) = nothing

"""
    shutdown!(a::CruiseApp)

This function will stop Cruise, his plugins and clean up the resources.

	shutdown!(sg::CRPlugin)

This will stop the given system graph by topologically calling shutdown! on the systems.
"""
function shutdown!()
	a = CruiseApp()
    if on(a)
        a.running = false
        for sg in values(a.plugins)
		    shutdown!(sg)
	    end
        DestroyAllCrates!(a.manager)
    end
end
shutdown!(sg::CRPlugin) = smap!(shutdown!, sg)
shutdown!(n::CRPluginNode) = (n.status[] = CRPluginStatus.OFF)

"""
    on(a::CruiseApp)

Returns true if the CruiseApp is running.
"""
on(a::CruiseApp) = a.running

"""
    off(a::CruiseApp)

Returns true if the CruiseApp isn't running.
"""
off(a::CruiseApp) = !a.running

merge_plugin!(app::CruiseApp, plugin::CRPlugin, phase=:postupdate) = merge_plugin!(app.plugins[phase], plugin)
merge_plugin!(plugin1::CRPlugin, plugin2::CRPlugin) = merge_graphs!(plugin1, plugin2)

preupdate_plugins(a::CruiseApp) = a.plugins[:preupdate]
postupdate_plugins(a::CruiseApp) = a.plugins[:postupdate]