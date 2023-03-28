--- setup
---@param params table
---@params params.register string The register to use for saving the link which generated by the plugin
local function setup(params)
  require("nvim-sync.config").init(params)
  require("nvim-sync.api").init()
end

return {
  setup = setup,
}
