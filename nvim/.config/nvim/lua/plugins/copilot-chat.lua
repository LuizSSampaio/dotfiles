return {
	"CopilotC-Nvim/CopilotChat.nvim",
	opts = {
		provider = "openrouter",
		providers = {
			openrouter = {
				prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,
				prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,

				get_headers = function()
					local api_key = assert(os.getenv("OPENROUTER_API_KEY"), "OPENROUTER_API_KEY env not set")
					return {
						Authorization = "Bearer " .. api_key,
						["Content-Type"] = "application/json",
					}
				end,

				get_models = function(headers)
					local response, err = require("CopilotChat.utils").curl_get("https://openrouter.ai/api/v1/models", {
						headers = headers,
						json_response = true,
					})

					if err then
						error(err)
					end

					return vim.iter(response.body.data)
						:map(function(model)
							return {
								id = model.id,
								name = model.name,
							}
						end)
						:totable()
				end,

				get_url = function()
					return "https://openrouter.ai/api/v1/chat/completions"
				end,
			},
		},
	},
}
