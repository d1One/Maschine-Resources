------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DataTrackingDialogPage = class( 'DataTrackingDialogPage', PageMaschine )

local BUTTON_INDEX_DECLINE = 5
local BUTTON_INDEX_ALLOW = 8

------------------------------------------------------------------------------------------------------------------------

function DataTrackingDialogPage:__init(Controller)

    PageMaschine.__init(self, "DataTrackingDialogPage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function DataTrackingDialogPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function DataTrackingDialogPage:setupScreen()

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

function DataTrackingDialogPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_DECLINE]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_DECLINE]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_DECLINE]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_DECLINE]:setText("DECLINE")

    self.Screen.ScreenButton[BUTTON_INDEX_ALLOW]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_ALLOW]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_ALLOW]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_ALLOW]:setText("ALLOW")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function DataTrackingDialogPage:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function DataTrackingDialogPage:onScreenButton(Index, Pressed)

    if Pressed and self.Screen.ScreenButton[Index]:isEnabled() and Index == BUTTON_INDEX_DECLINE then

        App:getHardwareInputManager():onButton(NI.HW.DATA_TRACKING_DIALOG_RESULT_DECLINE)

    elseif Pressed and self.Screen.ScreenButton[Index]:isEnabled() and Index == BUTTON_INDEX_ALLOW then

        App:getHardwareInputManager():onButton(NI.HW.DATA_TRACKING_DIALOG_RESULT_ALLOW)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
