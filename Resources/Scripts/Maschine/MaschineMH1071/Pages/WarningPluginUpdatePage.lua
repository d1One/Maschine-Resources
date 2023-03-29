------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WarningPluginUpdatePage = class( 'WarningPluginUpdatePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

local BUTTON_INDEX_CANCEL = 5
local BUTTON_INDEX_RESTART = 8

------------------------------------------------------------------------------------------------------------------------

function WarningPluginUpdatePage:__init(Controller)

    PageMaschine.__init(self, "WarningPluginUpdatePage", Controller)

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function WarningPluginUpdatePage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, { "", "", "", "" }, "HeadButton")
    self.ButtonBarLeft:setActive(false)

    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, { "", "", "", "" }, "HeadButton")

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.Logo = NI.GUI.insertBar(self.Screen.ScreenLeft.DisplayBar, "SuccessIcon")
    self.Logo:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftScreenText = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft.DisplayBar, "LeftScreenText")
    self.LeftScreenText:style("")
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.LeftScreenText)

    self.RightScreenText = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight.DisplayBar, "RightScreenText")
    self.RightScreenText:style("")
    self.Screen.ScreenRight.DisplayBar:setFlex(self.RightScreenText)

    self.LeftScreenText:setText("Plugin update successful")
    self.RightScreenText:setText("Restart is required to apply update.")

end

------------------------------------------------------------------------------------------------------------------------

function WarningPluginUpdatePage:updateScreenButtons(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()

    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setEnabled(not ShiftPressed)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setText("CANCEL")

    self.Screen.ScreenButton[BUTTON_INDEX_RESTART]:setEnabled(not ShiftPressed)
    self.Screen.ScreenButton[BUTTON_INDEX_RESTART]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[BUTTON_INDEX_RESTART]:setText("RESTART")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WarningPluginUpdatePage:onScreenButton(Index, Pressed)

    if Pressed and Index == BUTTON_INDEX_CANCEL then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_CANCEL)

    elseif Pressed and Index == BUTTON_INDEX_RESTART then

        if App:checkSaveBeforeContinue() then

            App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_REBOOT)

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
