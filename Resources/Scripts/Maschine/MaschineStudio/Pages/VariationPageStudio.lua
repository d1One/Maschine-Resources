require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Components/Pages/VariationPageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPageStudio = class( 'VariationPageStudio', VariationPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function VariationPageStudio:__init(Controller)

    VariationPageBase.__init(self, "VariationPageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function VariationPageStudio:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"VARIATION", "HUMANIZE", "RANDOM", "APPLY"},
        {"HeadButton", "HeadTabLeft", "HeadTabRight", "HeadButton"}, false)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)
    self.Screen.ScreenButton[1]:style("VARIATION", "HeadPin")

    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "StudioDisplay")

    local EmptyInfo = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "EmptyInfo")
    EmptyInfo:style("", "EmptyInfo")

    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenRight, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.ArrangerOV = self.Controller.SharedObjects.PatternEditorOverview

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageStudio:onShow(Show)

    if Show then
        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.ArrangerOV:setOverview()
    end

    VariationPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageStudio:updateParameters(ForceUpdate)

    Param = VariationPageBase.updateParameters(self, ForceUpdate)
    self.Controller.CapacitiveList:assignParametersToCaps(Param)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageStudio:updateScreens(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self.ArrangerOV:update(ForceUpdate)
    VariationPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

