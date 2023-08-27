{
  description = "NixOS backup service to make borgbackup jobs easier";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosModules = rec {
      backup-service = import ./module.nix;
      default = backup-service;
    };
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        alejandra
        nixd
      ];
    };
  };
}
