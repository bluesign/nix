-- Telescope fuzzy finder
---@type LazySpec
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      { "<Leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<Leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<Leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<Leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "gr", "<cmd>Telescope lsp_references<cr>", desc = "LSP references" },
      { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "LSP definitions" },
      { "gi", "<cmd>Telescope lsp_implementations<cr>", desc = "LSP implementations" },
      { "<Leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<Leader>lS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
    },
    opts = {
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
    end,
  },
}
