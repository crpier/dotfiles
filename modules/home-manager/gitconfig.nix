{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.gitconfig;
in
{
  options.crpier.dotfiles.gitconfig = {
    enable = lib.mkEnableOption "crpier gitconfig extras";
    installPackages = lib.mkEnableOption "packages used by crpier gitconfig";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the gitconfig bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        git
        delta
      ]
      ++ cfg.extraPackages
    );

    programs.git.enable = lib.mkDefault true;
    programs.git.includes = lib.mkAfter [
      { path = "${config.xdg.configHome}/extra.gitconfig"; }
    ];

    xdg.configFile."extra.gitconfig".source = ../../gitconfig/.config/extra.gitconfig;
    xdg.configFile."delta/catpuccin.gitconfig".text = lib.mkDefault "";
    xdg.configFile."local_configs/gitconfig".text = lib.mkDefault "";
  };
}
