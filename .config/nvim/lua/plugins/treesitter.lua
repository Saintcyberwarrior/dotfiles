return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile", "VeryLazy" },
	cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"python",
				"c",
				"cpp",
				"typst",
				-- "latex",
				"lua",
				"vim",
				"vimdoc",
				"bash",
				"markdown",
			},
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
