

do
	local ConstraintTypes = duplicator.ConstraintType
	local EntitiesToRestore = {}

	local function ResetCollisions(Entity)
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then return end

		PhysObj:EnableCollisions(true)
	end

	local function ClearHydraulic(Constraint)
		local ID = Constraint.MyCrtl

		if not ID then return end

		local Controller = ents.GetByIndex(ID)

		if not IsValid(Controller) then return end

		local Rope = Controller.Rope

		Controller:DontDeleteOnRemove(Constraint)
		Constraint:DontDeleteOnRemove(Controller)

		if IsValid(Rope) then
			Controller:DontDeleteOnRemove(Rope)
			Rope:DontDeleteOnRemove(Constraint)
		end
	end

	-- Similar to constraint.RemoveAll
	local function ClearConstraints(Entity)
		local Constraints = Entity.Constraints

		if not Constraints then return end

		for Index, Constraint in pairs(Constraints) do
			if IsValid(Constraint) then
				ResetCollisions(Constraint.Ent1)
				ResetCollisions(Constraint.Ent2)

				if Constraint.Type == "WireHydraulic" then ClearHydraulic(Constraint) end

				Constraint:Remove()
			end

			Constraints[Index] = nil
		end

		Entity:IsConstrained()
	end

	local function RestoreHydraulic(ID, Constraint, Rope)
		local Controller = ents.GetByIndex(ID)

		if not IsValid(Controller) then return end

		Constraint.MyCrtl = Controller:EntIndex()
		Controller.MyId   = Controller:EntIndex()

		Controller:SetConstraint(Constraint)
		Controller:DeleteOnRemove(Constraint)

		if IsValid(Rope) then
			Controller:SetRope(Rope)
			Controller:DeleteOnRemove(Rope)
		end

		Controller:SetLength(Controller.TargetLength)
		Controller:TriggerInput("Constant", Controller.current_constant)
		Controller:TriggerInput("Damping", Controller.current_damping)

		Constraint:DeleteOnRemove(Controller)
	end

	local function RestoreConstraint(Data)
		local Type    = Data.Type
		local Factory = ConstraintTypes[Type]

		if not Factory then return end

		local ID   = Data.MyCrtl
		local Args = {}

		if ID then Data.MyCrtl = nil end

		for Index, Name in ipairs(Factory.Args) do Args[Index] = Data[Name] end

		local Constraint, Rope = Factory.Func(unpack(Args))

		if Type == "WireHydraulic" then RestoreHydraulic(ID, Constraint, Rope) end
	end

	--- Saves the physical properties/constraints/etc. of an entity to the "Entities" table.  
	--- Should be used before calling Update functions on ACF entities. Call RestoreEntity after.  
	--- Necessary because some components will update their physics object on update (e.g. ammo crates/scalable guns).
	--- @param Entity table The entity to index
	function XCF.SaveEntity(Entity)
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then return end

		EntitiesToRestore[Entity] = {
			Constraints = constraint.GetTable(Entity),
			Gravity = PhysObj:IsGravityEnabled(),
			Motion = PhysObj:IsMotionEnabled(),
			Contents = PhysObj:GetContents(),
			Material = PhysObj:GetMaterial(),
		}

		ClearConstraints(Entity)

		-- If for whatever reason the entity is removed before RestoreEntity is called,
		-- Update the entity table
		Entity:CallOnRemove("XCF_RestoreEntity", function()
			EntitiesToRestore[Entity] = nil
		end)
	end

	--- Sets the properties/constraints/etc of an entity from the "Entities" table.  
	--- Should be used after calling Update functions on ACF entities.
	--- @param Entity table The entity to restore
	function XCF.RestoreEntity(Entity)
		if not IsValid(Entity) then return end
		if not EntitiesToRestore[Entity] then return end

		local PhysObj = Entity:GetPhysicsObject()
		local EntData = EntitiesToRestore[Entity]

		PhysObj:EnableGravity(EntData.Gravity)
		PhysObj:EnableMotion(EntData.Motion)
		PhysObj:SetContents(EntData.Contents)
		PhysObj:SetMaterial(EntData.Material)

		for _, Data in ipairs(EntData.Constraints) do RestoreConstraint(Data) end

		EntitiesToRestore[Entity] = nil

		-- Disables the CallOnRemove callback from earlier
		Entity:RemoveCallOnRemove("XCF_RestoreEntity")
	end
end