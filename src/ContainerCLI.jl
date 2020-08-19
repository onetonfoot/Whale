module Whale

using Comonicon, Pkg.TOML, SimpleContainerGenerator, Logging
import SimpleContainerGenerator: Config

const default_config = Config()

@main function whale(
    project_toml::String;
    julia_version = string(VERSION),
    make_sysimage::Bool = default_config.make_sysimage,
    parent_image::String = default_config.parent_image,
    julia_cpu_target = default_config.julia_cpu_target,
    packagecompiler_installation_command = default_config.packagecompiler_installation_command,
)

    project_info = TOML.parsefile(project_toml)
    pkgs = get(project_info, "deps", Dict()) |> keys |> collect
    dir = tempname()
    logger = Logging.global_logger()
    Logging.global_logger(NullLogger())
    SimpleContainerGenerator.create_dockerfile(
        pkgs,
        dir,
        julia_version = julia_version,
        make_sysimage = make_sysimage,
        parent_image = parent_image,
        julia_cpu_target = julia_version,
        packagecompiler_installation_command = packagecompiler_installation_command,
    )
    Logging.global_logger(logger)
    dockerfile = joinpath(dir, readdir(dir)[1])
    read(dockerfile, String) |> print
end


end


# TODO: Still need to support these

#   Keyword Arguments
#   –––––––––––––––––––
#     •    additional_apt::Vector{String}
#     •    exclude_packages_from_sysimage::Vector{String}
#     •    no_test::Vector{String}

#   Advanced Keyword Arguments
#   ––––––––––––––––––––––––––––
#     •    override_default_apt::Vector{String}
#     •    precompile_execution_env_vars::Dict{String, String}
#     •    wrapper_script_env_vars::Dict{String, String}