------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageMikroMK3 = class( 'PadModePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "PadModePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedSound()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound then
        self.Screen:setBottomRowToParameter(Sound:getBaseKeyParameter())
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikroMK3:onWheelEvent(EncoderInc)

    if self.Controller:isButtonPressed(NI.HW.BUTTON_SHIFT) then
        EncoderInc = 12 * EncoderInc -- shift in octaves (12 semitones)
    end

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound then
        local BaseKeyParam = Sound:getBaseKeyParameter()
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, BaseKeyParam, EncoderInc, false, true)
    end

end

------------------------------------------------------------------------------------------------------------------------
