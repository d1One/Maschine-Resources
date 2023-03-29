require "Scripts/Maschine/MaschineStudio/Pages/RepeatPageStudio"
require "Scripts/Shared/Components/Events4DWheel"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RepeatPageMK3 = class( 'RepeatPageMK3', RepeatPageStudio )

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:__init(Controller)

    RepeatPageStudio.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:updateScreens(ForceUpdate)

    RepeatPageStudio.updateScreens(self, ForceUpdate)

    if PadModeHelper.isKeyboardModeChanged() then
        self:sendAccessibilityInfoForPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:onWheel(Inc)

	if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
		return Events4DWheel.onWheel(self.Controller, Inc)
	end

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:onWheelDirection(Pressed, DirectionButton)

	Events4DWheel.onWheelDirection(self.Controller, Pressed, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:updateWheelButtonLEDs()

    --handled

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:onControllerTimer()

	Events4DWheel.onControllerTimer(self.Controller, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMK3:getAccessiblePageInfo()

    return PadModeHelper.getKeyboardMode() and "Arpeggiator" or "Note Repeat"

end

------------------------------------------------------------------------------------------------------------------------
