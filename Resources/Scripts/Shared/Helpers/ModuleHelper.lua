------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModuleHelper = class( 'ModuleHelper' )

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.isSlotFX(Slot)

    local Module = Slot and Slot:getModule()
    local Info = Module and Module:getInfo()
    local Type = Info and Info:getType()

    return Type and Type == NI.DATA.ModuleInfo.TYPE_EFFECT or false

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.isSlotMissing(Slot)

    local Module = Slot and Slot:getModule()
    local Info = Module and Module:getInfo()
    local Type = Info and Info:getType()

    return Type and Type ~= NI.DATA.ModuleInfo.TYPE_EFFECT and Type ~= NI.DATA.ModuleInfo.TYPE_INSTRUMENT or false

end

------------------------------------------------------------------------------------------------------------------------