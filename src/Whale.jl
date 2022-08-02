module Whale

using Comonicon, PackageCompiler, PrecompileSignatures, TOML

# Currently not used
function get_module(s::Symbol)
    expr = quote
        try
            using $s
        catch e
        end
    end
    eval(expr)
    getfield(Main, s)
end

function get_module_pkgs(mod)
    folder = pkgdir(mod)
    if isnothing(folder)
        return []
    end

    file = joinpath(folder, "Project.toml")
    toml = TOML.parsefile(file)
    get(toml, "deps", Dict()) |> keys |> collect
end

function _sysimage(
    mod_str::String,
    replace_default=false,
    sysimage_path=pwd(),
)
    mod_sym = Symbol(mod_str)
    mods = get_module_pkgs(Whale)
    push!(mods, string(mod_sym))
    quote

        using Whale.PackageCompiler, Whale.PrecompileSignatures, $mod_sym

        sigs = @macroexpand @precompile_signatures($mod_sym)
        file = tempname()
        write(file, string(sigs))
        precompile_statements_file = String[]
        push!(precompile_statements_file, file)

        PackageCompiler.create_sysimage(
            $mods,
            project=pkgdir($mod_sym),
            replace_default=$replace_default,
            sysimage_path=$sysimage_path,
            precompile_statements_file=precompile_statements_file
        )
    end
end

@cast function sysimage(mod::String; execute=false, replace_default=false)
    expr = _sysimage(mod, replace_default)
    execute ? eval(expr) : println(expr)
end

@cast function dockerize(mod::String)
    """
    FROM julia: latest
    RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git")'
    RUN whale sysimage $mod --replace 

    ENTRYPOINT julia -e "using $mod"
    """
end

@main

end