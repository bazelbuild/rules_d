load("@io_bazel_rules_d//d:d.bzl", "d_test")

d_test(
    name = "lib_that_depends_on_lib_test",
    srcs = ["lib_that_depends_on_lib_test.d"],
    imports = ["../lib_that_depends_on_lib"],
    deps = ["//tests/lib_that_depends_on_lib"],
)
