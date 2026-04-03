return {
	"chomosuke/typst-preview.nvim",
	ft = "typst",
	version = "1.*",
	build = function()
		require("typst-preview").update()
	end,
	keys = {
		-- This binds your <leader>tv shortcut to start the live preview
		{ "<leader>tv", "<cmd>TypstPreviewToggle<cr>", desc = "Toggle Typst Live Preview" },
	},
}
