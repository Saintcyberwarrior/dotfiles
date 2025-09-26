-- lua/plugins/vimtex.lua
return {
	"lervag/vimtex",
	ft = "tex",
	config = function()
		vim.g.vimtex_view_method = "skim" -- or 'skim' for macOS; 'preview' is not officially supported but can work

		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_compiler_autostart = 1 -- auto compile on save
	end,
}
