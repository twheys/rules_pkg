# Copyright 2019 The Bazel Authors. All rights reserved.
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

"""Provides rules for creating RPM packages via pkg_filegroup and friends.

pkg_rpm() depends on the existence of an rpmbuild toolchain. Many users will
find to convenient to use the one provided with their system. To enable that
toolchain add the following stanza to WORKSPACE:

```
# Find rpmbuild if it exists.
load("@rules_pkg//toolchains:rpmbuild_configure.bzl", "find_system_rpmbuild")
find_system_rpmbuild(name="rules_pkg_rpmbuild")
```
"""

load(
    "//pkg:providers.bzl",
    "PackageArtifactInfo",
    "PackageDirsInfo",
    "PackageFilegroupInfo",
    "PackageFilesInfo",
    "PackageSymlinkInfo",
    "PackageVariablesInfo",
)
load("//pkg/private:util.bzl", "setup_output_files")

rpm_filetype = [".rpm"]

spec_filetype = [".spec", ".spec.in", ".spec.tpl"]

# TODO(nacl): __install, __cp
# {0} is the source, {1} is the dest
#
# TODO(nacl, #292): cp -r does not do the right thing with TreeArtifacts
_INSTALL_FILE_STANZA_FMT = """
install -d %{{buildroot}}/$(dirname {1})
cp {0} %{{buildroot}}/{1}
"""

# TODO(nacl): __install
# {0} is the directory name
#
# This may not be strictly necessary, given that they'll be created in the
# CPIO when rpmbuild processes the `%files` list.
_INSTALL_DIR_STANZA_FMT = """
install -d %{{buildroot}}/{0}
"""

# {0} is the name of the link, {1} is the target, {2} is the desired symlink "mode".
#
# In particular, {2} exists because umasks on symlinks apply on macOS, unlike
# Linux.  You can't even change symlink permissions in Linux; all permissions
# apply to the target instead.
#
# This is not the case in BSDs and macOS.  This comes up because rpmbuild(8)
# does not know about the BSD "lchmod" call, which would otherwise be used to
# set permissions.
#
# This is primarily to ensure that tests pass.  Actually attempting to build
# functional RPMs on macOS in rules_pkg has not yet been attempted at any scale.
#
# XXX: This may not apply all that well to users of cygwin and mingw.  We'll
# deal with that when the time comes.
_INSTALL_SYMLINK_STANZA_FMT = """
%{{__install}} -d %{{buildroot}}/$(dirname {0})
%{{__ln_s}} {1} %{{buildroot}}/{0}
%if "%_host_os" != "linux"
    %{{__chmod}} -h {2} %{{buildroot}}/{0}
%endif
"""

def _package_contents_metadata(origin_label, grouping_label):
    """Named construct for helping to identify conflicting packaged contents"""
    return struct(
        origin = origin_label if origin_label else "<UNKNOWN>",
        group = grouping_label,
    )

def _conflicting_contents_error(destination, from1, from2, attr_name = "srcs"):
    real_from1_origin = "<UNKNOWN>" if not from1.origin else from1.origin
    real_from1_group = "directly" if not from1.group else "from group {}".format(from1.group)
    real_from2_origin = "<UNKNOWN>" if not from2.origin else from2.origin
    real_from2_group = "directly" if not from2.group else "from group {}".format(from2.group)

    message = """Destination {destination} is provided by both (1) {from1_origin} and (2) {from2_origin}; please ensure that each destination is provided by exactly one input.

    (1) {from1_origin} is provided {from1_group}
    (2) {from2_origin} is provided {from2_group}
    """.format(
        destination = destination,
        from1_origin = real_from1_origin,
        from1_group = real_from1_group,
        from2_origin = real_from2_origin,
        from2_group = real_from2_group,
    )

    fail(message, attr_name)

def _make_filetags(attributes, default_filetag = None):
    """Helper function for rendering RPM spec file tags, like

    ```
    %attr(0755, root, root) %dir
    ```
    """
    template = "%attr({mode}, {user}, {group}) {supplied_filetag}"

    mode = attributes.get("mode", "-")
    user = attributes.get("user", "-")
    group = attributes.get("group", "-")

    supplied_filetag = attributes.get("rpm_filetag", default_filetag)

    return template.format(
        mode = mode,
        user = user,
        group = group,
        supplied_filetag = supplied_filetag or "",
    )

def _make_absolute_if_not_already_or_is_macro(path):
    # Make a destination path absolute if it isn't already or if it starts with
    # a macro (assumed to be a value that starts with "%").
    #
    # If the user has provided a macro as the installation destination, assume
    # they know what they're doing.  Specifically, the macro needs to resolve to
    # an absolute path.

    # This may not be the fastest way to do this, but if it becomes a problem
    # this can be inlined easily.
    return path if path.startswith(("/", "%")) else "/" + path

#### Input processing helper functons.

# TODO(nacl, #459): These are redundant with functions and structures in
# pkg/private/pkg_files.bzl.  We should really use the infrastructure provided
# there, but as of writing, it's not quite ready.
def _process_files(pfi, origin_label, grouping_label, file_base, dest_check_map, packaged_directories, rpm_files_list, install_script_pieces):
    for dest, src in pfi.dest_src_map.items():
        metadata = _package_contents_metadata(origin_label, grouping_label)
        if dest in dest_check_map:
            _conflicting_contents_error(dest, metadata, dest_check_map[dest])
        else:
            dest_check_map[dest] = metadata

        abs_dest = _make_absolute_if_not_already_or_is_macro(dest)
        if src.is_directory:
            # Set aside TreeArtifact information for external processing
            #
            # @unsorted-dict-items
            packaged_directories.append({
                "src": src,
                "dest": abs_dest,
                # This doesn't exactly make it extensible, but it saves
                # us from having to having to maintain tag processing
                # code in multiple places.
                "tags": file_base,
            })
        else:
            # Files are well-known.  Take care of them right here.
            rpm_files_list.append(file_base + " " + abs_dest)
            install_script_pieces.append(_INSTALL_FILE_STANZA_FMT.format(
                src.path,
                abs_dest,
            ))

def _process_dirs(pdi, origin_label, grouping_label, file_base, dest_check_map, packaged_directories, rpm_files_list, install_script_pieces):
    for dest in pdi.dirs:
        metadata = _package_contents_metadata(origin_label, grouping_label)
        if dest in dest_check_map:
            _conflicting_contents_error(dest, metadata, dest_check_map[dest])
        else:
            dest_check_map[dest] = metadata

        abs_dirname = _make_absolute_if_not_already_or_is_macro(dest)
        rpm_files_list.append(file_base + " " + abs_dirname)

        install_script_pieces.append(_INSTALL_DIR_STANZA_FMT.format(
            abs_dirname,
        ))

def _process_symlink(psi, origin_label, grouping_label, file_base, dest_check_map, packaged_directories, rpm_files_list, install_script_pieces):
    metadata = _package_contents_metadata(origin_label, grouping_label)
    if psi.destination in dest_check_map:
        _conflicting_contents_error(psi.destination, metadata, dest_check_map[psi.destination])
    else:
        dest_check_map[psi.destination] = metadata

    abs_dest = _make_absolute_if_not_already_or_is_macro(psi.destination)
    rpm_files_list.append(file_base + " " + abs_dest)
    install_script_pieces.append(_INSTALL_SYMLINK_STANZA_FMT.format(
        abs_dest,
        psi.source,
        psi.attributes["mode"],
    ))

#### Rule implementation

def _pkg_rpm_impl(ctx):
    """Implements the pkg_rpm rule."""

    files = []
    tools = []
    args = ["--name=" + ctx.label.name]

    if ctx.attr.debug:
        args.append("--debug")

    if ctx.attr.rpmbuild_path:
        args.append("--rpmbuild=" + ctx.attr.rpmbuild_path)

        # buildifier: disable=print
        print("rpmbuild_path is deprecated. See the README for instructions on how" +
              " to migrate to toolchains")
    else:
        toolchain = ctx.toolchains["@rules_pkg//toolchains:rpmbuild_toolchain_type"].rpmbuild
        if not toolchain.valid:
            fail("The rpmbuild_toolchain is not properly configured: " +
                 toolchain.name)
        if toolchain.path:
            args.append("--rpmbuild=" + toolchain.path)
        else:
            executable_files = toolchain.label[DefaultInfo].files_to_run
            tools.append(executable_files)
            args.append("--rpmbuild=%s" % executable_files.executable.path)

    #### Calculate output file name
    # rpm_name takes precedence over name if provided
    if ctx.attr.package_name:
        rpm_name = ctx.attr.package_name
    else:
        rpm_name = ctx.attr.name

    default_file = ctx.actions.declare_file("{}.rpm".format(rpm_name))

    package_file_name = ctx.attr.package_file_name
    if not package_file_name:
        package_file_name = "%s-%s-%s.%s.rpm" % (
            rpm_name,
            ctx.attr.version,
            ctx.attr.release,
            ctx.attr.architecture,
        )

    outputs, output_file, output_name = setup_output_files(
        ctx,
        package_file_name = package_file_name,
        default_output_file = default_file,
    )

    #### rpm spec "preamble"
    preamble_pieces = []

    preamble_pieces.append("Name: " + rpm_name)

    # Version can be specified by a file or inlined.
    if ctx.attr.version_file:
        if ctx.attr.version:
            fail("Both version and version_file attributes were specified")

        preamble_pieces.append("Version: ${VERSION_FROM_FILE}")
        args.append("--version=@" + ctx.file.version_file.path)
        files.append(ctx.file.version_file)
    elif ctx.attr.version:
        preamble_pieces.append("Version: " + ctx.attr.version)
    else:
        fail("None of the version or version_file attributes were specified")

    # Release can be specified by a file or inlined.
    if ctx.attr.release_file:
        if ctx.attr.release:
            fail("Both release and release_file attributes were specified")

        preamble_pieces.append("Release: ${RELEASE_FROM_FILE}")
        args.append("--release=@" + ctx.file.release_file.path)
        files.append(ctx.file.release_file)
    elif ctx.attr.release:
        preamble_pieces.append("Release: " + ctx.attr.release)
    else:
        fail("None of the release or release_file attributes were specified")

    if ctx.attr.source_date_epoch_file:
        if ctx.attr.source_date_epoch:
            fail("Both source_date_epoch and source_date_epoch_file attributes were specified")
        args.append("--source_date_epoch=@" + ctx.file.source_date_epoch_file.path)
        files.append(ctx.file.source_date_epoch_file)
    elif ctx.attr.source_date_epoch != None:
        args.append("--source_date_epoch=" + str(ctx.attr.source_date_epoch))

    if ctx.attr.summary:
        preamble_pieces.append("Summary: " + ctx.attr.summary)
    if ctx.attr.url:
        preamble_pieces.append("URL: " + ctx.attr.url)
    if ctx.attr.license:
        preamble_pieces.append("License: " + ctx.attr.license)
    if ctx.attr.group:
        preamble_pieces.append("Group: " + ctx.attr.group)
    if ctx.attr.provides:
        preamble_pieces.extend(["Provides: " + p for p in ctx.attr.provides])
    if ctx.attr.conflicts:
        preamble_pieces.extend(["Conflicts: " + c for c in ctx.attr.conflicts])
    if ctx.attr.requires:
        preamble_pieces.extend(["Requires: " + r for r in ctx.attr.requires])
    if ctx.attr.requires_contextual:
        preamble_pieces.extend(
            [
                "Requires({}): {}".format(scriptlet, capability)
                for scriptlet in ctx.attr.requires_contextual.keys()
                for capability in ctx.attr.requires_contextual[scriptlet]
            ],
        )

    # TODO: BuildArch is usually not hardcoded in spec files, unless the package
    # is indeed restricted to a particular CPU architecture, or is actually
    # "noarch".  This will become more of a concern when we start providing
    # source RPMs.
    #
    # In the meantime, this will allow the "architecture" attribute to take
    # effect.
    if ctx.attr.architecture:
        preamble_pieces.append("BuildArch: " + ctx.attr.architecture)

    preamble_file = ctx.actions.declare_file(
        "{}.spec.preamble".format(rpm_name),
    )
    ctx.actions.write(
        output = preamble_file,
        content = "\n".join(preamble_pieces),
    )
    files.append(preamble_file)
    args.append("--preamble=" + preamble_file.path)

    #### %description

    if ctx.attr.description_file:
        if ctx.attr.description:
            fail("Both description and description_file attributes were specified")
        description_file = ctx.file.description_file
    elif ctx.attr.description:
        description_file = ctx.actions.declare_file(
            "{}.spec.description".format(rpm_name),
        )
        ctx.actions.write(
            output = description_file,
            content = ctx.attr.description,
        )
    else:
        fail("None of the description or description_file attributes were specified")

    files.append(description_file)
    args.append("--description=" + description_file.path)

    #### Non-procedurally-generated scriptlets

    substitutions = {}
    if ctx.attr.pre_scriptlet_file:
        if ctx.attr.pre_scriptlet:
            fail("Both pre_scriptlet and pre_scriptlet_file attributes were specified")
        pre_scriptlet_file = ctx.file.pre_scriptlet_file
        files.append(pre_scriptlet_file)
        args.append("--pre_scriptlet=" + pre_scriptlet_file.path)
    elif ctx.attr.pre_scriptlet:
        scriptlet_file = ctx.actions.declare_file(ctx.label.name + ".pre_scriptlet")
        files.append(scriptlet_file)
        ctx.actions.write(scriptlet_file, ctx.attr.pre_scriptlet)
        args.append("--pre_scriptlet=" + scriptlet_file.path)

    if ctx.attr.post_scriptlet_file:
        if ctx.attr.post_scriptlet:
            fail("Both post_scriptlet and post_scriptlet_file attributes were specified")
        post_scriptlet_file = ctx.file.post_scriptlet_file
        files.append(post_scriptlet_file)
        args.append("--post_scriptlet=" + post_scriptlet_file.path)
    elif ctx.attr.post_scriptlet:
        scriptlet_file = ctx.actions.declare_file(ctx.label.name + ".post_scriptlet")
        files.append(scriptlet_file)
        ctx.actions.write(scriptlet_file, ctx.attr.post_scriptlet)
        args.append("--post_scriptlet=" + scriptlet_file.path)

    if ctx.attr.preun_scriptlet_file:
        if ctx.attr.preun_scriptlet:
            fail("Both preun_scriptlet and preun_scriptlet_file attributes were specified")
        preun_scriptlet_file = ctx.file.preun_scriptlet_file
        files.append(preun_scriptlet_file)
        args.append("--preun_scriptlet=" + preun_scriptlet_file.path)
    elif ctx.attr.preun_scriptlet:
        scriptlet_file = ctx.actions.declare_file(ctx.label.name + ".preun_scriptlet")
        files.append(scriptlet_file)
        ctx.actions.write(scriptlet_file, ctx.attr.preun_scriptlet)
        args.append("--preun_scriptlet=" + scriptlet_file.path)

    if ctx.attr.postun_scriptlet_file:
        if ctx.attr.postun_scriptlet:
            fail("Both postun_scriptlet and postun_scriptlet_file attributes were specified")
        postun_scriptlet_file = ctx.file.postun_scriptlet_file
        files.append(postun_scriptlet_file)
        args.append("--postun_scriptlet=" + postun_scriptlet_file.path)
    elif ctx.attr.postun_scriptlet:
        scriptlet_file = ctx.actions.declare_file(ctx.label.name + ".postun_scriptlet")
        files.append(scriptlet_file)
        ctx.actions.write(scriptlet_file, ctx.attr.postun_scriptlet)
        args.append("--postun_scriptlet=" + scriptlet_file.path)

    #### Expand the spec file template; prepare data files

    spec_file = ctx.actions.declare_file("%s.spec" % rpm_name)
    ctx.actions.expand_template(
        template = ctx.file.spec_template,
        output = spec_file,
        substitutions = substitutions,
    )
    args.append("--spec_file=" + spec_file.path)
    files.append(spec_file)

    args.append("--out_file=" + output_file.path)

    # Add data files.
    if ctx.file.changelog:
        files.append(ctx.file.changelog)
        args.append(ctx.file.changelog.path)

    files += ctx.files.srcs

    #### Consistency checking; input processing

    # Ensure that no destinations collide.  RPMs that fail this check may be
    # correct, but the output may also create hard-to-debug issues.  Better to
    # err on the side of correctness here.
    dest_check_map = {}

    # The contents of the "%install" scriptlet
    install_script_pieces = []
    if ctx.attr.debug:
        install_script_pieces.append("set -x")

    # The list of entries in the "%files" list
    rpm_files_list = []

    # Directories (TreeArtifacts) are to be treated differently.  Specifically,
    # since Bazel does not know their contents at analysis time, processing them
    # needs to be delegated to a helper script.  This is done via the
    # _treeartifact_helper script used later on.
    packaged_directories = []

    # Iterate over all incoming data, checking for conflicts and creating
    # datasets as we go from the actual contents of the RPM.
    #
    # This is a naive approach to script creation is almost guaranteed to
    # produce an installation script that is longer than necessary.  A better
    # implementation would track directories that are created and ensure that
    # they aren't unnecessarily recreated.
    for dep in ctx.attr.srcs:
        # NOTE: This does not detect cases where directories are not named
        # consistently.  For example, all of these may collide in reality, but
        # won't be detected by the below:
        #
        # 1) usr/lib/libfoo.a
        # 2) /usr/lib/libfoo.a
        # 3) %{_libdir}/libfoo.a
        #
        # The most important thing, regardless of how these checks below are
        # done, is to be consistent with path naming conventions.
        #
        # There is also an unsolved question of determining how to handle
        # subdirectories of "PackageFilesInfo" targets that are actually
        # directories.

        # dep is a Target
        if PackageFilesInfo in dep:
            _process_files(
                dep[PackageFilesInfo],
                dep.label,  # origin label
                None,  # group label
                _make_filetags(dep[PackageFilesInfo].attributes),  # file_base
                dest_check_map,
                packaged_directories,
                rpm_files_list,
                install_script_pieces,
            )

        if PackageDirsInfo in dep:
            _process_dirs(
                dep[PackageDirsInfo],
                dep.label,  # origin label
                None,  # group label
                _make_filetags(dep[PackageDirsInfo].attributes, "%dir"),  # file_base
                dest_check_map,
                packaged_directories,
                rpm_files_list,
                install_script_pieces,
            )

        if PackageSymlinkInfo in dep:
            _process_symlink(
                dep[PackageSymlinkInfo],
                dep.label,  # origin label
                None,  # group label
                _make_filetags(dep[PackageSymlinkInfo].attributes),  # file_base
                dest_check_map,
                packaged_directories,
                rpm_files_list,
                install_script_pieces,
            )

        if PackageFilegroupInfo in dep:
            pfg_info = dep[PackageFilegroupInfo]
            for entry, origin in pfg_info.pkg_files:
                file_base = _make_filetags(entry.attributes)
                _process_files(
                    entry,
                    origin,
                    dep.label,
                    file_base,
                    dest_check_map,
                    packaged_directories,
                    rpm_files_list,
                    install_script_pieces,
                )
            for entry, origin in pfg_info.pkg_dirs:
                file_base = _make_filetags(entry.attributes, "%dir")
                _process_dirs(
                    entry,
                    origin,
                    dep.label,
                    file_base,
                    dest_check_map,
                    packaged_directories,
                    rpm_files_list,
                    install_script_pieces,
                )

            for entry, origin in pfg_info.pkg_symlinks:
                file_base = _make_filetags(entry.attributes)
                _process_symlink(
                    entry,
                    origin,
                    dep.label,
                    file_base,
                    dest_check_map,
                    packaged_directories,
                    rpm_files_list,
                    install_script_pieces,
                )

    #### Procedurally-generated scripts/lists (%install, %files)

    # We need to write these out regardless of whether we are using
    # TreeArtifacts.  That stage will use these files as inputs.
    install_script = ctx.actions.declare_file("{}.spec.install".format(rpm_name))
    ctx.actions.write(
        install_script,
        "\n".join(install_script_pieces),
    )

    rpm_files_file = ctx.actions.declare_file(
        "{}.spec.files".format(rpm_name),
    )
    ctx.actions.write(
        rpm_files_file,
        "\n".join(rpm_files_list),
    )

    # TreeArtifact processing work
    if packaged_directories:
        packaged_directories_file = ctx.actions.declare_file("{}.spec.packaged_directories.json".format(rpm_name))

        packaged_directories_inputs = [d["src"] for d in packaged_directories]

        # This isn't the prettiest thing in the world, but it works.  Bazel
        # needs the "File" data to pass to the command, but "File"s cannot be
        # JSONified.
        #
        # This data isn't used outside of this block, so it's probably fine.
        # Cleaner code would separate the JSONable values from the File type (in
        # a struct, probably).
        for d in packaged_directories:
            d["src"] = d["src"].path

        ctx.actions.write(packaged_directories_file, json.encode(packaged_directories))

        # Overwrite all following uses of the install script and files lists to
        # use the ones generated below.
        install_script_old = install_script
        install_script = ctx.actions.declare_file("{}.spec.install.with_dirs".format(rpm_name))
        rpm_files_file_old = rpm_files_file
        rpm_files_file = ctx.actions.declare_file("{}.spec.files.with_dirs".format(rpm_name))

        input_files = [packaged_directories_file, install_script_old, rpm_files_file_old]
        output_files = [install_script, rpm_files_file]

        helper_args = ctx.actions.args()
        helper_args.add_all(input_files)
        helper_args.add_all(output_files)

        ctx.actions.run(
            executable = ctx.executable._treeartifact_helper,
            use_default_shell_env = True,
            arguments = [helper_args],
            inputs = input_files + packaged_directories_inputs,
            outputs = output_files,
            progress_message = "Generating RPM TreeArtifact Data " + str(ctx.label),
        )

    # And then we're done.  Yay!

    files.append(install_script)
    args.append("--install_script=" + install_script.path)

    files.append(rpm_files_file)
    args.append("--file_list=" + rpm_files_file.path)

    #### Remaining setup

    additional_rpmbuild_args = []
    if ctx.attr.binary_payload_compression:
        additional_rpmbuild_args.extend([
            "--define",
            "_binary_payload {}".format(ctx.attr.binary_payload_compression),
        ])

    args.extend(["--rpmbuild_arg=" + a for a in additional_rpmbuild_args])

    for f in ctx.files.srcs:
        args.append(f.path)

    #### Call the generator script.

    ctx.actions.run(
        mnemonic = "MakeRpm",
        executable = ctx.executable._make_rpm,
        use_default_shell_env = True,
        arguments = args,
        inputs = files,
        outputs = [output_file],
        env = {
            "LANG": "en_US.UTF-8",
            "LC_CTYPE": "UTF-8",
            "PYTHONIOENCODING": "UTF-8",
            "PYTHONUTF8": "1",
        },
        tools = tools,
    )

    return [
        DefaultInfo(
            files = depset(outputs),
        ),
        PackageArtifactInfo(
            file = output_file,
            file_name = output_name,
            label = ctx.label.name,
        ),
    ]

# Define the rule.
pkg_rpm = rule(
    doc = """Creates an RPM format package via `pkg_filegroup` and friends.

    The uses the outputs of the rules in `mappings.bzl` to construct arbitrary
    RPM packages.  Attributes of this rule provide preamble information and
    scriptlets, which are then used to compose a valid RPM spec file.

    This rule will fail at analysis time if:

    - Any `srcs` input creates the same destination, regardless of other
      attributes.

    This rule only functions on UNIXy platforms. The following tools must be
    available on your system for this to function properly:

    - `rpmbuild` (as specified in `rpmbuild_path`, or available in `$PATH`)

    - GNU coreutils.  BSD coreutils may work, but are not tested.

    To set RPM file attributes (like `%config` and friends), set the
    `rpm_filetag` in corresponding packaging rule (`pkg_files`, etc).  The value
    is prepended with "%" and added to the `%files` list, for example:

    ```
    attrs = {"rpm_filetag": ("config(missingok, noreplace)",)},
    ```

    Is the equivalent to `%config(missingok, noreplace)` in the `%files` list.

    """,
    # @unsorted-dict-items
    attrs = {
        "package_name": attr.string(
            doc = """Optional; RPM name override.

            If not provided, the `name` attribute of this rule will be used
            instead.

            This influences values like the spec file name.
            """,
        ),
        "package_file_name": attr.string(
            doc = """See 'Common Attributes' in the rules_pkg reference.

            If this is not provided, the package file given a NVRA-style
            (name-version-release.arch) output, which is preferred by most RPM
            repositories.
            """,
        ),
        "package_variables": attr.label(
            doc = "See 'Common Attributes' in the rules_pkg reference",
            providers = [PackageVariablesInfo],
        ),
        "version": attr.string(
            doc = """RPM "Version" tag.

            Exactly one of `version` or `version_file` must be provided.
            """,
        ),
        "version_file": attr.label(
            doc = """File containing RPM "Version" tag.""",
            allow_single_file = True,
        ),
        "release": attr.string(
            doc = """RPM "Release" tag

            Exactly one of `release` or `release_file` must be provided.
            """,
        ),
        "release_file": attr.label(
            doc = """File containing RPM "Release" tag.""",
            allow_single_file = True,
        ),
        "group": attr.string(
            doc = """Optional; RPM "Group" tag.

            NOTE: some distributions (as of writing, Fedora > 17 and CentOS/RHEL
            > 5) have deprecated this tag.  Other distributions may require it,
            but it is harmless in any case.

            """,
        ),
        "source_date_epoch": attr.int(
            doc = """Value to export as SOURCE_DATE_EPOCH to facilitate repr

            Implicitly sets the `%clamp_mtime_to_source_date_epoch` in the
            subordinate call to `rpmbuild` to facilitate more consistent in-RPM
            file timestamps.
            """,
        ),
        "source_date_epoch_file": attr.label(
            doc = """File containing the SOURCE_DATE_EPOCH value.

            Implicitly sets the `%clamp_mtime_to_source_date_epoch` in the
            subordinate call to `rpmbuild` to facilitate more consistent in-RPM
            file timestamps.
            """,
            allow_single_file = True,
        ),
        # TODO(nacl): this should be augmented to use bazel platforms, and
        # should not really set BuildArch.
        #
        # TODO(nacl): This, uh, is more required than it looks.  It influences
        # the "A" part of the "NVRA" RPM file name, and RPMs file names look
        # funny if it's not provided.  The contents of the RPM are believed to
        # be set as expected, though.
        "architecture": attr.string(
            doc = """Package architecture.

            This currently sets the `BuildArch` tag, which influences the output
            architecture of the package.

            Typically, `BuildArch` only needs to be set when the package is
            known to be cross-platform (e.g. written in an interpreted
            language), or, less common, when it is known that the application is
            only valid for specific architectures.

            When no attribute is provided, this will default to your host's
            architecture.  This is usually what you want.

            """,
        ),
        "license": attr.string(
            doc = """RPM "License" tag.

            The software license for the code distributed in this package.

            The underlying RPM builder requires you to put something here; if
            your package is not going to be distributed, feel free to set this
            to something like "Internal".

            """,
            mandatory = True,
        ),
        "summary": attr.string(
            doc = """RPM "Summary" tag.

            One-line summary of this package.  Must not contain newlines.

            """,
            mandatory = True,
        ),
        "url": attr.string(
            doc = """RPM "URL" tag; this project/vendor's home on the Internet.""",
        ),
        "description": attr.string(
            doc = """Multi-line description of this package, corresponds to RPM %description.

            Exactly one of `description` or `description_file` must be provided.
            """,
        ),
        "description_file": attr.label(
            doc = """File containing a multi-line description of this package, corresponds to RPM
            %description.""",
            allow_single_file = True,
        ),
        # TODO: this isn't consumed yet
        "changelog": attr.label(
            allow_single_file = True,
        ),
        "srcs": attr.label_list(
            doc = """Mapping groups to include in this RPM.

            These are typically brought into life as `pkg_filegroup`s.
            """,
            mandatory = True,
            providers = [
                [PackageDirsInfo],
                [PackageFilesInfo],
                [PackageFilegroupInfo],
                [PackageSymlinkInfo],
            ],
        ),
        "debug": attr.bool(
            doc = """Debug the RPM helper script and RPM generation""",
            default = False,
        ),
        "pre_scriptlet": attr.string(
            doc = """RPM `%pre` scriptlet.  Currently only allowed to be a shell script.

            `pre_scriptlet` and `pre_scriptlet_file` are mutually exclusive.
            """,
        ),
        "pre_scriptlet_file": attr.label(
            doc = """File containing the RPM `%pre` scriptlet""",
            allow_single_file = True,
        ),
        "post_scriptlet": attr.string(
            doc = """RPM `%post` scriptlet.  Currently only allowed to be a shell script.

            `post_scriptlet` and `post_scriptlet_file` are mutually exclusive.
            """,
        ),
        "post_scriptlet_file": attr.label(
            doc = """File containing the RPM `%post` scriptlet""",
            allow_single_file = True,
        ),
        "preun_scriptlet": attr.string(
            doc = """RPM `%preun` scriptlet.  Currently only allowed to be a shell script.

            `preun_scriptlet` and `preun_scriptlet_file` are mutually exclusive.
            """,
        ),
        "preun_scriptlet_file": attr.label(
            doc = """File containing the RPM `%preun` scriptlet""",
            allow_single_file = True,
        ),
        "postun_scriptlet": attr.string(
            doc = """RPM `%postun` scriptlet.  Currently only allowed to be a shell script.

            `postun_scriptlet` and `postun_scriptlet_file` are mutually exclusive.
            """,
        ),
        "postun_scriptlet_file": attr.label(
            doc = """File containing the RPM `%postun` scriptlet""",
            allow_single_file = True,
        ),
        "conflicts": attr.string_list(
            doc = """List of capabilities that conflict with this package when it is installed.

            Cooresponds to the "Conflicts" preamble tag.

            See also: https://rpm.org/user_doc/dependencies.html
            """,
        ),
        "provides": attr.string_list(
            doc = """List of rpm capabilities that this package provides.

            Cooresponds to the "Provides" preamble tag.

            See also: https://rpm.org/user_doc/dependencies.html
            """,
        ),
        "requires": attr.string_list(
            doc = """List of rpm capability expressions that this package requires.

            Corresponds to the "Requires" preamble tag.

            See also: https://rpm.org/user_doc/dependencies.html
            """,
        ),
        "requires_contextual": attr.string_list_dict(
            doc = """Contextualized requirement specifications

            This is a map of various properties (often scriptlet types) to
            capability name specifications, e.g.:

            ```python
            {"pre": ["GConf2"],"post": ["GConf2"], "postun": ["GConf2"]}
            ```

            Which causes the below to be added to the spec file's preamble:

            ```
            Requires(pre): GConf2
            Requires(post): GConf2
            Requires(postun): GConf2
            ```

            This is most useful for ensuring that required tools exist when
            scriptlets are run, although there may be other valid use cases.
            Valid keys for this attribute may include, but are not limited to:

            - `pre`
            - `post`
            - `preun`
            - `postun`
            - `pretrans`
            - `posttrans`

            For capabilities that are always required by packages at runtime,
            use the `requires` attribute instead.

            See also: https://rpm.org/user_doc/more_dependencies.html

            NOTE: `pkg_rpm` does not check if the keys of this dictionary are
            acceptable to `rpm(8)`.
            """,
        ),
        "spec_template": attr.label(
            doc = """Spec file template.

            Use this if you need to add additional logic to your spec files that
            is not available by default.

            In most cases, you should not need to override this attribute.
            """,
            allow_single_file = spec_filetype,
            default = "//pkg/rpm:template.spec.tpl",
        ),
        "binary_payload_compression": attr.string(
            doc = """Compression mode used for this RPM

            Must be a form that `rpmbuild(8)` knows how to process, which will
            depend on the version of `rpmbuild` in use.  The value corresponds
            to the `%_binary_payload` macro and is set on the `rpmbuild(8)`
            command line if provided.

            Some examples of valid values (which may not be supported on your
            system) can be found [here](https://git.io/JU9Wg).  On CentOS
            systems (also likely Red Hat and Fedora), you can find some
            supported values by looking for `%_binary_payload` in
            `/usr/lib/rpm/macros`.  Other systems have similar files and
            configurations.

            If not provided, the compression mode will be computed by `rpmbuild`
            itself.  Defaults may vary per distribution or build of `rpm`;
            consult the relevant documentation for more details.

            WARNING: Bazel is currently not aware of action threading requirements
            for non-test actions.  Using threaded compression may result in
            overcommitting your system.
            """,
        ),
        "rpmbuild_path": attr.string(
            doc = """Path to a `rpmbuild` binary.  Deprecated in favor of the rpmbuild toolchain""",
        ),
        # Implicit dependencies.
        "_make_rpm": attr.label(
            default = Label("//pkg:make_rpm"),
            cfg = "exec",
            executable = True,
            allow_files = True,
        ),
        "_treeartifact_helper": attr.label(
            default = Label("//pkg/rpm:augment_rpm_files_install"),
            cfg = "exec",
            executable = True,
            allow_files = True,
        ),
    },
    executable = False,
    implementation = _pkg_rpm_impl,
    provides = [PackageArtifactInfo],
    toolchains = ["@rules_pkg//toolchains:rpmbuild_toolchain_type"],
)
