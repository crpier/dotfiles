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

    programs.git = {
      enable = lib.mkDefault true;
      aliases = {
        files = "!git diff --name-only $(git merge-base HEAD $(git rev-parse --abbrev-ref origin/HEAD))";
        stat = "!git diff --stat $(git merge-base HEAD $(git rev-parse --abbrev-ref origin/HEAD))";
      };
      includes = lib.mkAfter [
        { path = "${config.xdg.configHome}/delta/catpuccin.gitconfig"; }
        { path = "${config.xdg.configHome}/local_configs/gitconfig"; }
      ];
      extraConfig = {
        pull.rebase = false;
        push.default = "current";
        init.defaultBranch = "main";
        core = {
          pager = "delta";
          editor = "nvim";
        };
        delta = {
          line-numbers = true;
          features = "catppuccin-macchiato";
        };
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        interactive.diffFilter = "delta --color-only";
      };
    };

    xdg.configFile."delta/catpuccin.gitconfig".text = lib.mkDefault "";
    xdg.configFile."local_configs/gitconfig".text = lib.mkDefault "";
  };
}
