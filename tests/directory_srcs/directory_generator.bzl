def directory_generator_impl(ctx):
    # Declare a directory rather than a file and copy all sources
    out_dir = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [out_dir],
        command = "cp {} '{}'".format(
            " ".join(["'" + f.path + "'" for f in ctx.files.srcs]),
            out_dir.path,
        ),
    )

    # Return the directory File object as the default info files.
    return [
        DefaultInfo(
            files = depset([out_dir]),
        ),
    ]

directory_generator = rule(
    implementation = directory_generator_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)
