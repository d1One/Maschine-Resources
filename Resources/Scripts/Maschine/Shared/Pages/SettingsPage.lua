------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsPage = class( 'SettingsPage', PageMaschine )

local TITLE_BUTTON = 1
local SWITCHER_LEFT_BUTTON = 5
local SWITCHER_RIGHT_BUTTON = 6

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:__init(Controller)

    PageMaschine.__init(self, "SettingsPage", Controller)

    self.PageLEDs = { NI.HW.LED_SETTINGS }
    self.TabCount = 0
    self.CurrentIndex = 0
    self.Tabs = {}

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, { "SETTINGS", "", "", "" }, "HeadButton" , false, true)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"<<", ">>", "", ""}, "HeadButton", false, false)

    self.CategoriesSpacer = NI.GUI.insertBar(self.Screen.ScreenLeft.DisplayBar, "CategoriesSpacer")
    self.CategoriesSpacer:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.Categories = NI.GUI.insertHWSettingsCategoryList(self.Screen.ScreenLeft.DisplayBar, "HWSettingsCategoryList")
    self.ContextualStack = NI.GUI.insertStack(self.Screen.ScreenRight.DisplayBar, "Tabs")
    self.ContextualStack:style("SettingsTabs")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "StudioDisplay")
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.Categories)
    self.Screen.ScreenRight.DisplayBar:setFlex(self.ContextualStack)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:updateScreens(ForceUpdate)

    self.CategoriesSpacer:setActive(#self.Tabs <= NI.HW.SETTINGS_CATEGORIES_PER_ROW)

    for key,value in pairs(self.Tabs) do
        self.Tabs[key]:updateScreens(ForceUpdate)
    end

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:updateParameters(ForceUpdate)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        CurrentTab:updateParameters(self.Controller, self.ParameterHandler)
        self:updateScreenButtons(false)

    end

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:updateScreenButtons(ForceUpdate)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    for Index=1,8 do

        if CurrentTab and Index ~= TITLE_BUTTON and Index ~= SWITCHER_LEFT_BUTTON and Index ~= SWITCHER_RIGHT_BUTTON then

            CurrentTab:updateScreenButton(Index, self.Screen.ScreenButton[Index])

        end

    end

    self.Screen.ScreenButton[TITLE_BUTTON]:setSelected(true)
    self.Screen.ScreenButton[TITLE_BUTTON]:setEnabled(true)
    self.Screen.ScreenButton[TITLE_BUTTON]:setText("SETTINGS")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:addTab(Tab)

    self.TabCount = self.TabCount + 1
    local Index = self.TabCount

    Tab:addContextualBar(self.ContextualStack)
    self.Categories:addCategory(Tab:getCategory())

    table.insert(self.Tabs, Tab)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end


    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        CurrentTab:onShow(Show, self.Controller:getShiftPressed())

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onControllerTimer()

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        CurrentTab:onControllerTimer()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:canPrevColumn()

    return self.CurrentIndex > 1

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:canNextColumn()

    return self.CurrentIndex < self.TabCount

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:canPrevRow()

    return self.CurrentIndex > NI.HW.SETTINGS_CATEGORIES_PER_ROW

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:canNextRow()

    return self.CurrentIndex + NI.HW.SETTINGS_CATEGORIES_PER_ROW <= self.TabCount

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:selectPrevNextColumn(Next)

    if Next and self:canNextColumn() then

        self:selectTab(self.CurrentIndex + 1)

    elseif not Next and self:canPrevColumn() then

        self:selectTab(self.CurrentIndex - 1)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:selectPrevNextRow(Next)

    if Next and self:canNextRow() then

        self:selectTab(self.CurrentIndex + NI.HW.SETTINGS_CATEGORIES_PER_ROW)

    elseif not Next and self:canPrevRow() then

        self:selectTab(self.CurrentIndex - NI.HW.SETTINGS_CATEGORIES_PER_ROW)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onWheelDirection(Pressed, DirectionButton)

    if Pressed then

        if DirectionButton == NI.HW.BUTTON_WHEEL_LEFT or DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT then

            self:selectPrevNextColumn(DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT)
            self:sendAccessibilityInfoForPage()

        elseif DirectionButton == NI.HW.BUTTON_WHEEL_DOWN or DirectionButton == NI.HW.BUTTON_WHEEL_UP then

            self:selectPrevNextRow(DirectionButton == NI.HW.BUTTON_WHEEL_DOWN)

        end

    end

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:getIndexForCategory(Category)

    local MatchingTabIndex = -1

    for Index, Tab in pairs(self.Tabs) do

        if Tab:getCategory() == Category then

            MatchingTabIndex = Index

        end

    end

    return MatchingTabIndex

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:getTab(Index)

    if Index <= 0 or Index > self.TabCount then

        return nil

    end

    return self.Tabs[Index]

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:getTabWithCategory(Category)

    local Index = self:getIndexForCategory(Category)

    if Index <= 0 then

        return nil

    end

    return self.Tabs[Index]

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:selectTab(Index)

    if Index == self.CurrentIndex or Index <= 0 or Index > self.TabCount then

        return

    end

    local PreviousTab = self.Tabs[self.CurrentIndex] or nil

    if PreviousTab then

        PreviousTab:onShow(false, self.Controller:getShiftPressed())

    end

    self.CurrentIndex = Index

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        self.Screen:setArrowText(1, CurrentTab:getName())
        self.Screen.ScreenButton[SWITCHER_LEFT_BUTTON]:setEnabled(self:canPrevColumn())
        self.Screen.ScreenButton[SWITCHER_RIGHT_BUTTON]:setEnabled(self:canNextColumn())
        self.ContextualStack:setTopIndex(Index - 1)
        self.Categories:setSelected(self.CurrentIndex - 1)
        self.ParameterHandler.PageIndex = 1
        CurrentTab:onShow(true, self.Controller:getShiftPressed())
        self:updateScreens(true)
        self.Screen.ScreenRight.ParamBar:setActive(CurrentTab.RightScreenParameterBar == SettingsTab.WITH_PARAMETER_BAR)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:selectTabWithCategory(Category)

    local Index = self:getIndexForCategory(Category)

    if Index >= 0 then

        self:selectTab(Index)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:hasSystemUpdate()

    local SettingsTab = self:getTabWithCategory(NI.HW.SETTINGS_SYSTEM)

    if SettingsTab then
        return SettingsTab:hasSystemUpdate()

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onCapTouched(Cap, Touched)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        CurrentTab:onCapTouched(Cap, Touched, self.Controller, self.ParameterHandler)

    end

    self:updateScreens()
    NHLController:writeUserData()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onScreenButton(Index, Pressed)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil
    local IsEnabled = self.Screen.ScreenButton[Index]:isEnabled()

    if CurrentTab and IsEnabled then

        CurrentTab:onScreenButton(Index, Pressed)

    end

    if Pressed then

        if Index == SWITCHER_LEFT_BUTTON or Index == SWITCHER_RIGHT_BUTTON then

            self:selectPrevNextColumn(Index == SWITCHER_RIGHT_BUTTON)
            self:updateWheelButtonLEDs()

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onScreenEncoder(Index, Value)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then

        CurrentTab:onScreenEncoder(Index, Value, self.Controller, self.ParameterHandler)

    end

    self:updateScreens()

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:updateWheelButtonLEDs()

    local CanPrevColumn = self:canPrevColumn()
    local CanNextColumn = self:canNextColumn()
    local CanPrevRow = self:canPrevRow()
    local CanNextRow = self:canNextRow()
    local Color = LEDColors.WHITE

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanPrevColumn, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanNextColumn, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, CanPrevRow, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, CanNextRow, Color)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onWheel(Inc)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil
    local IsHandled = false

    if CurrentTab then

        IsHandled = CurrentTab:onWheel(Inc)

    end

    self:updateScreens()

    return IsHandled

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onWheelButton(Pressed)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil
    local IsHandled = false

    if CurrentTab then

        IsHandled = CurrentTab:onWheelButton(Pressed)

    end

    return IsHandled

end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:onShiftButton(Pressed)

    local CurrentTab = self.Tabs[self.CurrentIndex] or nil

    if CurrentTab then
        CurrentTab:onShiftButton(Pressed)

    end

    PageMaschine.onShiftButton(self, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsPage:getAccessiblePageInfo()

    local TabName = self.Tabs[self.CurrentIndex] and  self.Tabs[self.CurrentIndex]:getName() or ""
    return TabName .. " Settings"

end

------------------------------------------------------------------------------------------------------------------------
