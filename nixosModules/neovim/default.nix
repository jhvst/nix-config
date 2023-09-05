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
    ];
  };
}
