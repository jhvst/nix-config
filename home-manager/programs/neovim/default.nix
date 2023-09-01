{ inputs, outputs, nixpkgs, config, lib, pkgs, ... }: {

  home-manager.users.juuso.programs.neovim = {

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
          command = "bqnlsp";
          filetypes = [ "bqn" ];
        };
      };
    };
    defaultEditor = true;
    extraConfig = ''
      set cursorline
      set laststatus=2
      set nobackup
      set noswapfile
      set relativenumber
      set wrap linebreak

      let mapleader="\<SPACE>"
      let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.dylib'

      let g:himalaya_folder_picker = 'telescope'
      let g:himalaya_folder_picker_telescope_preview = 1

      nnoremap <leader>ff :Telescope find_files<CR>

      au BufRead,BufNewFile *.bqn setf bqn
      au BufRead,BufNewFile * if getline(1) =~ '^#!.*bqn$' | setf bqn | endif

      augroup autoformat_settings
        autocmd FileType html,css,sass,scss,less,json,js AutoFormatBuffer js-beautify
        autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
        autocmd FileType rust AutoFormatBuffer rustfmt
        autocmd Filetype yaml AutoFormatBuffer yamlfmt
      augroup END
    '';
    extraLuaConfig = ''
      require('gitsigns').setup()
      require("indent_blankline").setup {
        show_current_context = true,
        show_current_context_start = true,
      }
      vim.cmd('colorscheme base16-ia-dark')
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
        }
      }
      require('crates').setup()
      require("papis").setup({
        db_path = "/Users/juuso/.papis/papis-nvim.sqlite3",
        papis_python = {
          dir = "/Users/juuso/.papis",
          info_name = "info.yaml",
          notes_name = [[notes.org]],
        },
        enable_keymaps = true,
      })
    '';
    extraPackages = with pkgs; [
      cbqn # bqnlsp assumes cbqn in path
      fd
      gopls
      inputs.bqnlsp.packages.${pkgs.system}.lsp
      nil
      nixpkgs-fmt
      nodePackages.js-beautify
      papis
      ripgrep
      rustfmt
      sqlite
      tree-sitter
      yamlfmt
      yq-go
    ];
    plugins = with pkgs.vimPlugins; [
      coc-html
      coc-rust-analyzer
      coc-tsserver
      coc-yaml
      coq_nvim
      crates-nvim
      editorconfig-vim
      gitsigns-nvim
      himalaya-vim
      idris-vim
      indent-blankline-nvim
      limelight-vim # :LimeLight (also, consider :setlocal spell spelllang=en_us
      markdown-preview-nvim # :MarkdownPreview
      nui-nvim
      null-ls-nvim
      nvim-base16
      nvim-cmp
      nvim-dap
      nvim-dap-ui
      nvim-treesitter.withAllGrammars
      outputs.packages.${pkgs.system}.bqn-vim
      outputs.packages.${pkgs.system}.nvim-bqn
      pkgs.vimExtraPlugins.papis-nvim
      pkgs.vimExtraPlugins.sqlite-lua
      plenary-nvim
      telescope-nvim
      vim-codefmt
      vim-devicons
      vim-fugitive
    ];
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
  };

  home-manager.users.juuso.editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = false;
        max_line_width = 78;
        indent_style = "space";
        indent_size = 2;
      };
    };
  };

}
