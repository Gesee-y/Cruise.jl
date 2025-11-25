@App

```
CruiseApp
@gameloop
@gamelogic
awake!
update!
shutdown!
```

@Plugins

```
CRPlugin
CRPluginNode
add_system!
add_dependency!
remove_system!
remove_dependency!
enable_system
disable_system
merge_plugin!
getdep
isinitialized
isuninitialized
isdeprecated
hasfailed
getstatus
setstatus
getlasterror
setlasterr
hasfaileddeps
hasuninitializeddeps
hasalldepsinitialized
hasdeaddeps
```
@TempStorage

```
TempStorage
addvar!
getvar
hasvar
delvar!
clear!
start_auto_cleanup!
stop_auto_cleanup!
varsdict
createnamespace!
getnamespace
deletenamespace!
on
```

@Events

```
CRSubject
connect
disconnect
notify
```