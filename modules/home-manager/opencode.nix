{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.opencode;
in
{
  options.crpier.dotfiles.opencode = {
    enable = lib.mkEnableOption "crpier opencode dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier opencode dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the opencode bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages cfg.extraPackages;

    xdg.configFile."opencode" = {
      source = ../../opencode/.config/opencode;
      recursive = true;
    };
  };
}
