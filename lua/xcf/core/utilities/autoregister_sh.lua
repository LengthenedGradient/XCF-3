-- TODO: Localize globals?

--[[
Call Order:
	XCF.SpawnEntity <- (Duplicator / Tool gun spawn)
	XCF_PreSpawn
	XCF.UpdateEntityData <- (Tool gun update)
	Entity.Update
	XCF_PostUpdateEntityData
	XCF_PostSpawn
	PostEntityPaste <- (Duplicator only)
	XCF_PostMenuSpawn <- (Tool gun only)

Notable variables:
	XCF_LiveData: The current live data of the entity, updated whenever the entity is spawned or updated. Initialized by the toolgun on spawn, or by the duplicator when pasting.
		Certain datavar types like linked entities will have garbage data until PostEntityPaste is called. Do not use them until then.
	XCF_DupeData: A copy of the live data at the time of duplication. PostEntityPaste updates it immediately before copying. It's really just for flushing data, don't use it.
]]--

XCF.EntityTables = XCF.EntityTables or {}

-- Public entry point
function XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, FromDupe, NoUndo)
	print("XCF.SpawnEntity")
	local EntityTable = XCF.EntityTables[Class]
	if not EntityTable then return false, Class .. " is not a registered XCF entity class." end
	if not EntityTable.Spawn then return false, Class .. " does not have a spawn function." end

	local Entity = EntityTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)

	if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " failed to return a valid entity." end

	Entity:CPPISetOwner(Player)
	Entity:SetPlayer(Player)

	Entity.Owner = Player

	if not NoUndo then
		undo.Create(Entity.Name or Class)
		undo.AddEntity(Entity)
		undo.SetPlayer(Player)
		undo.Finish()
	end

	return true, Entity
end

-- Public entry point
function XCF.UpdateEntityData(Entity, DataVarKVs)
	print("XCF.UpdateEntityData")
	if not IsValid(Entity) then return false, "Can't update invalid entities." end
	if not isfunction(Entity.Update) then return false, "This entity does not support updating." end

	local Result, Message = Entity:Update(DataVarKVs)

	if Result then
		if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
	else
		Message = "Couldn't update entity: " .. (Message or "No reason provided.")
	end

	return Result, Message
end

function XCF.AutoRegister(ENT, Class, _)
	print("Autoregistered: ", ENT.PrintName)

	function ENT:Update(DataVarKVs)
		XCF.SaveEntity(self)
		self.XCF_LiveData = table.Copy(DataVarKVs)
		self:XCF_PostUpdateEntityData()
		XCF.RestoreEntity(self)
	end

	if not ENT.XCF_PostMenuSpawn then
		function ENT:XCF_PostMenuSpawn()
			XCF.DropToFloor(self)
		end
	end

	function ENT:PreEntityCopy()
		print("PreEntityCopy")
		self.XCF_DupeData = table.Copy(self.XCF_LiveData)

		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		print("PostEntityPaste")

		Ent.BaseClass.PostEntityPaste(Ent, Player, Ent, CreatedEntities)
	end

	local EntTable = XCF.EntityTables[Class] or {}
	XCF.EntityTables[Class] = EntTable

	-- Entity specific spawn function
	function EntTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		print("EntityTable.Spawn")
		local New = ents.Create(Class)
		if not IsValid(New) then return end

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.XCF_PreSpawn then
			New:XCF_PreSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		New:Spawn()
		Player:AddCount("_" .. Class, New)
		Player:AddCleanup(Class, New)

		New.XCF_LiveData = {}

		XCF.UpdateEntityData(New, DataVarKVs)
		if New.XCF_PostSpawn then
			New:XCF_PostSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		return New
	end

	-- Duplicator entry point
	local function SpawnFunction(Player, Pos, Angle, DataVarKVs)
		-- Collect the extra arguments passed in by duplicator into a KV format
		local _, Entity = XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, true)
		return Entity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "XCF_DupeData")
end