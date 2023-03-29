require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ManageStoragePage = class( 'ManageStoragePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:__init(Controller)

    PageMaschine.__init(self, "ManageStoragePage", Controller)

    self.PageLEDs = { NI.HW.LED_FILE }

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"STORAGE", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.Message = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "Message")
    self.Message:style("")
    self.Screen.ScreenLeft:setFlex(self.Message)

    local TwoColumns = NI.GUI.insertBar(self.Screen.ScreenRight, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")
    self.Screen.ScreenRight:setFlex(TwoColumns)

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.VolumeStatusLabel = NI.GUI.insertLabel(FirstColumn, "VolumeStatus")
    self.VolumeStatusLabel:style("", "")
    FirstColumn:setFlex(self.VolumeStatusLabel)

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_LEFT, "")
    self.VolumesList = NI.GUI.insertExternalVolumesList(SecondColumn, App, "VolumesList")
    SecondColumn:setFlex(self.VolumesList)

    self.Message:setText("Please select the device you want to format or eject")

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[1]:setSelected(true)
    self.Screen.ScreenButton[1]:setEnabled(true)

    self.Screen.ScreenButton[5]:setEnabled(true)
    self.Screen.ScreenButton[5]:setVisible(true)
    self.Screen.ScreenButton[5]:setText("CANCEL")

    self.Screen.ScreenButton[7]:setEnabled(self.VolumesList:getRowCount() > 0)
    self.Screen.ScreenButton[7]:setVisible(true)
    self.Screen.ScreenButton[7]:setText("FORMAT")

    self.Screen.ScreenButton[8]:setEnabled(self.VolumesList:getRowCount() > 0)
    self.Screen.ScreenButton[8]:setVisible(true)
    self.Screen.ScreenButton[8]:setText("EJECT")


    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:onScreenButton(Index, Pressed)

    local IsEnabled = self.Screen.ScreenButton[Index]:isEnabled()

    if Pressed and IsEnabled and Index == 5 then

        NHLController:getPageStack():popPage()

    elseif Pressed and IsEnabled and Index == 7 then

        self.VolumesList:formatSelectedVolume()
        NHLController:getPageStack():popPage()

    elseif Pressed and IsEnabled and Index == 8 then

        self.VolumesList:ejectSelectedVolume()
        NHLController:getPageStack():popPage()

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if not EncoderSmoothed then

        return

    end

    if Index == 8 then

        self.VolumesList:selectPrevNextItem(Next)

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:onShow(Show)

    if Show then

        self.VolumesList:updateVolumeList()

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:onWheel(Inc)

    self.VolumesList:selectPrevNextItem(Inc > 0)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ManageStoragePage:onWheelButton(Pressed)

    if Pressed and self.VolumesList:getRowCount() > 0 then

        self.VolumesList:ejectSelectedVolume()
        NHLController:getPageStack():popPage()
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

