------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NotesPage = class( 'NotesPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function NotesPage:__init(Controller)

    PageMaschine.__init(self, "NotesPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NOTES }

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:setupScreen()

	self.Screen = ScreenMaschineStudio(self)

    -- left screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"Notes", "", "", ""}, "HeadButton", true)
    self.Screen.ScreenButton[1]:style("NOTES", "HeadPin")

    -- always looks pinned
    self.Screen.ScreenButton[1]:setSelected(true)

    -- right screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)

end

------------------------------------------------------------------------------------------------------------------------
