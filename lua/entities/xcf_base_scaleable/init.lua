-- TODO: entities whos scale is set seem to have very high drag...
DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

AddCSLuaFile("shared.lua") -- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua") -- Send shared and cl_init to the client

include("shared.lua") -- Includes and runs shared file on the server

util.AddNetworkString "XCF_Scalable_Entity"

local ModelData = XCF.ModelData

do -- Networking related
	-- Transmits a scalable entity's scale and model
	local function TransmitScaleInfo(Entity, To)
		local Data  = Entity.XCFScaleData
		local Scale = Data.Scale

		net.Start("XCF_Scalable_Entity")
		net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
		net.WriteFloat(Scale[1])
		net.WriteFloat(Scale[2])
		net.WriteFloat(Scale[3])
		net.WriteString(Data.ModelPath)

		if To then net.Send(To) else net.Broadcast() end
	end

	function ENT:TransmitScaleInfo(To)
		TransmitScaleInfo(self, To)
	end

	--- If the client requests scale info, send it
	net.Receive("XCF_Scalable_Entity", function(_, Player)
		local Entity = ents.GetByIndex(net.ReadUInt(MAX_EDICT_BITS)) -- Equivalent to Entity()

		if IsValid(Entity) and Entity.XCFIsScalable then
			TransmitScaleInfo(Entity, Player)
		end
	end)
end

do -- Size and scale setter methods
	--- Sets the scale of the entity on the server
	--- Internally updates the physics mesh and transmits the change to the clients
	function ENT:ResizeEntity(Scale)
		local Data = self.XCFScaleData
		Data.Size = Data.OriginalSize * Scale
		Data.Scale = Scale

		local Mesh = ModelData.GetModelMesh(Data.ModelPath, Scale)

		self:PhysicsInitMultiConvex(Mesh)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:EnableCustomCollisions(true)
		self:DrawShadow(false)

		local PhysObj = self:GetPhysicsObject()

		self:TransmitScaleInfo()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end

		return PhysObj
	end
end

