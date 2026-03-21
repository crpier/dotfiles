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

    programs.fish = {
      enable = true;
      shellAliases = {
        ks = "kitty +kitten ssh";
        icat = "kitty +kitten icat";
        n = "nvim";
        rn = "uv run nvim";
        nconfig = "nvim $HOME/.config/nvim/init.lua";
        nlconfig = "nvim $HOME/.config/local_configs/nvim.lua";
        fconfig = "nvim $HOME/.config/fish/config.fish";
        flconfig = "nvim $HOME/.config/local_configs/config.fish";
        kconfig = "nvim $HOME/.config/kitty/kitty.conf";
        klconfig = "nvim $HOME/.config/local_configs/kitty.conf";
        gconfig = "nvim $HOME/.gitconfig";
        glconfig = "nvim $HOME/.config/extra.gitconfig";
        b = "bat";
        rsource = "source $HOME/.config/fish/config.fish";
        rpython = ''uv run --with rich python -i -c "from rich import inspect; from rich import pretty; pretty.install()"'';
        k = "kubectl";
        g = "git";
        gs = "git status";
        ga = "git add .";
        gc = "git commit -m";
        gcl = "git clone";
        gco = "git checkout";
        ge = "git clean -fd";
        gd = "git diff";
        gac = "git add . && git commit -m";
        gu = "git pull";
        gpom = "git pull origin master";
        gp = "git push";
        gr = "git reset HEAD --hard";
        glo = "git log";
        gl = "git lg";
        gl2 = "git lg2";
        gw = "git worktree";
        gsf = "git fetch origin 'refs/heads/*:refs/heads/*'";
        lg = "lazygit";
        e = "eza";
        ea = "eza -a";
        el = "eza -l";
        ela = "eza -la";
        et = "eza -aT --git-ignore -I '.git|.venv|node_modules|.solid|__pycache__'";
        stats = "echo $status";
        rmf = "rm -rf";
        opencode = "env OPENCODE_EXPERIMENTAL_PLAN_MODE=1 opencode";
      };
      shellAbbrs = {
        ur = "uv run";
      };
      functions = {
        fish_mode_prompt = "";
        fish_prompt = ''
          set -l last_status $status
          echo -e ''
          set_color $fish_color_cwd
          echo -n (prompt_pwd)
          set_color normal
          echo -n ' '
          if set -q VIRTUAL_ENV
              set_color $fish_color_escape
              echo -n \((basename $VIRTUAL_ENV)\)
              set_color normal
          end
          __terlar_git_prompt
          echo
          if not test $last_status -eq 0
              set_color $fish_color_error
          end
          echo -n '➤ '
          set_color normal
        '';
        no = ''
          set last_file (
              nvim --headless -u NONE \
                  +'lua io.write(vim.v.oldfiles[1] or "")' +q 2>/dev/null
          )

          if test -n "$last_file"; and test -f "$last_file"
              nvim $last_file $argv
          else
              nvim $argv
          end
        '';
        gacp = ''
          set message $argv[1]
          git add .
          git commit -m "$message"
          git push
        '';
        mkcd = ''
          set folder $argv[1]
          set args $argv[2..]
          mkdir $args $folder
          cd $folder
        '';
        last_history_item = ''
          echo $history[1]
        '';
      };
      interactiveShellInit = ''
        set -g fish_prompt_pwd_dir_length 100
        set -gx VIRTUAL_ENV_DISABLE_PROMPT yes

        set -gx PATH ~/.local/bin ~/.cargo/bin "$HOME/.opencode/bin" ~/.bun/bin $PATH
        set -gx EDITOR nvim
        set -gx PYTHONPATH .

        abbr -a !! --position anywhere --function last_history_item

        if test -f ~/.config/local_configs/config.fish
            source ~/.config/local_configs/config.fish
        end
      '';
    };

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
