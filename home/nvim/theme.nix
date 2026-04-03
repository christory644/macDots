{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      night-owl-nvim
      transparent-nvim
    ];

    extraConfigLua = ''
      -- ── Night Owl colorscheme ────────────────────────────────────────
      require("night-owl").setup()
      vim.cmd.colorscheme("night-owl")

      -- ── Transparent backgrounds ──────────────────────────────────────
      require("transparent").setup({
        groups = {
          "Normal",
          "NormalNC",
          "Comment",
          "Constant",
          "Special",
          "Identifier",
          "Statement",
          "PreProc",
          "Type",
          "Underlined",
          "Todo",
          "String",
          "Function",
          "Conditional",
          "Repeat",
          "Operator",
          "Structure",
          "LineNr",
          "NonText",
          "SignColumn",
          "CursorLineNr",
          "EndOfBuffer",
          -- Telescope
          "TelescopeBorder",
          "TelescopeNormal",
          "TelescopePromptBorder",
          "TelescopePromptNormal",
          "TelescopeResultsBorder",
          "TelescopeResultsNormal",
          "TelescopePreviewBorder",
          "TelescopePreviewNormal",
          -- NvimTree
          "NvimTreeNormal",
          "NvimTreeNormalNC",
          "NvimTreeWinSeparator",
          -- Bufferline
          "BufferLineFill",
          "BufferLineBackground",
          -- Gitsigns
          "GitSignsAdd",
          "GitSignsChange",
          "GitSignsDelete",
          -- Which-key
          "WhichKeyFloat",
          -- Notify
          "NotifyBackground",
        },
        extra_groups = {},
        exclude_groups = {},
      })
    '';
  };
}
