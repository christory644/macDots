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
    };
  };
}
