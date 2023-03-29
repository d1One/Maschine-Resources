------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SaveDialogPageBase = class( 'SaveDialogPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageBase:__init(Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageBase:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, { "", "", "", "" }, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, { "", "", "", "" }, "HeadButton")

    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.RightLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "LabelRight")
    self.RightLabel:style("")
    self.Screen.ScreenRight:setFlex(self.RightLabel)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageBase:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageBase:updateScreenButtons(ForceUpdate)

    -- Display button only on the right screen
    self.Screen.ScreenButton[5]:setText("CANCEL")
    self.Screen.ScreenButton[5]:setEnabled(true)
    self.Screen.ScreenButton[5]:setVisible(true)

    self.Screen.ScreenButton[7]:setText("DISCARD")
    self.Screen.ScreenButton[7]:setEnabled(true)
    self.Screen.ScreenButton[7]:setVisible(true)

    self.Screen.ScreenButton[8]:setText("SAVE")
    self.Screen.ScreenButton[8]:setEnabled(true)
    self.Screen.ScreenButton[8]:setVisible(true)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageBase:onScreenButton(Idx, Pressed)

    -- Display button only on the right screen
    local buttonOffset = 5

    if Idx >= buttonOffset and Pressed and self.Screen.ScreenButton[Idx]:isEnabled() then

        App:getHardwareInputManager():onButton(Idx - buttonOffset)

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
