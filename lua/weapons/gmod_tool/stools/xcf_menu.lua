TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"
TOOL.Command	 = nil
TOOL.ConfigName = ""

if CLIENT then
	TOOL.BuildCPanel = function(Panel)
		local BasePanel = XCF.InitMenuReloadableBase(Panel, "xcf_reload_main_menu", "CreateMainMenu")
		Panel:AddItem(BasePanel)
	end
end