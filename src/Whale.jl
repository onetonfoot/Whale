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
        using Whale, Whale.PackageCompiler, Whale.PrecompileSignatures, $mod_sym

        Whale.with_project($project_path) do project

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

function sysimage(project_path::String; sysimage_path=nothing, no_execute=false)
    expr = _sysimage(project_path, sysimage_path)
    no_execute ? println(expr) : eval(expr)
end

function dockerize(project::String)
    info = project_info(project)
    name = info.name
    """
    ARG project=\$HOME/$name
    FROM julia:latest
    RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git")'
    ADD $project \$project

    RUN julia -e 'using Whale; Whale.sysimage("~/$name")'

    ENTRYPOINT julia -J \$HOME/.julia/sysimages/$(info.name).so  --project=\$project
    """

end

end