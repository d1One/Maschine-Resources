------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabLibrary = class( 'SettingsTabLibrary', SettingsTab )

local BUTTON_INDEX_FACTORY = 2
local BUTTON_INDEX_USER = 3
local BUTTON_INDEX_RESCAN = 4
local BUTTON_INDEX_CANCEL = 7
local BUTTON_INDEX_ACTION = 8
local BUTTON_INDEX_REMOVE = 7
local BUTTON_INDEX_ADD = 8
local ENCODER_INDEX_WHICH_LIST = 1
local ENCODER_INDEX_SCROLL = 8
local ENCODER_INDEX_SCROLL_LABEL = 4
local ATTR_USE_BRACKETS = NI.UTILS.Symbol("UseBrackets")

local STACK_INDEX_FACTORY = 0
local STACK_INDEX_USER = 1

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:__init(Screen)
    self.Screen = Screen
    SettingsTab.__init(self, NI.HW.SETTINGS_LIBRARY, "LIBRARY", SettingsTab.NO_PARAMETER_BAR)

    self.PreviousFolder = NI.UTILS.Path()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:addContextualBar(ContextualStack)

    local Container = NI.GUI.insertBar(ContextualStack, "LibraryContainer")
    self.Stack = NI.GUI.insertStack(Container, "LibraryStack")
    self.Stack:style("")
    Container:setFlex(self.Stack)
    local FactoryContainer = NI.GUI.insertBar(self.Stack, "LibraryFactoryContainer")
    FactoryContainer:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.HWSettingsLibrary = NI.GUI.insertHWSettingsLibrary(FactoryContainer,
                                                            self.Screen.ScreenButton[BUTTON_INDEX_ACTION],
                                                            self.Screen.ScreenButton[BUTTON_INDEX_CANCEL],
                                                            "HWSettingsLibrary")
    self.GuiController = NI.GUI.insertHWSettingsLibraryController(App, self.HWSettingsLibrary)
    FactoryContainer:setFlex(self.HWSettingsLibrary)

    local UserContainer = NI.GUI.insertBar(self.Stack, "LibraryUserContainer")
    UserContainer:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local InfoBar = NI.GUI.insertLabel(UserContainer, "InfoBarRight")
    InfoBar:style("", "")
    self.ContentPathsList = NI.GUI.insertHWContentPathsList(UserContainer, App, "ContentPathsList")
    UserContainer:setFlex(self.ContentPathsList)

    self.ParamLabels = {}
    self.ParamBarRight = ScreenHelper.createBarWithLabels(Container, self.ParamLabels, {"", "", "", ""},
                                                          "BrowserParamBar", "BrowserParam")

    self:setFactoryMode()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:isFactoryMode()

    return self.Stack:getTopIndex() == STACK_INDEX_FACTORY

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:isUserMode()

    return self.Stack:getTopIndex() == STACK_INDEX_USER

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onShow(Show)

    if Show then
        if self:isFactoryMode() then
            self.GuiController:refreshProductList()

        elseif self:isUserMode() then
            self.ContentPathsList:refreshContentPaths()

        end
    else
        self.HWSettingsLibrary:setVisible(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:updateScreens(ForceUpdate)

    self.HWSettingsLibrary:setVisible(self:isFactoryMode())
    self:updateParameterLabels()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:updateScreenButton(Index, ScreenButton)

    local IsVisible = false
    local IsEnabled = false
    local IsSelected = false
    local IsFocused = false
    local ButtonText = ""
    local Style = "HeadButton"

    if Index == BUTTON_INDEX_FACTORY then
        IsVisible = true
        IsEnabled = true
        IsSelected = self:isFactoryMode()
        ButtonText = "FACTORY"
        Style = "HeadTabLeft"

    elseif Index == BUTTON_INDEX_USER then
        IsVisible = true
        IsEnabled = true
        IsSelected = self:isUserMode()
        ButtonText = "USER"
        Style = "HeadTabRight"

    elseif Index == BUTTON_INDEX_RESCAN then

        IsVisible = true
        IsEnabled = not App:getWorkspace():getDatabaseScanInProgressParameter():getValue()
        ButtonText = "RESCAN"

    elseif self:isFactoryMode() and (Index == BUTTON_INDEX_ACTION or Index == BUTTON_INDEX_CANCEL) then
        return -- we handle this in c++

    elseif self:isUserMode() and Index == BUTTON_INDEX_REMOVE then
        IsVisible = true
        IsEnabled = self:canRemoveSelectedUserItem()
        ButtonText = "REMOVE"

    elseif self:isUserMode() and Index == BUTTON_INDEX_ADD then
        IsVisible = true
        IsEnabled = true
        ButtonText = "ADD"

    end

    ScreenHelper.updateButton(ScreenButton, IsVisible, IsEnabled, IsSelected, IsFocused, ButtonText, Style)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:updateParameters(Controller, ParameterHandler)

    if self:isFactoryMode() then
        ParameterHandler.NumPages = 1
        ParameterHandler:setParameters({}, false)

        local Sections = {}
        Sections[ENCODER_INDEX_WHICH_LIST] = "Products"

        local Names = {}
        Names[ENCODER_INDEX_WHICH_LIST] = "SHOW"

        local Values = {}
        Values[ENCODER_INDEX_WHICH_LIST] = self.HWSettingsLibrary:getProductListTitle()

        local ProductListTitles = {}
        for _,Title in pairs(self.HWSettingsLibrary:getProductListTitles()) do
            table.insert(ProductListTitles, Title)
        end

        local ListValues = {}
        ListValues[ENCODER_INDEX_WHICH_LIST] = ProductListTitles

        ParameterHandler:setCustomSections(Sections)
        ParameterHandler:setCustomNames(Names)
        ParameterHandler:setCustomValues(Values)
        Controller.CapacitiveList:assignListsToCaps(ListValues, Values)

    else
        SettingsTab.updateParameters(self, Controller, ParameterHandler)

    end

    self:updateParameterLabels()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onScreenButton(Index, Pressed)

    if not Pressed then
        return
    end

    if Index == BUTTON_INDEX_FACTORY then
        self:setFactoryMode()

    elseif Index == BUTTON_INDEX_USER then
        self:setUserMode()

    elseif Index == BUTTON_INDEX_RESCAN then
        NI.DATA.DB3Access.rescanAllContentPaths(App)

    elseif self:isFactoryMode() and Index == BUTTON_INDEX_ACTION then
        if self.HWSettingsLibrary:isInErrorState() then
            self.GuiController:refreshProductList()

        elseif self.HWSettingsLibrary:isNotLoggedIn() and NI.APP.isNativeOS() then
            NHLController:getPageStack():pushPage(NI.HW.PAGE_LOGIN)

        else
            self.GuiController:doAction()

        end

    elseif self:isFactoryMode() and Index == BUTTON_INDEX_CANCEL then
        self.GuiController:cancel()

    elseif self:isUserMode() and Index == BUTTON_INDEX_ADD then
        NI.GUI.DialogAccess.openAddUserContentPathDialog(App, true)
        self.ContentPathsList:refreshContentPaths()

    elseif self:isUserMode() and Index == BUTTON_INDEX_REMOVE then
        self:onRemoveUserPath()

    end

end

------------------------------------------------------------------------------------------------------------------------

local scrollItems = function(self, Next)

    self.HWSettingsLibrary:selectPrevNextItem(Next)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:showInstallableProducts()

    self.GuiController:showInstallableProducts()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:showInstalledProducts()

    self.GuiController:showInstalledProducts()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:showUpdatableProducts()

    self.GuiController:showUpdatableProducts()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:canRemoveSelectedUserItem()

    local ContentPath = self.ContentPathsList:getSelectedItem()
    return ContentPath and NI.APP.PreferencesUserPaths.isUserPath(ContentPath) or false

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if not EncoderSmoothed then

        -- NOP

    elseif Index == ENCODER_INDEX_WHICH_LIST then

        self.GuiController:selectPrevNextProductList(Next)

    elseif Index == ENCODER_INDEX_SCROLL then

        if self:isFactoryMode() then
            scrollItems(self, Next)

        elseif self:isUserMode() then
            self.ContentPathsList:selectPrevNextItem(Next)
            self:updateParameters(Controller, ParameterHandler)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:updateParameterLabels()

    local Text = ""
    local IsVisible = true
    local NumItems = 0

    if self:isFactoryMode() then
        NumItems = self.HWSettingsLibrary:getNumItems()
        IsVisible = not self.HWSettingsLibrary:isShowingMessage()

    elseif self:isUserMode() then
        NumItems = self.ContentPathsList:getNumItems()

    end


    local Text = tostring(NumItems)..(NumItems == 1 and " item" or " items")

    self.ParamLabels[ENCODER_INDEX_SCROLL_LABEL]:setText(Text)
    self.ParamLabels[ENCODER_INDEX_SCROLL_LABEL]:setVisible(IsVisible)
    self.ParamLabels[ENCODER_INDEX_SCROLL_LABEL]:setSelected(true)
    self.ParamLabels[ENCODER_INDEX_SCROLL_LABEL]:setAttribute(ATTR_USE_BRACKETS, "true")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onWheel(Inc)

    local Next = Inc > 0

    if self:isFactoryMode() then
        scrollItems(self, Next)

    elseif self:isUserMode() then
        self.ContentPathsList:selectPrevNextItem(Next)

    end

    return true
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onWheelButton(Pressed)

    if Pressed
        and (NI.GUI.HWSettingsLibraryAlgorithms.selectedItemInstallable(self.HWSettingsLibrary)
             or NI.GUI.HWSettingsLibraryAlgorithms.selectedItemUpdatable(self.HWSettingsLibrary)
             or NI.GUI.HWSettingsLibraryAlgorithms.selectedItemInErrorState(self.HWSettingsLibrary)) then
        self.GuiController:doAction()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:setFactoryMode()

    self.Stack:setTopIndex(STACK_INDEX_FACTORY)
    self.PreviousFolder = NI.UTILS.Path()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:setUserMode()

    self.ContentPathsList:refreshContentPaths()
    self.Stack:setTopIndex(STACK_INDEX_USER)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabLibrary:onRemoveUserPath()

    local Frontend = App:getDatabaseFrontend()
    local ContentPath = self.ContentPathsList:getSelectedItem()
    if ContentPath then
        Frontend:removeContentPath(ContentPath)
        self.ContentPathsList:refreshContentPaths()

    end

end

------------------------------------------------------------------------------------------------------------------------
