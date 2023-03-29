------------------------------------------------------------------------------------------------------------------------
-- keeps track of the capactive knobs status
local class = require 'Scripts/Shared/Helpers/classy'
CapacitiveHelper = class( 'CapacitiveHelper' )

-- Stack-like table that keeps track of currently touched caps
local CapTouched = {}

------------------------------------------------------------------------------------------------------------------------

function CapacitiveHelper.reset()

    CapTouched = {}

end

------------------------------------------------------------------------------------------------------------------------
-- self.CapTouched functions like a stack. this functions finds the cap in the stack
local function findCapTouchedIndex(Cap)

    for Index in pairs (CapTouched) do
        if CapTouched[Index] == Cap then
            return Index
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveHelper.isCapTouched(Cap)

    return findCapTouchedIndex(Cap) ~= nil

end

------------------------------------------------------------------------------------------------------------------------
-- focus cap = last touched (in case there > 1), and enabled
function CapacitiveHelper.getFocusCap(CapEnabledFunc)

    for Index, CapIndex in pairs (CapTouched) do
        if CapEnabledFunc == nil or CapEnabledFunc(CapIndex) then
            return CapIndex
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveHelper.onCapTouched(Cap, Touched)

    local TableIndex = findCapTouchedIndex(Cap)

    if Touched then

        if not TableIndex then
            table.insert(CapTouched, 1, Cap)
        end

    elseif TableIndex then

        table.remove(CapTouched, TableIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------


