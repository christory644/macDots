{ ... }:

{
  programs.nixvim = {
    plugins.telescope = {
      enable = true;

      extensions = {
        fzf-native.enable = true;
      };

      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          options.desc = "Find files";
        };
        "<leader>fs" = {
          action = "live_grep";
          options.desc = "Live grep";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Find buffers";
        };
        "<leader>fr" = {
          action = "oldfiles";
          options.desc = "Recent files";
        };
        "<leader>fc" = {
          action = "grep_string";
          options.desc = "Grep string under cursor";
        };
      };
    };

    plugins.web-devicons.enable = true;

    # TodoTelescope keymap (depends on todo-comments plugin in utils.nix)
    keymaps = [
      {
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>TodoTelescope<CR>";
        options.desc = "Find TODOs";
      }
    ];
  };
}
