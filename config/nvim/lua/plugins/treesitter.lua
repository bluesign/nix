-- Customize Treesitter

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      enable = true,
      max_lines = 3,
    },
  },
  {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- Register Cadence parser
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.cadence = {
      install_info = {
        url = vim.env.TREE_SITTER_CADENCE_PATH or "/home/bluesign/src/tree-sitter-cadence",
        files = { "parser/parser.c", "parser/scanner.c" },
        generate_requires_npm = false,
        requires_generate_from_grammar = false,
      },
      filetype = "cadence",
    }

    -- Add to ensure_installed if you want auto-install
    opts.ensure_installed = opts.ensure_installed or {}
    vim.list_extend(opts.ensure_installed, {
      "lua",
      "vim",
      "go",
      -- "cadence", -- Uncomment after running :TSInstall cadence manually first time
    })
  end,
  },
}
