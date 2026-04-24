{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      alpha-nvim
      (pkgs.vimUtils.buildVimPlugin {
        pname = "alpha-cowsays-nvim";
        version = "unstable";
        src = pkgs.fetchFromGitHub {
          owner = "ozthemagician";
          repo = "alpha-cowsays-nvim";
          rev = "master";
          hash = "sha256-9CfNvxeeMUDCsYx12ZO7hrC80Za0TrY2osINPfc7xws=";
        };
      })
    ];

    extraConfigLua = ''
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      local cow = require("alpha-cowsays-nvim")

      dashboard.section.header.val = cow.cowsays()

      dashboard.section.buttons.val = {
        dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
        dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
        dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
        dashboard.button("SPC wr", "󰁯  > Restore Session", "<cmd>SessionRestore<CR>"),
        dashboard.button("q", " > Quit NVIM", "<cmd>qa<CR>"),
      }

      alpha.setup(dashboard.opts)

      vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
    '';
  };
}
