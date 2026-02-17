DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

AddCSLuaFile("shared.lua") -- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua") -- Send shared and cl_init to the client

include("shared.lua") -- Includes and runs shared file on the server

-- TODO: Add scaling later