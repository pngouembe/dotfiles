return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "black" },
      },
      format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "mypy", "ruff" },
      },
    },
  },
}
