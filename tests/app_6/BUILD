load("@io_bazel_rules_d//d:d.bzl", "d_binary")

d_binary(
    name = "app_6_binary",
    srcs = ["app_6.d"],
)

sh_test(
    name = "app_6",
    srcs = ["run_app_6.sh"],
    data = [":app_6_binary"],
)

genrule(
    name = "run_app_6",
    outs = ["run_app_6.sh"],
    executable = True,
    cmd = "echo $(rootpath :app_6_binary) > $@",
    tools = [":app_6_binary"],
)
