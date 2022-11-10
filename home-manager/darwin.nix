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
      (pkgs.callPackage <nixpkgs/pkgs/os-specific/darwin/mas> { })
    ];
    variables = {
      EDITOR = "nvim";
    };
  };

  homebrew = {
    enable = true;
    taps = [
      "homebrew/cask"
    ];
    brews = [
      "pam-reattach"
    ];
    casks = [
      "balenaetcher"
      "calibre"
      "charles"
      "datagrip"
      "discord"
      "dyalog"
      "firefox"
      "handbrake"
      "kid3"
      "microsoft-teams"
      "obs"
      "plex"
      "qbserve"
      "rar"
      "remarkable"
      "signal"
      "slack"
      "sourcetree"
      "steam"
      "sublime-text"
      "visual-studio-code"
      "vlc"
      "wireshark"
      "x2goclient"
      "zoom"
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
      file
      tree

      go
      python3
      rustup

      aria2
      butane
      cloudflared
      exiftool
      ffmpeg
      gh
      imagemagick
      neofetch
      nmap
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
    ];
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        tilish # Option+Enter
        tmux-fzf # Ctrl+a+Shift+f
        extrakto # Ctrl+a+Tab
      ];
      extraConfig = ''
        set -g @tilish-dmenu 'on'
        set -g mouse on

        bind | split-window -h
        unbind %

        set -g focus-events on
      '';
      shortcut = "a";
    };

    programs.fzf.enable = true;

    programs.nushell = {
      enable = true;
      envFile.text = ''
        let-env PATH = ($env.PATH | append '/run/current-system/sw/bin')
      '';
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
            command = "nil";
            filetypes = [ "nix" ];
            rootPatterns = [ "flake.nix" ];
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
        vim.cmd('colorscheme base16-ia-dark')
        require'nvim-treesitter.configs'.setup {
          highlight = {
            enable = true,
            disable = { "rust" },
            additional_vim_regex_highlighting = false,
          }
        }
        EOF
      '';
      extraPackages = with pkgs; [ nil gopls nixpkgs-fmt ];
      plugins = with pkgs.vimPlugins; [
        nerdtree
        vim-devicons
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        nerdtree-git-plugin
        editorconfig-vim
        nvim-base16
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
