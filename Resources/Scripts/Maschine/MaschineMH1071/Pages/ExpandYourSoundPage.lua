------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ExpandYourSoundPage = class( 'ExpandYourSoundPage', PageMaschine )

local BUTTON_INDEX_LATER = 5
local BUTTON_INDEX_NEXT = 8

------------------------------------------------------------------------------------------------------------------------

function ExpandYourSoundPage:__init(Controller)

    PageMaschine.__init(self, "ExpandYourSoundPage", Controller)

    self:setupScreen()
    self:setPinned()

    self.PageLEDs = { NI.HW.LED_BROWSE }

end

------------------------------------------------------------------------------------------------------------------------

function ExpandYourSoundPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function ExpandYourSoundPage:setupScreen()

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

function ExpandYourSoundPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setText("LATER")

    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setText("NEXT")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ExpandYourSoundPage:onScreenButton(Index, Pressed)

    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_LATER then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_CANCEL)

    elseif ShouldHandle and Index == BUTTON_INDEX_NEXT then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_OK)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
