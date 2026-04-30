# Repository Guidelines

## Project Structure & Module Organization

This repository contains GNU Guix system and home configuration in Scheme, with
a Nix flake used only for the development shell.

- `flake.nix` and `.envrc` define the local shell with `guix` and `qemu`.
- `channels.scm` defines Guix channels, including `nonguix`.
- `systems.scm` provides shared operating-system defaults.
- `systems/` contains host declarations: `systems/legion.scm` and the QEMU
  variant `systems/legion-vm.scm`.
- `homes.scm` provides shared home-environment defaults.
- `homes/` contains user declarations, currently `homes/luiz.scm`.
- `modules/` contains reusable modules, currently NVIDIA PRIME support in
  `modules/nvidia.scm`.

## Build, Test, and Development Commands

- `nix develop`: enter the development shell with Guix and QEMU available.
- `direnv allow`: enable automatic entry into the flake shell if using direnv.
- `guix system build -L . systems/legion.scm`: validate the physical host
  system derivation.
- `guix system image -L . -t qcow2 systems/legion-vm.scm`: build a QEMU qcow2
  image for the VM configuration.
- `guix home build -L . homes/luiz.scm`: validate and build the home
  environment.
- `guix pull -C channels.scm`: update Guix using the repository channel set.

Use `-L .` so local modules like `(systems)` and `(modules nvidia)` resolve.

## Coding Style & Naming Conventions

Use idiomatic Guile Scheme. Keep two-space indentation and prefer small
`define` blocks for packages, services, users, and file systems. Export public
values with the existing `%name` convention, for example
`%legion-operating-system` or `%conf-initial-home`. Host and home files should
end by evaluating the exported object so they can be passed directly to Guix.

## Testing Guidelines

There is no separate test suite. Treat successful Guix builds as validation.
Before changing shared files such as `systems.scm`, `homes.scm`, or
`modules/nvidia.scm`, build every affected host or home declaration. For
hardware-specific changes, validate `systems/legion-vm.scm` when a VM check is
sufficient, then build the physical host configuration before reconfigure.

## Commit & Pull Request Guidelines

This checkout has no Git metadata, so no project-specific commit pattern can be
inferred. Use concise imperative commits, such as
`Add Legion VM image configuration`. Pull requests should explain the affected
host or user, list validation commands, and call out hardware-sensitive changes:
UUIDs, bootloader targets, NVIDIA settings, firewall rules, or encrypted device
mappings.

## Security & Configuration Tips

Do not change disk UUIDs, LUKS mappings, firewall ports, channel introductions,
or bootloader targets without verifying the target machine. Keep secrets out of
Scheme files; use Guix services or external secret management where needed.
