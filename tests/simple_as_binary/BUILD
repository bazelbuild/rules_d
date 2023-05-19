load("@io_bazel_rules_d//d:d.bzl", "d_binary")

d_binary(
    name = "simple",
    srcs = ["simple.d"],
)

sh_test(
    name = "simple_as_binary",
    srcs = ["run_simple.sh"],
    data = [":simple"],
)

genrule(
    name = "run_simple",
    outs = ["run_simple.sh"],
    cmd = "echo $(rootpath :simple) > $@",
    executable = True,
    tools = [":simple"],
)
