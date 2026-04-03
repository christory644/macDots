{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.gitsigns = {
      enable = true;

      settings = {
        on_attach.__raw = ''
          function(bufnr)
            local gs = require("gitsigns")

            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map("n", "<leader>ghn", function()
              if vim.wo.diff then return "]c" end
              vim.schedule(function() gs.next_hunk() end)
              return "<Ignore>"
            end, { expr = true, desc = "Next hunk" })

            map("n", "<leader>ghp", function()
              if vim.wo.diff then return "[c" end
              vim.schedule(function() gs.prev_hunk() end)
              return "<Ignore>"
            end, { expr = true, desc = "Previous hunk" })

            -- Stage / Reset
            map({ "n", "v" }, "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
            map({ "n", "v" }, "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
            map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
            map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
            map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })

            -- Preview / Blame / Diff
            map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
            map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
            map("n", "<leader>hB", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
            map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
          end
        '';
      };
    };

    # Lazygit integration
    extraPlugins = with pkgs.vimPlugins; [
      lazygit-nvim
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>lg";
        action = "<cmd>LazyGit<CR>";
        options.desc = "Open LazyGit";
      }
    ];
  };
}
