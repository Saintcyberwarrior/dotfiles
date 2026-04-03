return {
	"stevearc/conform.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local conform = require("conform")
		conform.setup({
			formatters_by_ft = {
				python = { "ruff_format", "ruff_fix" },
				lua = { "stylua" },
				c = { "clang-format" },
				cpp = { "clang-format" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>fm", function()
			conform.format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
		end, { desc = "Format file" })
	end,
}
