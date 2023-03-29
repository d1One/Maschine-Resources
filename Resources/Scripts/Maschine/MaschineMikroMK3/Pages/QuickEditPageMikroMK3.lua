------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/QuickEditMikroMK3"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditPageMikroMK3 = class( 'QuickEditPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function QuickEditPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "QuickEditPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPageMikroMK3:updateScreen()

    if self.Controller.QuickEdit:inStepMode() then

        self.Screen:setTopRowIcon("")
        self.Screen:setTopRowText("Step")

    elseif self.Controller.QuickEdit:inMasterLevel() then

        self.Screen:setTopRowToMaster()

    elseif self.Controller.QuickEdit:inGroupLevel() then

        self.Screen:setTopRowToFocusedGroup()

    elseif self.Controller.QuickEdit:inSoundLevel() then

        self.Screen:setTopRowToFocusedSound()
    end

    self.Screen:setParameterName(self.Controller.QuickEdit:getModeString())
               :setParameterValue(self.Controller.QuickEdit:getValueString())

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPageMikroMK3:onWheelEvent(Inc)

    return self.Controller.QuickEdit:onWheel(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    self.Controller.QuickEdit:onPadEvent(PadIndex, Trigger, PadValue)

    -- onStateFlagsChanged() will not be called if the Sound focus doesn't change, but we need it to be called in order
    -- to update the screen whenever a pad is pressed or released, therefore call it here if nothing is changed on a
    -- pad event.
    if PadModeHelper.isStepModeEnabled()
        or PadModeHelper.getKeyboardMode()
        or PadIndex == NI.DATA.StateHelper.getFocusSoundIndex(App)+1 then

        self:updateScreen()

    end

    if not PadModeHelper.isStepModeEnabled() then
        PadModeHelper.onPadEvent(PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------
