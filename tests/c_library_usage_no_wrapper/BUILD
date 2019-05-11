load("@io_bazel_rules_d//d:d.bzl", "d_test")

d_test(
    name = "c_library_usage_no_wrapper",
    srcs = ["c_library_usage_no_wrapper.d"],
    deps = [":c_plus_one_lib"],
)

cc_library(
    name = "c_plus_one_lib",
    srcs = ["plus_one.c"],
)
