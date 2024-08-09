local fn = vim.fn

-- automagically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer, please close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- auto command that reloads nvim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- use protected call so nvim doesn't explode if packer is unavailable
local status_okayz, packer = pcall(require, "packer")
if not status_okayz then
  return
end

-- have packer use a floating popup instead of an embedded window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- install plugins on startup
return packer.startup(function(use)
  -- list of plugins goes here
  -- base plugins first
  use "wbthomason/packer.nvim"                        -- let packer manage itself
  use "nvim-lua/plenary.nvim"                         -- useful lua functions, used by lots o plugins
  use "windwp/nvim-autopairs"
  use "numToStr/Comment.nvim"
  use "JoosepAlviste/nvim-ts-context-commentstring"
  use "kyazdani42/nvim-web-devicons"
  use "kyazdani42/nvim-tree.lua"
  use "akinsho/bufferline.nvim"
  use "moll/vim-bbye"
  use "nvim-lualine/lualine.nvim"
  use "akinsho/toggleterm.nvim"
  use "ahmedkhalf/project.nvim"
  use "lewis6991/impatient.nvim"
  use "lukas-reineke/indent-blankline.nvim"
  use "goolord/alpha-nvim"

  -- colorschemes
  use "haishanh/night-owl.vim"

  -- completion plugins
  use "hrsh7th/nvim-cmp"                              -- completion plugin
  use "hrsh7th/cmp-buffer"                            -- buffer
  use "hrsh7th/cmp-path"                              -- path
  use "hrsh7th/cmp-cmdline"                           -- command
  use "saadparwaiz1/cmp_luasnip"                      -- snippet
  use "hrsh7th/cmp-nvim-lsp"                          -- neovim lsp
  use "hrsh7th/cmp-nvim-lua"                          -- neovim lua
  use "tamago324/cmp-zsh"                             -- zsh 

  -- LSP Goodness
  use "neovim/nvim-lspconfig"                         -- enable neovim native LSP
  use "williamboman/nvim-lsp-installer"               -- language server installeR
  use "jose-elias-alvarez/null-ls.nvim"
  use "RRethy/vim-illuminate"

  -- snippet plugins
  use "L3MON4D3/LuaSnip"                              -- snippet engine
  use "rafamadriz/friendly-snippets"                  -- lots o useful snippets

  -- Telescope
  use "nvim-telescope/telescope.nvim"

  -- Treesitter
 use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }
  use "p00f/nvim-ts-rainbow"

  -- Git
  use "lewis6991/gitsigns.nvim"

  -- Dap (debugger)
  use { "mfussenegger/nvim-dap" }
  use { "rcarriga/nvim-dap-ui" }
  use { "ravenxrz/DAPInstall.nvim" }

  -- automagically setup config after cloning packer.nvim
  -- leave this at the end of all plugin declarations
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)

