local map = vim.keymap.set

map({ "n", "v" }, ";", ":", { desc = "Enter command mode without shift" })

map({ "n", "i", "v" }, "<C-b>", function()
  Snacks.explorer()
end, { desc = "Toggle file explorer" })

map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
map("n", "<leader>dpr", function()
  require("dap-python").test_method()
end, { desc = "Debug Python test method" })
