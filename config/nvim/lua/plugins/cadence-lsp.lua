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
        local root_pattern = lspconfig.util.root_pattern("flow.json", ".git")
        configs.cadence = {
          default_config = {
            -- cmd = { "flow", "cadence", "language-server", "--enable-flow-client=false" },
            cmd = { "sh", "-c", "/tmp/cadence-language-server --enable-flow-client=false 2>/tmp/lsp-debug.log" },
            filetypes = { "cadence", "cdc" },
            root_dir = root_pattern,
            single_file_support = true,
            on_new_config = function(new_config, new_root_dir)
              new_config.init_options = {
                configPath = new_root_dir .. "/flow.json",
                numberOfAccounts = "1",
              }
            end,
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
