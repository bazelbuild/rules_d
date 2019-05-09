load("@io_bazel_rules_d//d:d.bzl", "d_test")

d_test(
    name = "app_5",
    srcs = ["app_5.d"],
    deps = [":c_lib"],
)

cc_library(
    name = "c_lib",
    srcs = ["cfunc.c"],
)
