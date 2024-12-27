{
  description = "NodeJS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_23 
          ];
          shellHook = ''
            echo "NodeJS development environment loaded"
						echo node --version
						echo npm --version
						bash bin/get_quartz.sh
          '';
        };
      });
}


