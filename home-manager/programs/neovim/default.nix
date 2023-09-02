{ inputs, outputs, nixpkgs, config, lib, pkgs, ... }: {

  home-manager.users.juuso.programs.nixvim = {

    enable = true;
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
      let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.dylib'

      let g:himalaya_folder_picker = 'telescope'
      let g:himalaya_folder_picker_telescope_preview = 1

      let g:limelight_bop = '^'
      let g:limelight_eop = '$'

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
    extraConfigLua = ''
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
      inputs.bqnlsp.packages.${pkgs.system}.lsp
      nixpkgs-fmt
      nodePackages.js-beautify
      papis
      ripgrep
      rustfmt
      sqlite
      yamlfmt
      yq-go
    ];
    plugins = {
      lsp = {
        enable = true;
        servers = {
          gopls.enable = true;
          html.enable = true;
          nil_ls.enable = true;
          rust-analyzer.enable = true;
          tsserver.enable = true;
          yamlls.enable = true;
        };
        preConfig = ''
          local configs = require('lspconfig.configs')
          local util = require('lspconfig.util')

          if not configs.bqnlsp then
            configs.bqnlsp = {
              default_config = {
                cmd = { 'bqnlsp' },
                cmd_env = {},
                filetypes = { 'bqn' },
                root_dir = util.find_git_ancestor,
                single_file_support = false,
              },
              docs = {
                description = [[ BQN Language Server ]],
                default_config = {
                  root_dir = [[util.find_git_ancestor]],
                },
              },
            }
          end
        '';
      };
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        showCurrentContext = true;
        showCurrentContextStart = true;
      };
      treesitter.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      coq_nvim
      crates-nvim
      editorconfig-vim
      goyo-vim
      himalaya-vim
      limelight-vim # :LimeLight (also, consider :setlocal spell spelllang=en_us
      markdown-preview-nvim # :MarkdownPreview
      nui-nvim
      null-ls-nvim
      nvim-cmp
      nvim-dap
      nvim-dap-ui
      outputs.packages.${pkgs.system}.bqn-vim
      outputs.packages.${pkgs.system}.nvim-bqn
      pkgs.vimExtraPlugins.papis-nvim
      pkgs.vimExtraPlugins.sqlite-lua
      plenary-nvim
      telescope-nvim
      vim-codefmt
      vim-fugitive
    ];
    viAlias = true;
    vimAlias = true;
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