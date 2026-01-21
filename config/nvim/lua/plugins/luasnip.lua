return {
  "L3MON4D3/LuaSnip",
  config = function(plugin, opts)
    require("astronvim.plugins.configs.luasnip")(plugin, opts)
    local luasnip = require("luasnip")

    -- Enable choice node support
    luasnip.setup({
      enable_autosnippets = true,
      store_selection_keys = "<Tab>",
    })

    -- Keymaps to cycle through choice nodes
    vim.keymap.set({ "i", "s" }, "<C-j>", function()
      if luasnip.choice_active() then
        luasnip.change_choice(1)
      end
    end, { silent = true, desc = "Next snippet choice" })

    vim.keymap.set({ "i", "s" }, "<C-k>", function()
      if luasnip.choice_active() then
        luasnip.change_choice(-1)
      end
    end, { silent = true, desc = "Previous snippet choice" })

    -- Jump forward in snippet (only when actively in a snippet AND can jump)
    vim.keymap.set({ "i", "s" }, "<Tab>", function()
      if luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
      end
    end, { silent = true, desc = "Jump to next snippet placeholder" })

    -- Jump backward in snippet
    vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
      end
    end, { silent = true, desc = "Jump to previous snippet placeholder" })
  end,
}
