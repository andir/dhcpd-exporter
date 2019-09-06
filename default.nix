{ nixpkgs ? <nixpkgs> }:
let
  pkgs = import nixpkgs {};
  python = pkgs.python3.override {
    packageOverrides = import ./deps.nix;
  };
  deps = p: with p; [
    prometheus_client
    isc_dhcp_filter
    freezegun
  ];
in rec {

  inherit pkgs python deps;

  pythonEnv = python.withPackages deps;

  build = pkgs.runCommand "dhcpd-exporter" {
    nativeBuildInputs = [ python.pkgs.wrapPython python.pkgs.black ];
    pythonPath = deps python.pkgs;
  } ''
    mkdir -p $out/bin
    black --check ${./dhcpd-exporter.py}
    cp ${./dhcpd-exporter.py} $out/bin/dhcpd-exporter
    wrapPythonProgramsIn $out/bin "$pythonPath"
  '';
}
