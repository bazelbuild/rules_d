load("@io_bazel_rules_d//d:d.bzl", "d_test")

d_test(
    name = "app_4",
    srcs = ["app_4.d"],
    deps = [
        "//tests/lib_2",
        "//tests/lib_2:lib_2_d_import",
    ],
    imports = [".."],
)
