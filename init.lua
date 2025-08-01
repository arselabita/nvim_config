vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)


-- Use tabs instead of spaces
vim.opt.expandtab = false
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.tabstop = 4

-- Enable absolute and relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Highlight trailing whitespace (can help with norminette)
-- vim.cmd [[highlight ExtraWhitespace ctermbg=red guibg=red]]
-- vim.cmd [[match ExtraWhitespace /\s\+$/]]

-- Keep text within 80 columns (show a guide)
vim.opt.colorcolumn = "81"

-- Turn off line wrapping
vim.opt.wrap = false

-- Show tab and trailing whitespace as symbols
vim.opt.list = true
vim.opt.listchars = {
  tab = '→ ',
  trail = '·',
  extends = '>',
  precedes = '<',
  nbsp = '␣'
}
