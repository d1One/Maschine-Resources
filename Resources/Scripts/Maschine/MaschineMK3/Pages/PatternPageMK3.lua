require "Scripts/Maschine/MaschineStudio/Pages/PatternPageStudio"
require "Scripts/Shared/Components/Events4DWheel"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageMK3 = class( 'PatternPageMK3', PatternPageStudio )

------------------------------------------------------------------------------------------------------------------------

function PatternPageMK3:__init(Controller)

    PatternPageStudio.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMK3:updateWheelButtonLEDs()

    --handled

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMK3:onControllerTimer()

    Events4DWheel.onControllerTimer(self.Controller, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMK3:onWheel(Inc)

	if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
		return Events4DWheel.onWheel(self.Controller, Inc)
	end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMK3:onWheelDirection(Pressed, DirectionButton)

	Events4DWheel.onWheelDirection(self.Controller, Pressed, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------
