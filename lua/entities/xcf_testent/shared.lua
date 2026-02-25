-- shared.lua --
DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF scalable test entity"
ENT.WireDebugName  = "XCF scalable test entity"

XCF.DefineDataVar("Volatility", "xcf_testent", "Float", 0, {Min = 0, Max = 1})
XCF.DefineDataVar("State", "xcf_testent", "UInt8", 0, {Min = 0, Max = 10})
XCF.DefineDataVar("Size", "xcf_testent", "Vector", Vector(1, 1, 1), {Min = Vector(0.1, 0.1, 0.1), Max = Vector(2, 2, 2)})
XCF.DefineDataVar("Material", "xcf_testent", "String", "phoenix_storms/grey_chrome", {MaxLength = 100})
XCF.DefineDataVar("MakeNoise", "xcf_testent", "Bool", false, {})