return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
            },
          },
        },
        pyright = {},
        clangd = {},
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "black",
        "clangd",
        "debugpy",
        "mypy",
        "pyright",
        "ruff",
        "rust-analyzer",
      },
    },
  },
}
