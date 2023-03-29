------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/LevelButtonsHelper"
require "Scripts/Shared/Helpers/SnapshotsHelper"

local ATTR_MODE = NI.UTILS.Symbol("mode")
local ATTR_IS_EXTERNAL_MODULE = NI.UTILS.Symbol("IsExternalModule")
local ATTR_HAS_TEXT = NI.UTILS.Symbol("HasText")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageStudio = class( 'ControlPageStudio', PageMaschine )


ControlPageStudio.PRESETS_OFF = 0
ControlPageStudio.PRESETS_PENDING = 1
ControlPageStudio.PRESETS_ON = 2

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:__init(Controller, Name)

    -- init base class
    PageMaschine.__init(self, Name ~= nil and Name or "ControlPageStudio", Controller)

    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_CONTROL }

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:setupScreen()

    self.CachedFocusSlotIndex = -1

    self.PresetListState = ControlPageStudio.PRESETS_OFF

    -- Screen Button Definition


    self.Screen = ScreenMaschineStudio(self)
    if NI.APP.FEATURE.EFFECTS_CHAIN then
        self.ScreenButtonText = {
            {"MASTER", "GROUP", "SOUND", "", "<<", ">>"}, -- Normal
            {"", "EDIT", "INSERT", "", "<<", ">>", "BYPASS", "REMOVE"} } -- with shift button held down

        self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft,
            {"MASTER", "GROUP", "SOUND", ""},
            {"HeadTabLeft", "HeadTabCenter", "HeadTabRight", "HeadButton"}, false)
        self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"<<", ">>", "", "BROWSE"}, "HeadButton", false, false)
    else
        self.ScreenButtonText = {
            {"", "", "", "", "<<", ">>"}, -- Normal
            {"", "", "", "", "<<", ">>", "BYPASS", "REMOVE"} } -- with shift button held down

        self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft,
            {"", "", "", ""},
            {"HeadTabLeft", "HeadTabCenter", "HeadTabRight", "HeadButton"}, false)
        self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"<<", ">>", "", "BROWSE"}, "HeadButton", false, false)
    end

    if NI.APP.FEATURE.EFFECTS_CHAIN then
        self.LevelButtons = LevelButtonsHelper(self.Screen.ScreenButton)
    end

    self.SlotStack = self.Controller.SharedObjects.SlotStack

    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "StudioDisplay")

    self.PluginBG = NI.GUI.insertPictureBar(self.Screen.ScreenRight.DisplayBar, "PluginBG")
    self.PluginBG:style(NI.GUI.ALIGN_WIDGET_DOWN, "PluginBG")
    self.PluginBG:setNoAlign(true)

    self.SoundInfoLabel = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "SoundInfo")
    self.SoundInfoLabel:style("", "SoundInfo")

    local PluginBar = NI.GUI.insertBar(self.Screen.ScreenRight.DisplayBar, "PluginBar")
    PluginBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "PluginBar")
    self.Screen.ScreenRight.DisplayBar:setFlex(PluginBar)

    -- insert big ass Logo
    self.PluginName = NI.GUI.insertMultilineTextEdit(PluginBar, "PluginName")
    self.PluginName:style("PluginName")

    self.PresetList = NI.GUI.insertResultListItemVector(PluginBar, "ResultList")
    self.PresetList:style(false, '')
    self.PresetList:getScrollbar():setAutohide(false)
    self.PresetList:getScrollbar():setShowIncDecButtons(false)

    self.PresetList:setVisible(false)
    self.PresetList:setActive(false)

    NI.GUI.connectVector(self.PresetList,
        BrowseHelper.getResultListSize, BrowseHelper.setupResultItem, BrowseHelper.loadResultItem)

    self.ParameterHandler.PrevNextPageFunc =
        function (Inc)
            NI.DATA.ParameterCache.advanceFocusPage(App, Inc > 0)
        end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onShow(Show)

    if Show then

        self.SlotStack:insertInto(self.Screen.ScreenLeft.DisplayBar)
        self.Screen.ScreenLeft.DisplayBar:setFlex(self.SlotStack.Stack)
        NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)

    else

        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
        LEDHelper.setLEDState(NI.HW.LED_MACRO, LEDHelper.LS_OFF)

        if NI.HW.FEATURE.JOGWHEEL and self.Controller.hasJogwheelControls() then
            NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_DEFAULT)
        end

        self:hidePresets()

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

local function isPresetListActive(self)

    return self.PresetList:isVisible() or self.PresetListState == ControlPageStudio.PRESETS_PENDING

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateScreens(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self:updateSoundInfoName()

    self:updatePresetList(ForceUpdate)

    if NI.HW.FEATURE.JOGWHEEL and self.Controller.hasJogwheelControls() then
        local NewJogWheelMode = isPresetListActive(self) and NI.HW.JOGWHEEL_MODE_CUSTOM or NI.HW.JOGWHEEL_MODE_DEFAULT
        NHLController:setJogWheelMode(NewJogWheelMode)
    end

    local ModulesVisibleParam = App:getWorkspace().getModulesVisibleParameter and App:getWorkspace():getModulesVisibleParameter()
    ForceUpdate = ForceUpdate or (ModulesVisibleParam and ModulesVisibleParam:isChanged() or false)

    if ForceUpdate then
        self.PluginBG:setAttribute(ATTR_MODE, MaschineHelper:isShowingPlugins() and "plugin" or "channel")
    end

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    local Module = FocusSlot and FocusSlot:getModule()
    local ModuleInfo = Module and Module:getInfo()
    local Id = ModuleInfo and ModuleInfo:getId()
    local HasSoundInfo = self.SoundInfoLabel:getText() ~= ""

    self.SoundInfoLabel:setAttribute(ATTR_IS_EXTERNAL_MODULE, Id == NI.DATA.ModuleInfo.ID_PLUGINHOST and "true" or "false")
    self.SoundInfoLabel:setAttribute(ATTR_HAS_TEXT, HasSoundInfo and "true" or "false")

    self:updateCachedFocusSlotIndex()

    self:updateRightDisplay(ForceUpdate)

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateBrowseButton(PluginMode, PluginLoaded)

    self.Screen.ScreenButton[8]:setVisible(PluginMode)
    self.Screen.ScreenButton[8]:setEnabled(PluginMode and PluginLoaded)
    
    self.Screen.ScreenButton[8]:setSelected(self.PresetListState == ControlPageStudio.PRESETS_PENDING
        or self.PresetListState == ControlPageStudio.PRESETS_ON)
    
    self.Screen.ScreenButton[8]:style("QUICK BROWSE", "BrowseIcon")

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:setupScreenButton4()

    self.Screen.ScreenButton[4]:setText(self.Controller:getShiftPressed() and "EXT LOCK" or "LOCK")
    self.Screen.ScreenButton[4]:setVisible(true)
    self.Screen.ScreenButton[4]:setEnabled(true)
    self.Screen.ScreenButton[4]:setSelected(
            not self.Controller:getShiftPressed() and NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW(App))

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateScreenButtons(ForceUpdate)

    local PluginMode = MaschineHelper:isShowingPlugins()
    if PluginMode and self.Controller:getShiftPressed() then

        self:updateScreenButtonsShiftPluginMode(ForceUpdate)

    else

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, self.ScreenButtonText[1])

        -- Plug-in name on arrow label
        self.Screen:setArrowText(1, MaschineHelper.getFocusChannelSlotName())

        if NI.APP.FEATURE.EFFECTS_CHAIN then
            self:setupScreenButton4()
            self.LevelButtons:updateButtons()
        end

        self.Screen.ScreenButton[5]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(false, false))
        self.Screen.ScreenButton[6]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(true, false))


        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
        local Id = SlotStackStudio.getPluginInfo(FocusSlotIndex)

        self:updateBrowseButton(PluginMode, Id ~= nil)
    end

    self.Controller:updateScreenButtonLEDs(self.Screen.ScreenButton)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateScreenButtonsShiftPluginMode(ForceUpdate)

    ScreenHelper.setWidgetText(self.Screen.ScreenButton, self.ScreenButtonText[2])
    self.Screen:setArrowText(1, "MOVE", "MOVE SLOT")

    -- Button 1,2 -- none, EDIT
    for Index = 1,2 do
        self.Screen.ScreenButton[Index]:setSelected(false)
    end

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    local Module = FocusSlot and FocusSlot:getModule()

    local IsPluginHost = Module ~= nil and Module:getInfo():getId() == NI.DATA.ModuleInfo.ID_PLUGINHOST
    self.Screen.ScreenButton[1]:style("", "HeadButton")
    self.Screen.ScreenButton[2]:style("EDIT", "HeadButton")

    self.Screen.ScreenButton[2]:setEnabled(IsPluginHost and Module:getWindow() and Module:getWindow():hasEditor())
    self.Screen.ScreenButton[2]:setSelected(IsPluginHost and Module:getPluginPopupOpenParameter():getValue())
    self.Screen.ScreenButton[2]:setVisible(not NI.APP.isHeadless())

    -- Button 3 -- EDIT
    self.Screen.ScreenButton[3]:setSelected(false)
    self.Screen.ScreenButton[3]:style("INSERT", "HeadButton")

    self:setupScreenButton4()

    -- Button 5 + 6: move plug-ins
    self.Screen.ScreenButton[5]:setEnabled(ControlHelper.canMoveFocusSlot(false))
    self.Screen.ScreenButton[6]:setEnabled(ControlHelper.canMoveFocusSlot(true))

    -- Button 7 -- BYPASS
    self.Screen.ScreenButton[7]:setText(self.ScreenButtonText[2][7])
    self.Screen.ScreenButton[7]:setEnabled(FocusSlot ~= nil)
    self.Screen.ScreenButton[7]:setSelected(FocusSlot ~= nil and not FocusSlot:getActiveParameter():getValue())

    -- Button 8 -- REMOVE
    self.Screen.ScreenButton[8]:setEnabled(FocusSlot ~= nil)
    self.Screen.ScreenButton[8]:setSelected(false)
    self.Screen.ScreenButton[8]:style("REMOVE", "HeadButton")

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateParameters(ForceUpdate)

    local Params = {}

    if self.SetupParametersFunc then
        Params = self.SetupParametersFunc(self.ParameterHandler)
    else
        for Index = 1, 8 do
            Params[Index] = NI.DATA.ParameterCache.getParameterByPosition(App, Index - 1)
        end

        self.ParameterHandler.NumPages = NI.DATA.ParameterCache.getNumPages(App)
        self.ParameterHandler.PageIndex = NI.DATA.ParameterCache.getFocusPage(App) + 1
    end

    self.ParameterHandler:setParameters(Params, true)
    self.Controller.CapacitiveList:assignParametersToCaps(Params)

    -- call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateSoundInfoName()

    local Name = ""
    local PluginMode = MaschineHelper:isShowingPlugins()
    local Slot = NI.DATA.StateHelper.getFocusSlot(App)

    if PluginMode and Slot then
        Name = NI.DATA.SlotAlgorithms.getSampleOrPresetName(Slot)
    end

    self.SoundInfoLabel:setText(Name)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateCachedFocusSlotIndex()

    if NI.DATA.ParameterCache.isValid(App) then
        self.CachedFocusSlotIndex = NI.DATA.StateHelper.getFocusSlot(App) and NI.DATA.StateHelper.getFocusSlotIndex(App) or nil
    end
end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:getFocusChannelLogo()

    local Path = self.PluginBG:getStringProperty("image-"..string.lower(self.SlotStack:getFocusChannelName()), "no")
    if Path ~= "no" then
        return NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Path, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:getFocusPluginLogoAndColor()

    local SlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

    local Id, Name, PicturePath = SlotStackStudio.getPluginInfo(SlotIndex)

    local Path = ""
    local Color
    local Internal = true

    if Id then

        if Id == NI.DATA.ModuleInfo.ID_PLUGINHOST then -- external
            Path = ResourceHelper.getLogo(PicturePath)
            Color = ResourceHelper.getColor(PicturePath)
            Internal = false

        -- internal
        else
            Path = self.PluginBG:getStringProperty("image-"..NI.UTILS.removeStringParensAndWhitespace(string.lower(Name)), "no")
            Color = self.PluginBG:getColorProperty("color-"..NI.UTILS.removeStringParensAndWhitespace(string.lower(Name)), 0)
        end

    end

    -- "empty" or generic VST plug-in
    if Path == "" then
        Path = self.PluginBG:getStringProperty(Id and "image-vst" or "image-empty", "no")
        Color = self.PluginBG:getColorProperty(Id and "color-vst" or "color-empty", 0)
        Internal = true
    end

    if Path and Path ~= "no" then
        return NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Path, Internal), Color, Name
    else
        return nil, Color, Name
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateRightDisplay(ForceUpdate)

    if not self.SlotStack:update(ForceUpdate) then
        return
    end

    local PluginMode = true

    if App:getWorkspace().getModulesVisibleParameter then
        PluginMode = MaschineHelper:isShowingPlugins()
    end

    local Logo, BGColor, Name

    if PluginMode then
        Logo, BGColor, Name = self:getFocusPluginLogoAndColor()
    else
        Logo = self:getFocusChannelLogo()
    end

    if BGColor and BGColor ~= "" then
        self.PluginBG:setBGColor(BGColor)
    else
        self.PluginBG:resetBGColor()
    end

    if Logo then
        self.PluginName:setText("")
        self.PluginBG:setPicture(Logo)
    else
        self.PluginName:setText(Name or "")
        self.PluginBG:resetPicture()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updateJogwheel()

    local LED_Left = NI.HW.FEATURE.JOGWHEEL and NI.HW.LED_TRANSPORT_PREV or NI.HW.LED_WHEEL_BUTTON_LEFT
    local LED_Right = NI.HW.FEATURE.JOGWHEEL and NI.HW.LED_TRANSPORT_NEXT or NI.HW.LED_WHEEL_BUTTON_RIGHT
    local BUTTON_Left = NI.HW.FEATURE.JOGWHEEL and NI.HW.BUTTON_TRANSPORT_PREV or NI.HW.BUTTON_WHEEL_LEFT
    local BUTTON_Right = NI.HW.FEATURE.JOGWHEEL and NI.HW.BUTTON_TRANSPORT_NEXT or NI.HW.BUTTON_WHEEL_RIGHT


    if self.PresetListState ~= ControlPageStudio.PRESETS_ON then

        LEDHelper.updateButtonLED(self.Controller, LED_Left, BUTTON_Left, false)
        LEDHelper.updateButtonLED(self.Controller, LED_Right, BUTTON_Right, false)
        if NI.HW.FEATURE.JOGWHEEL then
            LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_BROWSE, LEDHelper.LS_OFF)
        end

        return false
    end

    local ResultList = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
    local CanPrev = ResultList:getFocusItem() > 0
    local CanNext = ResultList:getItemCount() > 0 and ResultList:getFocusItem() < ResultList:getItemCount() - 1

    LEDHelper.updateButtonLED(self.Controller, LED_Left, BUTTON_Left, CanPrev)
    LEDHelper.updateButtonLED(self.Controller, LED_Right, BUTTON_Right, CanNext)

    if NI.HW.FEATURE.JOGWHEEL then
        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_BROWSE, LEDHelper.LS_BRIGHT)
        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        local PluginMode = MaschineHelper:isShowingPlugins()

        if PluginMode and self.Controller:getShiftPressed() then
            self:onScreenButtonShiftPluginMode(ButtonIdx)
        else
            self:onScreenButtonDefault(ButtonIdx)
        end

    elseif Pressed and ButtonIdx == 8 then
        self:onScreenButtonDefault(ButtonIdx)
    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:showPresets()

    self.PresetListState = ControlPageStudio.PRESETS_PENDING

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:hidePresets()

    self.PresetListState = ControlPageStudio.PRESETS_OFF
    self.PresetList:setVisible(false)
    self.PresetList:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onShiftButton(Pressed)

    if Pressed then
        self.PresetList:setVisible(false)
    end

    PageMaschine.onShiftButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onScreenButtonDefault(ButtonIdx)

    if ButtonIdx >= 1 and ButtonIdx <= 3 and NI.APP.FEATURE.EFFECTS_CHAIN then -- MASTER, GROUP, SOUND

        MaschineHelper.setFocusLevelTab(ButtonIdx - 1)

    -- Button 4: lock
    elseif ButtonIdx == 4
        and self.Screen.ScreenButton[4]:isEnabled()
        and self.Screen.ScreenButton[4]:isVisible()
        and NI.APP.FEATURE.EFFECTS_CHAIN then

        if self.Controller:getShiftPressed() then
            NHLController:getPageStack():popToBottomPage()
            NHLController:getPageStack():pushPage(NI.HW.PAGE_SNAPSHOTS)
        else
            SnapshotsHelper.toggleLock()
        end

    elseif ButtonIdx == 5 or ButtonIdx == 6 then -- SLOT Left/Right

        ControlHelper.onPrevNextSlot(ButtonIdx == 6, false)

    -- Button 8: browse
    elseif ButtonIdx == 8
        and self.Screen.ScreenButton[8]:isEnabled()
        and self.Screen.ScreenButton[8]:isVisible() then

        if isPresetListActive(self) then
            self:hidePresets()
        else
            self:showPresets()
            if NI.APP.FEATURE.EFFECTS_CHAIN then
                NI.DATA.QuickBrowseAccess.restoreFocusSlotOrSampleQuickBrowse(App)
            else
                NI.DATA.QuickBrowseAccess.restoreQuickBrowse(App)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onScreenButtonShiftPluginMode(ButtonIdx)

    if ButtonIdx == 2 then -- EDIT

        ControlHelper.togglePluginWindow()

    elseif ButtonIdx == 3 then -- INSERT

        -- call base class to set LED states properly before page change
        PageMaschine.onScreenButton(self, ButtonIdx, true)

        BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_FRESH)
        BrowseHelper.setFileTypeToDefault()

        self.Controller:showTempPage(NI.HW.PAGE_BROWSE)

    elseif ButtonIdx == 4 and self.Screen.ScreenButton[4]:isEnabled() and self.Screen.ScreenButton[4]:isVisible() then

        self:onScreenButton4ShiftPluginMode()

    elseif ButtonIdx == 5 or ButtonIdx == 6 then -- move plug-ins about

        if MaschineHelper:isShowingPlugins() then

            if ControlHelper.canMoveFocusSlot(ButtonIdx == 6) then
                ControlHelper.moveFocusSlot(ButtonIdx == 6)
            end
        end

    else

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
        local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)

        if Slots == nil or FocusSlot == nil then
            return
        end

        if ButtonIdx == 7 and self.Screen.ScreenButton[7]:isEnabled() then -- BYPASS

            NI.DATA.ParameterAccess.setBoolParameter(App,
                FocusSlot:getActiveParameter(), not FocusSlot:getActiveParameter():getValue())

        elseif ButtonIdx == 8 and self.Screen.ScreenButton[8]:isEnabled() then -- REMOVE

            NI.DATA.ChainAccess.removeSlot(App, Slots, FocusSlot)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onScreenButton4ShiftPluginMode()

    self.Controller:showTempPage(NI.HW.PAGE_SNAPSHOTS)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onDB3ModelChanged(Model)

    -- Hide the presets on any attribute changed that follows the original query
    if Model == NI.DB3.MODEL_ATTRIBUTES and self.PresetListState == ControlPageStudio.PRESETS_ON then
        self:hidePresets()
        self:updateScreens()
        return
    end

    -- Show
    -- Checking FileTypeFlag and MODEL_RESULTS here is a work-around:
    -- sometimes no quick browse query needs to run thus leaving the other sub-models unchanged
    local FileTypeFlag = App:getDatabaseFrontend():getBrowserModel():isFileTypeSetStateFlag()
    if (Model == NI.DB3.MODEL_ATTRIBUTES or (not FileTypeFlag and Model == NI.DB3.MODEL_RESULTS))
    and self.PresetListState == ControlPageStudio.PRESETS_PENDING then
        self.PresetListState = ControlPageStudio.PRESETS_ON
        self.PresetList:setVisible(true)
        self.PresetList:setActive(true)
        self.PresetList:forceAlign() -- scroll vector to focused item immediatlely
    end

    -- Update
    if Model == NI.DB3.MODEL_RESULTS and self.PresetList:isVisible() then
        local ResultList = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
        local FocusItem = ResultList:getFocusItem()
        WidgetHelper.VectorCenterOnItem(self.PresetList, FocusItem)
        self.PresetList:getScrollbar():setVisible(ResultList:getItemCount() > 5)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:updatePresetList(ForceUpdate)

    -- Only show the list if we're in the right mode
    self.PresetList:setVisible(
        (not NI.APP.FEATURE.EFFECTS_CHAIN or MaschineHelper:isShowingPlugins()) and
        self.PresetListState == ControlPageStudio.PRESETS_ON and not self.Controller:getShiftPressed())

    -- Force refresh preset list when we show the page
    if ForceUpdate and self.PresetListState == ControlPageStudio.PRESETS_ON then
        self:onDB3ModelChanged(NI.DB3.MODEL_RESULTS)
    end

    if not NI.APP.FEATURE.EFFECTS_CHAIN then
        return
    end

    if NI.DATA.ParameterCache.isValid(App) then
        local StateCache = App:getStateCache()

        local ShouldHidePresetList = StateCache:isFocusGroupChanged() or
            StateCache:isFocusSoundChanged() or
            StateCache:isFocusChainChanged() or
            -- we can not use StateCache:isFocusSoundChanged() because it is also triggered
            -- if the object inside the focused slot is changed.
            (self.CachedFocusSlotIndex ~= -1 and self.CachedFocusSlotIndex ~= NI.DATA.StateHelper.getFocusSlotIndex(App))

        if ShouldHidePresetList and isPresetListActive(self) then
            self:hidePresets()
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onWheel(Inc)

    if self.PresetList:isVisible() and
       (NI.HW.FEATURE.JOGWHEEL and NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM) then
        BrowseHelper.offsetResultListFocusBy(Inc, true)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onWheelButton(Pressed)

    if Pressed then

        if self.PresetListState == ControlPageStudio.PRESETS_ON then
            BrowseHelper.loadFocusItem()
            self:hidePresets()
        elseif not self.Controller:getShiftPressed() and MaschineHelper:isShowingPlugins() then
            self.Controller:showTempPage(NI.HW.PAGE_MODULE)
        end

        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onPrevNextButton(Pressed, Right)

    if Pressed and self.PresetListState == ControlPageStudio.PRESETS_ON then
        if BrowseHelper.offsetResultListFocusBy(Right and 1 or -1) then
            BrowseHelper.loadFocusItem()
        end

        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageStudio:onPageButton(Button, PageID, Pressed)

    -- call base class
    return PageMaschine.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
