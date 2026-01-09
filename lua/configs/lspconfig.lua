-- Minimal root_dir detector (expandable)
local function get_root_dir()
	return vim.fs.dirname(vim.fs.find({ ".git", "package.json", "pyproject.toml", "Cargo.toml" }, { upward = true })[1])
end

-- Check for executables across common Nix paths
local function find_executable(possible_names)
	for _, name in ipairs(possible_names) do
		if vim.fn.executable(name) == 1 then
			return name
		end
	end
	return nil
end

-- Optional: integrate with nvim-cmp if installed
local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")
local capabilities = has_cmp and cmp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

-- Optional: define `on_attach` to set up keymaps
local function on_attach(client, bufnr)
	-- Basic keymap example
	local map = function(mode, lhs, rhs)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
	end

	map("n", "gd", vim.lsp.buf.definition)
	map("n", "K", vim.lsp.buf.hover)
	map("n", "<leader>rn", vim.lsp.buf.rename)
end

-- Define your servers here
local servers = {
	clangd = {
		filetypes = { "c", "cpp", "objc", "objcpp" },
		cmd = find_executable({
			"/run/current-system/sw/bin/clangd",
			vim.fn.expand("~/.nix-profile/bin/clangd"),
			"clangd",
		}),
	},

	lua_ls = {
		filetypes = { "lua" },
		cmd = find_executable({ "lua-language-server" }),
		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
			},
		},
	},

	rust_analyzer = {
		filetypes = { "rust" },
		cmd = find_executable({
			"/run/current-system/sw/bin/rust-analyzer",
			vim.fn.expand("~/.nix-profile/bin/rust-analyzer"),
			"rust-analyzer",
		}),
		settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
				},
				procMacro = {
					enable = true,
				},
			},
			inlayHints = {
				enable = true;
				typeHints = true,
				chainingHints = true,
				bindingModeHints = true,
			}
		},
	},
}

-- Setup autocommands per server
for name, server in pairs(servers) do
	if server.cmd then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = server.filetypes,
			callback = function()
				vim.lsp.start({
					name = name,
					cmd = { server.cmd },
					root_dir = get_root_dir(),
					settings = server.settings,
					on_attach = on_attach,
					capabilities = capabilities,
				})
			end,
		})
	else
		vim.schedule(function()
			vim.notify(("LSP server `%s` not found in $PATH or Nix profile"):format(name), vim.log.levels.WARN)
		end)
	end
	-- Diagnostic display configuration
	vim.diagnostic.config({
		virtual_text = {
			prefix = "●", -- symbol before message (e.g., "●", "■", "▎")
			spacing = 2,
		},
		signs = true,
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = {
			border = "rounded",
			source = "always",
			header = "",
			prefix = "",
		},
	})
end
