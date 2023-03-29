------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/Pages/PatternLengthPage"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternLengthPageStudio = class( 'PatternLengthPageStudio', PatternLengthPage )

------------------------------------------------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageStudio:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "PatternLengthPageStudio", Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageStudio:setupScreen()

	self.Screen = ScreenMaschineStudio(self)

    -- screen buttons
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "METRONOME", "", ""}, "HeadButton", true)
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"2", "4", "8", "16"}, "HeadButton")

    -- parameter bar
    self.Screen.ParameterWidgets[4]:setName("LENGTH")

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageStudio:updateScreens(ForceUpdate)

    -- parameter bar
    self.ParameterHandler.SectionWidgets[4]:setText(
        NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and "Clip" or "Pattern")

    -- call base class
    PatternLengthPage.updateScreens(self, ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageStudio:getAccessiblePageInfo()

    return "Record Prepare"

end

------------------------------------------------------------------------------------------------------------------------
