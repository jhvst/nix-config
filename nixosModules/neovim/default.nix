{ config, pkgs, ... }: {
  options = { };
  config = {
    colorschemes.base16 = {
      enable = true;
      colorscheme = "ia-dark";
    };
    extraConfigVim = ''
      set cursorline
      set laststatus=2
      set nobackup
      set noswapfile
      set relativenumber
      set wrap linebreak

      let mapleader="\<SPACE>"

      nnoremap <leader>ff :Telescope find_files<CR>
    '';
    extraConfigLua = '''';
    extraPackages = with pkgs; [
      fd
      gcc
      ripgrep
      shellcheck
    ];
    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
        };
      };
      lsp-format.enable = true;
      luasnip.enable = true;
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = true;
        };
      };
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };
      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
        };
        nixvimInjections = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c # c is implicit dependency, not specifying it will lead to healtcheck errors
          diff
          fish
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          json
          lua
          luadoc
          make
          markdown # dep of noice
          markdown_inline # dep of noice
          nix
          query # implicit
          regex
          toml
          vim
          vimdoc
          xml
          yaml
        ];
      };
      fugitive.enable = true;
      noice.enable = true;
      notify.enable = true;
      cmp = {
        enable = true;
        settings = {
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
          snippet.expand = "luasnip";
          sources = [
            { name = "buffer"; }
            { name = "luasnip"; }
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "tmux"; }
          ];
        };
      };
      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "base16";
            iconsEnabled = false;
          };
          sections = {
            lualine_a = [ "" ];
            lualine_b = [ "" ];
            lualine_c = [ "location" { __unkeyed-1 = "filename"; path = 1; } "filetype" ];
            lualine_x = [ "diagonostics" ];
            lualine_y = [ "" ];
            lualine_z = [ "mode" ];
          };
          componentSeparators = {
            left = "";
            right = "";
          };
          sectionSeparators = {
            left = "";
            right = "";
          };
        };
      };
      web-devicons.enable = true;
      none-ls = {
        enable = true;
        sources.formatting.nixpkgs_fmt.enable = true;
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      editorconfig-vim
    ];
  };
}
