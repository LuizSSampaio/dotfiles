local default_model = "moonshotai/kimi-k2:free"
local available_models = {
	"moonshotai/kimi-k2:free",
	"moonshotai/kimi-k2",
	"google/gemini-2.0-flash-001",
	"google/gemini-2.5-pro",
	"anthropic/claude-3.7-sonnet",
	"anthropic/claude-sonnet-4",
	"openai/gpt-4.1-mini",
	"mistralai/devstral-medium",
}
local current_model = default_model

local function select_model()
	vim.ui.select(available_models, {
		prompt = "Select  Model:",
	}, function(choice)
		if choice then
			current_model = choice
			vim.notify("Selected model: " .. current_model)
		end
	end)
end

return {
	"olimorris/codecompanion.nvim",
	opts = {},
	config = function()
		require("codecompanion").setup({
			strategies = {
				chat = {
					adapter = "openrouter",
				},
				inline = {
					adapter = "openrouter",
				},
			},
			adapters = {
				openrouter = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							url = "https://openrouter.ai/api",
							api_key = assert(os.getenv("OPENROUTER_API_KEY"), "OPENROUTER_API_KEY env not set"),
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = current_model,
							},
						},
					})
				end,
			},
		})

		-- Expand 'cc' into 'CodeCompanion' in the command line
		vim.cmd([[cab cc CodeCompanion]])
	end,
	keys = {
		{ "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
		{
			"<leader>aa",
			"<cmd>CodeCompanionChat Toggle<cr>",
			desc = "Toggle (CodeCompanion)",
			mode = { "n", "v" },
		},
		{
			"<leader>aq",
			"<cmd>CodeCompanionChat Add<cr>",
			desc = "Add to chat (CodeCompanion)",
			mode = { "v" },
		},
		{
			"<leader>ap",
			"<cmd>CodeCompanionActions<cr>",
			desc = "Actions (CodeCompanion)",
			mode = { "n", "v" },
		},
		{
			"<leader>as",
			select_model,
			desc = "Select Model (CodeCompanion)",
			mode = { "n" },
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
}
