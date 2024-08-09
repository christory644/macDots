local status_okayz, configs = pcall(require, "nvim-treesitter.configs")
 if not status_okayz then
  return
end

configs.setup {
  ensure_installed = "all", -- either "all", or a list of languages we wish to have installed
  sync_install = false,
  ignore_install = { "phpdoc" }, -- List of parsers to ignore installing
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = { "css" }, -- list of language that will be disabled
    additional_vim_regex_highlighting = true,

  },
	autopairs = {
		enable = true,
	},
  context_commentstring = {
    enable = true
  },
  indent = { enable = true, disable = { "css", "python", "yaml" } },
  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, -- list of languages you want to disable the nvim-ts-rainbow plugin
    max_file_lines = nil,
    -- colors = {}, -- table of hex strings
    -- termcolors = {}, -- table of color name strings
  },
}
