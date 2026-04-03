{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # ── File browser (oil.nvim) ───────────────────────────────────────
      oil = {
        enable = true;
        settings = {
          view_options = {
            show_hidden = true;
          };
          keymaps = {
            "g?" = "actions.show_help";
            "<CR>" = "actions.select";
            "<C-v>" = "actions.select_vsplit";
            "<C-s>" = "actions.select_split";
            "<C-t>" = "actions.select_tab";
            "<C-p>" = "actions.preview";
            "<C-c>" = "actions.close";
            "<C-r>" = "actions.refresh";
            "-" = "actions.parent";
            "_" = "actions.open_cwd";
            "`" = "actions.cd";
            "~" = "actions.tcd";
            "gs" = "actions.change_sort";
            "gx" = "actions.open_external";
            "g." = "actions.toggle_hidden";
          };
        };
      };

      # ── Flash (jump / search) ─────────────────────────────────────────
      flash = {
        enable = true;
        settings = {
          modes = {
            search.enabled = false;
          };
        };
      };

      # ── Surround ──────────────────────────────────────────────────────
      nvim-surround = {
        enable = true;
      };

      # ── Comment ────────────────────────────────────────────────────────
      comment = {
        enable = true;
        settings = {
          pre_hook.__raw = ''
            require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
          '';
        };
      };

      ts-context-commentstring = {
        enable = true;
        settings = {
          enable_autocmd = false;
        };
      };

      # ── Auto pairs ────────────────────────────────────────────────────
      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true;
          ts_config = {
            lua = [ "string" ];
            javascript = [ "template_string" ];
          };
        };
      };

      # ── NvimTree ───────────────────────────────────────────────────────
      nvim-tree = {
        enable = true;
        settings = {
          filters.dotfiles = false;
          git.ignore = false;
          renderer = {
            indent_markers.enable = true;
            icons.show = {
              file = true;
              folder = true;
              folder_arrow = true;
              git = true;
            };
          };
          view.width = 35;
          actions.open_file = {
            quit_on_open = false;
            resize_window = true;
          };
        };
      };
    };

    # ── substitute.nvim (extraPlugin — no native NixVim module) ────────
    extraPlugins = with pkgs.vimPlugins; [
      substitute-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "vim-maximizer";
        src = pkgs.fetchFromGitHub {
          owner = "szw";
          repo = "vim-maximizer";
          rev = "2e54952fe91e140a2e69f35f22131219fcd9c5f1";
          hash = "sha256-+VPcMn4NuxLRpY1nXz7APaXlRQVZD3Y7SprB/hvNKww=";
        };
      })
    ];

    extraConfigLua = ''
      -- ── substitute.nvim ────────────────────────────────────────────
      require("substitute").setup()

      -- ── vim-maximizer has no Lua setup needed ──────────────────────
    '';

    keymaps = [
      # Oil
      {
        mode = "n";
        key = "<leader>eo";
        action = "<cmd>Oil<CR>";
        options.desc = "Open Oil file browser";
      }
      {
        mode = "n";
        key = "-";
        action = "<cmd>Oil<CR>";
        options.desc = "Open parent directory";
      }

      # Flash — operator-pending mode for motions (s/S in normal reserved for substitute)
      {
        mode = "o";
        key = "s";
        action.__raw = ''function() require("flash").jump() end'';
        options.desc = "Flash jump";
      }
      {
        mode = "o";
        key = "S";
        action.__raw = ''function() require("flash").treesitter() end'';
        options.desc = "Flash treesitter";
      }

      # Substitute
      {
        mode = "n";
        key = "s";
        action.__raw = ''function() require("substitute").operator() end'';
        options.desc = "Substitute operator";
      }
      {
        mode = "n";
        key = "ss";
        action.__raw = ''function() require("substitute").line() end'';
        options.desc = "Substitute line";
      }
      {
        mode = "n";
        key = "S";
        action.__raw = ''function() require("substitute").eol() end'';
        options.desc = "Substitute to EOL";
      }
      {
        mode = "x";
        key = "s";
        action.__raw = ''function() require("substitute").visual() end'';
        options.desc = "Substitute visual";
      }

      # Vim-maximizer
      {
        mode = "n";
        key = "<leader>sm";
        action = "<cmd>MaximizerToggle<CR>";
        options.desc = "Toggle maximize split";
      }

      # NvimTree
      {
        mode = "n";
        key = "<leader>ee";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = "n";
        key = "<leader>ef";
        action = "<cmd>NvimTreeFindFile<CR>";
        options.desc = "Find file in tree";
      }
      {
        mode = "n";
        key = "<leader>ec";
        action = "<cmd>NvimTreeCollapse<CR>";
        options.desc = "Collapse tree";
      }
      {
        mode = "n";
        key = "<leader>er";
        action = "<cmd>NvimTreeRefresh<CR>";
        options.desc = "Refresh tree";
      }
    ];
  };
}
