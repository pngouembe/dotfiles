local map = vim.keymap.set

map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
map("n", "<leader>dpr", function()
  require("dap-python").test_method()
end, { desc = "Debug Python test method" })
