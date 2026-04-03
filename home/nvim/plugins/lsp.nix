{ ... }:

{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;

      keymaps = {
        # Diagnostics keymaps (not attached to a buffer)
        diagnostic = {
          "<leader>d" = {
            action = "open_float";
            desc = "Line diagnostics";
          };
          "<leader>pd" = {
            action = "goto_prev";
            desc = "Previous diagnostic";
          };
          "<leader>nd" = {
            action = "goto_next";
            desc = "Next diagnostic";
          };
        };

        # LSP buffer-attached keymaps
        lspBuf = {
          "gD" = {
            action = "declaration";
            desc = "Go to declaration";
          };
          "gd" = {
            action = "definition";
            desc = "Go to definition";
          };
          "gi" = {
            action = "implementation";
            desc = "Go to implementation";
          };
          "gt" = {
            action = "type_definition";
            desc = "Go to type definition";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Code action";
          };
          "<leader>rn" = {
            action = "rename";
            desc = "Rename symbol";
          };
          "K" = {
            action = "hover";
            desc = "Hover documentation";
          };
        };

        extra = [
          {
            mode = "n";
            key = "gR";
            action.__raw = ''function() require("telescope.builtin").lsp_references() end'';
            options.desc = "LSP references";
          }
          {
            mode = "n";
            key = "<leader>D";
            action.__raw = ''function() require("telescope.builtin").diagnostics({ bufnr = 0 }) end'';
            options.desc = "Buffer diagnostics";
          }
          {
            mode = "n";
            key = "<leader>ds";
            action.__raw = ''function() require("telescope.builtin").lsp_document_symbols() end'';
            options.desc = "Document symbols";
          }
          {
            mode = "n";
            key = "<leader>ws";
            action.__raw = ''function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end'';
            options.desc = "Workspace symbols";
          }
          {
            mode = "n";
            key = "<leader>rs";
            action = "<cmd>LspRestart<CR>";
            options.desc = "Restart LSP";
          }
        ];
      };

      servers = {
        # Shell
        bashls.enable = true;

        # Web
        cssls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        svelte.enable = true;
        tailwindcss.enable = true;
        ts_ls.enable = true;

        emmet_ls = {
          enable = true;
          filetypes = [
            "html"
            "typescriptreact"
            "javascriptreact"
            "css"
            "sass"
            "scss"
            "less"
            "svelte"
          ];
        };

        # Elm
        elmls.enable = true;

        # Lua
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              diagnostics = {
                globals = [ "vim" ];
              };
            };
          };
        };

        # Python
        pyright.enable = true;

        # Rust
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };

        # Go
        gopls.enable = true;

        # Java
        java_language_server.enable = true;

        # Nix
        nil_ls.enable = true;

        # Elixir
        elixirls.enable = true;

        # Docker
        dockerls.enable = true;

        # GraphQL
        graphql.enable = true;

        # YAML
        yamlls.enable = true;
      };
    };
  };
}
