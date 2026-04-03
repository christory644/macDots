{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # ── Trouble (diagnostics list) ────────────────────────────────────
      trouble = {
        enable = true;
        settings = {
          modes = {
            diagnostics = {
              auto_close = false;
              auto_open = false;
            };
          };
        };
      };

      # ── Todo comments ─────────────────────────────────────────────────
      todo-comments = {
        enable = true;
        settings = {
          signs = true;
        };
      };

      # ── Dressing (improved UI for input/select) ───────────────────────
      dressing = {
        enable = true;
      };
    };

    # ── auto-session (extraPlugin — no native NixVim module) ───────────
    extraPlugins = with pkgs.vimPlugins; [
      auto-session
    ];

    extraConfigLua = ''
      -- ── auto-session ───────────────────────────────────────────────
      require("auto-session").setup({
        auto_restore_enabled = false,
        auto_session_suppress_dirs = {
          "~/",
          "~/repos",
          "~/Downloads",
          "~/Documents",
          "~/Desktop",
        },
      })
    '';

    keymaps = [
      # ── Trouble keymaps ───────────────────────────────────────────
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options.desc = "Workspace diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
        options.desc = "Document diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle focus=false<CR>";
        options.desc = "Symbols (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>cl";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>";
        options.desc = "LSP defs/refs (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xq";
        action = "<cmd>Trouble qflist toggle<CR>";
        options.desc = "Quickfix list (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xl";
        action = "<cmd>Trouble loclist toggle<CR>";
        options.desc = "Location list (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xt";
        action = "<cmd>Trouble todo toggle<CR>";
        options.desc = "TODOs (Trouble)";
      }

      # ── Todo-comments navigation ──────────────────────────────────
      {
        mode = "n";
        key = "<leader>nt";
        action.__raw = ''function() require("todo-comments").jump_next() end'';
        options.desc = "Next TODO comment";
      }
      {
        mode = "n";
        key = "<leader>pt";
        action.__raw = ''function() require("todo-comments").jump_prev() end'';
        options.desc = "Previous TODO comment";
      }

      # ── Auto-session keymaps ──────────────────────────────────────
      {
        mode = "n";
        key = "<leader>ss";
        action = "<cmd>SessionSave<CR>";
        options.desc = "Save session";
      }
      {
        mode = "n";
        key = "<leader>sr";
        action = "<cmd>SessionRestore<CR>";
        options.desc = "Restore session";
      }
    ];
  };
}
