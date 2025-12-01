-- Minimal rust + Mason setup for Neovim
-- Put this file at lua/plugins/rust.lua and require it from your init.lua or plugin loader:
-- require("plugins.rust").setup()

local M = {}

function M.setup()
  -- Safe-requires
  local ok_mason, mason = pcall(require, "mason")
  local ok_mason_lsp, mason_lspconfig = pcall(require, "mason-lspconfig")
  local ok_rt, rust_tools = pcall(require, "rust-tools")
  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")

  if not ok_mason or not ok_mason_lsp or not ok_lspconfig then
    vim.notify("Missing mason / mason-lspconfig / lspconfig. Install them first.", vim.log.levels.WARN)
    return
  end

  mason.setup()
  mason_lspconfig.setup({
    ensure_installed = { "rust_analyzer" }, -- LSP names (lspconfig)
  })

  -- Optionally ensure codelldb via Mason's UI or the registry below
  -- You can also run :MasonInstall codelldb manually.

  -- Build LSP capabilities (adds completion support if cmp_nvim_lsp exists)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end

  -- Common on_attach: set mappings or other per-buffer behavior
  local function on_attach(client, bufnr)
    local bufmap = function(mode, lhs, rhs, desc)
      if desc then desc = "LSP: " .. desc end
      vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, { noremap = true, silent = true })
    end
    -- example mappings (you can customize)
    bufmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover")
    bufmap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to definition")
    bufmap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", "References")
    bufmap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code action")
  end

  -- Try to detect codelldb path installed by Mason (best-effort).
  local codelldb_adapter = nil
  do
    local ok_registry, registry = pcall(require, "mason-registry")
    if ok_registry and registry then
      if registry.is_installed("codelldb") then
        local pkg = registry.get_package("codelldb")
        local install_path = pkg:get_install_path()
        local adapter_path = install_path .. "/extension/adapter/codelldb"
        -- liblldb name depends on OS; rust-tools will only need adapter command for DAP server
        codelldb_adapter = {
          type = "server",
          port = "${port}",
          executable = {
            command = adapter_path,
            args = { "--port", "${port}" },
          },
        }
      end
    end
  end

  -- rust-tools setup if available, otherwise fallback to plain lspconfig
  if ok_rt then
    rust_tools.setup({
      server = {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
          },
        },
      },
      dap = codelldb_adapter and { adapter = codelldb_adapter } or {},
    })
  else
    -- fallback: configure rust_analyzer directly
    lspconfig.rust_analyzer.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = "clippy" },
        },
      },
    })
  end

  -- Optionally ensure codelldb installed via mason CLI if you want:
  -- You can run: :MasonInstall codelldb
end

return M
