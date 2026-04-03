{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.harpoon = {
      enable = true;
      enableTelescope = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>ha";
        action.__raw = ''function() require("harpoon.mark").add_file() end'';
        options.desc = "Harpoon add file";
      }
      {
        mode = "n";
        key = "<leader>hh";
        action.__raw = ''function() require("harpoon.ui").toggle_quick_menu() end'';
        options.desc = "Harpoon quick menu";
      }
      {
        mode = "n";
        key = "<leader>1";
        action.__raw = ''function() require("harpoon.ui").nav_file(1) end'';
        options.desc = "Harpoon file 1";
      }
      {
        mode = "n";
        key = "<leader>2";
        action.__raw = ''function() require("harpoon.ui").nav_file(2) end'';
        options.desc = "Harpoon file 2";
      }
      {
        mode = "n";
        key = "<leader>3";
        action.__raw = ''function() require("harpoon.ui").nav_file(3) end'';
        options.desc = "Harpoon file 3";
      }
      {
        mode = "n";
        key = "<leader>4";
        action.__raw = ''function() require("harpoon.ui").nav_file(4) end'';
        options.desc = "Harpoon file 4";
      }
      {
        mode = "n";
        key = "<leader>hn";
        action.__raw = ''function() require("harpoon.ui").nav_next() end'';
        options.desc = "Harpoon next";
      }
      {
        mode = "n";
        key = "<leader>hp";
        action.__raw = ''function() require("harpoon.ui").nav_prev() end'';
        options.desc = "Harpoon prev";
      }
    ];
  };
}
