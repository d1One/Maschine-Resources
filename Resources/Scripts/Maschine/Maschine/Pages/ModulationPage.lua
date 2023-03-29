------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModulationPage = class( 'ModulationPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ModulationPage:__init(Controller)

    PageMaschine.__init(self, "ModulationPage", Controller)

    -- setup screen
    self.Screen = ScreenMaschine(self)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ALL  }

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function ModulationPage:setupScreen()

	-- setup screen
    self.Screen = ScreenMaschine(self)

	-- style screens
	self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadTab")
	self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadTab")

	-- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"MODULATION"})

end

------------------------------------------------------------------------------------------------------------------------
