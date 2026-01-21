-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Override CR for bracket expansion (runs after all plugins load)
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.keymap.set("i", "<CR>", function()
        local blink_ok, blink = pcall(require, "blink.cmp")
        if blink_ok and blink.is_visible() then
          blink.accept()
          return
        end

        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local before = line:sub(col, col)
        local after = line:sub(col + 1, col + 1)

        local pairs = { ["{"] = "}", ["["] = "]", ["("] = ")" }

        if pairs[before] == after then
          -- Get current indentation
          local indent = line:match("^%s*") or ""
          local row = vim.api.nvim_win_get_cursor(0)[1]

          -- Delete the line and replace with expanded version
          local new_lines = {
            line:sub(1, col) ,  -- everything up to and including {
            indent .. "\t",     -- indented middle line
            indent .. line:sub(col + 1),  -- } with original indent
          }

          vim.api.nvim_buf_set_lines(0, row - 1, row, false, new_lines)
          -- Position cursor on middle line, at end
          vim.api.nvim_win_set_cursor(0, { row + 1, #(indent .. "\t") })
        else
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<CR>", true, true, true),
            "n",
            false
          )
        end
      end, { noremap = true, silent = true })
    end)
  end,
})
