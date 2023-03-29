------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WarningSystemUpdateReadyPage = class( 'WarningSystemUpdateReadyPage', PageMaschine )

local BUTTON_INDEX_LATER = 5
local BUTTON_INDEX_INSTALL = 8

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:__init(Controller)

    PageMaschine.__init(self, "WarningSystemUpdateReadyPage", Controller)

    self.FutureTimepoint = NI.UTILS.FutureTimepoint()
    self.IsPassed = false

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"LATER", "", "", "INSTALL"}, "HeadButton")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.LeftLabel:setText("System Update downloaded")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.RightTitle = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight.DisplayBar, "RightTitle")
    self.RightTitle:style("")
    self.RightTitle:setText("The System Update is ready for installation.\nDo you want to install it now?")

    self.RightSubtitle = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight.DisplayBar, "RightSubtitle")
    self.RightSubtitle:style("")
    self.RightSubtitle:setText("Do not remove the SD card or unplug the power supply during the process.")

    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:onShow(Show)

    if Show then

        self.FutureTimepoint:setInSeconds(60)
        self.IsPassed = false

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:onControllerTimer()

    if not self.IsPassed and self.FutureTimepoint:isPassed() then

        self.Screen.ScreenButton[BUTTON_INDEX_INSTALL]:setText("INSTALL")
        self.IsPassed = true
        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_OK)

    elseif not self.FutureTimepoint:isPassed() then

        self.Screen.ScreenButton[BUTTON_INDEX_INSTALL]:setText(
            "INSTALL ("..tostring(self.FutureTimepoint:remainingSeconds() + 1)..")")

    end

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setSelected(false)

    self.Screen.ScreenButton[BUTTON_INDEX_INSTALL]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_INSTALL]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_INSTALL]:setSelected(false)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WarningSystemUpdateReadyPage:onScreenButton(Index, Pressed)

    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_LATER then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_CANCEL)

    elseif ShouldHandle and Index == BUTTON_INDEX_INSTALL then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_OK)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
