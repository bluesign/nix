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
    init = function()
      -- Use pre-compiled Cadence parser from nix
      local cadence_pkg = vim.env.TREE_SITTER_CADENCE_PATH
      if cadence_pkg and cadence_pkg ~= "" then
        local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local parser_dest = parser_dir .. "/cadence.so"
        local parser_src = cadence_pkg .. "/lib/cadence.so"

        -- Create parser directory if needed
        vim.fn.mkdir(parser_dir, "p")

        -- Symlink pre-compiled parser if not exists or broken
        if vim.fn.filereadable(parser_dest) == 0 then
          if vim.fn.filereadable(parser_src) == 1 then
            vim.fn.system({ "ln", "-sf", parser_src, parser_dest })
          end
        end
      end

      -- Register filetype mapping
      vim.treesitter.language.register("cadence", "cadence")
    end,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "lua",
        "vim",
        "go",
      })
    end,
  },
}
