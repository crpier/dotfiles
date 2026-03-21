{
  description = "Reusable Home Manager and NixOS modules from crpier's dotfiles";

  inputs.home-manager.url = "github:nix-community/home-manager";

  outputs = { self, home-manager, ... }: {
    homeManagerModules = {
      default = import ./modules/home-manager;
      fish = import ./modules/home-manager/fish.nix;
      gitconfig = import ./modules/home-manager/gitconfig.nix;
      kitty = import ./modules/home-manager/kitty.nix;
      lazygit = import ./modules/home-manager/lazygit.nix;
      opencode = import ./modules/home-manager/opencode.nix;
      ranger = import ./modules/home-manager/ranger.nix;
      tmux = import ./modules/home-manager/tmux.nix;
    };

    nixosModules = {
      default = import ./modules/nixos { inherit self home-manager; };
      dotfiles = import ./modules/nixos { inherit self home-manager; };
    };
  };
}
