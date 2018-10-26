{ pkgs ? import ./nixpkgs {} }:

with pkgs;
with darwin.apple_sdk.frameworks;

# XXX On Darwin, workaround
# https://github.com/NixOS/nixpkgs/issues/42059. See also
# https://github.com/NixOS/nixpkgs/pull/41589.
let cc = runCommand "cc-wrapper-bazel" {
    buildInputs = [ stdenv.cc makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${stdenv.cc}/bin/clang $out/bin/clang \
      --add-flags "-isystem ${llvmPackages.libcxx}/include/c++/v1 \
                   -F${CoreFoundation}/Library/Frameworks \
                   -F${CoreServices}/Library/Frameworks \
                   -F${Security}/Library/Frameworks \
                   -F${Foundation}/Library/Frameworks \
                   -L${libcxx}/lib \
                   -L${darwin.libobjc}/lib"
 '';

  mkShell = pkgs.mkShell.override {
    stdenv = if stdenv.isDarwin then overrideCC stdenv cc else stdenv;
  };
in
mkShell {
  buildInputs = [
    binutils
    go
    graphviz
    nix
    which
    python
    python36Packages.sphinx
    zip
    unzip
  ]
  # TODO use Bazel from Nixpkgs even on Darwin. Blocked by
  # https://github.com/NixOS/nixpkgs/issues/30590.
  ++ lib.optional stdenv.isLinux bazel;
}
