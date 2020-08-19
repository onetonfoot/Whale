using Comonicon
import Pkg.TOML
import SimpleContainerGenerator

pkgs = [
    "Foo", # Replace Foo, Bar, Baz, etc. with the names of actual packages that you want to use
    "Bar",
    "Baz",
]
julia_version = v"1.4.0"

SimpleContainerGenerator.create_dockerfile(pkgs,
                                           pwd();
                                           julia_version=julia_version)


# TOML.parsefile
                                           

