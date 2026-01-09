-- Minimal rust-analyzer setup using the new vim.lsp.config API
-- Put this in ~/.config/nvim/lua/lsp-rust-config.lua and require it from your init.lua
-- This avoids require('lspconfig') and uses vim.lsp.config (lspconfig v0.11+ migration)

-- Helper on_attach that enables inlay hints and adds keymaps
local function on_attach(client, bufnr)
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

  -- If Neovim has the inlay_hint API and server advertises support, enable hints
  if vim.lsp.buf.inlay_hint and client.server_capabilities and client.server_capabilities.inlayHintProvider then
    -- enable by default
    vim.lsp.buf.inlay_hint(bufnr, true)
    -- toggle keymap
    local state = true
    vim.keymap.set("n", "<leader>th", function()
      state = not state
      vim.lsp.buf.inlay_hint(bufnr, state)
      vim.notify("Inlay hints " .. (state and "enabled" or "disabled"))
    end, opts)
  end
end

-- Setup the server using the new vim.lsp.config API (replaces require('lspconfig').rust_analyzer.setup)
vim.lsp.config.rust_analyzer.setup({
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      procMacro = { enable = true },
      checkOnSave = {
        command = "clippy"
      },
      inlayHints = { typeHints = { enable = true }, parameterHints = { enable = true } },
    },
  },
})

-- require from init.lua with: require("lsp-rust-config")
