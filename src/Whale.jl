module Whale

using PackageCompiler, PrecompileSignatures, TOML, Libdl, Pkg

# When run from gloabl env we can get all of the packages installed
# Pkg.project().dependencies

# Pkg.dir("MyPkg")

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

function _sysimage(
    project::String, #TODO:  Should support both file paths or module names
    sysimage_path=nothing,
)

    info = project_info(project)
    mod_str = info.name
    mod_sym = Symbol(mod_str)

    if isnothing(sysimage_path)
        sysimage_path = joinpath(homedir(), ".julia", "sysimages", "$(mod_str).$(Libdl.dlext)")
    end

    quote
        using Pkg
        Pkg.activate($project)

        using Whale.PackageCompiler, Whale.PrecompileSignatures, $mod_sym

        sigs = @macroexpand @precompile_signatures($mod_sym)
        file = tempname()
        write(file, string(sigs))
        precompile_statements_file = String[]
        push!(precompile_statements_file, file)

        PackageCompiler.create_sysimage(
            String[],
            project=$project,
            sysimage_path=$sysimage_path,
            precompile_statements_file=precompile_statements_file
        )
    end

end

function sysimage(project::String; no_execute=false)
    previous_project = Pkg.project()
    expr = _sysimage(project)
    no_execute ? println(expr) : eval(expr)
    Pkg.activate(previous_project.path)
end

function dockerize(project::String)
    info = project_info(project)
    name = info.name
    """
    ARG project=\$HOME/$name
    FROM julia: latest
    RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git")'
    COPY $project project

    RUN julia -e 'using Whale; Whale.sysimage(\$project)'

    ENTRYPOINT julia -J \$HOME/.julia/sysimages/$(info.name).so 
    """

end

end