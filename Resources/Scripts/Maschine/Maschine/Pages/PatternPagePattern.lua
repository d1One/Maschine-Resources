------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/PatternPageBase"

require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"

local ATTR_HAS_ARROW = NI.UTILS.Symbol("HasArrow")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPagePattern = class( 'PatternPagePattern', PatternPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPagePattern:__init(ParentPage, Controller)

    PatternPageBase.__init(self, ParentPage, Controller, "PatternPagePattern")

end

------------------------------------------------------------------------------------------------------------------------

function PatternPagePattern:setupScreen()

    self.Screen = ScreenWithGrid(self)
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"PATTERN", "REMOVE", "DOUBLE", "DUPL",
        "CREATE", "DELETE", "<", ">"})

    -- Parameter Bar
    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.ParameterHandler.NumPages = 1

    -- set custom style to grid buttons
    for i, Button in ipairs(self.Screen.ButtonPad) do
        Button:style("", "SelectPad")
    end

    -- Base
    PatternPageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPagePattern:updateScreenButtons(ForceUpdate)

    -- update pad buttons
    ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad, PatternHelper.PatternStateFunctor)

    -- Arrow for Button #8
    local CanAdd = PatternHelper.canAddPatternBank()
    self.Screen.ScreenButton[8]:setAttribute(ATTR_HAS_ARROW, CanAdd and "false" or "true")

    -- Base
    PatternPageBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

