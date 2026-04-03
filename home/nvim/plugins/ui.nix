{ theme, ... }:

{
  programs.nixvim = {
    plugins = {
      # ── Statusline ────────────────────────────────────────────────────
      lualine = {
        enable = true;
        settings = {
          options = {
            theme.__raw = ''
              (function()
                local t = require("lualine.themes.${theme.apps.lualine}")
                -- Strip bold from all mode sections to fix fuzzy rendering
                for _, mode in ipairs({"normal","insert","visual","replace","command","inactive","terminal"}) do
                  if t[mode] and t[mode].a then
                    t[mode].a.gui = ""
                  end
                end
                return t
              end)()
            '';
            component_separators = { left = ""; right = ""; };
            section_separators = { left = ""; right = ""; };
            globalstatus = true;
          };
          sections = {
            lualine_a = [ "mode" ];
            lualine_b = [ "branch" "diff" "diagnostics" ];
            lualine_c = [ { __unkeyed-1 = "filename"; path = 1; } ];
            lualine_x = [ "encoding" "fileformat" "filetype" ];
            lualine_y = [ "progress" ];
            lualine_z = [ "location" ];
          };
        };
      };

      # ── Buffer tabs ───────────────────────────────────────────────────
      bufferline = {
        enable = true;
        settings = {
          options = {
            mode = "buffers";
            separator_style = "thin";
            diagnostics = "nvim_lsp";
            always_show_bufferline = true;
            show_buffer_close_icons = true;
            show_close_icon = false;
            offsets = [
              {
                filetype = "NvimTree";
                text = "File Explorer";
                highlight = "Directory";
                separator = true;
              }
            ];
          };
        };
      };

      # ── Keymap hints ──────────────────────────────────────────────────
      which-key = {
        enable = true;
        settings = {
          preset = "helix";
          delay = 500;
          spec = [
            { __unkeyed-1 = "<leader>b"; group = "Buffer"; }
            { __unkeyed-1 = "<leader>c"; group = "Code/Clear"; }
            { __unkeyed-1 = "<leader>d"; group = "Debug/Diagnostics"; }
            { __unkeyed-1 = "<leader>e"; group = "Explorer"; }
            { __unkeyed-1 = "<leader>f"; group = "Find"; }
            { __unkeyed-1 = "<leader>g"; group = "Git"; }
            { __unkeyed-1 = "<leader>h"; group = "Hunk"; }
            { __unkeyed-1 = "<leader>l"; group = "LazyGit"; }
            { __unkeyed-1 = "<leader>m"; group = "Format"; }
            { __unkeyed-1 = "<leader>n"; group = "Next/Notifications"; }
            { __unkeyed-1 = "<leader>T"; group = "Test"; }
            { __unkeyed-1 = "<leader>p"; group = "Prev"; }
            { __unkeyed-1 = "<leader>r"; group = "Rename/Restart"; }
            { __unkeyed-1 = "<leader>s"; group = "Split/Session/Substitute"; }
            { __unkeyed-1 = "<leader>t"; group = "Tab"; }
            { __unkeyed-1 = "<leader>w"; group = "Workspace"; }
            { __unkeyed-1 = "<leader>x"; group = "Trouble"; }
          ];
        };
      };

      # ── LSP progress indicator ─────────────────────────────────────────
      fidget = {
        enable = true;
        settings = {
          progress = {
            display = {
              done_icon = "✓";
              progress_icon = {
                pattern = "dots";
                period = 1;
              };
            };
          };
          notification = {
            window = {
              winblend = 0;  # match transparent setup
            };
          };
        };
      };

      # ── Indent guides ────────────────────────────────────────────────
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "┊";
          };
          scope = {
            enabled = true;
          };
          exclude = {
            filetypes = [
              "help"
              "dashboard"
              "NvimTree"
              "Trouble"
              "lazy"
            ];
          };
        };
      };
    };
  };
}
