# Copyright 2015 The Bazel Authors. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""D rules for Bazel."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def a_filetype(files):
    return [f for f in files if f.basename.endswith(".a")]

D_FILETYPE = [".d", ".di"]

ZIP_PATH = "/usr/bin/zip"

def _relative(src_path, dest_path):
    """Returns the relative path from src_path to dest_path."""
    src_parts = src_path.split("/")
    dest_parts = dest_path.split("/")
    n = 0
    for src_part, dest_part in zip(src_parts, dest_parts):
        if src_part != dest_part:
            break
        n += 1

    relative_path = ""
    for _ in range(n, len(src_parts)):
        relative_path += "../"
    relative_path += "/".join(dest_parts[n:])

    return relative_path

def _create_setup_cmd(lib, deps_dir):
    """Constructs a command for symlinking a library into the deps directory."""
    return (
        "ln -sf " + _relative(deps_dir, lib.path) + " " +
        deps_dir + "/" + lib.basename + "\n"
    )

def _files_directory(files):
    """Returns the shortest parent directory of a list of files."""
    dir = files[0].dirname
    for f in files:
        if len(dir) > len(f.dirname):
            dir = f.dirname
    return dir

def _d_toolchain(ctx):
    """Returns a struct containing info about the D toolchain.

    Args:
      ctx: The ctx object.

    Return:
      Struct containing the following fields:
        d_compiler_path: The path to the D compiler.
        link_flags: Linker (-L) flags for adding the standard library to the
            library search paths.
        import_flags: import (-I) flags for adding the standard library sources
            to the import paths.
    """

    d_compiler_path = ctx.file._d_compiler.path
    return struct(
        d_compiler_path = d_compiler_path,
        link_flags = ["-L-L" + ctx.files._d_stdlib[0].dirname],
        import_flags = [
            "-I" + _files_directory(ctx.files._d_stdlib_src),
            "-I" + _files_directory(ctx.files._d_runtime_import_src),
        ],
    )

def _format_version(name):
    """Formats the string name to be used in a --version flag."""
    return name.replace("-", "_")

def _build_compile_command(ctx, srcs, out, depinfo, extra_flags = []):
    """Returns a string containing the D compile command."""
    toolchain = _d_toolchain(ctx)
    cmd = (
        ["set -e;"] +
        depinfo.setup_cmd +
        [toolchain.d_compiler_path] +
        extra_flags + [
            "-of" + out.path,
            "-I.",
            "-debug",
            "-w",
            "-g",
        ] +
        ["-I%s/%s" % (ctx.label.package, im) for im in ctx.attr.imports] +
        ["-I%s" % im for im in depinfo.imports] +
        toolchain.import_flags +
        ["-version=Have_%s" % _format_version(ctx.label.name)] +
        ["-version=%s" % v for v in ctx.attr.versions] +
        ["-version=%s" % v for v in depinfo.versions] +
        srcs
    )
    return " ".join(cmd)

def _build_link_command(ctx, objs, out, depinfo):
    """Returns a string containing the D link command."""
    toolchain = _d_toolchain(ctx)
    cmd = (
        ["set -e;"] +
        depinfo.setup_cmd +
        [toolchain.d_compiler_path] +
        ["-of" + out.path] +
        toolchain.link_flags +
        depinfo.lib_flags +
        depinfo.link_flags +
        objs
    )
    return " ".join(cmd)

def _setup_deps(deps, name, working_dir):
    """Sets up dependencies.

    Walks through dependencies and constructs the commands and flags needed
    for linking the necessary dependencies.

    Args:
      deps: List of deps labels from ctx.attr.deps.
      name: Name of the current target.
      working_dir: The output directory of the current target's output.

    Returns:
      Returns a struct containing the following fields:
        libs: List of Files containing the target's direct library dependencies.
        transitive_libs: List of Files containing all of the target's
            transitive libraries.
        d_srcs: List of Files representing D source files of dependencies that
            will be used as inputs for this target.
        versions: List of D versions to be used for compiling the target.
        setup_cmd: String containing the symlink commands to be used to set
            up the dependencies.
        imports: List of Strings containing input paths that will be passed
            to the D compiler via -I flags.
        link_flags: List of linker flags.
        lib_flags: List of library search flags.
    """
    deps_dir = working_dir + "/" + name + ".deps"
    setup_cmd = ["rm -rf " + deps_dir + ";" + "mkdir -p " + deps_dir + ";"]

    libs = []
    transitive_libs = []
    d_srcs = []
    transitive_d_srcs = []
    versions = []
    imports = []
    link_flags = []
    symlinked_libs = []
    for dep in deps:
        if hasattr(dep, "d_lib"):
            # The dependency is a d_library.
            libs.append(dep.d_lib)
            transitive_libs.append(dep.transitive_libs)
            symlinked_libs.append(depset([dep.d_lib], transitive = [dep.transitive_libs]))
            d_srcs += dep.d_srcs
            transitive_d_srcs.append(dep.transitive_d_srcs)
            versions += dep.versions + ["Have_%s" % _format_version(dep.label.name)]
            link_flags += ["-L-l%s" % dep.label.name] + dep.link_flags
            imports += ["%s/%s" % (dep.label.package, im) for im in dep.imports]

        elif hasattr(dep, "d_srcs"):
            # The dependency is a d_source_library.
            d_srcs += dep.d_srcs
            transitive_d_srcs.append(dep.transitive_d_srcs)
            transitive_libs.append(dep.transitive_libs)
            symlinked_libs.append(dep.transitive_libs)
            link_flags += ["-L%s" % linkopt for linkopt in dep.linkopts]
            imports += ["%s/%s" % (dep.label.package, im) for im in dep.imports]
            versions += dep.versions

        elif CcInfo in dep:
            # The dependency is a cc_library
            native_libs = a_filetype(_get_libs_for_static_executable(dep))
            libs.extend(native_libs)
            transitive_libs.append(depset(native_libs))
            symlinked_libs.append(depset(native_libs))
            link_flags += ["-L-l%s" % dep.label.name]

        else:
            fail("D targets can only depend on d_library, d_source_library, or " +
                 "cc_library targets.", "deps")

    setup_cmd += [
        _create_setup_cmd(lib, deps_dir)
        for lib in depset(transitive = symlinked_libs).to_list()
    ]

    return struct(
        libs = depset(libs),
        transitive_libs = depset(transitive = transitive_libs),
        d_srcs = depset(d_srcs).to_list(),
        transitive_d_srcs = depset(transitive = transitive_d_srcs),
        versions = versions,
        setup_cmd = setup_cmd,
        imports = depset(imports).to_list(),
        link_flags = depset(link_flags).to_list(),
        lib_flags = ["-L-L%s" % deps_dir],
    )

def _d_library_impl(ctx):
    """Implementation of the d_library rule."""
    d_lib = ctx.outputs.d_lib

    # Dependencies
    depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, d_lib.dirname)

    # Build compile command.
    cmd = _build_compile_command(
        ctx = ctx,
        srcs = [src.path for src in ctx.files.srcs],
        out = d_lib,
        depinfo = depinfo,
        extra_flags = ["-lib"],
    )

    compile_inputs = depset(
        ctx.files.srcs +
        depinfo.d_srcs +
        ctx.files._d_stdlib +
        ctx.files._d_stdlib_src +
        ctx.files._d_runtime_import_src,
        transitive = [
            depinfo.transitive_d_srcs,
            depinfo.libs,
            depinfo.transitive_libs,
        ],
    )

    ctx.actions.run_shell(
        inputs = compile_inputs,
        tools = [ctx.file._d_compiler],
        outputs = [d_lib],
        mnemonic = "Dcompile",
        command = cmd,
        use_default_shell_env = True,
        progress_message = "Compiling D library " + ctx.label.name,
    )

    return struct(
        files = depset([d_lib]),
        d_srcs = ctx.files.srcs,
        transitive_d_srcs = depset(depinfo.d_srcs),
        transitive_libs = depset(transitive = [depinfo.libs, depinfo.transitive_libs]),
        link_flags = depinfo.link_flags,
        versions = ctx.attr.versions,
        imports = ctx.attr.imports,
        d_lib = d_lib,
    )

def _d_binary_impl_common(ctx, extra_flags = []):
    """Common implementation for rules that build a D binary."""
    d_bin = ctx.outputs.executable
    d_obj = ctx.actions.declare_file(d_bin.basename + ".o")
    depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, d_bin.dirname)

    # Build compile command
    compile_cmd = _build_compile_command(
        ctx = ctx,
        srcs = [src.path for src in ctx.files.srcs],
        depinfo = depinfo,
        out = d_obj,
        extra_flags = ["-c"] + extra_flags,
    )

    toolchain_files = (
        ctx.files._d_stdlib +
        ctx.files._d_stdlib_src +
        ctx.files._d_runtime_import_src
    )

    compile_inputs = depset(
        ctx.files.srcs + depinfo.d_srcs + toolchain_files,
        transitive = [depinfo.transitive_d_srcs],
    )
    ctx.actions.run_shell(
        inputs = compile_inputs,
        tools = [ctx.file._d_compiler],
        outputs = [d_obj],
        mnemonic = "Dcompile",
        command = compile_cmd,
        use_default_shell_env = True,
        progress_message = "Compiling D binary " + ctx.label.name,
    )

    # Build link command
    link_cmd = _build_link_command(
        ctx = ctx,
        objs = [d_obj.path],
        depinfo = depinfo,
        out = d_bin,
    )

    link_inputs = depset(
        [d_obj] + toolchain_files,
        transitive = [depinfo.libs, depinfo.transitive_libs],
    )

    ctx.actions.run_shell(
        inputs = link_inputs,
        tools = [ctx.file._d_compiler],
        outputs = [d_bin],
        mnemonic = "Dlink",
        command = link_cmd,
        use_default_shell_env = True,
        progress_message = "Linking D binary " + ctx.label.name,
    )

    return struct(
        d_srcs = ctx.files.srcs,
        transitive_d_srcs = depset(depinfo.d_srcs),
        imports = ctx.attr.imports,
    )

def _d_binary_impl(ctx):
    """Implementation of the d_binary rule."""
    return _d_binary_impl_common(ctx)

def _d_test_impl(ctx):
    """Implementation of the d_test rule."""
    return _d_binary_impl_common(ctx, extra_flags = ["-unittest"])

def _get_libs_for_static_executable(dep):
    """
    Finds the libraries used for linking an executable statically.
    This replaces the old API dep.cc.libs
    Args:
      dep: Target
    Returns:
      A list of File instances, these are the libraries used for linking.
    """
    libraries_to_link = dep[CcInfo].linking_context.libraries_to_link.to_list()

    libs = []
    for library_to_link in libraries_to_link:
        if library_to_link.static_library != None:
            libs.append(library_to_link.static_library)
        elif library_to_link.pic_static_library != None:
            libs.append(library_to_link.pic_static_library)
        elif library_to_link.interface_library != None:
            libs.append(library_to_link.interface_library)
        elif library_to_link.dynamic_library != None:
            libs.append(library_to_link.dynamic_library)
    return libs

def _d_source_library_impl(ctx):
    """Implementation of the d_source_library rule."""
    transitive_d_srcs = []
    transitive_libs = []
    transitive_transitive_libs = []
    transitive_imports = depset()
    transitive_linkopts = depset()
    transitive_versions = depset()
    for dep in ctx.attr.deps:
        if hasattr(dep, "d_srcs"):
            # Dependency is another d_source_library target.
            transitive_d_srcs.append(dep.d_srcs)
            transitive_imports = depset(dep.imports, transitive = [transitive_imports])
            transitive_linkopts = depset(dep.linkopts, transitive = [transitive_linkopts])
            transitive_versions = depset(dep.versions, transitive = [transitive_versions])
            transitive_transitive_libs.append(dep.transitive_libs)

        elif CcInfo in dep:
            # Dependency is a cc_library target.
            native_libs = a_filetype(_get_libs_for_static_executable(dep))
            transitive_libs.extend(native_libs)
            transitive_linkopts = depset(["-l%s" % dep.label.name], transitive = [transitive_linkopts])

        else:
            fail("d_source_library can only depend on other " +
                 "d_source_library or cc_library targets.", "deps")

    return struct(
        d_srcs = ctx.files.srcs,
        transitive_d_srcs = depset(transitive = transitive_d_srcs, order = "postorder"),
        transitive_libs = depset(transitive_libs, transitive = transitive_transitive_libs),
        imports = ctx.attr.imports + transitive_imports.to_list(),
        linkopts = ctx.attr.linkopts + transitive_linkopts.to_list(),
        versions = ctx.attr.versions + transitive_versions.to_list(),
    )

# TODO(dzc): Use ddox for generating HTML documentation.
def _d_docs_impl(ctx):
    """Implementation for the d_docs rule

      This rule runs the following steps to generate an archive containing
      HTML documentation generated from doc comments in D source code:
        1. Run the D compiler with the -D flags to generate HTML code
           documentation.
        2. Create a ZIP archive containing the HTML documentation.
    """
    d_docs_zip = ctx.outputs.d_docs
    docs_dir = d_docs_zip.dirname + "/_d_docs"
    objs_dir = d_docs_zip.dirname + "/_d_objs"

    target = struct(
        name = ctx.attr.dep.label.name,
        srcs = ctx.attr.dep.d_srcs,
        transitive_srcs = ctx.attr.dep.transitive_d_srcs,
        imports = ctx.attr.dep.imports,
    )

    # Build D docs command
    toolchain = _d_toolchain(ctx)
    doc_cmd = (
        [
            "set -e;",
            "rm -rf %s; mkdir -p %s;" % (docs_dir, docs_dir),
            "rm -rf %s; mkdir -p %s;" % (objs_dir, objs_dir),
            toolchain.d_compiler_path,
            "-c",
            "-D",
            "-Dd%s" % docs_dir,
            "-od%s" % objs_dir,
            "-I.",
        ] +
        ["-I%s/%s" % (ctx.label.package, im) for im in target.imports] +
        toolchain.import_flags +
        [src.path for src in target.srcs] +
        [
            "&&",
            "(cd %s &&" % docs_dir,
            ZIP_PATH,
            "-qR",
            d_docs_zip.basename,
            "$(find . -type f) ) &&",
            "mv %s/%s %s" % (docs_dir, d_docs_zip.basename, d_docs_zip.path),
        ]
    )

    toolchain_files = (
        ctx.files._d_stdlib +
        ctx.files._d_stdlib_src +
        ctx.files._d_runtime_import_src
    )
    ddoc_inputs = depset(target.srcs + toolchain_files, transitive = [target.transitive_srcs])
    ctx.actions.run_shell(
        inputs = ddoc_inputs,
        tools = [ctx.file._d_compiler],
        outputs = [d_docs_zip],
        mnemonic = "Ddoc",
        command = " ".join(doc_cmd),
        use_default_shell_env = True,
        progress_message = "Generating D docs for " + ctx.label.name,
    )

_d_common_attrs = {
    "srcs": attr.label_list(allow_files = D_FILETYPE),
    "imports": attr.string_list(),
    "linkopts": attr.string_list(),
    "versions": attr.string_list(),
    "deps": attr.label_list(),
}

_d_compile_attrs = {
    "_d_compiler": attr.label(
        default = Label("//d:dmd"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_d_runtime_import_src": attr.label(
        default = Label("//d:druntime-import-src"),
    ),
    "_d_stdlib": attr.label(
        default = Label("//d:libphobos2"),
    ),
    "_d_stdlib_src": attr.label(
        default = Label("//d:phobos-src"),
    ),
}

d_library = rule(
    _d_library_impl,
    attrs = dict(_d_common_attrs.items() + _d_compile_attrs.items()),
    outputs = {
        "d_lib": "lib%{name}.a",
    },
)

d_source_library = rule(
    _d_source_library_impl,
    attrs = _d_common_attrs,
)

d_binary = rule(
    _d_binary_impl,
    attrs = dict(_d_common_attrs.items() + _d_compile_attrs.items()),
    executable = True,
)

d_test = rule(
    _d_test_impl,
    attrs = dict(_d_common_attrs.items() + _d_compile_attrs.items()),
    executable = True,
    test = True,
)

_d_docs_attrs = {
    "dep": attr.label(mandatory = True),
}

d_docs = rule(
    _d_docs_impl,
    attrs = dict(_d_docs_attrs.items() + _d_compile_attrs.items()),
    outputs = {
        "d_docs": "%{name}-docs.zip",
    },
)

DMD_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])

config_setting(
    name = "darwin",
    values = {"host_cpu": "darwin"},
)

config_setting(
    name = "k8",
    values = {"host_cpu": "k8"},
)

filegroup(
    name = "dmd",
    srcs = select({
        ":darwin": ["dmd2/osx/bin/dmd"],
        ":k8": ["dmd2/linux/bin64/dmd"],
    }),
)

filegroup(
    name = "libphobos2",
    srcs = select({
        ":darwin": ["dmd2/osx/lib/libphobos2.a"],
        ":k8": [
            "dmd2/linux/lib64/libphobos2.a",
            "dmd2/linux/lib64/libphobos2.so",
        ],
    }),
)

filegroup(
    name = "phobos-src",
    srcs = glob(["dmd2/src/phobos/**/*.*"]),
)

filegroup(
    name = "druntime-import-src",
    srcs = glob([
        "dmd2/src/druntime/import/*.*",
        "dmd2/src/druntime/import/**/*.*",
    ]),
)
"""

def d_repositories():
    http_archive(
        name = "dmd_linux_x86_64",
        urls = [
            "http://downloads.dlang.org/releases/2020/dmd.2.090.0.linux.tar.xz",
        ],
        sha256 = "17b407da594ad8fe96e7a8937434aaec2511b8623f05c3c27a5bc48d63a468a5",
        build_file_content = DMD_BUILD_FILE,
    )

    http_archive(
        name = "dmd_darwin_x86_64",
        urls = [
            "http://downloads.dlang.org/releases/2020/dmd.2.090.0.osx.tar.xz",
        ],
        sha256 = "6f1120e1fabda1d9da39bbe9cdd1b0886003f435948c15b6457fc6dada7bd344",
        build_file_content = DMD_BUILD_FILE,
    )
