{
  description = "Elixir Phoenix Development Environment with SQLite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      # Define packages needed for both devShell and build
      commonPackages = with pkgs; [
        elixir
        erlang
        elixir_ls

        # tools
        just
      ];

      nixTools = with pkgs; [
        alejandra
        nixpkgs-fmt
      ];
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = commonPackages ++ nixTools;

        shellHook = ''
          export LANG=en_US.UTF-8
          export ERL_AFLAGS="-kernel shell_history enabled"
          export MIX_HOME="$PWD/.nix-mix"
          export HEX_HOME="$PWD/.nix-hex"
          export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
        '';
      };
    });
}
