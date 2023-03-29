------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicateSoundPageMikroMK3 = class( 'DuplicateSoundPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "DuplicateSoundPageMikroMK3", Controller)
    self.updateScreens = function() self:updateScreen() end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:onShow(Show)

    self:reset()
    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:reset()

    self.Mode = DuplicateHelper.SOUND
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedSound()
    self:updateScreenBottomEventParameter()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:updateScreenBottomEventParameter()

    local FocusedParameter = NHLController:focusedParameter()

    if not FocusedParameter or not FocusedParameter:maschineParameter() then
        return
    end

    if FocusedParameter:name() == "Duplicate Sound With Events" then

        self.Screen:setParameterName("Copy Events")
        self.Screen:setParameterValue(FocusedParameter:valueStringShort())

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    if not Trigger then
        return
    end

    DuplicateHelper.onPadEvent(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSoundPageMikroMK3:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------
