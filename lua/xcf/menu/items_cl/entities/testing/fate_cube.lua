local function CreateFateCubeMenu(MenuPanel)
	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")
	MenuPanel:AddButton("Test Button", function() print("Button Clicked") end)
	MenuPanel:AddCheckbox("Test Checkbox", function(_, Val) print("Checkbox Changed:", Val) end)

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddModelPrevew("models/hunter/blocks/cube075x075x075.mdl")
	Base:AddSlider("Volatility", 0, 1, 2)
	Base:AddNumberWang("Type", 0, 10)
	Base:AddVec3Slider("Scale")
	Base:AddTextEntry("Material")
end

XCF.AddMenuItem(1, "Fate Cube", "icon16/bricks.png", CreateFateCubeMenu, "Testing")