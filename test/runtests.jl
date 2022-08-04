using Whale, PackageCompiler, PrecompileSignatures, TOML, Test

project = realpath(joinpath(@__DIR__, "../example/MyPkg/"))

@testset "project_info" begin
    a_project = Pkg.project()
    info = Whale.project_info(project)
    b_project = Pkg.project()
    @test a_project.path == b_project.path

end

@testset "sysimage" begin
    @test_skip Whale.sysimage(project)
end

@testset "sysimage" begin
    @test Whale.dockerize(project) isa String
end