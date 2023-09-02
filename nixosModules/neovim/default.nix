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
      let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.dylib'

      let g:himalaya_folder_picker = 'telescope'
      let g:himalaya_folder_picker_telescope_preview = 1

      let g:limelight_bop = '^'
      let g:limelight_eop = '$'

      nnoremap <leader>ff :Telescope find_files<CR>

      au BufRead,BufNewFile *.bqn setf bqn
      au BufRead,BufNewFile * if getline(1) =~ '^#!.*bqn$' | setf bqn | endif

      augroup autoformat_settings
        autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
      augroup END
    '';
    extraConfigLua = ''
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
      nixpkgs-fmt
      papis
      ripgrep
      sqlite
      yq-go
    ];
    plugins = {
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
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
      plenary-nvim
      telescope-nvim
      vim-codefmt
      vim-fugitive
    ] ++ [
      pkgs.bqn-vim
      pkgs.bqnlsp
      pkgs.nvim-bqn
      pkgs.papis-nvim
      pkgs.sqlite-lua
    ];

  };
}
