{ inputs, outputs, config, lib, pkgs, ... }:

let
  nvim-bqn = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-bqn";
    version = "unstable";
    src = builtins.fetchGit {
      url = "https://git.sr.ht/~detegr/nvim-bqn";
      rev = "bbe1a8d93f490d79e55dd0ddf22dc1c43e710eb3";
    };
    meta.homepage = "https://git.sr.ht/~detegr/nvim-bqn/";
  };

in
{

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nix.extraOptions = ''
    builders = ssh://muro x86_64-linux
  '';

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  environment = {
    systemPackages = with pkgs; [
      # bind
      file
      git
      lsof
      nmap
      socat
      tree
      unar
      watch
    ];
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
      "reattach-to-user-namespace"
    ];
    casks = [
      "handbrake"
      "balenaetcher"
      "datagrip"
      "firefox"
      "homebrew/cask/dash"
      "kindle"
      "microsoft-teams"
      "numi"
      "obs"
      "remarkable"
      "signal"
      "slack"
      "sourcetree"
      "steam"
      "utm"
      "wireshark"
      "x2goclient"
      "zoom"
      "element"
      "secretive"
      "rescuetime"
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

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      direnv
      butane
      cloudflared
      exiftool
      ffmpeg_5
      gh
      imagemagick
      pngquant
      ripgrep-all
      wireguard-go
      wireguard-tools
      yle-dl
      yt-dlp
      subnetcalc

      mpv
      discord
      gimp
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
      envFile.text = ''
        let-env NIXPKGS_ALLOW_UNFREE = 1
        let-env EDITOR = "nvim"
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
          "/sbin"
          "/bin"
        ]}'
      '';
    };

    programs.neovim = {
      enable = true;
      coc.enable = true;
      coc.settings = {
        "languageserver" = {
          tsserver = {
            command = "typescript-language-server";
            args = [ "--stdio" "--tsserver-path=${pkgs.nodePackages.typescript}" ];
            filetypes = [ "js" ];
          };
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
          bqn = {
            command = "/Users/juuso/.nix-profile/bin/bqnlsp";
            filetypes = [ "bqn" ];
          };
          grammarly = {
            command = "grammarly-languageserver";
            args = [ "--stdio" ];
            initializationOptions = {
              clientId = "client_BaDkMgx4X19X9UxxYRCXZo";
            };
            filetypes = [ "markdown" ];
          };
        };
      };
      extraConfig = ''
        set cursorline
        set laststatus=2
        set nobackup
        set noswapfile
        set relativenumber
        set wrap linebreak

        nnoremap <C-f> :NERDTreeFind<CR>
        nnoremap <C-n> :NERDTree<CR>
        nnoremap <C-t> :NERDTreeToggle<CR>
        nnoremap <leader>n :NERDTreeFocus<CR>

        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
        autocmd VimEnter * NERDTree | wincmd p

        au BufRead,BufNewFile *.bqn setf bqn
        au BufRead,BufNewFile * if getline(1) =~ '^#!.*bqn$' | setf bqn | endif

        au BufRead,BufNewFile *.md setf markdown
        au BufRead,BufNewFile *.js setf js

        augroup autoformat_settings
          autocmd FileType html,css,sass,scss,less,json,js AutoFormatBuffer js-beautify
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
      extraPackages = with pkgs; [
        gopls
        nil
        nixpkgs-fmt
        nodePackages.js-beautify
        nodePackages.grammarly-languageserver
        rustfmt
        cbqn
        nodePackages.typescript-language-server
        nodePackages.typescript
      ];
      plugins = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        coc-html
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
        nvim-bqn
        bqn-vim
        idris-vim
      ];
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
    };

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
          normal.family = "iMWritingMonoS Nerd Font";
          size = 14;
        };
      };
    };
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
}
