local XCF = XCF

XCF.DataVarTypes = XCF.DataVarTypes or {} -- Maps type names to type definitions
XCF.DataVars = XCF.DataVars or {} -- Maps variable names to variable definitions
XCF.DataVarIDsToNames = XCF.DataVarIDsToNames or {} -- Maps variable UUIDs to their names for reverse lookup on receive

local TypeCounter = 0
function XCF.DefineDataVarType(Name, ReadFunc, WriteFunc, Options)
	XCF.DataVarTypes[Name] = {
		UUID = TypeCounter,
		Read = ReadFunc,
		Write = WriteFunc,
		Options = Options,
	}
	TypeCounter = TypeCounter + 1
	return XCF.DataVarTypes[Name]
end

--- Defines data variable on the client
local VarCounter = 0
function XCF.DefineDataVar(Name, Group, Type, Options)
	XCF.DataVars[Name] = {
		UUID = VarCounter,
		Group = Group,
		Type = Type,
		Options = Options,
		Values = {},
	}
	XCF.DataVarIDsToNames[VarCounter] = Name
	VarCounter = VarCounter + 1
	return XCF.DataVars[Name]
end

--- Returns whether a client is allowed to set a server datavars
function XCF.CanSetServerData(Player)
	if not IsValid(Player) then return true end -- No player, probably the server
	if Player:IsSuperAdmin() then return true end

	return XCF.GetServerBool("ServerDataAllowAdmin") and Player:IsAdmin()
end

-- Determine if we're on a listen server once a player joins
-- TODO: This may cause race conditions in the future if we send client data to a player when they spawn?
XCF.IsListenServer = XCF.IsListenServer or false
if SERVER then
	hook.Add("PlayerInitialSpawn", "XCF_DetectHost", function(ply)
		if ply:IsListenServerHost() then
			XCF.IsListenServer = true
			hook.Remove("PlayerInitialSpawn", "XCF_DetectHost")
		end
	end)
else
	hook.Add("InitPostEntity", "XCF_DetectHostClient", function()
		if LocalPlayer():IsListenServerHost() then
			XCF.IsListenServer = true
		end
		hook.Remove("InitPostEntity", "XCF_DetectHostClient")
	end)
end
print("XCF: Listen server mode is " .. tostring(XCF.IsListenServer))

local XCF_DATA_VAR_LIMIT_EXPONENT = 8 -- Maximum number of data vars allowed as an exponent of 2
local XCF_DATA_VAR_MAX_MESSAGE_SIZE = 128 -- Maximum size of a data var message in bytes
local ServerPlayer = "Server" -- Represents the server as if it were a player (technically this should be a player entity, but the server doesn't have one.)

if SERVER then util.AddNetworkString("XCF_DV_NET") end

-- TODO: Add queue for rate limitting per variable (and forcing option)

--- Sets a data variable and networks it to the other realm.
--- Target is either a player (client data), or nil (server data)
function XCF.SetDataVar(Key, Value, Target)
	local DataVar = XCF.DataVars[Key]
	local Player = Target or ServerPlayer -- Player entity, or the server string
	local ForServer = Player == ServerPlayer -- Are we trying to change the server's data or the client's?
	if not ForServer and not IsValid(Player) then error("XCF: Invalid player in SetDataVar") return end -- Invalid player, ignore
	if DataVar.Values[Player] ~= Value then
		DataVar.Values[Player] = Value

		net.Start("XCF_DV_NET")
		net.WriteUInt(DataVar.UUID, XCF_DATA_VAR_LIMIT_EXPONENT) -- Encoded Key
		net.WriteBool(ForServer)

		DataVar.Type.Write(Value)

		if SERVER then
			-- Broadcast server change to all clients / Network client change to a single client
			if ForServer then net.Broadcast()
			else
				if XCF.IsListenServer then net.Broadcast() -- Need to do this for loopback servers
				else net.Send(Player) end
			end
		elseif CLIENT then
			-- Network server / client change to server (authorized on receive)
			net.SendToServer()
		end
	end
end

--- Receive data var updates (SECURITY IS VERY IMPORTANT, NEVER TRUST THE CLIENT)
net.Receive("XCF_DV_NET", function(len, ply)
	if len > (XCF_DATA_VAR_MAX_MESSAGE_SIZE * 8) then return end -- Someone is being evil and sending a huge packet

	local ID = net.ReadUInt(XCF_DATA_VAR_LIMIT_EXPONENT) -- Encoded Key (always a number)

	local Key = XCF.DataVarIDsToNames[ID]
	if not Key then return end -- Invalid Key, ignore

	local DataVar = XCF.DataVars[Key]
	if not DataVar then return end -- Invalid DataVar, ignore

	local ForServer = net.ReadBool() -- Are we trying to change the server's data or the client's?

	local Player
	if SERVER then Player = ForServer and ServerPlayer or ply -- Server receives have a ply argument
	else Player = ForServer and ServerPlayer or LocalPlayer() end -- Client receives don't have a ply argument

	-- Only authorized users can set server's server data
	if SERVER and ForServer and not XCF.CanSetServerData(ply) then return end
	DataVar.Values[Player] = DataVar.Type.Read()
end)

-- Cleanup values when a player leaves to avoid stale data
hook.Add("PlayerDisconnected", "XCF_CleanupDataVars", function(ply)
	for _, dv in pairs(XCF.DataVars) do
		dv.Values[ply] = nil
	end
end)

--- Load data vars from a file. Used for persistent data on client/server and presets on client
-- function XCF.LoadDataVarsFromFile(Path, Filter, Blacklist) end

--- Save data vars to a file. Used for persistent data on client/server and presets on client
-- function XCF.SaveDataVarsToFile(Path, Filter, BlackList) end

----------------------------------------------------------

-- Basic types
XCF.DefineDataVarType("Bool",        net.ReadBool,        net.WriteBool)
XCF.DefineDataVarType("String",      net.ReadString,      net.WriteString)
XCF.DefineDataVarType("Float",       net.ReadFloat,       net.WriteFloat)
XCF.DefineDataVarType("Double",      net.ReadDouble,      net.WriteDouble)

-- Signed integers
XCF.DefineDataVarType("Int8",        function() return net.ReadInt(8)  end,  function(v) net.WriteInt(v, 8)  end)
XCF.DefineDataVarType("Int16",       function() return net.ReadInt(16) end,  function(v) net.WriteInt(v, 16) end)
XCF.DefineDataVarType("Int32",       function() return net.ReadInt(32) end,  function(v) net.WriteInt(v, 32) end)

-- Unsigned integers
XCF.DefineDataVarType("UInt8",       function() return net.ReadUInt(8)  end, function(v) net.WriteUInt(v, 8)  end)
XCF.DefineDataVarType("UInt16",      function() return net.ReadUInt(16) end, function(v) net.WriteUInt(v, 16) end)
XCF.DefineDataVarType("UInt32",      function() return net.ReadUInt(32) end, function(v) net.WriteUInt(v, 32) end)

-- Others
XCF.DefineDataVarType("Color",       net.ReadColor,       net.WriteColor)
XCF.DefineDataVarType("Angle",       net.ReadAngle,       net.WriteAngle)
XCF.DefineDataVarType("Vector",      net.ReadVector,      net.WriteVector)
XCF.DefineDataVarType("Normal",      net.ReadNormal,      net.WriteNormal)
XCF.DefineDataVarType("Entity",      net.ReadEntity,      net.WriteEntity)
XCF.DefineDataVarType("Player",      net.ReadPlayer,      net.WritePlayer)
XCF.DefineDataVarType("Table",       net.ReadTable,       net.WriteTable)
XCF.DefineDataVarType("Data",        net.ReadData,        net.WriteData)
XCF.DefineDataVarType("Bit",         net.ReadBit,         net.WriteBit)

----------------------------------------------------------

-- Test variable
XCF.DefineDataVar("TestVar", "TestGroup", XCF.DataVarTypes.String)