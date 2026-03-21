{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.lazygit;
in
{
  options.crpier.dotfiles.lazygit = {
    enable = lib.mkEnableOption "crpier lazygit dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier lazygit dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the lazygit bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        lazygit
        git
      ]
      ++ cfg.extraPackages
    );

    xdg.configFile."lazygit" = {
      source = ../../lazygit/.config/lazygit;
      recursive = true;
    };
  };
}
