let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = [
    pkgs.ansible
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.jmespath
    ]))
  ];
}
