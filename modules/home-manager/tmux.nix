{ config, lib, pkgs, ... }:
let
  cfg = config.crpier.dotfiles.tmux;
in
{
  options.crpier.dotfiles.tmux = {
    enable = lib.mkEnableOption "crpier tmux dotfiles";
    installPackages = lib.mkEnableOption "packages used by crpier tmux dotfiles";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install with the tmux bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackages (
      with pkgs;
      [
        tmux
      ]
      ++ cfg.extraPackages
    );

    home.file.".tmux.conf".source = ../../tmux/.tmux.conf;
    xdg.configFile."local_configs/.tmux.conf".text = lib.mkDefault "";
  };
}
