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

function project_info(project)
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
        project = Pkg.project()
        fn(project)
    catch e
        @error e
    finally
        Pkg.activate(previous_project.path)
    end
end

function _sysimage(
    project_path::String, #TODO:  Should support both file paths or module names
    sysimage_path=nothing,
)

    project_path = realpath(project_path)
    project = project_info(project_path)
    mod_str = project.name
    mod_sym = Symbol(mod_str)

    if isnothing(sysimage_path)
        sysimage_path = joinpath(homedir(), ".julia", "sysimages", "$(mod_str).$(Libdl.dlext)")
    end

    quote
        using Whale, Whale.PackageCompiler, Whale.PrecompileSignatures

        Whale.with_project($project_path) do project
            @eval using $mod_sym

            packages = project.dependencies |> keys |> collect

            if !isnothing(project.name)
                push!(packages, project.name)
            end

            sigs = @macroexpand @precompile_signatures($mod_sym)
            file = tempname()
            write(file, string(sigs))
            precompile_statements_file = String[]
            push!(precompile_statements_file, file)

            PackageCompiler.create_sysimage(
                packages,
                sysimage_path=$sysimage_path,
                precompile_statements_file=precompile_statements_file
            )
        end
    end

end

"""

* project_path -  file path to a julia project
* sysimage_path - defaults to `~/.julia/sysimages/<project name>.<ext>`  
* no_execute - return an expr instead of executing code

"""
function sysimage(project_path::String; sysimage_path=nothing, no_execute=false)
    expr = _sysimage(project_path, sysimage_path)
    no_execute ? println(expr) : eval(expr)
end

function dockerize(project_path::String)
    info = project_info(project_path)
    name = info.name
    """
    FROM julia:latest
    # install gcc which is needed for PackageCompiler
    RUN apt update && apt install build-essential -y
    RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git")'
    # the correct path depends on the docker build context
    ADD <replace me> /opt/$name
    RUN julia --project=/opt/MyPkg -e 'using Whale; Whale.sysimage("/opt/$name")'
    # this causes the project to be instantiated
    RUN julia -J \$HOME/.julia/sysimages/$name.so \
               --project=/opt/$name \
               -e 'using MyPkg'
    ENTRYPOINT julia -J \$HOME/.julia/sysimages/$name.so \
               --project=/opt/$name 
    """
end

end