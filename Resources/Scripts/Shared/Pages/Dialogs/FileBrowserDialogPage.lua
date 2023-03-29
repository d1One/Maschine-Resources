------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FileBrowserDialogPage = class( 'FileBrowserDialogPage', PageMaschine )

local BUTTON_INDEX_PARENT_DIRECTORY = 5
local BUTTON_INDEX_ENTER_DIRECTORY = 6
local BUTTON_INDEX_CANCEL = 7
local BUTTON_INDEX_OK = 8

local ATTR_STYLE = NI.UTILS.Symbol("Style")

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:__init(Controller)

    PageMaschine.__init(self, "FileBrowserDialogPage", Controller)

    self.OkText = "OK"
    self.Title = "Title"

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setupScreen()
    self.Screen = ScreenMaschineStudio(self)

    -- Left screen
    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("")
    self.ButtonBarLeft:setActive(false)
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    -- Right screen
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")
    self.ColumnFileBrowser = NI.GUI.insertColumnFileBrowser(self.Screen.ScreenRight, "ColumnFileBrowser")

    local ParameterBar = NI.GUI.insertBar(self.Screen.ScreenRight, "ParameterBar")
    ParameterBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.CwdLabel = NI.GUI.insertLabel(ParameterBar, "CwdDisplay")
    self.CwdLabel:style("", "")
    ParameterBar:setFlex(self.CwdLabel)

    self.ItemCountLabel = NI.GUI.insertLabel(ParameterBar, "ItemCount")
    self.ItemCountLabel:style("", "")

    self.ColumnFileBrowser:setCwdLabel(self.CwdLabel)
    self.ColumnFileBrowser:setItemCountLabel(self.ItemCountLabel)

    self.Screen.ScreenRight:setFlex(self.ColumnFileBrowser)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setTitle(Title, LeftScreenAttribute)

    self.Icon:setActive(LeftScreenAttribute ~= "Empty")
    self.Title = Title

    self.Screen.ScreenLeft:setAttribute(ATTR_STYLE, LeftScreenAttribute)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setIgnoredPaths(IgnoredPaths)

    self.ColumnFileBrowser:setIgnoredPaths(IgnoredPaths)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setOkText(Text)

    self.OkText = Text
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setStartPath(StartPath)

    self.ColumnFileBrowser:goToDirectory(StartPath)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setDirectoriesOnly(IsDirectoriesOnly)

    self.ColumnFileBrowser:setDirectoriesOnly(IsDirectoriesOnly)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:setTypeFilter(TypeFilter)

    self.ColumnFileBrowser:setTypeFilter(TypeFilter)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:updateScreens(ForceUpdate)

    self.LeftLabel:setText(self.Title)

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_PARENT_DIRECTORY]:setEnabled(self.ColumnFileBrowser:canGoToParent())
    self.Screen.ScreenButton[BUTTON_INDEX_PARENT_DIRECTORY]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_PARENT_DIRECTORY]:setSelected(false)

    self.Screen.ScreenButton[BUTTON_INDEX_ENTER_DIRECTORY]:setEnabled(self.ColumnFileBrowser:canGoToSelectedItem())
    self.Screen.ScreenButton[BUTTON_INDEX_ENTER_DIRECTORY]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_ENTER_DIRECTORY]:setSelected(false)

    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_CANCEL]:setText("CANCEL")

    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setEnabled(self.ColumnFileBrowser:hasValidSelectedItem())
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setText(self.OkText)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:updateWheelButtonLEDs()

    local CanLeft = self.ColumnFileBrowser:canGoToParent()
    local CanRight = self.ColumnFileBrowser:canGoToSelectedItem()
    local Color = LEDColors.WHITE

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, false, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, false, Color)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onShow(Show)

    Page.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onScreenButton(Index, Pressed)
    if Pressed and Index == BUTTON_INDEX_PARENT_DIRECTORY then
        self:onParentPressed()

    elseif Pressed and Index == BUTTON_INDEX_ENTER_DIRECTORY then
        self:onNextPressed()

    elseif Pressed and Index == BUTTON_INDEX_CANCEL then
        self:onCancel()

    elseif Pressed and Index == BUTTON_INDEX_OK then
        self:onOk()

    end

    self:updateScreens(false)
    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if EncoderSmoothed and Index == 8 then
        self:onSelectPrevNextItem(Next)

    end

    self:updateScreens(false)
    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onOk()

    local Entry = nil

    if self.ColumnFileBrowser:hasValidSelectedItem() then
        Entry = self.ColumnFileBrowser:getSelectedItem()

    end

    if Entry ~= nil then
        App:getHardwareInputManager():onHWFileResult(Entry:getPath())

    end

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onCancel()

    App:getHardwareInputManager():onHWFileResult()

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onParentPressed()

    if self.ColumnFileBrowser:canGoToParent() then
        self.ColumnFileBrowser:goToParent()

    end

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onNextPressed()

    if self.ColumnFileBrowser:canGoToSelectedItem() then
        self.ColumnFileBrowser:goToSelectedItem()

    end

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onEnterPressed()

    if self.ColumnFileBrowser:canGoToSelectedItem() then
        self.ColumnFileBrowser:goToSelectedItem()

    elseif self.ColumnFileBrowser:hasValidSelectedItem() then
        self:onOk()

    end

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onSelectPrevNextItem(Next)

    self.ColumnFileBrowser:selectPrevNextItem(Next)

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onWheel(Inc)
    self:onSelectPrevNextItem(Inc > 0)

    self:updateWheelButtonLEDs()
    self:updateScreens(false)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onWheelButton(Pressed)

    if Pressed then
        self:onEnterPressed()

    end

    self:updateWheelButtonLEDs()
    self:updateScreens(false)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function FileBrowserDialogPage:onWheelDirection(Pressed, DirectionButton)
    if Pressed then
        if DirectionButton == NI.HW.BUTTON_WHEEL_LEFT then
            self:onParentPressed()

        elseif DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT then
            self:onNextPressed()

        end
    end

    self:updateWheelButtonLEDs()
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------
