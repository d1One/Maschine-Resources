------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local PADS_TO_GROUPS =
{
    [NI.HW.PAD_13] = 1,
    [NI.HW.PAD_14] = 2,
    [NI.HW.PAD_15] = 3,
    [NI.HW.PAD_16] = 4,
    [NI.HW.PAD_9] = 5,
    [NI.HW.PAD_10] = 6,
    [NI.HW.PAD_11] = 7,
    [NI.HW.PAD_12] = 8
}

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GroupPadHelperMikroMK3 = class( 'GroupPadHelperMikroMK3' )

------------------------------------------------------------------------------------------------------------------------

function GroupPadHelperMikroMK3.showGroupPads(Page, PadLeds, GroupLeds, selectedPadFunction)

    local Bank = MaschineHelper.getFocusGroupBank(Page)
    local NumBanks = MaschineHelper.getNumFocusSongGroupBanks(true)
    local getWhite = function() return LEDColors.WHITE end

    -- return focused, enabled
    local getPadLEDStates = function (Index)
        if NumBanks > 1 then
            return (Index-1 == Bank), Index <= NumBanks
        end
        return false, false
    end

    -- pads
    LEDHelper.updateLEDsWithFunctor(PadLeds, 0, getPadLEDStates, getWhite)

    -- groups
    LEDHelper.updateLEDsWithFunctor(GroupLeds,
        Bank * 8,
        selectedPadFunction,
        function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPadHelperMikroMK3.setFocusGroupByPad(Page, PadIndex)

    local FocusBank = MaschineHelper.getFocusGroupBank(Page)

    if FocusBank == nil then
        return nil
    end

    local FocusGroup, IncludeNewGroups = true, true
    MaschineHelper.setFocusGroupBankAndGroup(nil, PadIndex-1, FocusGroup, IncludeNewGroups)  -- BankIndex >= 0

    local GroupPad = PADS_TO_GROUPS[PadIndex]
    local GroupIndex = GroupPad and (GroupPad + (FocusBank * 8))

    return GroupIndex

end

------------------------------------------------------------------------------------------------------------------------

function GroupPadHelperMikroMK3.defaultBankNavigationFunctions()

    return { Action = function (self, PadIndex) self:selectBank(PadIndex) end,
             When = function () return MaschineHelper.getNumFocusSongGroupBanks(true) > 1 end }

end

------------------------------------------------------------------------------------------------------------------------