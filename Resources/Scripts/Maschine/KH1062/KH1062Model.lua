require "Scripts/Maschine/Helper/GridHelper"

require "Scripts/Maschine/KH1062/BrowserNavigationTracker"
local MuteSoloLedButtons = require("Scripts/Maschine/KH1062/MuteSoloLedButtons")
require "Scripts/Maschine/KH1062/Pages/IdeasPage"
local IdeasPatternLengthEditorPage = require("Scripts/Maschine/KH1062/Pages/IdeasPatternLengthEditorPage")
require "Scripts/Maschine/KH1062/Pages/GroupNavigatorPage"
local PluginPage = require("Scripts/Maschine/KH1062/Pages/PluginPage")
require "Scripts/Maschine/KH1062/Pages/QuickEditPage"
local ParameterPage = require("Scripts/Shared/KH1062/Pages/ParameterPage")
local ParameterHelper = require("Scripts/Shared/KH1062/ParameterHelper")

local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
local ChainAccessHelper = require("Scripts/Shared/KH1062/ChainAccessHelper")
require "Scripts/Shared/KH1062/KH1062ModelBase"

require "Scripts/Shared/KH1062/Pages/BrowseFilterPage"
require "Scripts/Shared/KH1062/Pages/BrowseResultsPage"
require "Scripts/Shared/KH1062/Pages/ConfirmActionOverlayPage"
require "Scripts/Shared/KH1062/Pages/PageSwitchMessagePage"
require "Scripts/Shared/KH1062/Pages/TwoLineMessagePage"

local ActionLedButtonHelper = require("Scripts/Shared/Helpers/ActionLedButtonHelper")
require "Scripts/Shared/Helpers/ActionHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/TimerHelper"
require "Scripts/Shared/Helpers/ToggleLedButton"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KH1062Model = class( 'KH1062Model', KH1062ModelBase )

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:__init(Environment)

    KH1062ModelBase.__init(self, Environment)

    self.PAGE_ID_BROWSE_RESULTS = "browseResultsPage"
    self.PAGE_ID_BROWSE_FILTER = "browseFilterPage"
    self.PAGE_ID_PARAMETER = "parameterPage"
    self.PAGE_ID_PLUGIN = "pluginPage"
    self.PAGE_ID_PLUGIN_CHAIN_EDIT = "pagePluginChainEdit"
    self.PAGE_ID_BUSY = "busyPage"
    self.PAGE_ID_EDIT_SCALE = "editScalePage"
    self.PAGE_ID_EDIT_ARP = "editArpPage"
    self.PAGE_ID_PAGE_SWITCH = "pageSwitchPage"
    self.PAGE_ID_LIBRARY_SWITCH = "librarySwitchPage"
    self.PAGE_ID_GROUP_SOUND_NAVIGATOR = "groupNavigatorPage"
    self.PAGE_ID_CONFIRM_ACTION = "confirmActionOverlayPage"
    self.PAGE_ID_IDEAS = "ideasPage"
    self.PAGE_ID_IDEAS_PATTERN_LENGTH_EDITOR = "ideasPatternLengthEditorPage"
    self.PAGE_ID_KEY_MODE = "keyModePage"
    self.PAGE_ID_QUICK_EDIT = "quickEditPage"

    local GlobalSwitchEventTable = self.SwitchHandler:getGlobalSwitchEventTable()

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_NAVIGATE_BROWSE, Pressed = true },
                                      function()
                                        self:changeToBrowsePageBasedOnPreviouslyLoadedState()
                                      end)

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_CONTROL, Pressed = true },
                                      function()
                                        self.PageManager:changeRootPage(self.PAGE_ID_PLUGIN, true)
                                      end)

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_MIX, Pressed = true },
                                      function() self.PageManager:changeRootPage(self.PAGE_ID_GROUP_SOUND_NAVIGATOR, true) end)

    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_PATTERN, Pressed = true },
                                      function() self.PageManager:changeRootPage(self.PAGE_ID_IDEAS, true) end)

    GlobalSwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_TRANSPOSE_OCTAVE_PLUS, Pressed = true },
                                      function() self:toggleFocusGroupDrumKitMode() end)

    self.BrowserNavigationTracker = BrowserNavigationTracker(self.PAGE_ID_BROWSE_FILTER, PARAM_BC1)

    local IsQuantizeAutoAvailableFunc = function()
        if self.SwitchHandler:isShiftPressed() then
            local RecordAutoAvailable = true
            return RecordAutoAvailable
        else
            return self.Environment.DataModel:isQuantizeAvailable()
        end
    end

    local SetQuantizeAutoLedFunc = function(ActiveState)
        if self.SwitchHandler:isShiftPressed() then
            local AutoWriteEnabled = self.Environment.DataModel:isRecordAutoEnabled()
            self.Environment.LedController:setLEDState(NI.HW.LED_QUANTIZE, AutoWriteEnabled and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
        else
            self.Environment.LedController:setLEDState(NI.HW.LED_QUANTIZE, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end
    end

    local DoQuantizeAutoFunc = function()
        if self.SwitchHandler:isShiftPressed() then
            self.Environment.DataController:onToggleRecordAuto()
        else
            self.Environment.DataController:onQuantize()
        end
    end

    self.QuantizeAutoButtonHelper = ActionLedButtonHelper.createButton(
        IsQuantizeAutoAvailableFunc,
        SetQuantizeAutoLedFunc,
        DoQuantizeAutoFunc
    )
    GlobalSwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_QUANTIZE },
                                      function (Pressed) self.QuantizeAutoButtonHelper:onPressed(Pressed) end)

    local IsUndoRedoAvailableFunc = function()
        local DataModel = self.Environment.DataModel
        if self.SwitchHandler:isShiftPressed() then
            return DataModel:isRedoAvailable()
        else
            return DataModel:isUndoAvailable()
        end
    end
    local SetUndoRedoLedFunc = function(ActiveState)
        self.Environment.LedController:setLEDState(NI.HW.LED_UNDO, ButtonHelper.getLedStateFromActiveState(ActiveState))
    end
    local DoUndoRedoFunc = function()
        local DataController = self.Environment.DataController
        if self.SwitchHandler:isShiftPressed() then
            DataController:redo()
        else
            DataController:undo()
        end
    end

    self.UndoRedoButtonHelper = ActionLedButtonHelper.createButton(
        IsUndoRedoAvailableFunc,
        SetUndoRedoLedFunc,
        DoUndoRedoFunc
    )
    GlobalSwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_UNDO },
                                    function (Pressed) self.UndoRedoButtonHelper:onPressed(Pressed) end)

    self:createTempoLedButton()
    GlobalSwitchEventTable:setHandler({ Shift = false, Switch = NI.HW.BUTTON_TRANSPORT_TEMPO, Pressed = true },
                                    function() self.TempoLedButton:onToggleButton() end)


    self:createPages()
    self:registerRootPageLEDs()

    self:createClearButtonHelper()
    GlobalSwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_TRANSPORT_STOP },
        function(Pressed)
            self.ClearButtonHelper:onPressed(Pressed)
        end
    )

    self.PageManager:setRootPageChangedCallback(function() self:onRootPageChanged() end)
    self.PageManager:changeRootPage(self.PAGE_ID_PLUGIN)

    self:resetAllOwnedLEDs()

    self:updateRootPageSync()
    self:updateLEDs()

    self:acquireSectionControl({
        NI.HW.DEVICE_SECTION_PRESET_AND_PAGE,
        NI.HW.DEVICE_SECTION_PERFORM,
        NI.HW.DEVICE_SECTION_TRACK,
        NI.HW.DEVICE_SECTION_ENCODERS,
        NI.HW.DEVICE_SECTION_NAVIGATE,
        NI.HW.DEVICE_SECTION_KEY_MODE
    }, true)

    self.Environment.DataController.ParameterCacheController:setPageChangedCallback(function ()
        self:updateParameterCacheForCurrentFocus()
        self:updatePagingLeds()
    end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:createTempoLedButton()

    self.TempoLedButton = ToggleLedButton(

        function()
            return self.PageManager:isNonOverlayPageOpen(self.PAGE_ID_QUICK_EDIT)
        end,
        function(Active)
            self:setTempoPageActive(Active)
        end,
        function (ActiveState)
            self.Environment.LedController:setLEDState(NI.HW.LED_TRANSPORT_TEMPO,
                                                       ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,
        function()
            return not self.SwitchHandler:isShiftPressed()
        end

    )

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:createBrowserPages(PageList)

    local MuteSoloCallbacks = {

        createShiftStateButtons = function (Page)
            Page.MuteLedButton, Page.SoloLedButton =
                MuteSoloLedButtons.createMuteSoloSoundLedButtons(self.Environment, Page.SwitchEventTable)
        end,

        updateShiftStateLEDs = function (Page)
            Page.MuteLedButton:updateLed()
            Page.SoloLedButton:updateLed()
        end

    }

    PageList[self.PAGE_ID_BROWSE_RESULTS] =
    {
        Page = BrowseResultsPage(self.PAGE_ID_BROWSE_RESULTS, self.Environment, self, self.BrowserNavigationTracker, {

            changeToPluginPage = function()
                self.PageManager:changeRootPage(self.PAGE_ID_PLUGIN)
            end,

            changeToLastFilter = function()
                self.PageManager:changeRootPage(self.PAGE_ID_BROWSE_FILTER)
                self.PageManager.PageList[self.PAGE_ID_BROWSE_FILTER].Page:shiftToLastPopulatedFilterOrResults()
            end,

            clearFilters = function()
                self.PageManager:changeRootPage(self.PAGE_ID_BROWSE_FILTER)
                self.PageManager.PageList[self.PAGE_ID_BROWSE_FILTER].Page:clearFilters()
                self.PageManager.PageList[self.PAGE_ID_BROWSE_FILTER].Page:shiftToFirstFilterOrResults()
            end,

            openLibrarySwitchOverlay = function(TopLineText, BottomLineText)
                self:openLibrarySwitchOverlay(self.PAGE_ID_LIBRARY_SWITCH, TopLineText, BottomLineText)
            end,

            onLoadActionTriggered = function()
                self.Environment.DataController:setSoundFocus()
            end

        }, MuteSoloCallbacks),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_ROOT_PAGE,
        HandlesPresetButtons = true
    }

    PageList[self.PAGE_ID_BROWSE_FILTER] =
    {
        Page = BrowseFilterPage(self.PAGE_ID_BROWSE_FILTER, self.Environment, self,
                                { BrowseFilterPage.FileTypeFilter, PARAM_BC1, PARAM_ATTR1, PARAM_ATTR2, PARAM_ATTR3 },
                                self.BrowserNavigationTracker,
                                {
                                    changeToResultPage = function()
                                        self.PageManager:changeRootPage(self.PAGE_ID_BROWSE_RESULTS)
                                    end,

                                    openLibrarySwitchOverlay = function(TopLineText, BottomLineText)
                                        self:openLibrarySwitchOverlay(self.PAGE_ID_LIBRARY_SWITCH, TopLineText, BottomLineText)
                                    end

                                }, MuteSoloCallbacks),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_ROOT_PAGE,
        HandlesPresetButtons = true
    }

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:createPages()

    local PageList = {}
    local function IsShiftPressedFunc()
        return self.SwitchHandler:isShiftPressed()
    end

    self:createBrowserPages(PageList)

    PageList[self.PAGE_ID_PAGE_SWITCH] =
    {
        Page = PageSwitchMessagePage(self.PAGE_ID_PAGE_SWITCH, self.Environment, self.SwitchHandler),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_OVERLAY_PAGE
    }

    PageList[self.PAGE_ID_PARAMETER] =
    {
        Page = ParameterPage(self.PAGE_ID_PARAMETER, self.Environment.ScreenStack, self.SwitchHandler, function ()
            local Index = self.ParameterIndexStack:getTopIndex()
            return Index and self.Environment.DataModel.ParameterCacheModel:getParameterData(Index)
        end),
        LedID = NI.HW.LED_MIX,
        ModeERPs = NI.HW.ENC_MODE_CONTROL,
        Priority = PageManager.PRIORITY_PARAMETER_PAGE
    }

    PageList[self.PAGE_ID_PLUGIN] =
    {
        Page = PluginPage(
            self.PAGE_ID_PLUGIN,
            self.Environment,
            self.SwitchHandler,
            function ()
                return self.Environment.DataModel:getFocusedChainInfo()
            end,
            ChainAccessHelper.createChainEditCallbacks(
                self.Environment.DataModel.ChainModel,
                self.Environment.DataController.ChainController,
                self.ChainEditAccessibilityFuncs,
                self.chainEditOverlayCallbacks
            )
        ),
        ModeERPs = NI.HW.ENC_MODE_CONTROL,
        ParameterOwnerID = ParameterHelper.FOCUSED_OWNER_PLUGIN,
        EncoderOverlayPageID = self.PAGE_ID_PARAMETER,
        PageButtonOverlayPageID = self.PAGE_ID_PAGE_SWITCH,
        Priority = PageManager.PRIORITY_ROOT_PAGE
    }

    PageList[self.PAGE_ID_PLUGIN_CHAIN_EDIT] =
    {
        Page = TwoLineMessagePage(self.PAGE_ID_PLUGIN_CHAIN_EDIT, self.Environment.ScreenStack, self.SwitchHandler),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_OVERLAY_PAGE,
        OverlayTicks = self.PAGE_SWITCH_OVERLAY_TIME_TICKS
    }

    PageList[self.PAGE_ID_BUSY] =
    {
        Page = TwoLineMessagePage(self.PAGE_ID_BUSY, self.Environment.ScreenStack, self.SwitchHandler),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_OVERLAY_PAGE
    }

    PageList[self.PAGE_ID_LIBRARY_SWITCH] =
    {
        Page = TwoLineMessagePage(
            self.PAGE_ID_LIBRARY_SWITCH,
            self.Environment.ScreenStack,
            self.SwitchHandler
        ),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_OVERLAY_PAGE,
        OverlayTicks = self.PAGE_SWITCH_OVERLAY_TIME_TICKS
    }
    PageList[self.PAGE_ID_LIBRARY_SWITCH].Page:disableSwitchHandling()

    local createArpPage = function ()

        local Page = TwoLineMessagePage(self.PAGE_ID_EDIT_ARP, self.Environment.ScreenStack, self.SwitchHandler)
        Page.updateScreen = function ()
            Page:setMessage(
                self.Environment.DataModel:isFocusGroupDrumKitModeEnabled() and "Note Repeat" or "Arp",
                "Edit"
            )
        end
        return Page

    end

    PageList[self.PAGE_ID_EDIT_ARP] =
    {
        Page = createArpPage(),
        ModeERPs = NI.HW.ENC_MODE_CONTROL,
        ParameterOwnerID = ParameterHelper.FOCUSED_OWNER_PERFORM_ARP,
        EncoderOverlayPageID = self.PAGE_ID_PARAMETER,
        PageButtonOverlayPageID = self.PAGE_ID_PAGE_SWITCH,
        Priority = PageManager.PRIORITY_SMART_PLAY_PAGE
    }

    PageList[self.PAGE_ID_EDIT_SCALE] =
    {
        Page = TwoLineMessagePage(
            self.PAGE_ID_EDIT_SCALE,
            self.Environment.ScreenStack,
            self.SwitchHandler,
            "Scale",
            "Edit"
        ),
        ModeERPs = NI.HW.ENC_MODE_CONTROL,
        ParameterOwnerID = ParameterHelper.FOCUSED_OWNER_PERFORM_SCALE,
        EncoderOverlayPageID = self.PAGE_ID_PARAMETER,
        Priority = PageManager.PRIORITY_SMART_PLAY_PAGE
    }

    PageList[self.PAGE_ID_GROUP_SOUND_NAVIGATOR] =
    {
        Page = GroupNavigatorPage(
            self.PAGE_ID_GROUP_SOUND_NAVIGATOR,
            self.Environment,
            self.SwitchHandler,
            function(MessageText, CancelButtonId, CreateFunc)
                self:openConfirmActionOverlay(MessageText, "Create", CancelButtonId, CreateFunc)
            end
        ),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_ROOT_PAGE
    }

    PageList[self.PAGE_ID_CONFIRM_ACTION] =
    {
        Page = ConfirmActionOverlayPage(
            self.PAGE_ID_CONFIRM_ACTION,
            self.Environment.ScreenStack,
            self.SwitchHandler,
            function() self.PageManager:closeOverlay() end
        ),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_CONFIRM_ACTION
    }

    PageList[self.PAGE_ID_IDEAS] =
    {
        Page = IdeasPage(
            self.PAGE_ID_IDEAS,
            self.Environment.ScreenStack,
            self.Environment,
            self.SwitchHandler,
            {
                changeToGroupPage = function()
                    self.PageManager:changeRootPage(self.PAGE_ID_GROUP_SOUND_NAVIGATOR)
                end,
                openConfirmActionOverlay = function(MessageText, CancelButtonId, CreateFunc)
                    self:openConfirmActionOverlay(MessageText, "Create", CancelButtonId, CreateFunc)
                end,
                openPatternLengthEditor = function()
                    local PageID = self.PAGE_ID_IDEAS_PATTERN_LENGTH_EDITOR
                    self.PageManager:openOverlay(PageID)
                end
            }
        ),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_ROOT_PAGE,
    }

    PageList[self.PAGE_ID_KEY_MODE] =
    {
        Page = TwoLineMessagePage(self.PAGE_ID_KEY_MODE, self.Environment.ScreenStack, self.SwitchHandler),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_OVERLAY_PAGE
    }

    PageList[self.PAGE_ID_QUICK_EDIT] =
    {
        Page = QuickEditPage(
            self.PAGE_ID_QUICK_EDIT,
            self.Environment.ScreenStack,
            self.Environment,
            {
                isShiftPressed = IsShiftPressedFunc
            }),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_QUICK_EDIT_PAGE
    }
    PageList[self.PAGE_ID_QUICK_EDIT].Page:disableSwitchHandling()

    PageList[self.PAGE_ID_IDEAS_PATTERN_LENGTH_EDITOR] =
    {
        Page = IdeasPatternLengthEditorPage(
            self.PAGE_ID_IDEAS_PATTERN_LENGTH_EDITOR,
            self.Environment.ScreenStack,
            self.Environment.DataModel.IdeaSpaceModel,
            self.Environment.DataController.IdeaSpaceController,
            {
                isShiftPressedFunc = IsShiftPressedFunc,
                closePatternLengthEditorFunc = function()
                    self.PageManager:closePageAndOverlaysAbove(self.PAGE_ID_IDEAS_PATTERN_LENGTH_EDITOR)
                end
            }
        ),
        ModeERPs = NI.HW.ENC_MODE_NONE,
        Priority = PageManager.PRIORITY_PARAMETER_PAGE
    }


    self.PageManager:registerPages(PageList)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:registerRootPageLEDs()

    self:registerRootPageLED(
        NI.HW.LED_BROWSE,
        { self.PAGE_ID_BROWSE_FILTER, self.PAGE_ID_BROWSE_RESULTS },
        function()
            return self.PageManager:isRootPageActive(self.PAGE_ID_BROWSE_RESULTS)
        end
    )

    self:registerRootPageLED(NI.HW.LED_CONTROL, { self.PAGE_ID_PLUGIN },
        function()
            return true -- MIDI always available
        end
    )

    self:registerRootPageLED(NI.HW.LED_MIX, { self.PAGE_ID_GROUP_SOUND_NAVIGATOR },
        function()
            return true -- Instance always available
        end
    )

    self:registerRootPageLED(NI.HW.LED_IDEAS, { self.PAGE_ID_IDEAS },
        function()
            return false
        end
    )

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:onDB3ModelChanged(ModelType)

    self.PageManager:withTopNonOverlayPage(function (Page) Page:onDB3ModelChanged(ModelType) end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updateParameterCacheForCurrentFocus()

    local Parameters = self.Environment.DataModel.ParameterCacheModel:getFocusParameters()
    self.Environment.DataController.ParameterCacheController:setCachedParameters(Parameters)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:onStateFlagsChanged()

    self:withFocusedParameterOwner(function (ParameterOwnerID)
        self:updateParameterCacheForCurrentFocus()
    end)
    self.PageManager:withVisiblePage(function (Page)
                                        Page:onStateFlagsChanged()
                                        Page:updateLEDs()
                                     end)
    self:updateLEDs()
    self.PageManager:withVisiblePage(function (Page) Page:updateScreen() end)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:resetAllOwnedLEDs()

    self.Environment.LedController:turnOffLEDs({
        NI.HW.LED_PERFORM_ARPEGGIATOR,
        NI.HW.LED_PERFORM_SCALE,
        NI.HW.LED_TRANSPORT_TEMPO,
        NI.HW.LED_IDEAS,
        NI.HW.LED_UNDO,
        NI.HW.LED_QUANTIZE,
        NI.HW.LED_NAVIGATE_PRESET_UP,
        NI.HW.LED_NAVIGATE_PRESET_DOWN,
        NI.HW.LED_LEFT,
        NI.HW.LED_RIGHT,
        NI.HW.LED_BROWSE,
        NI.HW.LED_CONTROL
    })

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updatePagingLeds()

    if self:isTopNonOverlayPageParameterOwning() and not self.SwitchHandler:isShiftPressed() then
        self.LeftPagingLedButton:updateLed()
        self.RightPagingLedButton:updateLed()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updateLEDs()

    if self.Environment.AppModel:isBusy() then
        self:resetAllOwnedLEDs()
    else
        self:updateRootPageLEDs()
        self:updatePagingLeds()
        self:updatePresetLeds()
        self:updateScaleArpLeds()
        self.QuantizeAutoButtonHelper:updateLed()
        self.UndoRedoButtonHelper:updateLed()
        self.TempoLedButton:updateLed()
        self.ClearButtonHelper:updateLed()
        self:updateKeyModeLED()
        self:updateShiftLED()

        if self.Environment.AppModel:isNoHardwareService() then
            self:updateOctaveLED()

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:onRootPageChanged()

    self.ParameterIndexStack:clear()
    self:updateFocusedParameterOwner()
    self:updateLEDs()
    self:configureERPs()
    self.SwitchHandler:setPageSwitchEventTable(self.PageManager:getVisiblePage():getSwitchEventTable())

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:changeToBrowsePageBasedOnPreviouslyLoadedState()

    self.PageManager:closeSmartPlayPageAndOverlays()

    local lastBrowserPageAndFilter = self.BrowserNavigationTracker:getCurrentFilterPageAndFilter()
    self.PageManager:changeRootPage(lastBrowserPageAndFilter.PageID)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:PresetUpDownAvailable()

    local VisiblePageDetail = self.PageManager:getVisiblePageDetail()
    return self.Environment.DataModel:isFocusSlotValid() or VisiblePageDetail.HandlesPresetButtons

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updateFocusedParameterOwner()

    KH1062ModelBase.updateFocusedParameterOwner(self)
    self:updateParameterCacheForCurrentFocus()

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updateKeyModeLED()

    local Active = self.Environment.DataModel:isFocusGroupDrumKitModeEnabled()
    self.Environment.LedController:setLEDState(NI.HW.LED_TRANSPOSE_OCTAVE_PLUS,
                                               Active and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:updateOctaveLED()

    if not self.SwitchHandler:isShiftPressed() then
        local CurrentOctave = self.Environment.HardwareSectionController:getCurrentOctave()
        self.Environment.LedController:setLEDState(NI.HW.LED_TRANSPOSE_OCTAVE_MINUS,
                                                   CurrentOctave < 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
        self.Environment.LedController:setLEDState(NI.HW.LED_TRANSPOSE_OCTAVE_PLUS,
                                                   CurrentOctave > 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:toggleFocusGroupDrumKitMode()

    local ShouldEnableDrumKitMode = not self.Environment.DataModel:isFocusGroupDrumKitModeEnabled()
    self.Environment.DataController:setFocusGroupDrumKitModeEnabled(ShouldEnableDrumKitMode)

    local MessagePage = self.PageManager.PageList[self.PAGE_ID_KEY_MODE].Page
    if ShouldEnableDrumKitMode then
        MessagePage:setMessage("Pad", "Mode")
    else
        MessagePage:setMessage("Keyboard", "Mode")
    end
    self.PageManager:openOverlay(self.PAGE_ID_KEY_MODE, self.PAGE_SWITCH_OVERLAY_TIME_TICKS)

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:setTempoPageActive(Active)

    local PageID = self.PAGE_ID_QUICK_EDIT
    if Active then
        self.PageManager:openOverlay(PageID)
    else
        self.PageManager:closePageAndOverlaysAbove(PageID)
        self:updateLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:notifyShiftPressed(Pressed)

    if not Pressed then
        -- Unset the shift+stop button state otherwise it is remembered the next time shift is pressed.
        self.ClearButtonHelper.LedButtonStateHandler:onSwitchEvent(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Model:createClearButtonHelper()

    local IsClearButtonAvailableFunc = function()

        if self.SwitchHandler:isShiftPressed() then
            return self.Environment.DataModel.IdeaSpaceModel:isAnythingToClearInFocusPattern()
        else
            return true
        end

    end

    local SetClearButtonLedFunc = function(ActiveState)

        if self.SwitchHandler:isShiftPressed() then
            self.Environment.LedController:setLEDState(
                NI.HW.LED_TRANSPORT_STOP,
                ButtonHelper.getLedStateFromActiveState(ActiveState) or LEDHelper.LS_OFF
            )
        end

    end

    local OnClearButtonFunc = function()

        self.Environment.DataController.IdeaSpaceController:clearFocusPattern()

    end

    self.ClearButtonHelper = ActionLedButtonHelper.createButton(
        IsClearButtonAvailableFunc,
        SetClearButtonLedFunc,
        OnClearButtonFunc
    )

end
