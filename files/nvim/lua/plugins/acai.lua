-- ~/.config/nvim/lua/plugins/acai.lua
return {
	"ofcRS/nvim-acai",
	-- enabled = function()
	--   return os.getenv("OAI_URL") ~= nil and os.getenv("OAI_KEY") ~= nil and os.getenv("OAI_MODEL") ~= nil
	-- end,
	enabled = false,
	opts = {
		provider = "openai",
		providers = {
			openai = {
				api_key_env = "OAI_KEY",
				api_base = os.getenv("OAI_URL"),
				model = os.getenv("OAI_MODEL"),
			},
		},
	},
}
