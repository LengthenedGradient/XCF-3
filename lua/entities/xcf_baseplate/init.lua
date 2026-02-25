AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:XCF_PostUpdateEntityData()
	self:SetSize(self.XCF_LiveData.xcf_baseplate.Size)
end

function ENT:XCF_PreSpawn()
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
end

function ENT:XCF_PostSpawn(_, _, _, _)

end

function ENT:XCF_PostMenuSpawn()
	print("Spawned From Menu")
end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end

XCF.AutoRegister(ENT, "xcf_baseplate", "xcf_baseplate")