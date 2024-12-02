{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        packages = with pkgs; [
          ansible
          opentofu
          kubectl
          kubernetes-helm
          cdrtools
          (python3.withPackages (python-pkgs: [
            python-pkgs.jmespath
          ]))

        ];
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = packages;
        };
      }
    );
}
