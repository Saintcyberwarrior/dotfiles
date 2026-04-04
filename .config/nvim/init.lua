vim.g.mapleader = ","
require("core")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function loadPlugins()
	vim.opt.rtp:prepend(lazypath)
	require("lazy").setup("plugins", {
		change_detection = {
			notify = false,
		},
	})
end

local function setup()
	--------- lazy.nvim ---------------
	print("  Installing lazy.nvim & plugins ...")
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--depth=1", "--branch=stable", repo, lazypath })
	loadPlugins()
	vim.cmd("MasonToolsInstall")
end

vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
if not vim.loop.fs_stat(lazypath) then
	setup()
else
	loadPlugins()
	-- Load base46 cache if it exists
	if vim.loop.fs_stat(vim.g.base46_cache) then
		for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
			dofile(vim.g.base46_cache .. v)
		end
	end
end

-- Path generalization for custom keybindings
local user_local_bin = vim.fn.expand("$HOME") .. "/.local/bin"

vim.keymap.set("n", "<leader>l", function()
	vim.cmd("write!")
	local file = vim.fn.expand("%:p")
	vim.cmd("!" .. user_local_bin .. '/compiler "' .. file .. '"')
end, { desc = "Compile document" })

vim.keymap.set("n", "<leader>p", function()
	local file = vim.fn.expand("%:p")
	vim.cmd("!" .. user_local_bin .. '/opout "' .. file .. '"')
end, { desc = "Open output file" })

vim.api.nvim_create_autocmd("VimLeave", {
	pattern = "*.tex",
	callback = function()
		local file = vim.fn.expand("%")
		vim.cmd("!latexmk -c " .. file)
	end,
})
