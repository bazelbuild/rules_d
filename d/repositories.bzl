"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//d/private:toolchains_repo.bzl", "PLATFORMS", "toolchains_repo")
load("//d/private/sdk:versions.bzl", "SDK_VERSIONS")

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
# This is all fixed by bzlmod, so we just tolerate it for now.
def rules_d_dependencies():
    # The minimal version of bazel_skylib we require
    http_archive(
        name = "bazel_skylib",
        sha256 = "51b5105a760b353773f904d2bbc5e664d0987fbaf22265164de65d43e910d8ac",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.8.1/bazel-skylib-1.8.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.8.1/bazel-skylib-1.8.1.tar.gz",
        ],
    )
    http_archive(
        name = "package_metadata",
        sha256 = "32299ff025ceb859328557fbb3dd42464ad2520e25969188c230b45638feb949",
        strip_prefix = "supply-chain-0.0.2/metadata",
        url = "https://github.com/bazel-contrib/supply-chain/releases/download/v0.0.2/supply-chain-v0.0.2.tar.gz",
    )

########
# Remaining content of the file is only used to support toolchains.
########
_DOC = "Fetch external tools needed for d toolchain"
_ATTRS = {
    "d_version": attr.string(mandatory = True, values = SDK_VERSIONS.keys()),
    "platform": attr.string(mandatory = True, values = PLATFORMS.keys()),
}

def _archive_prefix(url):
    filename = url.rsplit("/", 1)[-1]
    if filename.startswith("dmd"):
        return "dmd2"
    elif filename.startswith("ldc"):
        for ext in [".tar.xz", ".zip"]:
            if filename.endswith(ext):
                return filename[:-len(ext)]
        return filename
    else:
        fail("Unknown compiler archive %s" % filename)

def _d_repo_impl(repository_ctx):
    d_version = repository_ctx.attr.d_version
    platform = repository_ctx.attr.platform
    if d_version not in SDK_VERSIONS:
        repository_ctx.fail("Unknown d_version: %s" % d_version)
    if platform not in SDK_VERSIONS[d_version]:
        repository_ctx.fail("Unsupported platform: %s for %s" % (platform, d_version))
    sdk = SDK_VERSIONS[d_version][platform]
    repository_ctx.download_and_extract(
        url = sdk["url"],
        integrity = sdk["integrity"],
        stripPrefix = _archive_prefix(sdk["url"]),
    )
    build_bazel_template = "@rules_d//d/private/sdk:BUILD.%s.bazel" % d_version[0:3]

    # Base BUILD file for this repository
    repository_ctx.template("BUILD.bazel", Label(build_bazel_template))

d_repositories = repository_rule(
    _d_repo_impl,
    doc = _DOC,
    attrs = _ATTRS,
)

# Wrapper macro around everything above, this is the primary API
def d_register_toolchains(name, register = True, **kwargs):
    """Convenience macro for users which does typical setup.

    - create a repository for each built-in platform like "d_linux_amd64"
    - TODO: create a convenience repository for the host platform like "d_host"
    - create a repository exposing toolchains for each platform like "d_platforms"
    - register a toolchain pointing at each platform
    Users can avoid this macro and do these steps themselves, if they want more control.
    Args:
        name: base name for all created repos, like "d1_14"
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
        **kwargs: passed to each d_repositories call
    """
    for platform in PLATFORMS.keys():
        d_repositories(name = name + "_" + platform, platform = platform, **kwargs)
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
    )
