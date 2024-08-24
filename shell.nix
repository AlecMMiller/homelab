let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = with pkgs; [
    ansible
    opentofu
    kubectl
    cdrtools
    (python3.withPackages (python-pkgs: [
      python-pkgs.jmespath
    ]))
  ];
}
