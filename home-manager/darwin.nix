{ config, lib, pkgs, ... }:

{

  imports = [
    <home-manager/nix-darwin>
  ];

  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  environment = {
    systemPackages = with pkgs; [
      git
      (pkgs.callPackage <nixpkgs/pkgs/os-specific/darwin/iproute2mac> { })
    ];
    variables = {
      EDITOR = "nvim";
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    taps = [
      "homebrew/cask"
    ];
    brews = [
      "pam-reattach"
    ];
    casks = [
      "balenaetcher"
      "handbrake"
      "remarkable"
      "vlc"
      "calibre"
      "kid3"
      "signal"
      "wireshark"
      "charles"
      "microsoft-teams"
      "slack"
      "x2goclient"
      "datagrip"
      "obs"
      "sourcetree"
      "zoom"
      "discord"
      "plex"
      "steam"
      "dyalog"
      "qbserve"
      "sublime-text"
      "firefox"
      "rar"
      "visual-studio-code"
    ];
    masApps = { };
  };

  programs = {
    fish.enable = true;
    fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";
  };

  security.pam.enableSudoTouchIdAuth = true;

  users.users.juuso = {
    name = "juuso";
    home = "/Users/juuso";
    shell = pkgs.fish;
  };
  environment.shells = [ pkgs.fish ];

  home-manager.users.juuso = { pkgs, ... }: {

    home.packages = with pkgs; [
      tree
      file

      python3
      rustup
      go

      aria2
      butane
      cloudflared
      ffmpeg
      gh
      imagemagick
      nmap
      exiftool
      pngquant
      podman
      ripgrep-all
      socat
      sox
      watch
      wireguard-go
      wireguard-tools
      yle-dl
      yt-dlp
      neofetch
    ];
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [ tilish ];
      extraConfig = ''
        set -g mouse on

        bind | split-window -h
        unbind %

        set -g focus-events on
      '';
      shortcut = "a";
    };

    programs.neovim = {
      enable = true;
      coc.enable = true;
      coc.settings = {
        "languageserver" = {
          go = {
            command = "gopls";
            rootPatterns = [ "go.mod" ];
            trace.server = "verbose";
            filetypes = [ "go" ];
          };
          nix = {
            command = "rnix-lsp";
            filetypes = [ "nix" ];
          };
        };
      };
      extraConfig = ''
        set number
        set cursorline

        set nobackup
        set noswapfile

        nnoremap <leader>n :NERDTreeFocus<CR>
        nnoremap <C-n> :NERDTree<CR>
        nnoremap <C-t> :NERDTreeToggle<CR>
        nnoremap <C-f> :NERDTreeFind<CR>

        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
        autocmd VimEnter * NERDTree | wincmd p

        autocmd BufEnter * highlight! link SignColumn LineNr

        augroup autoformat_settings
          autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
        augroup END

        lua << EOF
        require'nvim-treesitter.configs'.setup {
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          }
        }
        EOF
      '';
      extraPackages = with pkgs; [ rnix-lsp gopls nixpkgs-fmt ];
      plugins = with pkgs.vimPlugins; [
        nerdtree
        vim-devicons
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        nerdtree-git-plugin
        editorconfig-vim
        vim-codefmt
        vim-gitgutter
      ];
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
    };

    home.stateVersion = "22.11";

    editorconfig.enable = true;
    editorconfig.settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        max_line_width = 78;
        indent_style = "space";
        indent_size = 2;
      };
    };

    programs.bottom.enable = true;

    programs.alacritty = {
      enable = true;
      settings = {
        # Oxide colors
        colors = {
          primary = {
            background = "#212121";
            foreground = "#c0c5ce";
            bright_foreground = "#f3f4f5";
          };
          cursor = {
            text = "#212121";
            cursor = "#c0c5ce";
          };
          normal = {
            black = "#212121";
            red = "#e57373";
            green = "#a6bc69";
            yellow = "#fac863";
            blue = "#6699cc";
            magenta = "#c594c5";
            cyan = "#5fb3b3";
            white = "#c0c5ce";
          };
          bright = {
            black = "#5c5c5c";
            red = "#e57373";
            green = "#a6bc69";
            yellow = "#fac863";
            blue = "#6699cc";
            magenta = "#c594c5";
            cyan = "#5fb3b3";
            white = "#f3f4f5";
          };
          indexed_colors = [ ];
        };
        font = {
          normal = {
            family = "iMWritingMonoS Nerd Font";
          };
          size = 14;
        };
      };
    };
  };

  system.stateVersion = 4;
}
