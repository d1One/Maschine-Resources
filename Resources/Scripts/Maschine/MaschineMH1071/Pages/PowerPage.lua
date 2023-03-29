------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PowerPage = class( 'PowerPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function PowerPage:__init(Controller)

    PageMaschine.__init(self, "PowerPage", Controller)

    self.PageLEDs = { NI.HW.LED_FILE }

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function PowerPage:setupScreen()

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

    self.Logo = NI.GUI.insertBar(self.Screen.ScreenLeft.DisplayBar, "PowerIcon")
    self.Logo:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftScreenText = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft.DisplayBar, "LeftScreenText")
    self.LeftScreenText:style("")
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.LeftScreenText)

    self.RightScreenText = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight.DisplayBar, "RightScreenText")
    self.RightScreenText:style("")
    self.Screen.ScreenRight.DisplayBar:setFlex(self.RightScreenText)

    self.LeftScreenText:setText("You are about to shut down\nMASCHINE+")
    self.RightScreenText:setText("Do you want to proceed?")

end

------------------------------------------------------------------------------------------------------------------------

function PowerPage:updateScreenButtons(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()

    self.Screen.ScreenButton[5]:setEnabled(not ShiftPressed)
    self.Screen.ScreenButton[5]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[5]:setText("CANCEL")

    self.Screen.ScreenButton[7]:setEnabled(not ShiftPressed)
    self.Screen.ScreenButton[7]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[7]:setText("RESTART")

    self.Screen.ScreenButton[8]:setEnabled(true)
    self.Screen.ScreenButton[8]:setVisible(true)

    if ShiftPressed then

        self.Screen.ScreenButton[8]:setText("RECOVERY")

    else

        self.Screen.ScreenButton[8]:setText("SHUT DOWN")

    end

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PowerPage:onScreenButton(Index, Pressed)

    local ShiftPressed = self.Controller:getShiftPressed()
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == 5 then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_CANCEL)

    elseif ShouldHandle and Index == 7 then

        if App:checkSaveBeforeContinue() then

            App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_REBOOT)

        end

    elseif ShouldHandle and Index == 8 then

        if App:checkSaveBeforeContinue() then

            if ShiftPressed then

                App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_RECOVERY)

            else

                App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_SHUTDOWN)

            end

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
