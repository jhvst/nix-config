{ inputs, outputs, config, lib, pkgs, ... }: {

  nixpkgs = {
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

    buildMachines = [{
      hostName = "muro";
      systems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
      maxJobs = 24;
    }];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true
    '';

    package = pkgs.nix;

  };

  services.nix-daemon.enable = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  environment = {
    systemPackages = with pkgs; [
      discord
      mpv
      utm
      zoom-us
    ];
    etc."wireguard/ponkila.conf" = {
      source = "${config.home-manager.users.juuso.home.homeDirectory}/.config/wireguard/ponkila.conf";
    };
  };

  networking.hostName = "darwin";

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
    brews = [ ];
    casks = [
      "balenaetcher"
      "element"
      "firefox"
      "handbrake"
      "homebrew/cask/dash"
      "numi"
      "remarkable"
      "rescuetime"
      "secretive"
      "signal"
      "slack"
      "sourcetree"
    ];
    masApps = { };
  };

  security.pam.enableSudoTouchIdAuth = true;

  users.users.juuso = {
    name = "juuso";
    home = "/Users/juuso";
    shell = pkgs.fish;
  };

  home-manager.users.juuso = { pkgs, ... }: {

    home.stateVersion = "23.05";

    sops = {
      defaultSopsFile = ./secrets/default.yaml;
      gnupg = with config.home-manager.users.juuso.home; {
        home = "${homeDirectory}/.gnupg/trezor";
      };
      secrets."wireguard/ponkila.conf" = {
        path = "%r/wireguard/ponkila.conf";
      };
      secrets."git/sendemail" = {
        path = "%r/git/sendemail";
      };
    };

    home.packages = with pkgs; [
      age
      bind # nslookup
      butane
      cloudflared
      exiftool
      ffmpeg_5
      file
      gnupg
      imagemagick
      lsof
      nmap
      pam-reattach
      passage
      pngquant
      reattach-to-user-namespace
      ripgrep-all
      socat
      sops
      subnetcalc
      tree
      trezor_agent
      trezord
      unar
      watch
      wireguard-go
      wireguard-tools
      yle-dl
      yt-dlp
    ];

    programs.fish = with config.home-manager.users.juuso; {
      enable = true;
      loginShellInit = ''
        set -x EDITOR nvim
        set -x ponkila (getconf DARWIN_USER_TEMP_DIR)${sops.secrets."wireguard/ponkila.conf".name}
        set -x GNUPGHOME ${home.homeDirectory}/.gnupg/trezor
        set -x PATH '${lib.concatStringsSep ":" [
          "${home.homeDirectory}/.nix-profile/bin"
          "/run/wrappers/bin"
          "/etc/profiles/per-user/${home.username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/opt/homebrew/bin"
          "/usr/bin"
          "/sbin"
          "/bin"
        ]}'
      '';
    };

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        extrakto # Ctrl+a+Tab
        tilish # Option+Enter
        tmux-fzf # Ctrl+a+Shift+f
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
        let NERDTreeShowHidden=1

        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
        autocmd VimEnter * NERDTree | wincmd p

        au BufRead,BufNewFile *.bqn setf bqn
        au BufRead,BufNewFile * if getline(1) =~ '^#!.*bqn$' | setf bqn | endif

        au BufRead,BufNewFile *.md setf markdown

        augroup autoformat_settings
          autocmd FileType html,css,sass,scss,less,json,js AutoFormatBuffer js-beautify
          autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
          autocmd FileType rust AutoFormatBuffer rustfmt
          autocmd Filetype yaml AutoFormatBuffer yamlfmt
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
        nodePackages.grammarly-languageserver
        nodePackages.js-beautify
        rustfmt
        yamlfmt
      ];
      plugins = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        coc-html
        coc-rust-analyzer
        coc-tsserver
        coc-yaml
        crates-nvim
        editorconfig-vim
        gitsigns-nvim
        idris-vim
        indent-blankline-nvim
        limelight-vim # :LimeLight (also, consider :setlocal spell spelllang=en_us
        markdown-preview-nvim # :MarkdownPreview
        nerdtree
        nerdtree-git-plugin
        nvim-base16
        vim-codefmt
        vim-devicons
        vim-fugitive
      ] ++ [
        outputs.packages.aarch64-darwin.bqn-vim
        outputs.packages.aarch64-darwin.nvim-bqn
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

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      includes = with config.home-manager.users.juuso; [{
        path = sops.secrets."git/sendemail".path;
      }];
      signing.key = "8F84B8738E67A3453F05D29BC2DC6A67CB7F891F";
      signing.signByDefault = true;
      userEmail = "juuso@ponkila.com";
      userName = "Juuso Haavisto";
      ignores = [
        ".DS_Store"
      ];
    };
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.stateVersion = 4;
}
