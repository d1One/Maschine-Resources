------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TextInputPage = class( 'TextInputPage', PageMaschine )

local ATTR_STYLE = NI.UTILS.Symbol("Style")

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:__init(Controller)

    PageMaschine.__init(self, "TextInputPage", Controller)

    -- setup screen
    self:setupScreen()

    self.CurrentRow = 1
    self.CurrentColumn = 1
    self:updateSelection(true)
    self:setEditedText("")
    self.IsPasswordMode = false

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:makeLabelRow(characters, id)

    local bar = NI.GUI.insertBar(self.Container, "Bar" .. id)
    bar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "TextInputKeyboardLine")

    local row = {}

    for i = 1, #characters do
        row[i] = NI.GUI.insertLabel(bar, id .. i)
        row[i]:style(characters:sub(i, i), "TextInputLetter")
        row[i]:setEnabled(true)
        row[i]:setVisible(true)
    end
    return { bar, row }

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:makeKeyboard(id, rows)
    local labelBars = {}
    local labelRows = {}

    for i = 1, 4 do
        local barRow = self:makeLabelRow(rows[i], "LabelInput_" .. id .. "_" .. i)
        labelBars[i] = barRow[1]
        labelRows[i] = barRow[2]
    end

    return { labelBars, labelRows }
end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight,
        {"SPACE", "BACKSPACE", "CANCEL", "ENTER"}, "HeadButton")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.Container = NI.GUI.insertBar(self.Screen.ScreenRight, "Container")
    self.Container:style(NI.GUI.ALIGN_WIDGET_DOWN,"")
    self.Screen.ScreenRight:setFlex(self.Container)

    self.TextBox = NI.GUI.insertLabel(self.Container, "TextField")
    self.TextBox:style("", "TextInputTextField")
    local Space = NI.GUI.insertBar(self.Container, "Space")
    NI.GUI.enableCropModeInitialForLabel(self.TextBox)

    self.KeyboardRegular = self:makeKeyboard("Regular", {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz",
        "0123456789!@#$^&*()\\/?,_+-",
        "\"%'.;:<>=~[]{}|"
    })

    self.KeyboardFileName = self:makeKeyboard("FileName", {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz",
        "0123456789!@#$^&(),_+-%.=~",
        "[]{}",
    })

    self:setKeyboard(0)

    self.Container:setFlex(Space)
    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setEditedText(Text, PasswordTimerRunning)

    self.TextResult = Text
    local SubLength = PasswordTimerRunning and #Text - 1 or #Text
    Text = string.gsub(Text, ".", function(Char) return self.IsPasswordMode and "●" or Char end, SubLength)
    self.TextBox:setText(Text .. "|")

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:addCharacter(Char)

    self.Controller:setTimer(self, 50)
    self:setEditedText(self.TextResult .. Char, true)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:space()

    self:addCharacter(" ")

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:backSpace()

    self:setEditedText(self.TextResult:sub(1, #self.TextResult-1))

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setStrings(Message, Prefill)

    self.LeftLabel:setText(Message)
    self:setEditedText(Prefill)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setKeyboard(Index)

    if self.Keyboard then
        for i = 1, 4 do
            self.Keyboard[1][i]:setVisible(false)
            self.Keyboard[1][i]:setActive(false)
        end
    end

    if Index == 0 then
        self.Keyboard = self.KeyboardRegular
    elseif Index == 1 then
        self.Keyboard = self.KeyboardFileName
    end

    for i = 1, 4 do
        self.Keyboard[1][i]:setVisible(true)
        self.Keyboard[1][i]:setActive(true)
    end

    self.InputLabels = self.Keyboard[2]

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setPasswordMode(IsPasswordMode)

    self.IsPasswordMode = IsPasswordMode

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:setLeftScreenAttribute(Attribute)

    self.Icon:setActive(Attribute ~= "Empty")

    self.Screen.ScreenLeft:setAttribute(ATTR_STYLE, Attribute)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)
    self.LastJogWheelMode = NHLController:getJogWheelMode()

    if Show then

        self.LastJogWheelMode = NHLController:getJogWheelMode()
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)

        self:updateScreens(true)

    else

        self:setEditedText("")
        self.IsPasswordMode = false

        if self.LastJogWheelMode then
            NHLController:setJogWheelMode(self.LastJogWheelMode)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onTimer()

    self:setEditedText(self.TextResult)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:updateWheelButtonLEDs()

    local Color = LEDColors.WHITE
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, true, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, true, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, true, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, true, Color)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 5 then

            self:space()

        elseif Idx == 6 then

            self:backSpace()

        elseif Idx == 7 then

            App:getHardwareInputManager():onHWTextResult()

        elseif Idx == 8 then

            App:getHardwareInputManager():onHWTextResult(self.TextResult)

        end

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:updateSelection(Selected)
    local label = self.InputLabels[self.CurrentRow][self.CurrentColumn]
    label:setSelected(Selected)
end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:moveRow(Inc)
    local nRows = #self.InputLabels
    local lastRowColumns = #self.InputLabels[nRows]

    self:updateSelection(false)

    self.CurrentRow = self.CurrentRow + Inc

    if self.CurrentRow > nRows then
        self.CurrentRow = 1
    elseif self.CurrentRow == nRows and self.CurrentColumn > lastRowColumns then
        self.CurrentRow = 1
    elseif self.CurrentRow <= 0 and self.CurrentColumn > lastRowColumns then
        self.CurrentRow = nRows - 1
    elseif self.CurrentRow <= 0 then
        self.CurrentRow = nRows
    end

    self:updateSelection(true)
end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:moveColumn(Inc)
    local nColumns = #self.InputLabels[self.CurrentRow]

    self:updateSelection(false)

    self.CurrentColumn = self.CurrentColumn + Inc

    if self.CurrentColumn > nColumns then
        self.CurrentColumn = self.CurrentColumn - nColumns
    elseif self.CurrentColumn <= 0 then
        self.CurrentColumn = self.CurrentColumn + nColumns
    end

    self:updateSelection(true)
end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onWheel(Inc)
    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        self:moveColumn(Inc)
    end
    return false
end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onWheelButton(Pressed)

    if Pressed then
        local label = self.InputLabels[self.CurrentRow][self.CurrentColumn]

        self:addCharacter(label:getText())
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function TextInputPage:onWheelDirection(Pressed, DirectionButton)
    if Pressed then
        if DirectionButton == NI.HW.BUTTON_WHEEL_LEFT then
            self:moveColumn(-1)
        elseif DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT then
            self:moveColumn(1)
        elseif DirectionButton == NI.HW.BUTTON_WHEEL_UP then
            self:moveRow(-1)
        elseif DirectionButton == NI.HW.BUTTON_WHEEL_DOWN then
            self:moveRow(1)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
