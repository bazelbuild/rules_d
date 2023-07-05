load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

package(default_visibility = ["//visibility:public"])

native_binary(
    name = "dmd",
    out = "dmdcopy.exe",
    src = select({
        "@bazel_tools//src/conditions:darwin": "osx/bin/dmd",
        "@bazel_tools//src/conditions:linux_x86_64": "linux/bin64/dmd",
        "@bazel_tools//src/conditions:windows_x64": "windows/bin64/dmd.exe",
    }),
    data = select({
        "@bazel_tools//src/conditions:darwin": ["osx/bin/dmd.conf"],
        "@bazel_tools//src/conditions:linux_x86_64": ["linux/bin64/dmd.conf"],
        "@bazel_tools//src/conditions:windows_x64": glob(["windows/lib64/mingw/**"]) + [
            "windows/bin64/sc.ini",
            "windows/bin64/lld-link.exe",
            "windows/bin64/libcurl.dll",
            "windows/bin64/msvcr120.dll",
            "windows/lib64/curl.lib",
        ],
    }),
)

cc_import(
    name = "libphobos2",
    # shared_library = select({
    #     "@bazel_tools//src/conditions:linux_x86_64": "linux/lib64/libphobos2.so",
    #     "//conditions:default": None,
    # }),
    static_library = select({
        "@bazel_tools//src/conditions:darwin": "osx/lib/libphobos2.a",
        "@bazel_tools//src/conditions:linux_x86_64": "linux/lib64/libphobos2.a",
        "@bazel_tools//src/conditions:windows_x64": "windows/lib64/phobos64.lib",
    }),
)

filegroup(
    name = "phobos_src",
    srcs = glob(["src/phobos/**/*.*"]),
)

filegroup(
    name = "druntime_src",
    srcs = glob([
        "src/druntime/import/*.*",
        "src/druntime/import/**/*.*",
    ]),
)
