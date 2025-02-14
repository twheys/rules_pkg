# rules_pkg - 0.6.0

<div class="toc">
  <h2>Common Attributes</h2>
  <ul>
    <li><a href="#common">Package attributes</a></li>
    <li><a href="#mapping-attrs">File attributes</a></li>
  </ul>

  <h2>Packaging Rules</h2>
  <ul>
    <li><a href="#pkg_deb">pkg_deb</a></li>
    <li><a href="#pkg_tar">pkg_tar</a></li>
    <li><a href="#pkg_rpm">pkg_rpm</a></li>
    <li><a href="#pkg_zip">pkg_zip</a></li>
  </ul>

  <h2>File Tree Creation Rules</h2>
  <ul>
    <li><a href="#filter_directory">filter_directory</a></li>
    <li><a href="#pkg_filegroup">pkg_filegroup</a></li>
    <li><a href="#pkg_files">pkg_files</a></li>
    <li><a href="#pkg_mkdirs">pkg_mkdirs</a></li>
    <li><a href="#pkg_mklink">pkg_mklink</a></li>
    <li><a href="#pkg_attributes">pkg_attributes</a></li>
    <li><a href="#strip_prefix.files_only">strip_prefix</a></li>
  </ul>
</div>
<a name="common"></a>

### Common Attributes

These attributes are used in several rules within this module.

**ATTRIBUTES**

| Name              | Description                                                                                                                                                                     | Type                                                               | Mandatory       | Default                                   |
| :-------------    | :-------------                                                                                                                                                                  | :-------------:                                                    | :-------------: | :-------------                            |
| out               | Name of the output file. This file will always be created and used to access the package content. If `package_file_name` is also specified, `out` will be a symlink.            | String                                                             | required        |                                           |
| package_file_name | The name of the file which will contain the package. The name may contain variables in the form `{var}`. The values for substitution are specified through `package_variables`. | String                                                             | optional        | package type specific                     |
| package_variables | A target that provides `PackageVariablesInfo` to substitute into `package_file_name`.                                                                                           | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional        | None                                      |
| attributes        | Attributes to set on entities created within packages.  Not to be confused with bazel rule attributes.  See 'Mapping "Attributes"' below                                        | Undefined.                                                         | optional        | Varies.  Consult individual rule documentation for details. |

See
[examples/naming_package_files](https://github.com/bazelbuild/rules_pkg/tree/main/examples/naming_package_files)
for examples of how `out`, `package_file_name`, and `package_variables`
interact.

<a name="mapping-attrs"></a>
### Mapping "Attributes"

The "attributes" attribute specifies properties of package contents as used in
rules such as `pkg_files`, and `pkg_mkdirs`.  These allow fine-grained control
of the contents of your package.  For example:

```python
attributes = pkg_attributes(
    mode = "0644",
    user = "root",
    group = "wheel",
    my_custom_attribute = "some custom value",
)
```

`mode`, `user`, and `group` correspond to common UNIX-style filesystem
permissions.  Attributes should always be specified using the `pkg_attributes`
helper macro.

Each mapping rule has some default mapping attributes.  At this time, the only
default is "mode", which will be set if it is not otherwise overridden by the user.

If `user` and `group` are not specified, then defaults for them will be chosen
by the underlying package builder.  Any specific behavior from package builders
should not be relied upon.

Any other attributes should be specified as additional arguments to
`pkg_attributes`.
<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_deb"></a>

## pkg_deb

<pre>
pkg_deb(<a href="#pkg_deb-name">name</a>, <a href="#pkg_deb-archive_name">archive_name</a>, <a href="#pkg_deb-kwargs">kwargs</a>)
</pre>

Creates a deb file. See pkg_deb_impl.

**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  <p align="center"> - </p>   |  none |
| archive_name |  <p align="center"> - </p>   |  <code>None</code> |
| kwargs |  <p align="center"> - </p>   |  none |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_deb_impl"></a>

## pkg_deb_impl

<pre>
pkg_deb_impl(<a href="#pkg_deb_impl-name">name</a>, <a href="#pkg_deb_impl-architecture">architecture</a>, <a href="#pkg_deb_impl-architecture_file">architecture_file</a>, <a href="#pkg_deb_impl-breaks">breaks</a>, <a href="#pkg_deb_impl-built_using">built_using</a>, <a href="#pkg_deb_impl-built_using_file">built_using_file</a>,
             <a href="#pkg_deb_impl-conffiles">conffiles</a>, <a href="#pkg_deb_impl-conffiles_file">conffiles_file</a>, <a href="#pkg_deb_impl-config">config</a>, <a href="#pkg_deb_impl-conflicts">conflicts</a>, <a href="#pkg_deb_impl-data">data</a>, <a href="#pkg_deb_impl-depends">depends</a>, <a href="#pkg_deb_impl-depends_file">depends_file</a>, <a href="#pkg_deb_impl-description">description</a>,
             <a href="#pkg_deb_impl-description_file">description_file</a>, <a href="#pkg_deb_impl-distribution">distribution</a>, <a href="#pkg_deb_impl-enhances">enhances</a>, <a href="#pkg_deb_impl-homepage">homepage</a>, <a href="#pkg_deb_impl-maintainer">maintainer</a>, <a href="#pkg_deb_impl-out">out</a>, <a href="#pkg_deb_impl-package">package</a>,
             <a href="#pkg_deb_impl-package_file_name">package_file_name</a>, <a href="#pkg_deb_impl-package_variables">package_variables</a>, <a href="#pkg_deb_impl-postinst">postinst</a>, <a href="#pkg_deb_impl-postrm">postrm</a>, <a href="#pkg_deb_impl-predepends">predepends</a>, <a href="#pkg_deb_impl-preinst">preinst</a>, <a href="#pkg_deb_impl-prerm">prerm</a>,
             <a href="#pkg_deb_impl-priority">priority</a>, <a href="#pkg_deb_impl-provides">provides</a>, <a href="#pkg_deb_impl-recommends">recommends</a>, <a href="#pkg_deb_impl-replaces">replaces</a>, <a href="#pkg_deb_impl-section">section</a>, <a href="#pkg_deb_impl-suggests">suggests</a>, <a href="#pkg_deb_impl-templates">templates</a>, <a href="#pkg_deb_impl-triggers">triggers</a>,
             <a href="#pkg_deb_impl-urgency">urgency</a>, <a href="#pkg_deb_impl-version">version</a>, <a href="#pkg_deb_impl-version_file">version_file</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| architecture |  Package architecture. Must not be used with architecture_file.   | String | optional | "all" |
| architecture_file |  File that contains the package architecture.             Must not be used with architecture.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| breaks |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| built_using |  The tool that were used to build this package provided either inline (with built_using) or from a file (with built_using_file).   | String | optional | "" |
| built_using_file |  The tool that were used to build this package provided either inline (with built_using) or from a file (with built_using_file).   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| conffiles |  The list of conffiles or a file containing one conffile per line. Each item is an absolute path on the target system where the deb is installed. See https://www.debian.org/doc/debian-policy/ch-files.html#s-config-files.   | List of strings | optional | [] |
| conffiles_file |  The list of conffiles or a file containing one conffile per line. Each item is an absolute path on the target system where the deb is installed. See https://www.debian.org/doc/debian-policy/ch-files.html#s-config-files.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| config |  config file used for debconf integration.             See https://www.debian.org/doc/debian-policy/ch-binary.html#prompting-in-maintainer-scripts.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| conflicts |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| data |  A tar file that contains the data for the debian package.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| depends |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| depends_file |  File that contains a list of package dependencies. Must not be used with <code>depends</code>.             See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| description |  The package description. Must not be used with <code>description_file</code>.   | String | optional | "" |
| description_file |  The package description. Must not be used with <code>description</code>.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| distribution |  "distribution: See http://www.debian.org/doc/debian-policy.   | String | optional | "unstable" |
| enhances |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| homepage |  The homepage of the project.   | String | optional | "" |
| maintainer |  The maintainer of the package.   | String | required |  |
| out |  See Common Attributes   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| package |  The name of the package   | String | required |  |
| package_file_name |  See Common Attributes.             Default: "{package}-{version}-{architecture}.deb   | String | optional | "" |
| package_variables |  See Common Attributes   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| postinst |  The post-install script for the package.             See http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| postrm |  The post-remove script for the package.             See http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| predepends |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| preinst |  "The pre-install script for the package.             See http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| prerm |  The pre-remove script for the package.             See http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| priority |  The priority of the package.             See http://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities.   | String | optional | "" |
| provides |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| recommends |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| replaces |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| section |  The section of the package.             See http://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections.   | String | optional | "" |
| suggests |  See http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps.   | List of strings | optional | [] |
| templates |  templates file used for debconf integration.             See https://www.debian.org/doc/debian-policy/ch-binary.html#prompting-in-maintainer-scripts.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| triggers |  triggers file for configuring installation events exchanged by packages.             See https://wiki.debian.org/DpkgTriggers.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| urgency |  "urgency: See http://www.debian.org/doc/debian-policy.   | String | optional | "medium" |
| version |  Package version. Must not be used with <code>version_file</code>.   | String | optional | "" |
| version_file |  File that contains the package version.             Must not be used with <code>version</code>.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_rpm"></a>

## pkg_rpm

<pre>
pkg_rpm(<a href="#pkg_rpm-name">name</a>, <a href="#pkg_rpm-architecture">architecture</a>, <a href="#pkg_rpm-binary_payload_compression">binary_payload_compression</a>, <a href="#pkg_rpm-changelog">changelog</a>, <a href="#pkg_rpm-conflicts">conflicts</a>, <a href="#pkg_rpm-debug">debug</a>, <a href="#pkg_rpm-description">description</a>,
        <a href="#pkg_rpm-description_file">description_file</a>, <a href="#pkg_rpm-group">group</a>, <a href="#pkg_rpm-license">license</a>, <a href="#pkg_rpm-package_file_name">package_file_name</a>, <a href="#pkg_rpm-package_name">package_name</a>, <a href="#pkg_rpm-package_variables">package_variables</a>,
        <a href="#pkg_rpm-post_scriptlet">post_scriptlet</a>, <a href="#pkg_rpm-post_scriptlet_file">post_scriptlet_file</a>, <a href="#pkg_rpm-postun_scriptlet">postun_scriptlet</a>, <a href="#pkg_rpm-postun_scriptlet_file">postun_scriptlet_file</a>, <a href="#pkg_rpm-pre_scriptlet">pre_scriptlet</a>,
        <a href="#pkg_rpm-pre_scriptlet_file">pre_scriptlet_file</a>, <a href="#pkg_rpm-preun_scriptlet">preun_scriptlet</a>, <a href="#pkg_rpm-preun_scriptlet_file">preun_scriptlet_file</a>, <a href="#pkg_rpm-provides">provides</a>, <a href="#pkg_rpm-release">release</a>, <a href="#pkg_rpm-release_file">release_file</a>,
        <a href="#pkg_rpm-requires">requires</a>, <a href="#pkg_rpm-requires_contextual">requires_contextual</a>, <a href="#pkg_rpm-rpmbuild_path">rpmbuild_path</a>, <a href="#pkg_rpm-source_date_epoch">source_date_epoch</a>, <a href="#pkg_rpm-source_date_epoch_file">source_date_epoch_file</a>,
        <a href="#pkg_rpm-spec_template">spec_template</a>, <a href="#pkg_rpm-srcs">srcs</a>, <a href="#pkg_rpm-summary">summary</a>, <a href="#pkg_rpm-url">url</a>, <a href="#pkg_rpm-version">version</a>, <a href="#pkg_rpm-version_file">version_file</a>)
</pre>

Creates an RPM format package via `pkg_filegroup` and friends.

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

    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| architecture |  Package architecture.<br><br>            This currently sets the <code>BuildArch</code> tag, which influences the output             architecture of the package.<br><br>            Typically, <code>BuildArch</code> only needs to be set when the package is             known to be cross-platform (e.g. written in an interpreted             language), or, less common, when it is known that the application is             only valid for specific architectures.<br><br>            When no attribute is provided, this will default to your host's             architecture.  This is usually what you want.   | String | optional | "" |
| binary_payload_compression |  Compression mode used for this RPM<br><br>            Must be a form that <code>rpmbuild(8)</code> knows how to process, which will             depend on the version of <code>rpmbuild</code> in use.  The value corresponds             to the <code>%_binary_payload</code> macro and is set on the <code>rpmbuild(8)</code>             command line if provided.<br><br>            Some examples of valid values (which may not be supported on your             system) can be found [here](https://git.io/JU9Wg).  On CentOS             systems (also likely Red Hat and Fedora), you can find some             supported values by looking for <code>%_binary_payload</code> in             <code>/usr/lib/rpm/macros</code>.  Other systems have similar files and             configurations.<br><br>            If not provided, the compression mode will be computed by <code>rpmbuild</code>             itself.  Defaults may vary per distribution or build of <code>rpm</code>;             consult the relevant documentation for more details.<br><br>            WARNING: Bazel is currently not aware of action threading requirements             for non-test actions.  Using threaded compression may result in             overcommitting your system.   | String | optional | "" |
| changelog |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| conflicts |  List of capabilities that conflict with this package when it is installed.<br><br>            Cooresponds to the "Conflicts" preamble tag.<br><br>            See also: https://rpm.org/user_doc/dependencies.html   | List of strings | optional | [] |
| debug |  Debug the RPM helper script and RPM generation   | Boolean | optional | False |
| description |  Multi-line description of this package, corresponds to RPM %description.<br><br>            Exactly one of <code>description</code> or <code>description_file</code> must be provided.   | String | optional | "" |
| description_file |  File containing a multi-line description of this package, corresponds to RPM             %description.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| group |  Optional; RPM "Group" tag.<br><br>            NOTE: some distributions (as of writing, Fedora &gt; 17 and CentOS/RHEL             &gt; 5) have deprecated this tag.  Other distributions may require it,             but it is harmless in any case.   | String | optional | "" |
| license |  RPM "License" tag.<br><br>            The software license for the code distributed in this package.<br><br>            The underlying RPM builder requires you to put something here; if             your package is not going to be distributed, feel free to set this             to something like "Internal".   | String | required |  |
| package_file_name |  See 'Common Attributes' in the rules_pkg reference.<br><br>            If this is not provided, the package file given a NVRA-style             (name-version-release.arch) output, which is preferred by most RPM             repositories.   | String | optional | "" |
| package_name |  Optional; RPM name override.<br><br>            If not provided, the <code>name</code> attribute of this rule will be used             instead.<br><br>            This influences values like the spec file name.   | String | optional | "" |
| package_variables |  See 'Common Attributes' in the rules_pkg reference   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| post_scriptlet |  RPM <code>%post</code> scriptlet.  Currently only allowed to be a shell script.<br><br>            <code>post_scriptlet</code> and <code>post_scriptlet_file</code> are mutually exclusive.   | String | optional | "" |
| post_scriptlet_file |  File containing the RPM <code>%post</code> scriptlet   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| postun_scriptlet |  RPM <code>%postun</code> scriptlet.  Currently only allowed to be a shell script.<br><br>            <code>postun_scriptlet</code> and <code>postun_scriptlet_file</code> are mutually exclusive.   | String | optional | "" |
| postun_scriptlet_file |  File containing the RPM <code>%postun</code> scriptlet   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| pre_scriptlet |  RPM <code>%pre</code> scriptlet.  Currently only allowed to be a shell script.<br><br>            <code>pre_scriptlet</code> and <code>pre_scriptlet_file</code> are mutually exclusive.   | String | optional | "" |
| pre_scriptlet_file |  File containing the RPM <code>%pre</code> scriptlet   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| preun_scriptlet |  RPM <code>%preun</code> scriptlet.  Currently only allowed to be a shell script.<br><br>            <code>preun_scriptlet</code> and <code>preun_scriptlet_file</code> are mutually exclusive.   | String | optional | "" |
| preun_scriptlet_file |  File containing the RPM <code>%preun</code> scriptlet   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| provides |  List of rpm capabilities that this package provides.<br><br>            Cooresponds to the "Provides" preamble tag.<br><br>            See also: https://rpm.org/user_doc/dependencies.html   | List of strings | optional | [] |
| release |  RPM "Release" tag<br><br>            Exactly one of <code>release</code> or <code>release_file</code> must be provided.   | String | optional | "" |
| release_file |  File containing RPM "Release" tag.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| requires |  List of rpm capability expressions that this package requires.<br><br>            Corresponds to the "Requires" preamble tag.<br><br>            See also: https://rpm.org/user_doc/dependencies.html   | List of strings | optional | [] |
| requires_contextual |  Contextualized requirement specifications<br><br>            This is a map of various properties (often scriptlet types) to             capability name specifications, e.g.:<br><br>            <pre><code>python             {"pre": ["GConf2"],"post": ["GConf2"], "postun": ["GConf2"]}             </code></pre><br><br>            Which causes the below to be added to the spec file's preamble:<br><br>            <pre><code>             Requires(pre): GConf2             Requires(post): GConf2             Requires(postun): GConf2             </code></pre><br><br>            This is most useful for ensuring that required tools exist when             scriptlets are run, although there may be other valid use cases.             Valid keys for this attribute may include, but are not limited to:<br><br>            - <code>pre</code>             - <code>post</code>             - <code>preun</code>             - <code>postun</code>             - <code>pretrans</code>             - <code>posttrans</code><br><br>            For capabilities that are always required by packages at runtime,             use the <code>requires</code> attribute instead.<br><br>            See also: https://rpm.org/user_doc/more_dependencies.html<br><br>            NOTE: <code>pkg_rpm</code> does not check if the keys of this dictionary are             acceptable to <code>rpm(8)</code>.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> List of strings</a> | optional | {} |
| rpmbuild_path |  Path to a <code>rpmbuild</code> binary.  Deprecated in favor of the rpmbuild toolchain   | String | optional | "" |
| source_date_epoch |  Value to export as SOURCE_DATE_EPOCH to facilitate reproducible builds<br><br>            Implicitly sets the <code>%clamp_mtime_to_source_date_epoch</code> in the             subordinate call to <code>rpmbuild</code> to facilitate more consistent in-RPM             file timestamps.<br><br>            Negative values (like the default) disable this feature.   | Integer | optional | -1 |
| source_date_epoch_file |  File containing the SOURCE_DATE_EPOCH value.<br><br>            Implicitly sets the <code>%clamp_mtime_to_source_date_epoch</code> in the             subordinate call to <code>rpmbuild</code> to facilitate more consistent in-RPM             file timestamps.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| spec_template |  Spec file template.<br><br>            Use this if you need to add additional logic to your spec files that             is not available by default.<br><br>            In most cases, you should not need to override this attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | //pkg/rpm:template.spec.tpl |
| srcs |  Mapping groups to include in this RPM.<br><br>            These are typically brought into life as <code>pkg_filegroup</code>s.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| summary |  RPM "Summary" tag.<br><br>            One-line summary of this package.  Must not contain newlines.   | String | required |  |
| url |  RPM "URL" tag; this project/vendor's home on the Internet.   | String | optional | "" |
| version |  RPM "Version" tag.<br><br>            Exactly one of <code>version</code> or <code>version_file</code> must be provided.   | String | optional | "" |
| version_file |  File containing RPM "Version" tag.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_tar"></a>

## pkg_tar

<pre>
pkg_tar(<a href="#pkg_tar-name">name</a>, <a href="#pkg_tar-kwargs">kwargs</a>)
</pre>

Creates a .tar file. See pkg_tar_impl.

**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  <p align="center"> - </p>   |  none |
| kwargs |  <p align="center"> - </p>   |  none |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_tar_impl"></a>

## pkg_tar_impl

<pre>
pkg_tar_impl(<a href="#pkg_tar_impl-name">name</a>, <a href="#pkg_tar_impl-build_tar">build_tar</a>, <a href="#pkg_tar_impl-compressor">compressor</a>, <a href="#pkg_tar_impl-compressor_args">compressor_args</a>, <a href="#pkg_tar_impl-deps">deps</a>, <a href="#pkg_tar_impl-empty_dirs">empty_dirs</a>, <a href="#pkg_tar_impl-empty_files">empty_files</a>, <a href="#pkg_tar_impl-extension">extension</a>,
             <a href="#pkg_tar_impl-files">files</a>, <a href="#pkg_tar_impl-include_runfiles">include_runfiles</a>, <a href="#pkg_tar_impl-mode">mode</a>, <a href="#pkg_tar_impl-modes">modes</a>, <a href="#pkg_tar_impl-mtime">mtime</a>, <a href="#pkg_tar_impl-out">out</a>, <a href="#pkg_tar_impl-owner">owner</a>, <a href="#pkg_tar_impl-ownername">ownername</a>, <a href="#pkg_tar_impl-ownernames">ownernames</a>, <a href="#pkg_tar_impl-owners">owners</a>,
             <a href="#pkg_tar_impl-package_base">package_base</a>, <a href="#pkg_tar_impl-package_dir">package_dir</a>, <a href="#pkg_tar_impl-package_dir_file">package_dir_file</a>, <a href="#pkg_tar_impl-package_file_name">package_file_name</a>, <a href="#pkg_tar_impl-package_variables">package_variables</a>,
             <a href="#pkg_tar_impl-portable_mtime">portable_mtime</a>, <a href="#pkg_tar_impl-private_stamp_detect">private_stamp_detect</a>, <a href="#pkg_tar_impl-remap_paths">remap_paths</a>, <a href="#pkg_tar_impl-srcs">srcs</a>, <a href="#pkg_tar_impl-stamp">stamp</a>, <a href="#pkg_tar_impl-strip_prefix">strip_prefix</a>, <a href="#pkg_tar_impl-symlinks">symlinks</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| build_tar |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | //pkg/private:build_tar |
| compressor |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| compressor_args |  -   | String | optional | "" |
| deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| empty_dirs |  -   | List of strings | optional | [] |
| empty_files |  -   | List of strings | optional | [] |
| extension |  -   | String | optional | "tar" |
| files |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| include_runfiles |  -   | Boolean | optional | False |
| mode |  -   | String | optional | "0555" |
| modes |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| mtime |  -   | Integer | optional | -1 |
| out |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| owner |  -   | String | optional | "0.0" |
| ownername |  -   | String | optional | "." |
| ownernames |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| owners |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| package_base |  -   | String | optional | "./" |
| package_dir |  -   | String | optional | "" |
| package_dir_file |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| package_file_name |  See Common Attributes   | String | optional | "" |
| package_variables |  See Common Attributes   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| portable_mtime |  -   | Boolean | optional | True |
| private_stamp_detect |  -   | Boolean | optional | False |
| remap_paths |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| srcs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| stamp |  Enable file time stamping.  Possible values:&lt;ul&gt; &lt;li&gt;stamp = 1: Use the time of the build as the modification time of each file in the archive.&lt;/li&gt; &lt;li&gt;stamp = 0: Use an "epoch" time for the modification time of each file. This gives good build result caching.&lt;/li&gt; &lt;li&gt;stamp = -1: Control the chosen modification time using the --[no]stamp flag.&lt;/li&gt; &lt;/ul&gt;   | Integer | optional | 0 |
| strip_prefix |  -   | String | optional | "" |
| symlinks |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_zip"></a>

## pkg_zip

<pre>
pkg_zip(<a href="#pkg_zip-name">name</a>, <a href="#pkg_zip-kwargs">kwargs</a>)
</pre>

Creates a .zip file. See pkg_zip_impl.

**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  <p align="center"> - </p>   |  none |
| kwargs |  <p align="center"> - </p>   |  none |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_zip_impl"></a>

## pkg_zip_impl

<pre>
pkg_zip_impl(<a href="#pkg_zip_impl-name">name</a>, <a href="#pkg_zip_impl-mode">mode</a>, <a href="#pkg_zip_impl-out">out</a>, <a href="#pkg_zip_impl-package_dir">package_dir</a>, <a href="#pkg_zip_impl-package_file_name">package_file_name</a>, <a href="#pkg_zip_impl-package_variables">package_variables</a>,
             <a href="#pkg_zip_impl-private_stamp_detect">private_stamp_detect</a>, <a href="#pkg_zip_impl-srcs">srcs</a>, <a href="#pkg_zip_impl-stamp">stamp</a>, <a href="#pkg_zip_impl-strip_prefix">strip_prefix</a>, <a href="#pkg_zip_impl-timestamp">timestamp</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| mode |  The default mode for all files in the archive.   | String | optional | "0555" |
| out |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| package_dir |  The prefix to add to all all paths in the archive.   | String | optional | "/" |
| package_file_name |  See Common Attributes   | String | optional | "" |
| package_variables |  See Common Attributes   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| private_stamp_detect |  -   | Boolean | optional | False |
| srcs |  List of files that should be included in the archive.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| stamp |  Enable file time stamping.  Possible values:&lt;ul&gt; &lt;li&gt;stamp = 1: Use the time of the build as the modification time of each file in the archive.&lt;/li&gt; &lt;li&gt;stamp = 0: Use an "epoch" time for the modification time of each file. This gives good build result caching.&lt;/li&gt; &lt;li&gt;stamp = -1: Control the chosen modification time using the --[no]stamp flag.&lt;/li&gt; &lt;/ul&gt;   | Integer | optional | 0 |
| strip_prefix |  -   | String | optional | "" |
| timestamp |  Time stamp to place on all files in the archive, expressed as seconds since the Unix Epoch, as per RFC 3339.  The default is January 01, 1980, 00:00 UTC.<br><br>Due to limitations in the format of zip files, values before Jan 1, 1980 will be rounded up and the precision in the zip file is limited to a granularity of 2 seconds.   | Integer | optional | 315532800 |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#filter_directory"></a>

## filter_directory

<pre>
filter_directory(<a href="#filter_directory-name">name</a>, <a href="#filter_directory-excludes">excludes</a>, <a href="#filter_directory-outdir_name">outdir_name</a>, <a href="#filter_directory-prefix">prefix</a>, <a href="#filter_directory-renames">renames</a>, <a href="#filter_directory-src">src</a>, <a href="#filter_directory-strip_prefix">strip_prefix</a>)
</pre>

Transform directories (TreeArtifacts) using pkg_filegroup-like semantics.

    Effective order of operations:
    
    1) Files are `exclude`d
    2) `renames` _or_ `strip_prefix` is applied.
    3) `prefix` is applied 
    
    In particular, if a `rename` applies to an individual file, `strip_prefix`
    will not be applied to that particular file.
    
    Each non-`rename``d path will look like this:

    ```
    $OUTPUT_DIR/$PREFIX/$FILE_WITHOUT_STRIP_PREFIX
    ```

    Each `rename`d path will look like this:
    
    ```
    $OUTPUT_DIR/$PREFIX/$FILE_RENAMED
    ```
    
    If an operation cannot be applied (`strip_prefix`) to any component in the
    directory, or if one is unused (`exclude`, `rename`), the underlying command
    will fail.  See the individual attributes for details.
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| excludes |  Files to exclude from the output directory.<br><br>            Each element must refer to an individual file in <code>src</code>.<br><br>            All exclusions must be used.   | List of strings | optional | [] |
| outdir_name |  Name of output directory (otherwise defaults to the rule's name)   | String | optional | "" |
| prefix |  Prefix to add to all paths in the output directory.<br><br>            This does not include the output directory name, which will be added             regardless.   | String | optional | "" |
| renames |  Files to rename in the output directory.<br><br>            Keys are destinations, values are sources prior to any path             modifications (e.g. via <code>prefix</code> or <code>strip_prefix</code>).  Files that are             <code>exclude</code>d must not be renamed.<br><br>            This currently only operates on individual files.  <code>strip_prefix</code>             does not apply to them.<br><br>            All renames must be used.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| src |  Directory (TreeArtifact) to process.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| strip_prefix |  Prefix to remove from all paths in the output directory.<br><br>            Must apply to all paths in the directory, even those rename'd.   | String | optional | "" |


<a name="#pkg_filegroup"></a>

## pkg_filegroup

<pre>
pkg_filegroup(<a href="#pkg_filegroup-name">name</a>, <a href="#pkg_filegroup-prefix">prefix</a>, <a href="#pkg_filegroup-srcs">srcs</a>)
</pre>

Package contents grouping rule.

    This rule represents a collection of packaging specifications (e.g. those
    created by `pkg_files`, `pkg_mklink`, etc.) that have something in common,
    such as a prefix or a human-readable category.
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| prefix |  A prefix to prepend to provided paths, applied like so:<br><br>            - For files and directories, this is simply prepended to the destination             - For symbolic links, this is prepended to the "destination" part.   | String | optional | "" |
| srcs |  A list of packaging specifications to be grouped together.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |


<a name="#pkg_files"></a>

## pkg_files

<pre>
pkg_files(<a href="#pkg_files-name">name</a>, <a href="#pkg_files-attributes">attributes</a>, <a href="#pkg_files-excludes">excludes</a>, <a href="#pkg_files-prefix">prefix</a>, <a href="#pkg_files-renames">renames</a>, <a href="#pkg_files-srcs">srcs</a>, <a href="#pkg_files-strip_prefix">strip_prefix</a>)
</pre>

General-purpose package target-to-destination mapping rule.

    This rule provides a specification for the locations and attributes of
    targets when they are packaged. No outputs are created other than Providers
    that are intended to be consumed by other packaging rules, such as
    `pkg_rpm`.

    Labels associated with these rules are not passed directly to packaging
    rules, instead, they should be passed to an associated `pkg_filegroup` rule,
    which in turn should be passed to packaging rules.

    Consumers of `pkg_files`s will, where possible, create the necessary
    directory structure for your files so you do not have to unless you have
    special requirements.  Consult `pkg_mkdirs` for more details.
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| attributes |  Attributes to set on packaged files.<br><br>            Always use <code>pkg_attributes()</code> to set this rule attribute.<br><br>            If not otherwise overridden, the file's mode will be set to UNIX             "0644", or the target platform's equivalent.<br><br>            Consult the "Mapping Attributes" documentation in the rules_pkg             reference for more details.   | String | optional | "{}" |
| excludes |  List of files or labels to exclude from the inputs to this rule.<br><br>            Mostly useful for removing files from generated outputs or             preexisting <code>filegroup</code>s.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| prefix |  Installation prefix.<br><br>            This may be an arbitrary string, but it should be understandable by             the packaging system you are using to have the desired outcome.  For             example, RPM macros like <code>%{_libdir}</code> may work correctly in paths             for RPM packages, not, say, Debian packages.<br><br>            If any part of the directory structure of the computed destination             of a file provided to <code>pkg_filegroup</code> or any similar rule does not             already exist within a package, the package builder will create it             for you with a reasonable set of default permissions (typically             <code>0755 root.root</code>).<br><br>            It is possible to establish directory structures with arbitrary             permissions using <code>pkg_mkdirs</code>.   | String | optional | "" |
| renames |  Destination override map.<br><br>            This attribute allows the user to override destinations of files in             <code>pkg_file</code>s relative to the <code>prefix</code> attribute.  Keys to the             dict are source files/labels, values are destinations relative to             the <code>prefix</code>, ignoring whatever value was provided for             <code>strip_prefix</code>.<br><br>            If the key refers to a TreeArtifact (directory output), you may             specify the constant <code>REMOVE_BASE_DIRECTORY</code> as the value, which             will result in all containing files and directories being installed             relative to the otherwise specified install prefix (via the <code>prefix</code>             and <code>strip_prefix</code> attributes), not the directory name.<br><br>            The following keys are rejected:<br><br>            - Any label that expands to more than one file (mappings must be               one-to-one).<br><br>            - Any label or file that was either not provided or explicitly               <code>exclude</code>d.<br><br>            The following values result in undefined behavior:<br><br>            - "" (the empty string)<br><br>            - "."<br><br>            - Anything containing ".."   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| srcs |  Files/Labels to include in the outputs of these rules   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| strip_prefix |  What prefix of a file's path to discard prior to installation.<br><br>            This specifies what prefix of an incoming file's path should not be             included in the output package at after being appended to the             install prefix (the <code>prefix</code> attribute).  Note that this is only             applied to full directory names, see <code>strip_prefix</code> for more             details.<br><br>            Use the <code>strip_prefix</code> struct to define this attribute.  If this             attribute is not specified, all directories will be stripped from             all files prior to being included in packages             (<code>strip_prefix.files_only()</code>).<br><br>            If prefix stripping fails on any file provided in <code>srcs</code>, the build             will fail.<br><br>            Note that this only functions on paths that are known at analysis             time.  Specifically, this will not consider directories within             TreeArtifacts (directory outputs), or the directories themselves.             See also #269.   | String | optional | "." |


<a name="#pkg_mkdirs"></a>

## pkg_mkdirs

<pre>
pkg_mkdirs(<a href="#pkg_mkdirs-name">name</a>, <a href="#pkg_mkdirs-attributes">attributes</a>, <a href="#pkg_mkdirs-dirs">dirs</a>)
</pre>

Defines creation and ownership of directories in packages

    Use this if:

    1) You need to create an empty directory in your package.

    2) Your package needs to explicitly own a directory, even if it already owns
       files in those directories.

    3) You need nonstandard permissions (typically, not "0755") on a directory
       in your package.

    For some package management systems (e.g. RPM), directory ownership (2) may
    imply additional semantics.  Consult your package manager's and target
    distribution's documentation for more details.
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| attributes |  Attributes to set on packaged directories.<br><br>            Always use <code>pkg_attributes()</code> to set this rule attribute.<br><br>            If not otherwise overridden, the directory's mode will be set to             UNIX "0755", or the target platform's equivalent.<br><br>            Consult the "Mapping Attributes" documentation in the rules_pkg             reference for more details.   | String | optional | "{}" |
| dirs |  Directory names to make within the package<br><br>            If any part of the requested directory structure does not already             exist within a package, the package builder will create it for you             with a reasonable set of default permissions (typically <code>0755             root.root</code>).   | List of strings | required |  |


<a name="#pkg_mklink"></a>

## pkg_mklink

<pre>
pkg_mklink(<a href="#pkg_mklink-name">name</a>, <a href="#pkg_mklink-attributes">attributes</a>, <a href="#pkg_mklink-dest">dest</a>, <a href="#pkg_mklink-src">src</a>)
</pre>

Define a symlink  within packages

    This rule results in the creation of a single link within a package.

    Symbolic links specified by this rule may point at files/directories outside of the
    package, or otherwise left dangling.

    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| attributes |  Attributes to set on packaged symbolic links.<br><br>            Always use <code>pkg_attributes()</code> to set this rule attribute.<br><br>            Symlink permissions may have different meanings depending on your             host operating system; consult its documentation for more details.<br><br>            If not otherwise overridden, the link's mode will be set to UNIX             "0777", or the target platform's equivalent.<br><br>            Consult the "Mapping Attributes" documentation in the rules_pkg             reference for more details.   | String | optional | "{}" |
| dest |  Link "target", a path within the package.<br><br>            This is the actual created symbolic link.<br><br>            If the directory structure provided by this attribute is not             otherwise created when exist within the package when it is built, it             will be created implicitly, much like with <code>pkg_files</code>.<br><br>            This path may be prefixed or rooted by grouping or packaging rules.   | String | required |  |
| src |  Link "source", a path on the filesystem.<br><br>            This is what the link "points" to, and may point to an arbitrary             filesystem path, even relative paths.   | String | required |  |


<a name="#pkg_attributes"></a>

## pkg_attributes

<pre>
pkg_attributes(<a href="#pkg_attributes-mode">mode</a>, <a href="#pkg_attributes-user">user</a>, <a href="#pkg_attributes-group">group</a>, <a href="#pkg_attributes-kwargs">kwargs</a>)
</pre>

Format attributes for use in package mapping rules.

If "mode" is not provided, it will default to the mapping rule's default
mode.  These vary per mapping rule; consult the respective documentation for
more details.

Not providing any of "user", or "group" will result in the package builder
choosing one for you.  The chosen value should not be relied upon.

Well-known attributes outside of the above are documented in the rules_pkg
reference.

This is the only supported means of passing in attributes to package mapping
rules (e.g. `pkg_files`).


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| mode |  string: UNIXy octal permissions, as a string.   |  <code>None</code> |
| user |  string: Filesystem owning user.   |  <code>None</code> |
| group |  string: Filesystem owning group.   |  <code>None</code> |
| kwargs |  any other desired attributes.   |  none |


<a name="#strip_prefix.files_only"></a>

## strip_prefix.files_only

<pre>
strip_prefix.files_only()
</pre>



**PARAMETERS**



<a name="#strip_prefix.from_pkg"></a>

## strip_prefix.from_pkg

<pre>
strip_prefix.from_pkg(<a href="#strip_prefix.from_pkg-path">path</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| path |  <p align="center"> - </p>   |  <code>""</code> |


<a name="#strip_prefix.from_root"></a>

## strip_prefix.from_root

<pre>
strip_prefix.from_root(<a href="#strip_prefix.from_root-path">path</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| path |  <p align="center"> - </p>   |  <code>""</code> |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pkg_rpm"></a>

## pkg_rpm

<pre>
pkg_rpm(<a href="#pkg_rpm-name">name</a>, <a href="#pkg_rpm-architecture">architecture</a>, <a href="#pkg_rpm-changelog">changelog</a>, <a href="#pkg_rpm-data">data</a>, <a href="#pkg_rpm-debug">debug</a>, <a href="#pkg_rpm-release">release</a>, <a href="#pkg_rpm-release_file">release_file</a>, <a href="#pkg_rpm-rpmbuild_path">rpmbuild_path</a>,
        <a href="#pkg_rpm-source_date_epoch">source_date_epoch</a>, <a href="#pkg_rpm-source_date_epoch_file">source_date_epoch_file</a>, <a href="#pkg_rpm-spec_file">spec_file</a>, <a href="#pkg_rpm-version">version</a>, <a href="#pkg_rpm-version_file">version_file</a>)
</pre>

Legacy version

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| architecture |  -   | String | optional | "all" |
| changelog |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| data |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| debug |  -   | Boolean | optional | False |
| release |  -   | String | optional | "" |
| release_file |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| rpmbuild_path |  -   | String | optional | "" |
| source_date_epoch |  -   | Integer | optional | 0 |
| source_date_epoch_file |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| spec_file |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| version |  -   | String | optional | "" |
| version_file |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


