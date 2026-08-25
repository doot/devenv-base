{
  pkgs,
  lib,
  config,
  ...
}:
# TODO: Is there any advantage to having the `options.shared` blocks below for `rust`, `nix`, `shell`, etc, vs
# just putting them directly in the `profiles.base.module` block? It seems like it just makes things harder to read with disjointed blocks and if statements
# instead of just keeping everything related to "rust" in the rust profile.
{
  options.shared = {
    languages = {
      rust.enable = lib.mkEnableOption "Rust default options";
      nix.enable = lib.mkEnableOption "Nix default options";
      shell.enable = lib.mkEnableOption "Shell default options";
    };
  };

  config = {
    # packages = lib.mkIf config.shared.languages.rust.enable lib.optionals (!config.container.isBuilding && !config.devenv.isTesting) [
    # Development packages to include only when not building a container or testing
    packages = lib.mkIf config.shared.languages.rust.enable [
      pkgs.bacon
      pkgs.lldb
      pkgs.loco # TODO: Make this dependent on something else, or move directly into oic
    ];

    languages = {
      nix = lib.mkIf config.shared.languages.nix.enable {
        # enable = !config.containers.isBuilding;
        enable = true;
        lsp.enable = true;
      };

      shell = lib.mkIf config.shared.languages.shell.enable {
        enable = true;
        lsp.enable = true;
      };

      rust = lib.mkIf config.shared.languages.rust.enable {
        enable = true;
        toolchainFile = ./rust-toolchain.toml;
        lsp.enable = true;
        mold.enable = true;
        rustflags = "-Z threads=8";
      };
    };

    profiles = {
      base.module = {
        shared = {
          languages = {
            nix.enable = true;
            shell.enable = true;
          };
        };

        cachix.pull = ["devenv" "pre-commit-hooks"];

        devcontainer.enable = true;

        delta.enable = true;

        packages = [
          pkgs.github-cli
          # pkgs.statix # TODO: Is this needed? Should be included by git-hooks?
          # pkgs.deadnix # TODO: Is this needed? Should be included by git-hooks?
          pkgs.nil # TODO: Is this needed? Should be included by git-hooks?
          pkgs.jq # Needed for tasks and CLI script that use jq
          # pkgs.cowsay
        ];

        enterShell = ''
          echo "Loaded base profile."
        '';

        git-hooks = {
          hooks = {
            commitizen.enable = !config.container.isBuilding;
            deadnix.enable = !config.container.isBuilding;
            statix.enable = !config.container.isBuilding;
            alejandra.enable = !config.container.isBuilding;
            markdownlint = {
              enable = !config.container.isBuilding;
              settings.configuration = {
                MD013 = {
                  line_length = 180;
                };
              };
            };
            check-json.enable = !config.container.isBuilding;
            pretty-format-json = {
              enable = !config.container.isBuilding;
              args = ["--no-sort-keys"];
            };
            check-yaml.enable = !config.container.isBuilding;
          };
        };
      };

      rust = {
        extends = ["base"];
        module = {
          shared.languages.rust.enable = true;

          enterTest = ''
            rustc --version
            echo "Running tests"
            cargo fmt --check
            cargo build
            cargo clippy --all-targets --all-features
            cargo test
          '';

          enterShell = ''
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo "RUST_SRC_PATH: $RUST_SRC_PATH"
          '';

          git-hooks = {
            hooks = {
              cargo-check.enable = !config.container.isBuilding;
              clippy = {
                enable = true;
                settings.allFeatures = true;
                settings.denyWarnings = true;
              };
              rustfmt = {
                enable = !config.container.isBuilding;
                settings.config-path = ".rustfmt.toml";
              };
              check-toml.enable = !config.container.isBuilding;
            };
          };
        };
      };
    };
  };
}
