------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/GroupPageMikroMK3"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/MiscHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditGroupPageMikroMK3 = class( 'QuickEditGroupPageMikroMK3', GroupPageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function QuickEditGroupPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "QuickEditGroupPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditGroupPageMikroMK3:onShow(Show)

    self.Controller.QuickEdit:resetGroupTuneOffset()
    self.Screen:showParameterInBottomRow()

    GroupPageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditGroupPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedGroup()

    self.Screen:setParameterName(self.Controller.QuickEdit:getModeString())
               :setParameterValue(self.Controller.QuickEdit:getValueString())

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditGroupPageMikroMK3:onWheelEvent(Inc)

    self.Controller.QuickEdit:onWheel(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditGroupPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    self.Controller.QuickEdit:onPadEvent(PadIndex, Trigger, PadValue)

    if GroupPageMikroMK3.onPadEvent then
        GroupPageMikroMK3.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------
