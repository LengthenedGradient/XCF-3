AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:XCF_PostUpdateEntityData()
	print("XCF_PostUpdateEntityData")
	self:SetSize(self.XCF_LiveData.Size)
end

function ENT:XCF_PreSpawn()
	print("XCF_PreSpawn")
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
end

function ENT:XCF_PostSpawn(_, _, _, _)
	print("XCF_PostSpawn")
end

function ENT:XCF_PostMenuSpawn()
	print("XCF_PostMenuSpawn")
end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end

XCF.AutoRegister(ENT, "xcf_baseplate", "xcf_baseplate")