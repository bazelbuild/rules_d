load("@io_bazel_rules_d//d:d.bzl", "d_test")

d_test(
    name = "d_library_usage",
    srcs = ["d_library_usage.d"],
    deps = ["//tests/simple_d_library"],
    imports = ["../simple_d_library"],
)
