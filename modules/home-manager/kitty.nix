{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.kitty;
in
{
  options.crpier.dotfiles.kitty = {
    enable = lib.mkEnableOption "crpier kitty dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier kitty dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the kitty bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        kitty
        neovim
        fish
      ]
      ++ cfg.extraPackages
    );

    xdg.configFile."kitty" = {
      source = ../../kitty/.config/kitty;
      recursive = true;
    };
    xdg.configFile."local_configs/kitty.conf".text = lib.mkDefault "";
  };
}
