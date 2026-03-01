local function CreateMenu(MenuPanel)
	XCF.SetDataVar("SpawnClass", "ToolGun", "xcf_baseplate")

	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("xcf_baseplate")
	Base:AddModelPreview("models/hunter/blocks/cube075x075x075.mdl")
	XCF.CreatePanelsFromDataVars(Base, "xcf_baseplate")
end

XCF.AddMenuItem(1, "Baseplates", "icon16/shape_square.png", CreateMenu, "Integral")