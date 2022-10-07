# Whale

This package helps with distributing julia programs by easing the creating of sysimages, relocatable apps and dockerfiles, it's a thin wrapper around [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl) and [PrecompileSignatures](https://github.com/rikhuijzer/PrecompileSignatures.jl) with some easy-to-use defaults. Currently, it's unregistered so install it with.


```julia
]add "https://github.com/onetonfoot/Whale.git"
```

There are 3 function `sysimage`,`app` and `docker` each takes a module as a argument.

```julia
using Whale, MyPkg
Whale.sysimage(MyPkg)
``` 

This will build and output a sysimage to `~/.julia/sysimage/MyPkg.<ext>` where `<ext>` is the platform specific extension

```julia
using Whale, MyPkg
Whale.app(MyPkg)
``` 

This will build and output an  app to `~/.julia/apps/MyPkg`

```julia
using Whale, MyPkg
Whale.docker(MyPkg)
``` 

This will output a `Dockerfile` to the given module's `pkgdir`.
