{ ... }:

{
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;

      settings = {
        auto_install = false; # Nix manages grammars

        highlight.enable = true;
        indent.enable = true;

        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            scope_incremental = false;
            node_decremental = "<bs>";
          };
        };
      };

      nixGrammars = true;
    };

    plugins.treesitter.settings.ensure_installed = [
      "lua"
      "vim"
      "vimdoc"
      "bash"
      "json"
      "yaml"
      "toml"
      "markdown"
      "markdown_inline"
      "html"
      "css"
      "javascript"
      "typescript"
      "tsx"
      "svelte"
      "rust"
      "go"
      "java"
      "c_sharp"
      "elixir"
      "python"
      "dockerfile"
      "graphql"
      "regex"
      "sql"
      "nix"
      "kdl"
      "gitcommit"
      "gitignore"
    ];

    # Auto-close / auto-rename HTML & JSX tags
    plugins.ts-autotag.enable = true;
  };
}
