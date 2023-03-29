------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WarningSystemUpdatePage = class( 'WarningSystemUpdatePage', PageMaschine )

local BUTTON_INDEX_OK = 8

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdatePage:__init(Controller)

    PageMaschine.__init(self, "WarningSystemUpdatePage", Controller)

    self:setupScreen()
    self:setPinned()

    self.PageLEDs = { NI.HW.LED_SETTINGS }

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdatePage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdatePage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdatePage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setText("OK")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdatePage:onScreenButton(Index, Pressed)

    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_OK then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_OK)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
