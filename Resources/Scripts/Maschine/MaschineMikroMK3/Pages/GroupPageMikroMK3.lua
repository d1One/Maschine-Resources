------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Components/PadMapper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local function inEraseMode(self)

    return self.Controller:isButtonPressed(NI.HW.BUTTON_SHIFT) and
            self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_ERASE)

end

------------------------------------------------------------------------------------------------------------------------

local PAD_MAPPING = PadMapper()

PAD_MAPPING:map(1, 8, {GroupPadHelperMikroMK3.defaultBankNavigationFunctions()})

PAD_MAPPING:map(9, 16, {{
    Action = function (self, PadIndex) self:selectGroup(PadIndex) end,
    When = function (self) return not inEraseMode(self) end,
}, {
    Action = function (self, PadIndex) self:eraseGroup(PadIndex) end,
    When = function (self) return inEraseMode(self) end,
}})

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GroupPageMikroMK3 = class( 'GroupPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "GroupPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:setBottomRowIcon()

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedGroup()

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    local Handler = PAD_MAPPING:find(PadIndex, self)
    if not Handler then
        return
    end

    Handler.Action(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:selectBank(PadIndex)

    MaschineHelper.setFocusGroupBankAndGroup(nil, PadIndex - 1, true, true)  -- PadIndex >= 0

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:selectGroup(PadIndex)

    local GroupIndex = GroupPadHelperMikroMK3.setFocusGroupByPad(self, PadIndex)

    if not GroupIndex then
        return
    end

    MaschineHelper.setFocusGroup(GroupIndex, true)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:eraseGroup(PadIndex)

    local GroupIndex = GroupPadHelperMikroMK3.setFocusGroupByPad(self, PadIndex)

    if not GroupIndex then
        return
    end

    MaschineHelper.removeGroup(GroupIndex)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikroMK3:updatePadLEDs()

    local selectedPadFunction =
    function (Index)
        return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, true)
    end

    GroupPadHelperMikroMK3.showGroupPads(self,
                                        self.Controller.PAD_LEDS,
                                        self.Controller.GROUP_LEDS,
                                        selectedPadFunction)

end

------------------------------------------------------------------------------------------------------------------------
