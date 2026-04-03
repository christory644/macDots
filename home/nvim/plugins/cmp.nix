{ ... }:

{
  programs.nixvim = {
    plugins = {
      cmp = {
        enable = true;

        settings = {
          snippet.expand = ''
            function(args)
              require("luasnip").lsp_expand(args.body)
            end
          '';

          mapping = {
            "<C-p>".__raw = "cmp.mapping.select_prev_item()";
            "<C-n>".__raw = "cmp.mapping.select_next_item()";
            "<C-Space>".__raw = "cmp.mapping.complete()";
            "<C-e>".__raw = "cmp.mapping.abort()";
            "<C-y>".__raw = "cmp.mapping.confirm({ select = true })";
            "<CR>".__raw = "cmp.mapping.confirm({ select = false })";
            "<Tab>".__raw = ''
              cmp.mapping(function(fallback)
                local luasnip = require("luasnip")
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_locally_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { "i", "s" })
            '';
            "<S-Tab>".__raw = ''
              cmp.mapping(function(fallback)
                local luasnip = require("luasnip")
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { "i", "s" })
            '';
          };

          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
            { name = "path"; }
          ];

          # formatting.format is auto-set by lspkind.cmp.enable below
        };
      };

      # Snippet engine
      luasnip = {
        enable = true;
        fromVscode = [ { } ]; # Load friendly-snippets
      };

      # VS Code-style snippet collection
      friendly-snippets.enable = true;

      # Icons in completion menu
      lspkind = {
        enable = true;
        settings.cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            luasnip = "[Snip]";
            buffer = "[Buf]";
            path = "[Path]";
          };
        };
      };
    };
  };
}
