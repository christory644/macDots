return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({
      -- automatically install missing parsers when entering a buffer
      -- not recommended if you don't have the tree sitter cli installed
      -- use npm -g i tree-sitter-cli to install it
      auto_install = true,
      -- enable autotagging (with nvim-ts-autotag plugin)
      autotag = {
        enable = true,
      },
      -- ensure the following language parsers are always installed
      ensure_installed = {
        "bash",
        "c",
        "clojure",
        "comment",
        "commonlisp",
        "cpp",
        "css",
        "csv",
        "cuda",
        "elixir",
        "elm",
        "erlang",
        "gdscript",
        "git_config",
        "gitignore",
        "gleam",
        "go",
        "graphql",
        "haskell",
        "helm",
        "html",
        "http",
        "java",
        "javascript",
        "jq",
        "json",
        "kotlin",
        "lua",
        "make",
        "markdown",
        "nix",
        "ocaml",
        "perl",
        "php",
        "prisma",
        "python",
        "ruby",
        "rust",
        "scala",
        "scss",
        "solidity",
        "sql",
        "svelte",
        "terraform",
        "tmux",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
        "xml",
        "yaml",
        "zig",
      },
      -- enable syntax highlighting
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      -- enable indentation
      indent = {
        enable = true,
      },
      -- install parsers asynchronously (only applies to `ensure_installed`)
      sync_install = false,
    })
  end,
}
