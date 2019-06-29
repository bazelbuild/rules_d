load("@io_bazel_rules_d//d:d.bzl", "d_test")
load("@io_bazel_rules_d//tests/directory_srcs:directory_generator.bzl", "directory_generator")

# Provides a single declared directory File as its output in Default Info,
# containing a copy of all srcs. This is similar to capturing the output of the
# D protoc plugin as a single directory, for example.
directory_generator(
    name = "dir_gen",
    srcs = ["main.d"],
)

# Test that consuming a declared directory in the srcs attribute is correctly
# expanded to the contained files.
d_test(
    name = "directory_srcs",
    srcs = ["dir_gen"],
)
