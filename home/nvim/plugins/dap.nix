{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      dap.enable = true;
      dap-ui.enable = true;
      dap-go.enable = true;
      dap-python.enable = true;
    };

    # DAP debug adapters for additional languages
    extraPlugins = with pkgs.vimPlugins; [
      nvim-dap-vscode-js
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>db";
        action.__raw = ''function() require("dap").toggle_breakpoint() end'';
        options.desc = "Toggle breakpoint";
      }
      {
        mode = "n";
        key = "<leader>dB";
        action.__raw = ''
          function()
            require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
          end
        '';
        options.desc = "Conditional breakpoint";
      }
      {
        mode = "n";
        key = "<leader>dc";
        action.__raw = ''function() require("dap").continue() end'';
        options.desc = "Continue";
      }
      {
        mode = "n";
        key = "<leader>di";
        action.__raw = ''function() require("dap").step_into() end'';
        options.desc = "Step into";
      }
      {
        mode = "n";
        key = "<leader>do";
        action.__raw = ''function() require("dap").step_over() end'';
        options.desc = "Step over";
      }
      {
        mode = "n";
        key = "<leader>dO";
        action.__raw = ''function() require("dap").step_out() end'';
        options.desc = "Step out";
      }
      {
        mode = "n";
        key = "<leader>dr";
        action.__raw = ''function() require("dap").repl.open() end'';
        options.desc = "Open REPL";
      }
      {
        mode = "n";
        key = "<leader>du";
        action.__raw = ''function() require("dapui").toggle() end'';
        options.desc = "Toggle DAP UI";
      }
      {
        mode = "n";
        key = "<leader>dx";
        action.__raw = ''function() require("dap").terminate() end'';
        options.desc = "Terminate debug session";
      }
      {
        mode = "n";
        key = "<leader>dl";
        action.__raw = ''function() require("dap").run_last() end'';
        options.desc = "Re-run last debug session";
      }
    ];

    extraConfigLua = ''
      -- Automatically open/close dap-ui when debugging starts/stops
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- ── JS/TS debug adapter (vscode-js-debug) ────────────────────────
      require("dap-vscode-js").setup({
        debugger_path = "${pkgs.vscode-js-debug}/lib/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })

      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "''${file}",
            cwd = "''${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "''${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            url = "http://localhost:3000",
            webRoot = "''${workspaceFolder}",
          },
        }
      end

      -- ── Rust debug adapter (codelldb via rust-analyzer) ───────────────
      dap.adapters.codelldb = {
        type = "server",
        port = "''${port}",
        executable = {
          command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb",
          args = { "--port", "''${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "''${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- ── Elixir debug adapter (elixir-ls includes DAP) ────────────────
      dap.adapters.mix_task = {
        type = "executable",
        command = "${pkgs.elixir-ls}/bin/elixir-ls",
        args = {},
      }

      dap.configurations.elixir = {
        {
          type = "mix_task",
          name = "mix test",
          task = "test",
          taskArgs = { "--trace" },
          request = "launch",
          startApps = true,
          projectDir = "''${workspaceFolder}",
          requireFiles = { "test/**/test_helper.exs", "test/**/*_test.exs" },
        },
        {
          type = "mix_task",
          name = "phx.server",
          task = "phx.server",
          request = "launch",
          projectDir = "''${workspaceFolder}",
        },
      }
    '';
  };
}
