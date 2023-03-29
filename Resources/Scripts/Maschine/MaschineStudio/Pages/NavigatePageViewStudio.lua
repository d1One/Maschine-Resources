------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/Pages/NavigatePageView"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageViewStudio = class( 'NavigatePageViewStudio', NavigatePageView )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:__init(ParentPage, Controller)

    NavigatePageView.__init(self, ParentPage, Controller, "NavigatePageViewStudio", NavigatePageStudio.PAGE_NAV)
       self.PageLEDs = { NI.HW.LED_NAVIGATE }
end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:setupScreen()

    -- create screen
    self.Screen = ScreenMaschineStudio(self)

    -- left screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"NAVIGATE", "IDEAS", "SONG", "MIXER"},
        {"HeadPin", "HeadTabLeft", "HeadTabRight", "HeadButton"}, false)

    -- Right screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"BROWSER", "EXPANDED", "MODULATION", "FOLLOW"}, "HeadButton", false, false)
    local EmptyInfo = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "EmptyInfo")
    EmptyInfo:style("", "EmptyInfo")

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:onScreenButton(ButtonIdx, Pressed)

    NavigatePageView.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:onWheelButton(Pressed)

    -- handled: no QE
    return true
end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:updateScreenButtons(ForceUpdate)

    NavigatePageView.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:updateZoomResetStates()

    self.ArrangerHasBeenResetted = false
    self.PatternEditorHasBeenResetted = false
    self.ZoneMapHasBeenResetted = false
    self.WaveHasBeenResetted = false

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageViewStudio:getAccessiblePageInfo()

    return "Navigate"

end

------------------------------------------------------------------------------------------------------------------------
