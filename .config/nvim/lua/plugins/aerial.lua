return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		backends = { "lsp", "treesitter", "markdown", "man" },
		layout = {
			min_width = 28,
			default_direction = "prefer_right",
		},
		attach_mode = "window",
		close_automatic_events = {},
		filter_kind = false,
		highlight_on_hover = true,
		autojump = true,
	},
	keys = {
		{ "<leader>a", "<cmd>AerialToggle!<CR>", desc = "Toggle Aerial" },
		{ "{", "<cmd>AerialPrev<CR>", desc = "Prev symbol" },
		{ "}", "<cmd>AerialNext<CR>", desc = "Next symbol" },
	},
}
