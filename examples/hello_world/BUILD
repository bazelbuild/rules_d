load("//d:d.bzl", "d_binary", "d_docs")

package(default_visibility = ["//visibility:public"])

d_binary(
    name = "hello_world",
    srcs = ["hello_world.d"],
    deps = [
        "//examples/hello_lib:greeter",
        "//examples/hello_lib:native_greeter",
    ],
)

d_docs(
    name = "hello_world_docs",
    dep = ":hello_world",
)
