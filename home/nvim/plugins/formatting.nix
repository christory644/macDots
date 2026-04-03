{ ... }:

{
  programs.nixvim = {
    plugins = {
      # ── Formatting ────────────────────────────────────────────────────
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            javascript = [ "prettier" ];
            typescript = [ "prettier" ];
            javascriptreact = [ "prettier" ];
            typescriptreact = [ "prettier" ];
            css = [ "prettier" ];
            html = [ "prettier" ];
            json = [ "prettier" ];
            yaml = [ "prettier" ];
            markdown = [ "prettier" ];
            svelte = [ "prettier" ];
            lua = [ "stylua" ];
            python = [ "black" "isort" ];
            rust = [ "rustfmt" ];
            go = [ "gofumpt" ];
            nix = [ "nixfmt" ];
            elm = [ "elm_format" ];
            elixir = [ "mix" ];
            # Java: uses Spotless (palantir style) via `./gradlew spotlessApply`
            # conform falls back to LSP formatting for Java
          };

          format_on_save = {
            timeout_ms = 1000;
            lsp_fallback = true;
          };
        };
      };

      # ── Linting ───────────────────────────────────────────────────────
      lint = {
        enable = true;
        lintersByFt = {
          javascript = [ "eslint_d" ];
          typescript = [ "eslint_d" ];
          javascriptreact = [ "eslint_d" ];
          typescriptreact = [ "eslint_d" ];
          svelte = [ "eslint_d" ];
          python = [ "pylint" ];
          elixir = [ "credo" ];
        };

        autoCmd = {
          event = [ "BufEnter" "BufWritePost" "InsertLeave" ];
          callback.__raw = ''
            function()
              require("lint").try_lint()
            end
          '';
        };
      };
    };

    # Manual format keymap
    keymaps = [
      {
        mode = [ "n" "v" ];
        key = "<leader>mp";
        action.__raw = ''
          function()
            require("conform").format({
              lsp_fallback = true,
              async = false,
              timeout_ms = 1000,
            })
          end
        '';
        options.desc = "Format file or selection";
      }
    ];
  };
}
