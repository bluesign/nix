return {
  "saghen/blink.cmp",
  dependencies = { "L3MON4D3/LuaSnip" },
  opts = {
    snippets = {
      expand = function(snippet)
        require("luasnip").lsp_expand(snippet)
      end,
      active = function(filter)
        if filter and filter.direction then
          return require("luasnip").jumpable(filter.direction)
        end
        return require("luasnip").in_snippet()
      end,
      jump = function(direction)
        require("luasnip").jump(direction)
      end,
    },
    completion = {
      trigger = {
        show_in_snippet = false,
        show_on_trigger_character = true,
      },
    },
    keymap = {
      preset = "default",
      ["<CR>"] = {}, -- Disable blink's CR, we handle it in polish.lua
    },
    sources = {
      default = { "lsp", "path" },
      providers = {
        snippets = { enabled = false },
        buffer = { enabled = false },
      },
    },
  },
}
