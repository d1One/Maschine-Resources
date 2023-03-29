------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FactoryResetPage = class( 'FactoryResetPage', PageMaschine )

local BUTTON_INDEX_CANCEL = 5
local BUTTON_INDEX_RESET = 8

------------------------------------------------------------------------------------------------------------------------

function FactoryResetPage:__init(Controller)

    PageMaschine.__init(self, "FactoryResetPage", Controller)

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function FactoryResetPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"CANCEL", "", "", "RESET"}, "HeadButton")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("", "")

    self.RightLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "LabelRight")
    self.RightLabel:style("")

    self.ButtonBarLeft:setActive(false)

    self.LeftLabel:setText("Caution")
    self.RightLabel:setText("You are about to perform a system reset.\nThis will erase your settings and\npreferences. This cannot be undone.")

end

------------------------------------------------------------------------------------------------------------------------

function FactoryResetPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setText("CANCEL")

    self.Screen.ScreenButton[BUTTON_INDEX_RESET]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_RESET]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_RESET]:setText("RESET")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function FactoryResetPage:onScreenButton(Index, Pressed)

    if Pressed and Index == BUTTON_INDEX_CANCEL then
        NHLController:getPageStack():popPage()

    elseif Pressed and Index == BUTTON_INDEX_RESET then
        NI.UTILS.NativeOSHelpers.rebootToRecovery(App, NI.UTILS.NativeOSHelpers.RecoveryAppMode.FactoryReset)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
