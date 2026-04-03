{ ... }:

{
  programs.nixvim = {
    plugins = {
      dap.enable = true;
      dap-ui.enable = true;
      dap-go.enable = true;
      dap-python.enable = true;
    };

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
    '';
  };
}
