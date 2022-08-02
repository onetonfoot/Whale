using Whale, PackageCompiler, PrecompileSignatures, TOML

# module MyModule

# function f(x::Int, y::Float64)
#     x + y
# end
# end

# expr = Whale._sysimage("ExamplePkg")

# expr = Whale.sysimage("ExamplePkg", execute=true, replace_default=true)

# expr = @macroexpand PrecompileSignatures.@precompile_signatures(Whale)
# expr = @macroexpand PrecompileSignatures.@precompile_signatures(MyModule)

# using ExamplePkg

# PackageCompiler.create_sysimage([
#         "ExamplePkg",
#     ],
#     project=pkgdir(ExamplePkg),
#     sysimage_path=pwd(),
#     replace_default=false
# )