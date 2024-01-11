{ inputs, outputs, nixpkgs, config, lib, pkgs, ... }: {

  home-manager.users.juuso.programs.nixvim = let neovim = (import ../../../nixosModules/neovim) { inherit config pkgs; }; in with neovim.config; {
    inherit colorschemes extraConfigVim extraConfigLua extraPackages plugins extraPlugins;
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
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
