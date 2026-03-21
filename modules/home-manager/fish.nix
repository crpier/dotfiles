{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.fish;
in
{
  options.crpier.dotfiles.fish = {
    enable = lib.mkEnableOption "crpier fish dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier fish dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the fish dotfiles bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        fish
        neovim
        uv
        bat
        kubectl
        git
        lazygit
        eza
        kitty
      ]
      ++ cfg.extraPackages
    );

    xdg.configFile."fish/config.fish".source = ../../fish/.config/fish/config.fish;
    xdg.configFile."fish/completions" = {
      source = ../../fish/.config/fish/completions;
      recursive = true;
    };
    xdg.configFile."fish/functions" = {
      source = ../../fish/.config/fish/functions;
      recursive = true;
    };
    xdg.configFile."fish/themes" = {
      source = ../../fish/.config/fish/themes;
      recursive = true;
    };
    xdg.configFile."local_configs/config.fish".text = lib.mkDefault "";
  };
}
