{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # ── Neotest (test runner framework) ──────────────────────────────
      neotest = {
        enable = true;
        settings = {
          quickfix = {
            open = false;  # don't auto-open quickfix
          };
          output = {
            enabled = true;
            open_on_run = true;
          };
          status = {
            enabled = true;
            signs = true;
            virtual_text = true;
          };
        };

        adapters = {
          jest = {
            enable = true;
            settings = {
              jestCommand = "npx jest";
            };
          };
          vitest = {
            enable = true;
          };
          golang = {
            enable = true;
          };
          python = {
            enable = true;
            settings = {
              runner = "pytest";
            };
          };
          rust = {
            enable = true;
          };
          elixir = {
            enable = true;
          };
        };
      };
    };

    keymaps = [
      # ── Test runner keymaps ──────────────────────────────────────
      {
        mode = "n";
        key = "<leader>Tt";
        action.__raw = ''function() require("neotest").run.run() end'';
        options.desc = "Run nearest test";
      }
      {
        mode = "n";
        key = "<leader>Tf";
        action.__raw = ''function() require("neotest").run.run(vim.fn.expand("%")) end'';
        options.desc = "Run tests in file";
      }
      {
        mode = "n";
        key = "<leader>Ts";
        action.__raw = ''function() require("neotest").run.run({ suite = true }) end'';
        options.desc = "Run test suite";
      }
      {
        mode = "n";
        key = "<leader>Tl";
        action.__raw = ''function() require("neotest").run.run_last() end'';
        options.desc = "Re-run last test";
      }
      {
        mode = "n";
        key = "<leader>To";
        action.__raw = ''function() require("neotest").output.open({ enter = true }) end'';
        options.desc = "Show test output";
      }
      {
        mode = "n";
        key = "<leader>Tp";
        action.__raw = ''function() require("neotest").output_panel.toggle() end'';
        options.desc = "Toggle output panel";
      }
      {
        mode = "n";
        key = "<leader>Tu";
        action.__raw = ''function() require("neotest").summary.toggle() end'';
        options.desc = "Toggle test summary";
      }
      {
        mode = "n";
        key = "<leader>Tx";
        action.__raw = ''function() require("neotest").run.stop() end'';
        options.desc = "Stop running test";
      }
      {
        mode = "n";
        key = "<leader>Td";
        action.__raw = ''function() require("neotest").run.run({ strategy = "dap" }) end'';
        options.desc = "Debug nearest test";
      }
    ];
  };
}
