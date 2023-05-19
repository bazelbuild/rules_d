load("@io_bazel_rules_d//d:d.bzl", "d_source_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "simple_c_library",
    srcs = ["simple_library.c"],
)

d_source_library(
    name = "simple_c_library_wrapper",
    srcs = ["simple_library_wrapper.di"],
)
