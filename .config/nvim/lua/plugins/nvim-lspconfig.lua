return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		{ "williamboman/mason.nvim" },
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		require("nvchad.lsp")
		local capabilities = vim.lsp.protocol.make_client_capabilities()

		-- Lua (with third-party checking disabled to stop the "Too large file" spam)
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "vim" } },
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME, -- Only look at actual Neovim runtime files
						},
					},
					telemetry = { enable = false },
				},
			},
		})
		vim.lsp.enable("lua_ls")

		-- Python
		vim.lsp.config("pylsp", { capabilities = capabilities })
		vim.lsp.enable("pylsp")

		vim.lsp.config("ruff", { capabilities = capabilities })
		vim.lsp.enable("ruff")

		-- Typst & LaTeX
		vim.lsp.config("tinymist", { capabilities = capabilities })
		vim.lsp.enable("tinymist")

		vim.lsp.config("texlab", { capabilities = capabilities })
		vim.lsp.enable("texlab")

		-- C/C++
		vim.lsp.config("clangd", { capabilities = capabilities })
		vim.lsp.enable("clangd")

		-- LSP Diagnostics styling
		vim.diagnostic.config({
			virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
			float = { border = "rounded" },
		})

		-- Mappings
		local keymap = vim.keymap
		keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "LSP declaration" })
		keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP definition" })
		keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP hover" })
		keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
		keymap.set("n", "ca", vim.lsp.buf.code_action, { desc = "LSP code action" })
		keymap.set("n", "gr", vim.lsp.buf.references, { desc = "LSP references" })
		keymap.set("n", "fd", function()
			vim.diagnostic.open_float({ border = "rounded" })
		end, { desc = "Floating diagnostic" })
	end,
}
