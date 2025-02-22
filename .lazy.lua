return {
	{
		"epwalsh/obsidian.nvim",
		opts = {
			wiki_link_func = "prepend_note_path",
		},
	},
	{
		"renerocksai/telekasten.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-telekasten/calendar-vim" },
		config = function()
			require("telekasten").setup({
				home = vim.fn.expand("~/Projects/recipes/content"),
				templates = vim.fn.expand("~/PProjects/recipes/content/_meta_/_templates_/"), -- path to templates
				vaults = {
					recipes = { home = vim.fn.expand("~/Projects/recipes/content/") },
				},
			})
		end,
	},
}
-- References:
--   [1] https://kezhenxu94.me/blog/lazyvim-project-specific-settings
