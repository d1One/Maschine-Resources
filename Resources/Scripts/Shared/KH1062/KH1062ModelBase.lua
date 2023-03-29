require "Scripts/Shared/Components/Timer"
local AccessibilityTextHelper = require("Scripts/Shared/Helpers/AccessibilityTextHelper")
local ActionLedButtonHelper = require("Scripts/Shared/Helpers/ActionLedButtonHelper")
require "Scripts/Shared/Helpers/TimerHelper"
require "Scripts/Shared/Helpers/ToggleButton"
local AccessibilityHelper = require("Scripts/Shared/KH1062/AccessibilityHelper")
local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
require "Scripts/Shared/KH1062/PageManager"
require "Scripts/Shared/KH1062/ParameterIndexStack"
local PresetButtonHandlerFactory = require("Scripts/Shared/KH1062/PresetButtonHandlerFactory")
require "Scripts/Shared/KH1062/QuickBrowseController"
require "Scripts/Shared/KH1062/SwitchHandler"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KH1062ModelBase = class( 'KH1062ModelBase' )

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:__init(Environment)

    self.Environment = Environment

    if Environment.SetupApplicationState then
        self.Environment.SetupApplicationState()
    end

    self.SwitchHandler = SwitchHandler(NI.HW.BUTTON_PERFORM_SHIFT)

    local GlobalSwitchEventTable = self.SwitchHandler:getGlobalSwitchEventTable()

    GlobalSwitchEventTable:setHandler(
        { Switch = NI.HW.BUTTON_PERFORM_SHIFT },
        function(Pressed)
            self.PageManager:withVisiblePage(function(Page) Page:updateLEDs() end)
            self:notifyShiftPressed(Pressed)
            self:updateLEDs()
        end
    )

    GlobalSwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_TRANSPOSE_OCTAVE_MINUS },
                                        function() self:updateLEDs() end)

    GlobalSwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_TRANSPOSE_OCTAVE_PLUS },
                                        function() self:updateLEDs() end)

    self:updateShiftLED()

    self.PageManager = PageManager()
    self.PageManager:setPageChangedCallback(function() self:onPageChanged() end)

    self.RootPageLEDs = {}

    self.Timer = Timer()

    self.PAGE_SWITCH_OVERLAY_TIME_TICKS = TimerHelper.convertSecondsToTimerTicks(1)
    self.PARAMETER_OVERLAY_TIME_TICKS = TimerHelper.convertSecondsToTimerTicks(1)

    self.ParameterIndexStack = ParameterIndexStack()

    self.NUM_ERPS = 8

    for ParameterIndex = 0, self.NUM_ERPS - 1 do
        local SwitchID = NI.HW.BUTTON_CAP_1 + ParameterIndex
        GlobalSwitchEventTable:setHandler({ Switch = SwitchID, Pressed = true },
                                            function() self:onEncoderTouched(ParameterIndex) end)
        GlobalSwitchEventTable:setHandler({ Switch = SwitchID, Pressed = false },
                                            function() self:onEncoderReleased(ParameterIndex) end)
    end

    local IsPresetUpAvailableFunc = function()
        return self:PresetUpDownAvailable()
    end

    local DoPresetUpFunc = function()
        AccessibilityHelper.sayIfTrainingModeElse(Environment.AccessibilityModel, Environment.AccessibilityController, "Preset Up",
            function()
                local VisiblePage = self.PageManager:getVisiblePage()
                if VisiblePage and VisiblePage.onNavPresetButton then
                    VisiblePage:onNavPresetButton(true)
                else
                    self.Environment.QuickBrowseController:presetUp()
                end
            end
        )
    end

    self.PresetUpLedButton = PresetButtonHandlerFactory.createHandler(
        NI.HW.LED_NAVIGATE_PRESET_UP,
        DoPresetUpFunc,
        IsPresetUpAvailableFunc,
        Environment
    )

    local IsPresetDownAvailableFunc = function()
        return self:PresetUpDownAvailable()
    end

    local DoPresetDownFunc = function()
        AccessibilityHelper.sayIfTrainingModeElse(Environment.AccessibilityModel, Environment.AccessibilityController, "Preset Down",
            function()
                local VisiblePage = self.PageManager:getVisiblePage()
                if VisiblePage and VisiblePage.onNavPresetButton then
                    VisiblePage:onNavPresetButton(false)
                else
                    self.Environment.QuickBrowseController:presetDown()
                end
            end
        )
    end

    self.PresetDownLedButton = PresetButtonHandlerFactory.createHandler(
        NI.HW.LED_NAVIGATE_PRESET_DOWN,
        DoPresetDownFunc,
        IsPresetDownAvailableFunc,
        Environment
    )

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_NAVIGATE_PRESET_UP },
        function (Pressed) self.PresetUpLedButton:onPressed(Pressed) end)

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_NAVIGATE_PRESET_DOWN },
        function (Pressed) self.PresetDownLedButton:onPressed(Pressed) end)

    local PluginDisplayText = "Plug-in"
    local OpenPluginChainEditOverlay = function(TopLineText, BottomLineText)
        self:openPluginChainEditOverlay(self.PAGE_ID_PLUGIN_CHAIN_EDIT, TopLineText, BottomLineText)
        Environment.AccessibilityController.say(TopLineText .. " " .. BottomLineText)
    end

    self.chainEditOverlayCallbacks = {
        onFocusSlotMoved = function (SlotNumber)
            self:openPluginChainEditOverlay(self.PAGE_ID_PLUGIN_CHAIN_EDIT, PluginDisplayText .. " Moved", "to Slot " .. SlotNumber)
        end,
        onUserConfirmsFocusSlotPluginRemoval = function(RemovePluginFunc)
            self:openConfirmActionOverlay("Remove Plug-in", "Confirm", NI.HW.BUTTON_WHEEL_DOWN, RemovePluginFunc)
        end,
        onFocusSlotRemoved = function ()
            OpenPluginChainEditOverlay(PluginDisplayText, "Removed")
        end,
        onFocusSlotActiveToggled = function (IsActive)
            local EnabledText = IsActive and "Enabled" or "Disabled"
            OpenPluginChainEditOverlay(PluginDisplayText, EnabledText)
        end
    }

    local doWithTrainingModeAlternativeTextFunc = function(DoFunc, TrainingModeText)
        AccessibilityHelper.sayIfTrainingModeElse(
            Environment.AccessibilityModel,
            Environment.AccessibilityController,
            TrainingModeText,
            DoFunc
        )
    end

    self.ChainEditAccessibilityFuncs = {
        say = function(Text)
            self.Environment.AccessibilityController.say(Text)
        end,
        doWithTrainingModeAlternative = doWithTrainingModeAlternativeTextFunc,
        sayWithTrainingModeAlternative = function(Text, TrainingModeText)
            doWithTrainingModeAlternativeTextFunc(function() Environment.AccessibilityController.say(Text) end, TrainingModeText)
        end
    }

    local function speakPageNameAgainIfNotChanged()
        local ParameterCacheModel = self.Environment.DataModel.ParameterCacheModel
        local RepeatPageName = ParameterCacheModel:getFocusedParameterPageCount() > 0
        if RepeatPageName then
            self.Environment.AccessibilityController.say(ParameterCacheModel:getFocusedParameterPageName())
        end
        return RepeatPageName
    end

    self.LeftPagingLedButton = ActionLedButtonHelper.createButton(
        function ()
            return self:isTopNonOverlayPageParameterOwning()
                and self.Environment.DataModel.ParameterCacheModel:canPageLeft()
        end,

        function (ActiveState)
            self.Environment.LedController:setLEDState(NI.HW.LED_LEFT, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,

        function ()
            self:withFocusedParameterOwner(function ()
                self.Environment.DataController:decrementFocusPage()
                self:openPageSwitchOverlay()
            end)
        end,

        nil,

        function ()
            if not speakPageNameAgainIfNotChanged() then
                self:sayIfTrainingModeElse(
                    "Page Left",
                    nil
                )
            end
        end
    )

    self.RightPagingLedButton = ActionLedButtonHelper.createButton(
        function ()
            return self:isTopNonOverlayPageParameterOwning()
                and self.Environment.DataModel.ParameterCacheModel:canPageRight()
        end,

        function (ActiveState)
            self.Environment.LedController:setLEDState(NI.HW.LED_RIGHT, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,

        function ()
            self:withFocusedParameterOwner(function ()
                self.Environment.DataController:incrementFocusPage()
                self:openPageSwitchOverlay()
            end)
        end,

        nil,

        function ()
            if not speakPageNameAgainIfNotChanged() then
                self:sayIfTrainingModeElse(
                    "Page Right",
                    nil
                )
            end
        end
    )

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_LEFT },
                                        function (Pressed) self.LeftPagingLedButton:onPressed(Pressed) end)
    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_RIGHT },
                                        function (Pressed) self.RightPagingLedButton:onPressed(Pressed) end)

    local ScaleArpDataModel = self.Environment.DataModel.ScaleArpDataModel
    self.GetScaleParameterStateFunc = function() return ScaleArpDataModel:getScaleParameterState() end
    self.GetArpParameterStateFunc = function() return ScaleArpDataModel:getArpeggiatorParameterState() end

    local ScaleText = "Scale"
    local ArpText = "Arp"
    local function createScaleArpAccessibleButtonFunc(ButtonText)
        return function(ButtonState)
            self.Environment.AccessibilityController.say(AccessibilityTextHelper.getOnOffFieldText(ButtonText, ButtonState))
        end
    end

    self.ScaleButton = ToggleButton(self.GetScaleParameterStateFunc,
                                    function(BoolData) return ScaleArpDataModel:setScaleParameterState(BoolData) end,
                                    createScaleArpAccessibleButtonFunc(ScaleText))
    self.ArpButton = ToggleButton(self.GetArpParameterStateFunc,
                                    function(BoolData) return ScaleArpDataModel:setArpeggiatorParameterState(BoolData) end,
                                    createScaleArpAccessibleButtonFunc(ArpText))

    local function createScaleArpButtonHandler(Button, TrainingText)
        return function()
            self:sayIfTrainingModeElse(TrainingText,
                function()
                    Button:onToggleButton()
                    self:updateScaleArpLeds()
                end
            )
        end
    end

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_PERFORM_SCALE, Pressed = true },
                                        createScaleArpButtonHandler(self.ScaleButton, ScaleText))

    GlobalSwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_PERFORM_SCALE, Pressed = true },
                                        function() self:toggleScaleArpPage(self.PAGE_ID_EDIT_SCALE, "Scale Edit") end)

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_PERFORM_ARPEGGIATOR, Pressed = true },
                                        createScaleArpButtonHandler(self.ArpButton, ArpText))

    GlobalSwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_PERFORM_ARPEGGIATOR, Pressed = true },
                                        function() self:toggleScaleArpPage(self.PAGE_ID_EDIT_ARP, "Arp Edit") end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:getSwitchHandler()

    return self.SwitchHandler

 end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updateRootPageSync()

    self.PageManager:changeRootPage(self.PageManager.ActiveRootPageID, false)

    if self.Environment.AppModel:isBusy() then
        self:openBusyDialog()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:registerRootPageLED(LedID, PageIDs, ShiftAvailableFunctor)

    self.RootPageLEDs[LedID] = {
        PageIDs = PageIDs,
        IsShiftFunctionAvailable = ShiftAvailableFunctor
    }

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updateRootPageLEDs()

    local function getPageActiveLEDState(LedDetail)
        if LedDetail.PageIDs == nil or #LedDetail.PageIDs == 0 then
            return LEDHelper.LS_OFF
        end
        for _,PageID in pairs(LedDetail.PageIDs) do
            if self.PageManager:isRootPageActive(PageID) then
                return LEDHelper.LS_BRIGHT
            end
        end
        return LEDHelper.LS_DIM
    end

    local function getPageLEDState(IsShiftPressed, LedDetail)
        if IsShiftPressed then
            return LedDetail.IsShiftFunctionAvailable() and LEDHelper.LS_DIM or LEDHelper.LS_OFF
        else
            return getPageActiveLEDState(LedDetail)
        end
    end

    local IsShiftPressed = self.SwitchHandler:isShiftPressed()
    for LedID, LedDetail in pairs(self.RootPageLEDs) do
        self.Environment.LedController:setLEDState(LedID, getPageLEDState(IsShiftPressed, LedDetail))
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onSwitchEvent(SwitchID, Pressed)

    if self.Environment.AppModel:isBusy() then
        return true
    end

    self.SwitchHandler:onSwitchEvent(SwitchID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onWheelEvent(WheelID, Value)

    if self.Environment.AppModel:isBusy() then
        return true
    end

    self.PageManager:withVisiblePage(function (Page) Page:onWheel(Value) end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:openBusyDialog()

    local GetBusyMessage = function (BusyState)
        if BusyState == NI.HW.BUSY_LOADING or BusyState == NI.HW.BUSY_PRESETS then
            return "Busy...", "Loading"
        else
            return "Busy...", "See Software"
        end
    end

    self:resetAllOwnedLEDs()
    local BusyPage = self.PageManager.PageList[self.PAGE_ID_BUSY].Page
    BusyPage:setMessage(GetBusyMessage(self.Environment.AppModel:getBusyState()))
    AccessibilityHelper.sayIfBusyStateIsBlocking(
        self.Environment.AccessibilityController,
        self.Environment.AppModel:getBusyState()
    )
    self.PageManager:openOverlay(self.PAGE_ID_BUSY)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:closeBusyDialog()

    self.PageManager:closeOverlay()
    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onControllerTimer()

    self.Environment.BrowserController:processDelayedSearches()
    self.Timer:onControllerTimer()
    self.PageManager:onTimer()
    if self.Environment.AccessibilityController then
        self.Environment.AccessibilityController:onTimerNotification()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:shouldOpenEncoderTouchedOverlay()

    return self.Environment.DataModel.ParameterCacheModel:getFocusedParameterPageCount() > 0

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onEncoderTouched(Index)

    self.ParameterIndexStack:addAtBottom(Index)
    if self:shouldOpenEncoderTouchedOverlay() then
        self.PageManager:openEncoderOverlayForCurrentPage()
        self.PageManager:withVisiblePage(
            function(ActivePage)
                if ActivePage.sayPage then
                    ActivePage:sayPage()
                end
            end
        )
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onEncoderReleased(Index)

    local PageDetail = self.PageManager:getTopNonOverlayPage()
    if PageDetail and PageDetail.EncoderOverlayPageID then
        self.ParameterIndexStack:remove(Index, false)
        self.PageManager:withVisiblePage(function (VisiblePage)
            VisiblePage:updateScreen()
        end)

        if self.ParameterIndexStack:getSize() == 0 then
            self.PageManager:scheduleRemove(PageDetail.EncoderOverlayPageID, self.PARAMETER_OVERLAY_TIME_TICKS)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onEncoderEvent(Index, Value)

    if not self:shouldOpenEncoderTouchedOverlay() or self.Environment.AccessibilityModel:isTrainingMode() then
        return
    end

    local WasEncoderTouched = self.ParameterIndexStack:contains(Index)
    if WasEncoderTouched then
        self.ParameterIndexStack:bringToTop(Index)
    else
        self.ParameterIndexStack:setParameterTurnedWithoutTouch(Index)
    end

    self.PageManager:openEncoderOverlayForCurrentPage()

    if not WasEncoderTouched then
        self.PageManager:scheduleRemove(self.PAGE_ID_PARAMETER, self.PARAMETER_OVERLAY_TIME_TICKS)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:configureERPs()

    local PageDetail = self.PageManager:getVisiblePageDetail()

    if PageDetail and PageDetail.ModeERPs then
        self.Environment.HardwareSectionController:configureERPs(PageDetail.ModeERPs)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:openLibrarySwitchOverlay(PageID, TopLineText, BottomLineText)

    local PageDefinition = self.PageManager.PageList[PageID]
    PageDefinition.Page:setMessage(TopLineText, BottomLineText)
    self.Environment.AccessibilityController.say(TopLineText .. " " .. BottomLineText)
    self.PageManager:openOverlay(PageID, PageDefinition.OverlayTicks)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:openPluginChainEditOverlay(PageID, MessageLine1, MessageLine2)

    local PageDefinition = self.PageManager.PageList[PageID]
    PageDefinition.Page:setMessage(MessageLine1, MessageLine2)
    self.PageManager:openOverlay(PageID, PageDefinition.OverlayTicks)
    self.PageManager:withVisiblePage(function (ActivePage)
        ActivePage:updateScreen()
    end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:openPageSwitchOverlay()

    local PageDetail = self.PageManager:getTopNonOverlayPage()

    if PageDetail and PageDetail.PageButtonOverlayPageID then
        self.PageManager:openOverlay(PageDetail.PageButtonOverlayPageID, self.PAGE_SWITCH_OVERLAY_TIME_TICKS)
        self.PageManager:withVisiblePage(function (ActivePage)
            ActivePage:updateScreen()
        end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:onPageChanged()

    local SwitchEventTargetPage = self.PageManager:getActiveSwitchEventTarget()
    self.SwitchHandler:setPageSwitchEventTable(
        SwitchEventTargetPage and SwitchEventTargetPage:getSwitchEventTable() or nil
    )

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updatePresetLeds()

    self.PresetUpLedButton:updateLed()
    self.PresetDownLedButton:updateLed()

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updateShiftLED()

    self.Environment.LedController:setLEDState(NI.HW.LED_PERFORM_SHIFT,
        self.SwitchHandler:isShiftPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:openConfirmActionOverlay(ActionText, ConfirmText, CancelButtonId, ActionFunc)

    self.Environment.AccessibilityController.say(ActionText .. ", push to confirm")
    self.PageManager:withPage(self.PAGE_ID_CONFIRM_ACTION,
        function(Page)
            if Page and Page.configureAction then
                Page:configureAction(
                    ActionText,
                    ConfirmText,
                    CancelButtonId,
                    function()
                        self.PageManager:closeOverlay()
                        ActionFunc()
                    end
                )
            end
        end
    )

    self.PageManager:openOverlay(self.PAGE_ID_CONFIRM_ACTION)
    self.PageManager:withVisiblePage(function (ActivePage)
        ActivePage:updateScreen()
    end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:withFocusedParameterOwner(CallbackFunction)

    local PageDetail = self.PageManager:getTopNonOverlayPage()
    local ParameterOwnerID = PageDetail and PageDetail.ParameterOwnerID

    if ParameterOwnerID ~= nil then
        CallbackFunction(ParameterOwnerID)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updateScaleArpLeds()

    local LedStateFn = function(StateFn)
        return StateFn() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    end

    local ScaleArpDataModel = self.Environment.DataModel.ScaleArpDataModel
    self.Environment.LedController:setLEDState(
        NI.HW.LED_PERFORM_SCALE,
        LedStateFn(self.GetScaleParameterStateFunc)
    )
    self.Environment.LedController:setLEDState(
        NI.HW.LED_PERFORM_ARPEGGIATOR,
        LedStateFn(self.GetArpParameterStateFunc)
    )

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:changeSmartPlayPage(OptionalPageID)

    self.PageManager:closeSmartPlayPageAndOverlays()
    if OptionalPageID then
        self.PageManager:openPage(OptionalPageID)
    end

    self:updateFocusedParameterOwner()

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:toggleScaleArpPage(PageID, AccessibilityText)

    self:sayIfTrainingModeElse(AccessibilityText,
        function()
            if self.PageManager:isNonOverlayPageOpen(PageID) then
                self:changeSmartPlayPage(nil)
            else
                self:changeSmartPlayPage(PageID)
            end
            self.PageManager:withVisiblePage(
                function(Page)
                    self.Environment.AccessibilityController.say(AccessibilityTextHelper.getOnOffFieldText(AccessibilityText, Page.Name == PageID))
                end
            )
        end
    )

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:updateFocusedParameterOwner()

    self:withFocusedParameterOwner(function (ParameterOwnerID)
        self.Environment.DataController:setFocusedParameterOwner(ParameterOwnerID)
    end)
    self:configureERPs()

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:isTopNonOverlayPageParameterOwning()

    local PageDetail = self.PageManager:getTopNonOverlayPage()
    return PageDetail.ModeERPs == NI.HW.ENC_MODE_CONTROL

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:acquireSectionControl(DeviceSections, Acquire)

    for _,Section in ipairs(DeviceSections) do
        if not Section then
            error("Failed to acquire section")
        end
        self.Environment.HardwareSectionController:acquireSectionControl(Section, Acquire)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062ModelBase:sayIfTrainingModeElse(Text, ElseFunc)

    local Env = self.Environment
    AccessibilityHelper.sayIfTrainingModeElse(Env.AccessibilityModel, Env.AccessibilityController, Text, ElseFunc)

end
