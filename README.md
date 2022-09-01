# Whale

This package helps with creating sysimages, apps and dockerfiles, it's a thin wrapper around [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl) and [PrecompileSignatures](https://github.com/rikhuijzer/PrecompileSignatures.jl) with some easy-to-use defaults. Currently, it's unregistered so install it with.


```julia

]add "https://github.com/onetonfoot/Whale.git
```

To build a sysimage

```julia
using Whale, MyPkg
Whale.sysimage(MyPkg)
``` 

This will build and output a sysimage to `~/.julia/sysimage/MyPkg.<ext>` where `<ext>` is the platform specific extension

For apps

```julia
using Whale, MyPkg
Whale.app(MyPkg)
``` 

This will build and output an  app to `~/.julia/apps/MyPkg`