{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.ranger;
in
{
  options.crpier.dotfiles.ranger = {
    enable = lib.mkEnableOption "crpier ranger dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier ranger dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the ranger bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        ranger
        atool
        xsel
        fzf
      ]
      ++ cfg.extraPackages
    );

    xdg.configFile."ranger" = {
      source = ../../ranger/.config/ranger;
      recursive = true;
    };
  };
}
