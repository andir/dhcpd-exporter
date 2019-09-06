self: super: {
  isc_dhcp_filter = super.callPackage ({buildPythonPackage, fetchFromGitHub, freezegun, isc_dhcp_leases}: super.buildPythonPackage rec {
    pname = "isc-dhcp-filter";
    version = "0.0.2";
    src = fetchFromGitHub {
      owner = "andir";
      repo = pname;
      rev = "v${version}";
      sha256 = "1ypsl49mfbyb6l008wmvixg5vgv5pzas9k9xpx999a6yny11jh50";
    };
    propagatedBuildInputs = [ isc_dhcp_leases ];
    checkInputs = [ freezegun ];
  }) {};

  isc_dhcp_leases = super.callPackage ({buildPythonPackage, fetchFromGitHub, freezegun, six}: super.buildPythonPackage rec {
    pname = "isc_dhcp_leases";
    version = "0.9.1";
    src = fetchFromGitHub {
      owner = "MartijnBraam";
      repo = "python-isc-dhcp-leases";
      rev = "${version}";
      sha256 = "0j87v7b97p79dkicvwwj8sbw98svj67vpxwalkq7h3nfx2bhj1mg";
    };
    propagatedBuildInputs = [ six ];
    checkInputs = [ freezegun ];
  }) {};
}
