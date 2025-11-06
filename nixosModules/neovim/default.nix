{ pkgs, ... }: {
  options = { };
  config = {
    colorschemes.base16 = {
      enable = true;
      colorscheme = "ia-dark";
    };
    extraConfigLua = ''
      -- https://git.sr.ht/~whynothugo/lsp_lines.nvim#setup
      vim.diagnostic.config({ virtual_text = false })
      vim.diagnostic.config({ virtual_lines = true })
      vim.opt.foldcolumn = "1"

      -- helper: collect items (folds or single lines) in [start_line, end_line]
      local function collect_items(start_line, end_line)
        local items = {}
        local line = start_line
        while line <= end_line do
          local fc = vim.fn.foldclosed(line)
          if fc ~= -1 and fc >= start_line and fc <= end_line then
            local fe = vim.fn.foldclosedend(line)
            local lines = vim.fn.getline(line, fe)
            table.insert(items, { key = lines[1], lines = lines })
            line = fe + 1
          else
            local text = vim.fn.getline(line)
            table.insert(items, { key = text, lines = { text } })
            line = line + 1
          end
        end
        return items
      end

      -- core sort routine: sorts items by key (first line), case-insensitive
      local function sort_items(items, cmp)
        cmp = cmp or function(a, b) return a.key:lower() < b.key:lower() end
        table.sort(items, cmp)
        local out = {}
        for _, it in ipairs(items) do
          vim.list_extend(out, it.lines)
        end
        return out
      end

      -- replace buffer region with sorted lines
      local function replace_region(start_line, end_line, sorted_lines)
        vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, sorted_lines)
      end

      -- public: sort visual selection treating folds as units
      function sort_visual()
        -- save view and folds
        local viewfile = vim.fn.tempname()
        vim.cmd("silent! mkview " .. vim.fn.fnameescape(viewfile))

        local start_line = vim.fn.line("'<")
        local end_line   = vim.fn.line("'>")

        -- collect and replace
        local items = collect_items(start_line, end_line)
        local sorted = sort_items(items)
        replace_region(start_line, end_line, sorted)

        vim.cmd("normal! zx")
        vim.cmd("silent! loadview " .. vim.fn.fnameescape(viewfile))
        vim.fn.delete(viewfile)
      end

      vim.api.nvim_create_user_command("FoldSortVisual", sort_visual, { range = true, desc = "Fold-aware sort (visual)" })
      vim.keymap.set("v", "<leader>fs", ":<C-U>FoldSortVisual<CR>", { desc = "Fold-aware sort (visual)" })
    '';
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
    extraPackages = with pkgs; [
      fd
      gcc
      ripgrep
      shellcheck
    ];
    extraPlugins = with pkgs.vimPlugins; [
      editorconfig-vim
    ];
    plugins = {
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
      fugitive.enable = true;
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = true;
        };
      };
      lsp = {
        enable = true;
        inlayHints = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
        };
      };
      lsp-format.enable = true;
      lsp-lines.enable = true;
      lualine = {
        enable = true;
        settings = {
          componentSeparators = {
            left = "";
            right = "";
          };
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
          sectionSeparators = {
            left = "";
            right = "";
          };
        };
      };
      luasnip.enable = true;
      noice.enable = true;
      none-ls = {
        enable = true;
        sources.formatting.nixpkgs_fmt.enable = true;
      };
      notify.enable = true;
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };
      treesitter = {
        enable = true;
        folding = true;
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
        nixvimInjections = true;
        settings.indent.enable = true;
      };
      treesitter-context.enable = true;
      web-devicons.enable = true;
    };
  };
}
