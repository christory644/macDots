{ ... }:

{
  programs.nixvim.keymaps = [
    # ── Exit insert mode ──────────────────────────────────────────────
    { mode = "i"; key = "jk"; action = "<ESC>"; options.desc = "Exit insert mode"; }
    { mode = "i"; key = "jj"; action = "<ESC>"; options.desc = "Exit insert mode"; }
    { mode = "i"; key = "kj"; action = "<ESC>"; options.desc = "Exit insert mode"; }
    { mode = "i"; key = "kk"; action = "<ESC>"; options.desc = "Exit insert mode"; }

    # ── Clear search highlights ───────────────────────────────────────
    { mode = "n"; key = "<leader>ch"; action = "<cmd>nohl<CR>"; options.desc = "Clear search highlights"; }

    # ── Delete without yanking ────────────────────────────────────────
    { mode = "n"; key = "x"; action = "\"_x"; options.desc = "Delete char without register"; }

    # ── Increment / Decrement ─────────────────────────────────────────
    { mode = "n"; key = "<leader>+"; action = "<C-a>"; options.desc = "Increment number"; }
    { mode = "n"; key = "<leader>-"; action = "<C-x>"; options.desc = "Decrement number"; }

    # ── Close buffer quickly ─────────────────────────────────────────
    { mode = "n"; key = "<S-q>"; action = "<cmd>bdelete<CR>"; options.desc = "Close buffer"; }

    # ── Resize splits ────────────────────────────────────────────────
    { mode = "n"; key = "<C-Up>"; action = "<cmd>resize +2<CR>"; options.desc = "Increase split height"; }
    { mode = "n"; key = "<C-Down>"; action = "<cmd>resize -2<CR>"; options.desc = "Decrease split height"; }
    { mode = "n"; key = "<C-Left>"; action = "<cmd>vertical resize -2<CR>"; options.desc = "Decrease split width"; }
    { mode = "n"; key = "<C-Right>"; action = "<cmd>vertical resize +2<CR>"; options.desc = "Increase split width"; }

    # ── Stay in visual indent mode ───────────────────────────────────
    { mode = "v"; key = "<"; action = "<gv"; options.desc = "Indent left and reselect"; }
    { mode = "v"; key = ">"; action = ">gv"; options.desc = "Indent right and reselect"; }

    # ── Move lines in visual mode ────────────────────────────────────
    { mode = "v"; key = "J"; action = ":m '>+1<CR>gv=gv"; options.desc = "Move selection down"; }
    { mode = "v"; key = "K"; action = ":m '<-2<CR>gv=gv"; options.desc = "Move selection up"; }

    # ── Window splits ─────────────────────────────────────────────────
    { mode = "n"; key = "<leader>sv"; action = "<C-w>v"; options.desc = "Split window vertically"; }
    { mode = "n"; key = "<leader>sh"; action = "<C-w>s"; options.desc = "Split window horizontally"; }
    { mode = "n"; key = "<leader>se"; action = "<C-w>="; options.desc = "Equalize split sizes"; }
    { mode = "n"; key = "<leader>sx"; action = "<cmd>close<CR>"; options.desc = "Close current split"; }

    # ── Window focus ──────────────────────────────────────────────────
    { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Focus left window"; }
    { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Focus lower window"; }
    { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Focus upper window"; }
    { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Focus right window"; }

    # ── Tabs ──────────────────────────────────────────────────────────
    { mode = "n"; key = "<leader>to"; action = "<cmd>tabnew<CR>"; options.desc = "Open new tab"; }
    { mode = "n"; key = "<leader>tx"; action = "<cmd>tabclose<CR>"; options.desc = "Close current tab"; }
    { mode = "n"; key = "<leader>tn"; action = "<cmd>tabn<CR>"; options.desc = "Next tab"; }
    { mode = "n"; key = "<leader>tp"; action = "<cmd>tabp<CR>"; options.desc = "Previous tab"; }
    { mode = "n"; key = "<leader>tf"; action = "<cmd>tabnew %<CR>"; options.desc = "Open file in new tab"; }

    # ── Buffers (cycle) ───────────────────────────────────────────────
    { mode = "n"; key = "H"; action = "<cmd>BufferLineCyclePrev<CR>"; options.desc = "Previous buffer"; }
    { mode = "n"; key = "L"; action = "<cmd>BufferLineCycleNext<CR>"; options.desc = "Next buffer"; }

    # ── Buffer management ─────────────────────────────────────────────
    { mode = "n"; key = "<leader>bx"; action = "<cmd>bdelete<CR>"; options.desc = "Close current buffer"; }
    {
      mode = "n";
      key = "<leader>bxl";
      action.__raw = ''
        function()
          require("bufferline").close_in_direction("left")
        end
      '';
      options.desc = "Close buffers to the left";
    }
    {
      mode = "n";
      key = "<leader>bxr";
      action.__raw = ''
        function()
          require("bufferline").close_in_direction("right")
        end
      '';
      options.desc = "Close buffers to the right";
    }
    {
      mode = "n";
      key = "<leader>bxf";
      action.__raw = ''
        function()
          require("bufferline").close_with_pick()
        end
      '';
      options.desc = "Pick buffer to close";
    }
    {
      mode = "n";
      key = "<leader>bs";
      action.__raw = ''
        function()
          require("bufferline").toggle_pin()
        end
      '';
      options.desc = "Pin/unpin buffer";
    }
    {
      mode = "n";
      key = "<leader>bf";
      action.__raw = ''
        function()
          require("bufferline").pick()
        end
      '';
      options.desc = "Pick buffer";
    }

    # ── Go to buffer by number ────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>1";
      action.__raw = ''function() require("bufferline").go_to(1, true) end'';
      options.desc = "Go to buffer 1";
    }
    {
      mode = "n";
      key = "<leader>2";
      action.__raw = ''function() require("bufferline").go_to(2, true) end'';
      options.desc = "Go to buffer 2";
    }
    {
      mode = "n";
      key = "<leader>3";
      action.__raw = ''function() require("bufferline").go_to(3, true) end'';
      options.desc = "Go to buffer 3";
    }
    {
      mode = "n";
      key = "<leader>4";
      action.__raw = ''function() require("bufferline").go_to(4, true) end'';
      options.desc = "Go to buffer 4";
    }
    {
      mode = "n";
      key = "<leader>5";
      action.__raw = ''function() require("bufferline").go_to(5, true) end'';
      options.desc = "Go to buffer 5";
    }
    {
      mode = "n";
      key = "<leader>6";
      action.__raw = ''function() require("bufferline").go_to(6, true) end'';
      options.desc = "Go to buffer 6";
    }
    {
      mode = "n";
      key = "<leader>7";
      action.__raw = ''function() require("bufferline").go_to(7, true) end'';
      options.desc = "Go to buffer 7";
    }
    {
      mode = "n";
      key = "<leader>8";
      action.__raw = ''function() require("bufferline").go_to(8, true) end'';
      options.desc = "Go to buffer 8";
    }
    {
      mode = "n";
      key = "<leader>9";
      action.__raw = ''function() require("bufferline").go_to(9, true) end'';
      options.desc = "Go to buffer 9";
    }
    {
      mode = "n";
      key = "<leader>$";
      action.__raw = ''function() require("bufferline").go_to(-1, true) end'';
      options.desc = "Go to last buffer";
    }
  ];
}
