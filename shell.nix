let
  inherit (import ./default.nix {}) pkgs pythonEnv python;

  libfaketime = pkgs.libfaketime.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "wolfcw";
      repo = "libfaketime";
      rev = "v0.9.8";
      sha256 = "1mfdl82ppgbdvy1ny8mb7xii7p0g7awvn4bn36jb8v4r545slmjc";
    };
  });

  devRun = pkgs.writeScriptBin "devRun" ''
    #!${pkgs.runtimeShell}
    PATH="${pythonEnv}/bin:${pkgs.reflex}/bin"
    LD_PRELOAD=${libfaketime}/lib/libfaketime.so.1 \
    FAKETIME='%' \
    FAKETIME_FOLLOW_FILE=$(pwd)/dhcpd.leases \
    FAKETIME_DONT_RESET=1 \
    exec python ./dhcpd-exporter.py "$@"
  '';

in pkgs.mkShell {
  nativeBuildInputs = [
    pythonEnv
    pkgs.mypy
    python.pkgs.black

    devRun
 ];
}
