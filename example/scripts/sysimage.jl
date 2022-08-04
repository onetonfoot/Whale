using PackageCompiler, Whale

project = joinpath(@__DIR__, "../MyPkg/")
Whale.sysimage(project)