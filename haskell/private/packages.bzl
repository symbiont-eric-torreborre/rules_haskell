"""Package list handling"""

load(":private/set.bzl", "set")

def pkg_info_to_compile_flags(pkg_info, for_plugin = False):
    """Map package info to GHC command-line arguments.

    Args:
      pkg_info: Package info collected by `ghc_info()`.
      for_plugin: Whether the package is a plugin dependency.

    Returns:
      The list of command-line arguments that should be passed to GHC.
    """
    namespace = "plugin-" if for_plugin else ""
    args = [
        # In compile.bzl, we pass this just before all -package-id
        # arguments. Not doing so leads to bizarre compile-time failures.
        # It turns out that equally, not doing so leads to bizarre
        # link-time failures. See
        # https://github.com/tweag/rules_haskell/issues/395.
        "-hide-all-{}packages".format(namespace),
    ]

    if not pkg_info.has_version:
        args.extend([
            # Macro version are disabled for all packages by default
            # and enabled for package with version
            # see https://github.com/tweag/rules_haskell/issues/414
            "-fno-version-macros",
        ])

    for package_id in pkg_info.package_ids:
        args.extend(["-{}package-id".format(namespace), package_id])

    for package_db in pkg_info.package_dbs:
        args.extend(["-package-db", package_db])

    return args

def expose_packages(hs_info, lib_info, use_my_pkg_id, custom_package_databases, version):
    """
    Returns the information that is needed by GHC in order to enable haskell
    packages.

    hs_info: is common to all builds
    version: if the rule contains a version, we will export the CPP version macro

    All the other arguments are not understood well:

    lib_info: only used for repl and linter
    use_my_pkg_id: only used for one specific task in compile.bzl
    custom_package_databases: override the package_databases of hs_info, used only by the repl
    """
    has_version = version != None and version != ""

    # Expose all bazel dependencies
    package_ids = []
    for package in hs_info.package_ids:
        # XXX: repl and lint uses this lib_info flags
        # It is set to None in all other usage of this function
        # TODO: find the meaning of this flag
        if lib_info == None or package != lib_info.package_id:
            # XXX: use_my_pkg_id is not None only in compile.bzl
            if (use_my_pkg_id == None) or package != use_my_pkg_id:
                package_ids.append(package)

    # Only include package DBs for deps.
    package_dbs = []
    for cache in hs_info.package_databases.to_list() if custom_package_databases == None else custom_package_databases.to_list():
        package_dbs.append(cache.dirname)

    ghc_info = struct(
        has_version = has_version,
        package_ids = package_ids,
        package_dbs = package_dbs,
    )
    return ghc_info
