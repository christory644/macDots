local status_okayz, _ = pcall(require, "lspconfig")
if not status_okayz then
  return
end

require "user.lsp.lsp-installer"
require("user.lsp.handlers").setup()
require "user.lsp.null-ls"
