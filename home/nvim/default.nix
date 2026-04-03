{ ... }:

{
  imports = [
    ./keymaps.nix
    ./theme.nix
    ./plugins/telescope.nix
    ./plugins/treesitter.nix
    ./plugins/lsp.nix
    ./plugins/cmp.nix
    ./plugins/dap.nix
    ./plugins/git.nix
    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/formatting.nix
    ./plugins/utils.nix
    ./plugins/alpha.nix
    ./plugins/harpoon.nix
    ./plugins/undotree.nix
    ./plugins/diffview.nix
  ];

  programs.nixvim = {
    enable = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    opts = {
      # Line numbers
      relativenumber = true;
      number = true;

      # Indentation
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;

      # Display
      wrap = false;
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;
      background = "dark";

      # Clipboard
      clipboard = "unnamedplus";

      # Mouse
      mouse = "nv";

      # Splits
      splitright = true;
      splitbelow = true;

      # Search
      ignorecase = true;
      smartcase = true;

      # Files
      swapfile = false;
      undofile = true;

      # Spell (used in markdown/gitcommit autocommands)
      spelllang = "en_us";
    };

    # ── Autocommands ──────────────────────────────────────────────────
    autoCmd = [
      # Highlight yanked text briefly
      {
        event = "TextYankPost";
        pattern = "*";
        callback.__raw = ''
          function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
          end
        '';
        desc = "Highlight yanked text";
      }

      # q closes help, quickfix, man pages, and lspinfo
      {
        event = "FileType";
        pattern = [ "help" "qf" "man" "lspinfo" "checkhealth" ];
        callback.__raw = ''
          function(event)
            vim.bo[event.buf].buflisted = false
            vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
          end
        '';
        desc = "Close help/qf/man with q";
      }

      # Word wrap and spell check for prose
      {
        event = "FileType";
        pattern = [ "markdown" "gitcommit" ];
        callback.__raw = ''
          function()
            vim.opt_local.wrap = true
            vim.opt_local.spell = true
          end
        '';
        desc = "Wrap and spell for prose";
      }

      # Prevent auto-comment on new lines
      {
        event = "BufEnter";
        pattern = "*";
        callback.__raw = ''
          function()
            vim.opt.formatoptions:remove({ "c", "r", "o" })
          end
        '';
        desc = "No auto-comment on new lines";
      }
    ];
  };
}
