load("@bazel_skylib//rules:common_settings.bzl", "string_setting")

D_TOOLCHAIN = "@//d:toolchain_type"

# string_setting(
#     name = "compiler_type",
#     values = [
#         "dmd",
#         "ldc",
#     ],
# )
# 
# config_setting(
#     name = "dmd",
#     flag_values = {
#         ":compiler_type": "dmd",
#     },
# )
# 
# config_setting(
#     name = "ldc",
#     flag_values = {
#         ":compiler_type": "ldc",
#     },
# )

def _d_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        name = ctx.label.name,
        d_compiler = ctx.attr.d_compiler,
        link_flags = ctx.attr.link_flags,
        import_flags = ctx.attr.import_flags,
        libphobos = ctx.attr.libphobos,
        libphobos_src = ctx.attr.libphobos_src,
        druntime = ctx.attr.druntime,
        druntime_src = ctx.attr.druntime_src,
        version_flag = ctx.attr.version_flag,
    )
    return [toolchain_info]

d_toolchain = rule(
    _d_toolchain_impl,
    attrs = {
        "d_compiler": attr.label(
            executable = True,
            # allow_files = True,
            cfg = "host",
        ),
        "link_flags": attr.string_list(
            default = [],
        ),
        "import_flags": attr.string_list(),
        "libphobos": attr.label(),
        "libphobos_src": attr.label(),
        "druntime": attr.label(),
        "druntime_src": attr.label(),
        "version_flag": attr.string(),
    },
)
