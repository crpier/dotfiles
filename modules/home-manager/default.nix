{ config, lib, ... }:
{
  imports = [
    ./fish.nix
    ./gitconfig.nix
    ./kitty.nix
    ./lazygit.nix
    ./opencode.nix
    ./ranger.nix
    ./tmux.nix
  ];

  options.crpier.dotfiles.enableAll = lib.mkEnableOption "all crpier dotfiles modules";
  options.crpier.dotfiles.installPackages = lib.mkEnableOption "package bundles for all crpier dotfiles modules";

  config = lib.mkIf config.crpier.dotfiles.enableAll {
    crpier.dotfiles.fish.enable = lib.mkDefault true;
    crpier.dotfiles.gitconfig.enable = lib.mkDefault true;
    crpier.dotfiles.kitty.enable = lib.mkDefault true;
    crpier.dotfiles.lazygit.enable = lib.mkDefault true;
    crpier.dotfiles.opencode.enable = lib.mkDefault true;
    crpier.dotfiles.ranger.enable = lib.mkDefault true;
    crpier.dotfiles.tmux.enable = lib.mkDefault true;

    crpier.dotfiles.fish.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.gitconfig.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.kitty.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.lazygit.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.opencode.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.ranger.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
    crpier.dotfiles.tmux.installPackages = lib.mkDefault config.crpier.dotfiles.installPackages;
  };
}
