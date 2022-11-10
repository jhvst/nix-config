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

  security.pam.enableSudoTouchIdAuth = true;

  users.users.juuso = {
    name = "juuso";
    home = "/Users/juuso";
    shell = pkgs.nushell;
  };
  environment.shells = [ pkgs.nushell ];

  # nushell: ductape for whomever decision it was to search for Application Support instead of home config
  environment.extraInit = ''
    ln -s $HOME/.config/nushell/env.nu "$HOME/Library/Application Support/nushell/env.nu"
    ln -s $HOME/.config/nushell/config.nu "$HOME/Library/Application Support/nushell/config.nu"
  '';

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

    programs.nushell = with config.home-manager.users.juuso.home; {
      enable = true;
      configFile.text = ''
        def nuopen [arg, --raw (-r)] { if $raw { open -r $arg } else { open $arg } }
        alias open = ^open
      '';
      envFile.text = ''
        let-env NIX_PATH = "${lib.concatStringsSep ":" [
          "darwin-config=${lib.concatStringsSep ":" [
            "${homeDirectory}/.nixpkgs/darwin-configuration.nix"
            "${homeDirectory}/.nix-defexpr/channels"
          ]}"
          "nixpkgs=${lib.concatStringsSep ":" [
            "/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
            "/nix/var/nix/profiles/per-user/root/channels"
          ]}"
        ]}"
        let-env PATH = '${lib.concatStringsSep ":" [
          "${homeDirectory}/.nix-profile/bin"
          "/run/wrappers/bin"
          "/etc/profiles/per-user/${username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/opt/homebrew/bin"
          "/usr/bin"
          "/bin"
        ]}'
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
        set cursorline
        set laststatus=2
        set nobackup
        set noswapfile
        set relativenumber

        nnoremap <C-f> :NERDTreeFind<CR>
        nnoremap <C-n> :NERDTree<CR>
        nnoremap <C-t> :NERDTreeToggle<CR>
        nnoremap <leader>n :NERDTreeFocus<CR>

        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
        autocmd VimEnter * NERDTree | wincmd p

        augroup autoformat_settings
          autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
          autocmd FileType rust AutoFormatBuffer rustfmt
        augroup END

        lua << EOF
        require('gitsigns').setup()
        require("indent_blankline").setup {
          show_current_context = true,
          show_current_context_start = true,
        }
        vim.cmd('colorscheme base16-ia-dark')
        require'nvim-treesitter.configs'.setup {
          highlight = {
            enable = true,
            disable = { "rust" },
          }
        }
        require('crates').setup()
        EOF
      '';
      extraPackages = with pkgs; [ nil gopls nixpkgs-fmt rustfmt ];
      plugins = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        coc-rust-analyzer
        crates-nvim
        editorconfig-vim
        gitsigns-nvim
        indent-blankline-nvim
        limelight-vim # :LimeLight (also, consider :setlocal spell spelllang=en_us
        markdown-preview-nvim # :MarkdownPreview
        nerdtree
        nerdtree-git-plugin
        nvim-base16
        vim-codefmt
        vim-devicons
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

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.stateVersion = 4;
}
