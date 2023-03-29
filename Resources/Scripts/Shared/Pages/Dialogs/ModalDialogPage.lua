------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModalDialogPage = class( 'ModalDialogPage', PageMaschine )

local ATTR_STYLE = NI.UTILS.Symbol("Style")

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:__init(Controller)

    PageMaschine.__init(self, "ModalDialogPage", Controller)

    -- setup screen
    self:setupScreen()

    self.ButtonsText = {}

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, { "", "", "", "" }, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, { "", "", "", "" }, "HeadButton")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.RightLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "LabelRight")
    self.RightLabel:style("")
    self.Screen.ScreenRight:setFlex(self.RightLabel)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:setContent(Title, Message, leftScreenAttribute, Button1Text, Button2Text, Button3Text, Button4Text)

    self.Icon:setActive(leftScreenAttribute ~= "Empty")

    self.Screen.ScreenLeft:setAttribute(ATTR_STYLE, leftScreenAttribute)

    self.LeftLabel:setText(Title)
    self.RightLabel:setText(Message)
    self.AccessibleText = Title .. ". " .. Message

    self.ButtonsText[1] = Button1Text
    self.ButtonsText[2] = Button2Text
    self.ButtonsText[3] = Button3Text
    self.ButtonsText[4] = Button4Text

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:updateScreenButtons(ForceUpdate)

    -- Display button only on the right screen
    self.Screen.ScreenButton[5]:setText(string.upper(self.ButtonsText[1]))
    self.Screen.ScreenButton[5]:setEnabled(string.len(self.ButtonsText[1]) >=1)
    self.Screen.ScreenButton[5]:setVisible(string.len(self.ButtonsText[1]) >=1)

    self.Screen.ScreenButton[6]:setText(string.upper(self.ButtonsText[2]))
    self.Screen.ScreenButton[6]:setEnabled(string.len(self.ButtonsText[2]) >=1)
    self.Screen.ScreenButton[6]:setVisible(string.len(self.ButtonsText[2]) >=1)

    self.Screen.ScreenButton[7]:setText(string.upper(self.ButtonsText[3]))
    self.Screen.ScreenButton[7]:setEnabled(string.len(self.ButtonsText[3]) >=1)
    self.Screen.ScreenButton[7]:setVisible(string.len(self.ButtonsText[3]) >=1)

    self.Screen.ScreenButton[8]:setText(string.upper(self.ButtonsText[4]))
    self.Screen.ScreenButton[8]:setEnabled(string.len(self.ButtonsText[4]) >=1)
    self.Screen.ScreenButton[8]:setVisible(string.len(self.ButtonsText[4]) >=1)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:onScreenButton(Idx, Pressed)

    -- Display button only on the right screen
    local buttonOffset = 5

    if Idx >= buttonOffset and Pressed and self.Screen.ScreenButton[Idx]:isEnabled() then

        App:getHardwareInputManager():onButton(Idx - buttonOffset)

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ModalDialogPage:getAccessiblePageInfo()

    return self.AccessibleText

end

------------------------------------------------------------------------------------------------------------------------
