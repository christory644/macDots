{ pkgs, theme, ... }:

{
  programs.nixvim = {
    plugins = {
      # ── Noice (modern UI for messages, cmdline, popups) ──────────────
      noice = {
        enable = true;
        settings = {
          lsp = {
            # Override markdown rendering for LSP hover/signature
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
            progress = {
              enabled = false; # fidget handles this
            };
          };
          presets = {
            bottom_search = true;         # search bar at bottom
            command_palette = true;        # cmdline & popupmenu together
            long_message_to_split = true;  # long messages go to split
            lsp_doc_border = true;         # border around hover docs
          };
          routes = [
            # Skip "written" messages
            {
              filter = {
                event = "msg_show";
                kind = "";
                find = "written";
              };
              opts = { skip = true; };
            }
            # Skip search count messages
            {
              filter = {
                event = "msg_show";
                kind = "search_count";
              };
              opts = { skip = true; };
            }
          ];
        };
      };

      # Dependencies
      notify = {
        enable = true;
        settings = {
          background_colour = theme.palette.bg;
          fps = 30;
          render = "default";
          stages = "fade_in_slide_out";
          timeout = 3000;
          top_down = true;
        };
      };
    };

    # nui.nvim is auto-pulled by noice, but ensure it's available
    extraPlugins = with pkgs.vimPlugins; [
      nui-nvim
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>nd";
        action = "<cmd>Noice dismiss<CR>";
        options.desc = "Dismiss notifications";
      }
      {
        mode = "n";
        key = "<leader>nl";
        action = "<cmd>Noice last<CR>";
        options.desc = "Last notification";
      }
      {
        mode = "n";
        key = "<leader>nh";
        action = "<cmd>Noice history<CR>";
        options.desc = "Notification history";
      }
    ];
  };
}
