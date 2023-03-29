------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NewDriveDialogPage = class( 'NewDriveDialogPage', PageMaschine )

local BUTTON_INDEX_LATER = 5
local BUTTON_INDEX_ADD_NOW = 8

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:__init(Controller)

    PageMaschine.__init(self, "NewDriveDialogPage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.LeftLabel:setText("New volume detected")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_LATER]:setText("LATER")

    self.Screen.ScreenButton[BUTTON_INDEX_ADD_NOW]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_ADD_NOW]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_ADD_NOW]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_ADD_NOW]:setText("ADD NOW")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:onShow(Show)

    -- call base class
    Page.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function NewDriveDialogPage:onScreenButton(Index, Pressed)

    if Pressed and self.Screen.ScreenButton[Index]:isEnabled() and Index == BUTTON_INDEX_LATER then

        App:getHardwareInputManager():onButton(NI.HW.NEW_DRIVE_DIALOG_RESULT_LATER)

    elseif Pressed and self.Screen.ScreenButton[Index]:isEnabled() and Index == BUTTON_INDEX_ADD_NOW then

        App:getHardwareInputManager():onButton(NI.HW.NEW_DRIVE_DIALOG_RESULT_ADD_NOW)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
