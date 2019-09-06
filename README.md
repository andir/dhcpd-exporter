# ISC dhcpd Prometheus Exporter

This is a very trivial and inefficient implementation of an exporter for the ISC dhcpcd. It currently only exposes information regarding the IPv4 leases and their lifetime.


# Hacking

This project is using [`black`](https://github.com/psf/black) for code formatting. And [`nix`](https://nixos.org/nix) for both the developement and runtime environments.
