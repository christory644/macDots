{ ... }:

{
  programs.nixvim = {
    plugins.diffview = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<CR>";
        options.desc = "Open diffview";
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<CR>";
        options.desc = "File history (current)";
      }
      {
        mode = "n";
        key = "<leader>gH";
        action = "<cmd>DiffviewFileHistory<CR>";
        options.desc = "File history (all)";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>DiffviewClose<CR>";
        options.desc = "Close diffview";
      }
    ];
  };
}
