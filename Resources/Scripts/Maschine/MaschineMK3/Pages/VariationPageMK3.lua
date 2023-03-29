------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/VariationPageStudio"
require "Scripts/Shared/Components/Events4DWheel"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPageMK3 = class( 'VariationPageMK3', VariationPageStudio )

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:__init(Controller)

    VariationPageBase.__init(self, "VariationPageMK3", Controller)

    -- override page leds if MK3
    self.PageLEDs = { NI.HW.LED_VARIATION }

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:updateWheelButtonLEDs()

    --handled

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:onControllerTimer()

    Events4DWheel.onControllerTimer(self.Controller, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:onWheel(Inc)

	if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
		return Events4DWheel.onWheel(self.Controller, Inc)
	end

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:onWheelDirection(Pressed, DirectionButton)

	Events4DWheel.onWheelDirection(self.Controller, Pressed, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMK3:getAccessiblePageInfo()

    return "Variation"

end

------------------------------------------------------------------------------------------------------------------------
