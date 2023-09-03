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

      augroup autoformat_settings
        autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
      augroup END
    '';
    extraConfigLua = '''';
    extraPackages = with pkgs; [
      fd
      nixpkgs-fmt
      ripgrep
    ];
    plugins = {
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
        };
      };
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        showCurrentContext = true;
        showCurrentContextStart = true;
      };
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };
      treesitter.enable = true;
      fugitive.enable = true;
      coq-nvim = {
        enable = true;
        autoStart = true;
        installArtifacts = true;
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      editorconfig-vim
      himalaya-vim
      vim-codefmt
    ];
  };
}
