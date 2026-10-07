{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.follows = "nixpkgs-lock/set-and-setting";
    nix-lefthook-tdd-order-bats-src.url = "github:pr0d1r2/nix-lefthook-tdd-order-bats";
    nix-lefthook-tdd-order-bats-src.flake = false;
  };
  outputs = inputs: import ./flake-outputs.nix inputs;
}
