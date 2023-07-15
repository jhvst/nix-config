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

      nnoremap <C-f> :NERDTreeFind<CR>
      nnoremap <C-n> :NERDTree<CR>
      nnoremap <C-t> :NERDTreeToggle<CR>
      nnoremap <leader>n :NERDTreeFocus<CR>
      let NERDTreeShowHidden=1

      autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
      autocmd VimEnter * NERDTree | wincmd p

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
          disable = { "rust", "nix" },
        }
      }
      require('crates').setup()
    '';
    extraPackages = with pkgs; [
      cbqn # bqnlsp assumes cbqn in path
      gopls
      inputs.bqnlsp.packages.${pkgs.system}.lsp
      nil
      nixpkgs-fmt
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
      coq_nvim
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
      nvim-dap
      nvim-dap-ui
      outputs.packages.${pkgs.system}.bqn-vim
      outputs.packages.${pkgs.system}.nvim-bqn
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
