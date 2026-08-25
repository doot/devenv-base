{
  # TODO:: This flake is only needed until devenv supports consuming remote devenv.yaml inputs.
  # Until then, this duplicates the inputs from devenv.yaml in this so that devenv configurations
  # that import this one can all use the same pinned nixpkgs and git-hooks versions.
  description = "Shared devenv base configuration";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = _: {};
}
