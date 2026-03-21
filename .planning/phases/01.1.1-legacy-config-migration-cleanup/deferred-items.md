# Deferred Items

- Plan `01.1.1-02` host build verification (`nix build --no-link path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel`) cannot complete in this executor environment because local user is not trusted to set `--system` or `--always-allow-substitutes`, and local machine is `x86_64-linux` while target derivation requires native `aarch64-linux` build steps.
