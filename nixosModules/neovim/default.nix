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

      let g:himalaya_folder_picker = 'telescope'
      let g:himalaya_folder_picker_telescope_preview = 1

      nnoremap <leader>ff :Telescope find_files<CR>
    '';
    extraConfigLua = '''';
    extraPackages = with pkgs; [
      fd
      nixpkgs-fmt
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
        scope = {
          enabled = true;
          showStart = true;
        };
      };
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };
      treesitter = {
        enable = true;
        indent = true;
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
      nvim-cmp = {
        enable = true;
        snippet.expand = "luasnip";
        mapping = {
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = {
            action = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                else
                  fallback()
                end
              end
            '';
            modes = [
              "i"
              "s"
            ];
          };
        };
        sources = [
          { name = "buffer"; }
          { name = "luasnip"; }
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "tmux"; }
        ];
      };
      lualine = {
        enable = true;
        theme = "base16";
        iconsEnabled = false;
        sections = {
          lualine_a = [ "" ];
          lualine_b = [ "" ];
          lualine_c = [ "location" { name = "filename"; extraConfig.path = 1; } "filetype" ];
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
    extraPlugins = with pkgs.vimPlugins; [
      editorconfig-vim
      himalaya-vim
    ];
  };
}
