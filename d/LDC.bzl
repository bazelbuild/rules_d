load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

package(default_visibility = ["//visibility:public"])

native_binary(
    name = "ldc2",
    out = "ldc2copy.exe",
    src = select({
        "@bazel_tools//src/conditions:darwin": "bin/ldc2",
        "@bazel_tools//src/conditions:linux_x86_64": "bin/ldc2",
        "@bazel_tools//src/conditions:windows_x64": "bin/ldc2.exe",
    }),
    # TODO: add the conf files to `data` field.
)

cc_import(
    name = "libphobos2",
    shared_library = select({
        "@bazel_tools//src/conditions:darwin": "osx/lib/dmd",
        "@bazel_tools//src/conditions:linux_x86_64": "lib/libphobos2-ldc-shared.so",
        "@bazel_tools//src/conditions:windows_x64": "lib/phobos2-ldc-shared.lib",
    }),
    static_library = select({
        "@bazel_tools//src/conditions:darwin": "osx/lib/dmd",
        "@bazel_tools//src/conditions:linux_x86_64": "lib/libphobos2-ldc.a",
        "@bazel_tools//src/conditions:windows_x64": "lib/phobos2-ldc.lib",
    }),
)

cc_import(
    name = "druntime",
    shared_library = select({
        "@bazel_tools//src/conditions:darwin": "osx/lib/dmd",
        "@bazel_tools//src/conditions:linux_x86_64": "lib/libdruntime-ldc-shared.so",
        "@bazel_tools//src/conditions:windows_x64": "lib/druntime-ldc-shared.lib",
    }),
    static_library = select({
        "@bazel_tools//src/conditions:darwin": "osx/lib/dmd",
        "@bazel_tools//src/conditions:linux_x86_64": "lib/libdruntime-ldc.a",
        "@bazel_tools//src/conditions:windows_x64": "lib/druntime-ldc.lib",
    }),
)

filegroup(
    name = "phobos_src",
    srcs = glob([
        "import/std/**/*.*",
        "import/std/*.*",
        "import/etc/**/*.*",
        "import/etc/*.*",
    ]),
)

filegroup(
    name = "druntime_src",
    srcs = glob([
        "import/core/**/*.*",
        "import/core/*.*",
        "import/ldc/**/*.*",
        "import/ldc/*.*",
    ]),
)
