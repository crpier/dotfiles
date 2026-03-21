{ self, home-manager }:
{ config, lib, ... }:
let
  userModule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "crpier dotfiles for ${name}";
      enableAll = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the full exported dotfiles set for this user.";
      };
      installPackages = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install package bundles for enabled dotfiles modules for this user.";
      };
      modules = {
        fish = lib.mkEnableOption "fish dotfiles for ${name}";
        gitconfig = lib.mkEnableOption "gitconfig dotfiles for ${name}";
        kitty = lib.mkEnableOption "kitty dotfiles for ${name}";
        lazygit = lib.mkEnableOption "lazygit dotfiles for ${name}";
        opencode = lib.mkEnableOption "opencode dotfiles for ${name}";
        ranger = lib.mkEnableOption "ranger dotfiles for ${name}";
        tmux = lib.mkEnableOption "tmux dotfiles for ${name}";
      };
    };
  };

  enabledUsers = lib.filterAttrs (_: userCfg: userCfg.enable) config.crpier.dotfiles.users;
in
{
  imports = [ home-manager.nixosModules.home-manager ];

  options.crpier.dotfiles.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule userModule);
    default = { };
    description = "Users that should receive the exported crpier dotfiles Home Manager modules.";
  };

  config = lib.mkIf (enabledUsers != { }) {
    home-manager.useGlobalPkgs = lib.mkDefault true;
    home-manager.useUserPackages = lib.mkDefault true;

    home-manager.users = lib.mapAttrs (_: userCfg: {
      imports = [ self.homeManagerModules.default ];

      crpier.dotfiles.enableAll = userCfg.enableAll;
      crpier.dotfiles.installPackages = userCfg.installPackages;

      crpier.dotfiles.fish.enable = lib.mkDefault userCfg.modules.fish;
      crpier.dotfiles.gitconfig.enable = lib.mkDefault userCfg.modules.gitconfig;
      crpier.dotfiles.kitty.enable = lib.mkDefault userCfg.modules.kitty;
      crpier.dotfiles.lazygit.enable = lib.mkDefault userCfg.modules.lazygit;
      crpier.dotfiles.opencode.enable = lib.mkDefault userCfg.modules.opencode;
      crpier.dotfiles.ranger.enable = lib.mkDefault userCfg.modules.ranger;
      crpier.dotfiles.tmux.enable = lib.mkDefault userCfg.modules.tmux;
    }) enabledUsers;
  };
}
