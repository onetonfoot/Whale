using PackageCompiler, Whale

project = joinpath(@__DIR__, "../MyPkg/")

open(joinpath(@__DIR__, "Dockerfile"), "w") do f
    write(f, Whale.dockerize(project))
end