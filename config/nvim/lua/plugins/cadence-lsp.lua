-- Cadence LSP configuration using flow-cli

---@type LazySpec
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local lspconfig = require "lspconfig"
      local configs = require "lspconfig.configs"

      -- Register cadence LSP if not already registered
      if not configs.cadence then
        configs.cadence = {
          default_config = {
            -- cmd = { "flow", "cadence", "language-server", "--enable-flow-client=false" },
            cmd = { "sh", "-c", "/tmp/cadence-language-server --enable-flow-client=false 2>/tmp/lsp-debug.log" },
            filetypes = { "cadence", "cdc" },
            root_dir = lspconfig.util.root_pattern("flow.json", ".git"),
            single_file_support = true,
            init_options = {
              configPath = vim.fn.expand("~/flow.json"),
              numberOfAccounts = "1",
            },
          },
        }
      end
    end,
  },
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = { "cadence" },
    },
  },
}
