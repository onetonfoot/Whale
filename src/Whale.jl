module Whale

using PackageCompiler, PrecompileSignatures, TOML, Libdl, Pkg

function get_module_pkgs(mod)
    folder = pkgdir(mod)
    if isnothing(folder)
        return []
    end

    file = joinpath(folder, "Project.toml")
    toml = TOML.parsefile(file)
    get(toml, "deps", Dict()) |> keys |> collect
end

isproject(folder) = isfile(joinpath(folder, "Project.toml"))

project_info(mod::Module) = project_info(pkgdir(mod))

function project_info(project::AbstractString)
    redirect_stdio(stderr=devnull, stdout=devnull) do
        previous_project = Pkg.project()
        Pkg.activate(project)
        info = Pkg.project()
        Pkg.activate(previous_project.path)
        info
    end
end

function with_project(fn, project_path)
    previous_project = Pkg.project()
    try
        Pkg.activate(project_path)
        Pkg.instantiate()
        project = Pkg.project()
        fn(project)
    catch e
        @error e
    finally
        Pkg.activate(previous_project.path)
    end
end

function module_packages(mod::Module)::Vector{String}
    project_path = pkgdir(mod)
    info = Whale.project_info(project_path)
    packages = info.dependencies |> keys |> collect
    return packages
end

# currently this causes PackageCompiler to segfault
# need another way to auto generate precompile statements
function precompile_file(mod::Module)
    sigs = @macroexpand @precompile_signatures(mod)
    file = tempname()
    write(file, string(sigs))
    return file
end

function sysimage(
    mod::Module; #TODO:  Should support both file paths or module names
    sysimage_path="",
    packages=module_packages(mod),
    kwargs...
)

    project_path = pkgdir(mod)
    project = project_info(project_path)
    mod_str = project.name

    if isempty(sysimage_path)
        sysimage_path = joinpath(homedir(), ".julia", "sysimages", "$(mod_str).$(Libdl.dlext)")
    end

    Whale.with_project(project_path) do project
        PackageCompiler.create_sysimage(
            packages,
            sysimage_path=sysimage_path;
            kwargs...
        )
    end
end

"""
Outputs a docker file in the modules directory
"""
dockerize(mod::Module) = dockerize(pkgdir(mod))

function dockerize(project_path::String)
    info = project_info(project_path)
    name = info.name
    s = """
    FROM julia:latest
    # install gcc which is needed for PackageCompiler
    RUN apt update && apt install build-essential -y
    # the correct path depends on the docker build context
    ADD . /opt/$name
    RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git"); Pkg.develop(path="/opt/$name")'
    RUN julia -e 'using Whale, $name; Whale.sysimage($name)'
    # this causes the project to be instantiated
    # RUN julia -J \$HOME/.julia/sysimages/$name.so \
    #            --project=/opt/$name \
    #            -e 'using MyPkg'
    ENTRYPOINT julia -J \$HOME/.julia/sysimages/$name.so \
               --project=/opt/$name 
    """

    write(joinpath(project_path, "Dockerfile"), s)
end

"""
"""
function app(mod::Module; app_path=nothing, kwargs...)

    @info kwargs

    project_path = pkgdir(mod)
    project = project_info(project_path)
    mod_str = project.name

    if isnothing(app_path)
        app_path = joinpath(homedir(), ".julia", "apps", "$(mod_str)")
    end

    PackageCompiler.create_app(
        project_path,
        app_path,
        ; kwargs...
    )
end


end