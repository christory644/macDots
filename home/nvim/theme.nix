{ pkgs, theme, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      (builtins.getAttr theme.apps.nvimPlugin pkgs.vimPlugins)
    ];

    extraConfigLua = ''
      -- ── Colorscheme (${theme.name}) ──────────────────────────────────
      ${theme.apps.nvimSetup}
      vim.cmd.colorscheme("${theme.apps.nvim}")

      -- ── Transparent backgrounds ──────────────────────────────────────
      -- Clear bg on editor groups so terminal transparency shows through.
      -- Done manually instead of transparent-nvim to avoid bleed into
      -- lualine/bufferline UI chrome.
      local transparent_groups = {
        "Normal", "NormalNC", "NormalFloat", "FloatBorder",
        "SignColumn", "LineNr", "CursorLineNr", "EndOfBuffer", "NonText",
        "Comment", "Constant", "Special", "Identifier", "Statement",
        "PreProc", "Type", "Underlined", "Todo", "String", "Function",
        "Conditional", "Repeat", "Operator", "Structure",
        -- Telescope
        "TelescopeBorder", "TelescopeNormal",
        "TelescopePromptBorder", "TelescopePromptNormal",
        "TelescopeResultsBorder", "TelescopeResultsNormal",
        "TelescopePreviewBorder", "TelescopePreviewNormal",
        -- NvimTree
        "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeWinSeparator",
        -- Gitsigns
        "GitSignsAdd", "GitSignsChange", "GitSignsDelete",
        -- Which-key
        "WhichKeyFloat",
        -- Notify
        "NotifyBackground",
      }
      for _, group in ipairs(transparent_groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
        if ok then
          hl.bg = nil
          hl.ctermbg = nil
          vim.api.nvim_set_hl(0, group, hl)
        end
      end

      -- ── Fix fuzzy bold text in UI chrome ─────────────────────────────
      -- Operator Mono Lig's bold weight renders fuzzy at small sizes.
      -- Disable bold on lualine mode sections and bufferline tabs.
      local function unbold(group)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
        if ok then
          hl.bold = false
          vim.api.nvim_set_hl(0, group, hl)
        end
      end

      -- Bufferline selected tab
      local bl_bold_groups = {
        "BufferLineBufferSelected", "BufferLineTabSelected",
        "BufferLineDiagnosticSelected", "BufferLineHintSelected",
        "BufferLineInfoSelected", "BufferLineWarningSelected",
        "BufferLineErrorSelected", "BufferLineModifiedSelected",
        "BufferLineNumbersSelected", "BufferLinePickSelected",
      }
      for _, group in ipairs(bl_bold_groups) do
        unbold(group)
      end
    '';
  };
}
