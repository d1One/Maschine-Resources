require "Scripts/Maschine/MaschineStudio/Pages/EventsPageStudio"
require "Scripts/Shared/Components/Events4DWheel"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
EventsPageMK3 = class( 'EventsPageMK3', EventsPageStudio )

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:__init(Controller)

    EventsPageStudio.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:updateWheelButtonLEDs()

    --handled, do not execute default implementation
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:onWheel(Inc)

	if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
		return Events4DWheel.onWheel(self.Controller, Inc)
	end

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:onWheelDirection(Pressed, DirectionButton)

	Events4DWheel.onWheelDirection(self.Controller, Pressed, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:onControllerTimer()

	Events4DWheel.onControllerTimer(self.Controller, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMK3:getAccessiblePageInfo()

    return "Events"

end

------------------------------------------------------------------------------------------------------------------------
