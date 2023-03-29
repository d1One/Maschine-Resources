------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
USBStorageModePage = class( 'USBStorageModePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function USBStorageModePage:__init(Controller)

    PageMaschine.__init(self, "USBStorageModePage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function USBStorageModePage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", "DISCONNECT"}, "HeadButton")

    self.LeftLabel = NI.GUI.insertLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("", "")
    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.RightLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "LabelRight")
    self.RightLabel:style("")

    self.ButtonBarLeft:setActive(false)

    self.LeftLabel:setText("STORAGE MODE")
    self.RightLabel:setText("To exit STORAGE MODE, safely eject your SD card on your computer and then press DISCONNECT")

end

------------------------------------------------------------------------------------------------------------------------

function USBStorageModePage:onScreenButton(Idx, Pressed)

    -- Display button only on the right screen
    local buttonOffset = 5

    if Idx >= buttonOffset and Pressed and self.Screen.ScreenButton[Idx]:isEnabled() then

        App:getHardwareInputManager():onButton(Idx - buttonOffset)

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
