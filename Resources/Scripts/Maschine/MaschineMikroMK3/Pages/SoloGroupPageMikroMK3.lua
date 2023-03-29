------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/MuteSoloHelperMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloGroupPageMikroMK3 = class( 'SoloGroupPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function SoloGroupPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "SoloGroupPageMikroMK3", Controller)
    self.LastPressedPadIndex = nil

end

------------------------------------------------------------------------------------------------------------------------

function SoloGroupPageMikroMK3:onShow(Show)

    self.LastPressedPadIndex = nil

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SoloGroupPageMikroMK3:updateScreen()

    MuteSoloHelperMikroMK3.setTopLineGroup(self, self.LastPressedPadIndex)
    self.Screen:setBottomRowText("")

end

------------------------------------------------------------------------------------------------------------------------

function SoloGroupPageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    if not Trigger then
        return
    end

    local GroupIndex = GroupPadHelperMikroMK3.setFocusGroupByPad(self, PadIndex)

    if GroupIndex == nil then
        return
    end

    MuteSoloHelper.toggleGroupSoloState(GroupIndex)
    self.LastPressedPadIndex = GroupIndex

end

------------------------------------------------------------------------------------------------------------------------

function SoloGroupPageMikroMK3:updatePadLEDs()

    MuteSoloHelperMikroMK3.updateGroupPadLeds(self)

end

------------------------------------------------------------------------------------------------------------------------