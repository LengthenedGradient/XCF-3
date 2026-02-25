-- TODO: Localize globals?
XCF.EntityTables = XCF.EntityTables or {}

-- Public entry point
function XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, FromDupe, NoUndo)
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

function XCF.AutoRegister(ENT, Class)
	print("Autoregistered: ", ENT.PrintName)

	function ENT:Update(DataVarKVs)
		XCF.SaveEntity(self)
		
		XCF.RestoreEntity(self)
	end

	local EntTable = XCF.EntityTables[Class] or {}
	XCF.EntityTables[Class] = EntTable

	-- Entity specific spawn function
	function EntTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)
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

		XCF.UpdateEntityData(New, DataVarKVs)
		if New.XCF_PostSpawn then
			New:XCF_PostSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		return New
	end

	-- Duplicator entry point
	local DataVarKeys = XCF.DataVarScopesOrdered[Class]
	local function SpawnFunction(Player, Pos, Angle, ...)
		-- Collect the extra arguments passed in by duplicator into a KV format
		local Values = {...}
		local DataVarKVs = {}
		for i, Key in ipairs(DataVarKeys) do DataVarKVs[Key] = Values[i] end

		local _, Entity = XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, true)
		return Entity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", unpack(DataVarKeys))
end