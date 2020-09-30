package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_d//d:d.bzl", "d_library", "d_test")

config_setting(
    name = "x64_windows",
    values = {"host_cpu": "x64_windows"},
)

d_test(
    name = "linkopts",
    srcs = [
        "linkopts.d",
    ],
    imports = ["."],
    deps = [
        ":linkopts_lib",
    ],
)

d_library(
    name = "linkopts_lib",
    srcs = [
        "linkopts_lib.d",
    ],
    deps = [
        ":linkopts_lib_cc",
    ],
)

cc_library(
    name = "linkopts_lib_cc",
    srcs = ["linkopts_lib.cpp"],
    defines = select({
        ":x64_windows": ["WIN32"],
        "//conditions:default": [],
    }),
    linkopts = select({
        ":x64_windows": ["/DEFAULTLIB:winhttp"],
        "//conditions:default": ["-lcurl"],
    }),
)
