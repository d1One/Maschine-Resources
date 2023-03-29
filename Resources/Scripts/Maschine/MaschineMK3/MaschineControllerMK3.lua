------------------------------------------------------------------------------------------------------------------------
-- Maschine Controller MK3
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/MaschineStudioController"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Maschine/MaschineMK3/QuickEditMK3"
require "Scripts/Maschine/MaschineMK3/TouchstripControllerMK3"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTabAudio"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTabGeneral"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTabHardware"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTabMidi"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MaschineControllerMK3 = class( 'MaschineControllerMK3', MaschineStudioController )

------------------------------------------------------------------------------------------------------------------------

MaschineControllerMK3.BUTTON_TO_PAGE =
{
    [NI.HW.BUTTON_CONTROL]          = NI.HW.PAGE_CONTROL,
    [NI.HW.BUTTON_BROWSE]           = NI.HW.PAGE_BROWSE,
    [NI.HW.BUTTON_SAMPLE]           = NI.HW.PAGE_SAMPLING,
    [NI.HW.BUTTON_ARRANGE]          = NI.HW.PAGE_ARRANGER,
    [NI.HW.BUTTON_MIX]              = NI.HW.PAGE_MIXER,

    [NI.HW.BUTTON_SCENE]            = NI.HW.PAGE_SCENE,
    [NI.HW.BUTTON_PATTERN]          = NI.HW.PAGE_PATTERN,
    [NI.HW.BUTTON_EVENTS]           = NI.HW.PAGE_EVENTS,
    [NI.HW.BUTTON_VARIATION]        = NI.HW.PAGE_VARIATION,
    [NI.HW.BUTTON_DUPLICATE]        = NI.HW.PAGE_DUPLICATE,
    [NI.HW.BUTTON_SELECT]           = NI.HW.PAGE_SELECT,
    [NI.HW.BUTTON_SOLO]             = NI.HW.PAGE_SOLO,
    [NI.HW.BUTTON_MUTE]             = NI.HW.PAGE_MUTE,

    [NI.HW.BUTTON_NOTE_REPEAT]      = NI.HW.PAGE_REPEAT,
    [NI.HW.BUTTON_TRANSPORT_EVENTS] = NI.HW.PAGE_EVENTS,
    [NI.HW.BUTTON_STEP]             = NI.HW.PAGE_STEP_STUDIO,

    [NI.HW.BUTTON_NOTES]            = NI.HW.PAGE_NOTES,
    [NI.HW.BUTTON_SETTINGS]         = NI.HW.PAGE_SETTINGS
}

------------------------------------------------------------------------------------------------------------------------

MaschineControllerMK3.BUTTON_TO_PAGE_SHIFT =
{
    [NI.HW.BUTTON_FOLLOW]           = NI.HW.PAGE_GRID,
    [NI.HW.BUTTON_MACRO]            = NI.HW.PAGE_MACRO_ASSIGN,
    [NI.HW.BUTTON_VARIATION]        = NI.HW.PAGE_NAVIGATE,
}

------------------------------------------------------------------------------------------------------------------------

MaschineControllerMK3.MODIFIER_PAGES =
{
    NI.HW.PAGE_DUPLICATE,
    NI.HW.PAGE_GRID,
    NI.HW.PAGE_EVENTS,
    NI.HW.PAGE_MUTE,
    NI.HW.PAGE_NAVIGATE,
    NI.HW.PAGE_PAGE,
    NI.HW.PAGE_PATTERN,
    NI.HW.PAGE_REPEAT,
    NI.HW.PAGE_SCENE,
    NI.HW.PAGE_SELECT,
    NI.HW.PAGE_SOLO,
    NI.HW.PAGE_VARIATION,
    -- The following pages are part modifier by design, in that they're pinnable but not unpinnable.
    -- Their function setPinned() should be overridden so that they're not unpinned by default with screen button 1.
    NI.HW.PAGE_CHORD,
    NI.HW.PAGE_FILE,
    NI.HW.PAGE_KEYBOARD,
    NI.HW.PAGE_MACRO,
    NI.HW.PAGE_MACRO_ASSIGN,
    NI.HW.PAGE_PAD,
    NI.HW.PAGE_SETTINGS,
    NI.HW.PAGE_SIXTEEN_VEL,
    NI.HW.PAGE_SNAPSHOTS,
    NI.HW.PAGE_STEP_STUDIO
}


------------------------------------------------------------------------------------------------------------------------

MaschineControllerMK3.TEMPORARY_PAGES =
{
    NI.HW.PAGE_SAVE_AS
}

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:__init()

    -- contruct base class
    HardwareControllerBase.__init(self)

    self.TransportSection.OnWheelFunctor = function(Inc)
        if self:getShiftPressed() then
            local UseStepGrid = NHLController:getWheelPressed()
            NI.DATA.TransportAccess.nudgeTransportPosition(App, Inc, UseStepGrid, self:getErasePressed())
        end
    end

    self.QuickEdit = QuickEditMK3(self)
    self.Footswitch = FootswitchStudio(self)
    self.CapacitiveList = CapacitiveOverlayList(self)
    self.CapacitiveNavIcons = CapacitiveOverlayNavIcons(self)
    self.TouchstripController = TouchstripControllerMK3()

    LEDHelper.LEDValues = MaschineStudioController.LEDValues

    -- create Shared Objects and Maschine pages
    self:createSharedObjects()
    self:createPages()

    self:addSettingsTabs()

    self.hasJogwheelControls = function() return false end
    self.hasEditControls     = function() return false end

    NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)

    NHLController:resetAllLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:createPages()

    local Shared = "Scripts/Shared/Pages/"
    local MaschineStudio = "Scripts/Maschine/MaschineStudio/Pages/"
    local MaschineMk3 = "Scripts/Maschine/MaschineMK3/Pages/"
    local MaschineShared = "Scripts/Maschine/Shared/Pages/"

    self.PageManager:register(NI.HW.PAGE_CONTROL, MaschineMk3.."ControlPageMK3", "ControlPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_BROWSE, MaschineMk3.."BrowsePageMK3", "BrowsePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_MODULE, MaschineStudio.."ModulePageStudio", "ModulePageStudio", true)
    self.PageManager:register(NI.HW.PAGE_SAMPLING, MaschineMk3.."SamplingPageMK3", "SamplingPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_ARRANGER, MaschineMk3.."ArrangerPageMK3", "ArrangerPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_MIXER, MaschineMk3.."MixerPageMK3", "MixerPageMK3", true)

    self.PageManager:register(NI.HW.PAGE_CHORD, MaschineMk3.."ChordsModePageMK3", "ChordsModePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_KEYBOARD, MaschineMk3.."KeyboardModePageMK3", "KeyboardModePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_SIXTEEN_VEL, MaschineMk3.."SixteenVelModePageMK3", "SixteenVelModePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_PAD, MaschineMk3.."PadModePageMK3", "PadModePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_SCENE, MaschineStudio.."SceneForwardPageStudio", "SceneForwardPageStudio", true)
    self.PageManager:register(NI.HW.PAGE_PATTERN, MaschineMk3.."PatternPageMK3", "PatternPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_NAVIGATE, MaschineMk3 .. "NavigatePageMK3", "NavigatePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE, MaschineStudio.."DuplicatePageStudio", "DuplicatePageStudio", true)
    self.PageManager:register(NI.HW.PAGE_SELECT, MaschineStudio.."SelectPageStudio", "SelectPageStudio", true)
    self.PageManager:register(NI.HW.PAGE_SOLO, MaschineStudio.."SoloPageStudio", "SoloPageStudio", true)
    self.PageManager:register(NI.HW.PAGE_MUTE, MaschineStudio.."MutePageStudio", "MutePageStudio", true)

    self.PageManager:register(NI.HW.PAGE_REPEAT, MaschineMk3.."RepeatPageMK3", "RepeatPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_GRID, MaschineMk3.."GridPageMK3", "GridPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_EVENTS, MaschineMk3.."EventsPageMK3", "EventsPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_VARIATION, MaschineMk3.."VariationPageMK3", "VariationPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_STEP_MOD, MaschineMk3.."StepPageModMK3", "StepPageModMK3", true)

    self.PageManager:register(NI.HW.PAGE_PATTERN_LENGTH, MaschineStudio.."PatternLengthPageStudio", "PatternLengthPageStudio")
    self.PageManager:register(NI.HW.PAGE_LOOP, MaschineMk3.."LoopPageMK3", "LoopPageMK3")
    self.PageManager:register(NI.HW.PAGE_BUSY, Shared.."BusyPageStudio", "BusyPageStudio")
    self.PageManager:register(NI.HW.PAGE_MACRO, MaschineMk3.."MacroPageMK3", "MacroPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_MACRO_ASSIGN, MaschineMk3.."MacroAssignPage", "MacroAssignPage", true)
    self.PageManager:register(NI.HW.PAGE_STEP_STUDIO, MaschineMk3.."StepPageMK3", "StepPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_SNAPSHOTS, MaschineMk3.."SnapshotsPageMK3", "SnapshotsPageMK3")
    self.PageManager:register(NI.HW.PAGE_FILE, MaschineMk3 .. "FilePageMK3", "FilePageMK3", true)
    self.PageManager:register(NI.HW.PAGE_MODAL_DIALOG, Shared.."Dialogs/ModalDialogPage", "ModalDialogPage", true)
    self.PageManager:register(NI.HW.PAGE_TEXT_INPUT_DIALOG, Shared.."Dialogs/TextInputPage", "TextInputPage", true)
    self.PageManager:register(NI.HW.PAGE_AUDIO_EXPORT, MaschineMk3.."AudioExportPageMK3", "AudioExportPageMK3", true)
    self.PageManager:register(NI.HW.PAGE_SAVE_AS, MaschineShared.."SaveAsPage", "SaveAsPage", true)
    self.PageManager:register(NI.HW.PAGE_NOTES, MaschineMk3.."NotesPage", "NotesPage")
    self.PageManager:register(NI.HW.PAGE_SAVE_DIALOG, MaschineStudio .. "SaveDialogPageStudio", "SaveDialogPageStudio", true)
    self.PageManager:register(NI.HW.PAGE_SETTINGS, MaschineShared.."SettingsPage", "SettingsPage", true)


end

------------------------------------------------------------------------------------------------------------------------
-- setup screen button handler
------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:setupButtonHandler()

    MaschineStudioController.setupButtonHandler(self)

    self.SwitchHandler[NI.HW.BUTTON_WHEEL_UP] = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_UP) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_DOWN] = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_DOWN) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_LEFT] = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_LEFT) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_RIGHT] = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_RIGHT) end

    self.SwitchHandler[NI.HW.BUTTON_FIX_VELOCITY] = function(Pressed) self:onFixedVelocityButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PAD_MODE] = function(Pressed) self:onPadModeButton(NI.HW.BUTTON_PAD_MODE, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_KEYBOARD] = function(Pressed) self:onPadModeButton(NI.HW.BUTTON_KEYBOARD, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_CHORDS] = function(Pressed) self:onPadModeButton(NI.HW.BUTTON_CHORDS, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_FILE] = function(Pressed) self:onFileButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOLLOW] = function(Pressed) self:onFollowButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TAP] = function(Pressed) self:onTapTempo(Pressed) end
    self.SwitchHandlerShift[NI.HW.BUTTON_TAP] = function(Pressed) self:onMetroButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_NOTE_REPEAT] = function(Pressed) self:onNoteRepeatButton(Pressed) end

    -- MK3 transport
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_STOP] = function(Pressed) self:onStopButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PITCH] = function(Pressed) self:onPitchButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_MOD] = function(Pressed) self:onModButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_PERFORM] = function(Pressed) self:onPerformButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_NOTES] = function(Pressed) self:onNotesButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_LOCK] = function(Pressed) self:onLockButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_MACRO] = function(Pressed) self:onMacroButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_VARIATION] = function(Pressed) self:onVariationButton(Pressed) end
    self.SwitchHandlerShift[NI.HW.BUTTON_VARIATION] = function(Pressed) self:onVariationButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_FOOT2_DETECT]    = function(Pressed) self:onFootswitchDetect(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT2_TIP]       = function(Pressed) self:onFootswitchTip(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT2_RING]      = function(Pressed) self:onFootswitchRing(1, Pressed) end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:setupEncoderHandler()

    -- Default screen knob handlers
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_1] = function(EncoderInc) self:onScreenEncoder(1, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_2] = function(EncoderInc) self:onScreenEncoder(2, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_3] = function(EncoderInc) self:onScreenEncoder(3, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_4] = function(EncoderInc) self:onScreenEncoder(4, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_5] = function(EncoderInc) self:onScreenEncoder(5, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_6] = function(EncoderInc) self:onScreenEncoder(6, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_7] = function(EncoderInc) self:onScreenEncoder(7, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_8] = function(EncoderInc) self:onScreenEncoder(8, EncoderInc) end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onControllerTimer()

    self:updateFollowLED()
    self:updateTouchstripModeLEDs()
    self.TouchstripController:updateLEDs()
    self:updateLockLED()

    if NHLController:getPadMode() == NI.HW.PAD_MODE_STEP then
        StepHelper.onControllerTimer(self)
    end

    MaschineStudioController.onControllerTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onCustomProcess(ForceUpdate)

    if App:getMetronome():getEnabledParameter():isChanged() then
        self:updateMetroLED()
    end

    -- refresh sampling button state when recorder state changes
    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if Recorder and Recorder:getRecordingFlag():isChanged() then
        self:syncPageButtonLEDsWithPageStack()
    end

    MaschineStudioController.onCustomProcess(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:addSettingsTabs()

    local SettingsPage = self:getPage(NI.HW.PAGE_SETTINGS)

    if not SettingsPage then
        return
    end

    -- GENERAL
    SettingsPage:addTab(SettingsTabGeneral())

    -- AUDIO
    if NI.APP.isStandalone() then
        SettingsPage:addTab(SettingsTabAudio())
    end

    -- MIDI
    if NI.APP.isStandalone() then
        SettingsPage:addTab(SettingsTabMidi())
    end

    -- HARDWARE
    SettingsPage:addTab(SettingsTabHardware())

    SettingsPage:selectTab(1)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:clearTempPage()

    local TopPageID = NHLController:getPageStack():getTopPage()

    for Index, TempPageID in ipairs(MaschineControllerMK3.TEMPORARY_PAGES) do

        if TopPageID ~= TempPageID then

            NHLController:getPageStack():removePage(TempPageID)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPageButton(Button, PageID, Pressed)

    if not MaschineHelper.shouldHandlePageButton(PageID) then
        return
    end

    HardwareControllerBase.onPageButton(self, Button, PageID, Pressed)

    self:clearTempPage()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updatePageSync(ForceUpdate)

    if NHLController:getPadMode() ~= NI.HW.PAD_MODE_STEP then
        -- Reset step modulation data here since it can be valid on any page where Step Mode is enabled.
        StepHelper.resetStepModulationHoldData()
    end

    MaschineStudioController.updatePageSync(self, ForceUpdate)

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateFollowLED()

    local TopPageID = NHLController:getPageStack():getTopPage()
    local LedState

    if TopPageID == NI.HW.PAGE_GRID then

         LedState = LEDHelper.LS_BRIGHT

    elseif PadModeHelper.isStepModeEnabled() then

        LedState = StepHelper.FollowModeOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF

    else

        local FollowModeOn = App:getWorkspace():getFollowPlayPositionParameter():getValue()
        LedState = FollowModeOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF

    end

    LEDHelper.setLEDState(NI.HW.LED_FOLLOW, LedState)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateMetroLED()

    local LedState = (App:getMetronome():getEnabledParameter():getValue() or self:isButtonPressed(NI.HW.BUTTON_TAP))
        and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF

    LEDHelper.setLEDState(NI.HW.LED_TAP, LedState)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateLockLED()

    if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_SNAPSHOTS then
        LEDHelper.setLEDState(NI.HW.LED_LOCK, LEDHelper.LS_BRIGHT)
    elseif NHLController:getPageStack():isPageInStack(NI.HW.PAGE_SNAPSHOTS) then
        LEDHelper.setLEDState(NI.HW.LED_LOCK, LEDHelper.LS_DIM)
    else
        LEDHelper.updateButtonLED(self, NI.HW.LED_LOCK, NI.HW.BUTTON_LOCK, SnapshotsHelper.isLockActive())
    end

end

------------------------------------------------------------------------------------------------------------------------

local function isCurrentPadModeTriggeringSound()

    local PadMode = NHLController:getPadMode()

    return PadMode == NI.HW.PAD_MODE_SOUND
        or PadMode == NI.HW.PAD_MODE_KEYBOARD
        or PadMode == NI.HW.PAD_MODE_16_VELOCITY

end

------------------------------------------------------------------------------------------------------------------------

local function getTouchstripMode()

    return NHLController:getContext():getTouchstripModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

local function focusSoundForNotesMode(PadIndex, Trigger)

    local IsNotesMode = getTouchstripMode() == NI.HW.TS_MODE_NOTES
    if IsNotesMode and isCurrentPadModeTriggeringSound() then
        if Trigger and not PadModeHelper.getKeyboardMode() and not PadModeHelper.is16VelocityMode() then
            MaschineHelper.setFocusSound(PadIndex, true)
            return true
        end
    end

    return false
end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPadEvent(PadIndex, Trigger, PadValue)

    if not self.ActivePage then
        return
    end

    if Trigger then
        self.ActivePage:sendAccessiblePadInfo(PadIndex)
    end

    -- QuickEdit: always checked
    self.QuickEdit:onPadEvent(PadIndex, Trigger)

    if self:getShiftPressed() then
        -- For the pages that are reached with the Shift button modifier, we don't want the secondary
        -- pad shift-functions called when holding down shift with page button.  The shift-functions
        -- should only be called if the corresponding page button is not pressed, i.e. the page is pinned open.
        local TopPage = NHLController:getPageStack():getTopPage()
        local PreventShiftFunctions = false

        for ButtonId, PageId in pairs(MaschineControllerMK3.BUTTON_TO_PAGE_SHIFT) do
            if TopPage == PageId then
                PreventShiftFunctions = self:isButtonPressed(ButtonId)
                break
            end
        end

        if MaschineHelper.onPadEventShift(PadIndex, Trigger, self:getErasePressed(), PreventShiftFunctions) then
            return
        elseif not Trigger and PadModeHelper.isStepModeEnabled() then
            -- When step mode is enabled ignore release event
            return
        end
    end

    if focusSoundForNotesMode(PadIndex, Trigger) then
        return
    end

    HardwareControllerBase.onPadEvent(self, PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------
-- 4-way directional encoder wheel handler
function MaschineControllerMK3:onWheelDirection(Pressed, DirectionButton)

    if self.ActivePage then
        self.ActivePage:onWheelDirection(Pressed, DirectionButton)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onLockButton(Pressed)

    if self:getShiftPressed() or NHLController:getPageStack():getTopPage() == NI.HW.PAGE_SNAPSHOTS then
        self:onPageButton(NI.HW.BUTTON_LOCK, NI.HW.PAGE_SNAPSHOTS, Pressed)
    elseif Pressed then
        SnapshotsHelper.toggleLock()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onMacroButton(Pressed)

    local PageId = self:getShiftPressed() and NI.HW.PAGE_MACRO_ASSIGN or NI.HW.PAGE_MACRO

    if Pressed then

        if NI.DATA.ParameterPageAccess.isMacroPageActive(App) and NHLController:getPageStack():getTopPage() == NI.HW.PAGE_CONTROL then
            return -- already on macro (but on control page)
        elseif PageId == NI.HW.PAGE_MACRO_ASSIGN and NHLController:getPageStack():getTopPage() == NI.HW.PAGE_MACRO then
            NHLController:getPageStack():popPage()
        end
    end

    HardwareControllerBase.onPageButton(self, NI.HW.BUTTON_MACRO, PageId, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:getShiftPageID(Button, CurPageID, Pressed)

    if Button == NI.HW.BUTTON_FOLLOW then
        return NI.HW.PAGE_GRID
    end

    if Button == NI.HW.BUTTON_PATTERN then
        return NI.HW.PAGE_PATTERN -- override base class, that returns PAGE_VARIATION
    end

    if Button == NI.HW.BUTTON_MACRO then -- shift+macro acts as toggle between two pages
        return NHLController:getPageStack():isPageInStack(NI.HW.PAGE_MACRO_ASSIGN) and NI.HW.PAGE_MACRO or NI.HW.PAGE_MACRO_ASSIGN
    end

    return HardwareControllerBase.getShiftPageID(self, Button, CurPageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
-- Handle shift functions that do not show a page (only called if pressed)
------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPageButtonShift(Button, Pressed)

    -- Avoid using MaschineStudioController:onPageButtonShift()
    return HardwareControllerBase.onPageButtonShift(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onNoteRepeatButton(Pressed)

    if Pressed then

        -- Disable step mode when we go to note repeat
        if PadModeHelper.isStepModeEnabled() then
            NHLController:getPageStack():removePage(NI.HW.PAGE_STEP_STUDIO)
            MK3Helper.setPadModeParametersByButton(NI.HW.BUTTON_PAD_MODE)
        end

        if self:getShiftPressed() and not PadModeHelper.getKeyboardMode() then

            PadModeHelper.setKeyboardMode(true)

            if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_REPEAT then
                return
            end

        end
    end

    self:onPageButton(NI.HW.BUTTON_NOTE_REPEAT, NI.HW.PAGE_REPEAT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateWheelButtonLEDs()

    if self.ActivePage and self.ActivePage.updateWheelButtonLEDs then
        self.ActivePage:updateWheelButtonLEDs()
    else
        LEDHelper.resetButtonLEDs({ NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.LED_WHEEL_BUTTON_DOWN,
                                    NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.LED_WHEEL_BUTTON_RIGHT })
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateMacroButtonLED()

    if not NHLController:getPageStack():isPageInStack(NI.HW.PAGE_MACRO_ASSIGN) then
        MaschineStudioController.updateMacroButtonLED(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateStepButtonLED()

    local StepLedState = PadModeHelper.isStepModeEnabled() and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
    LEDHelper.setLEDState(NI.HW.LED_STEP, StepLedState)

end

------------------------------------------------------------------------------------------------------------------------

local function updateFixedVelocityLED()

    local FixedVelocityOn
    if PadModeHelper.isStepModeEnabled() then
        FixedVelocityOn = StepHelper.isFixedVelocity()
    else
        FixedVelocityOn = PadModeHelper.getPadVelocityMode() ~= NI.HW.PAD_VELOCITY_NORMAL
    end

    LEDHelper.setLEDState(NI.HW.LED_FIX_VELOCITY, FixedVelocityOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updatePageButtonLEDs()

    MaschineStudioController.updatePageButtonLEDs(self)

    updateFixedVelocityLED()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updatePadModeButtonLED()

    local LedState = LEDHelper.LS_OFF
    LEDHelper.setLEDState(NI.HW.LED_PAD_MODE, LedState)
    LEDHelper.setLEDState(NI.HW.LED_KEYBOARD, LedState)
    LEDHelper.setLEDState(NI.HW.LED_CHORDS, LedState)
    LEDHelper.setLEDState(NI.HW.LED_FIX_VELOCITY, LedState)

    if PadModeHelper.isStepModeEnabled() then
        -- Step button LED gets updated with updateStepButtonLED function
        return
    end

    -- Pad mode button leds
    if PadModeHelper.isChordModeEnabled() then
        LEDHelper.setLEDState(NI.HW.LED_CHORDS, LEDHelper.LS_BRIGHT)
    elseif PadModeHelper.getKeyboardMode() then
        LEDHelper.setLEDState(NI.HW.LED_KEYBOARD, LEDHelper.LS_BRIGHT)
    elseif not PadModeHelper.is16VelocityMode() then
        LEDHelper.setLEDState(NI.HW.LED_PAD_MODE, LEDHelper.LS_BRIGHT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:updateTouchstripModeLEDs()

    local TouchstripMode = NHLController:getContext():getTouchstripModeParameter():getValue()

    local LEDStatePitch = TouchstripMode == NI.HW.TS_MODE_PITCH
    LEDHelper.setLEDState(NI.HW.LED_PITCH, LEDStatePitch and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateMod = TouchstripMode == NI.HW.TS_MODE_MOD
    LEDHelper.setLEDState(NI.HW.LED_MOD, LEDStateMod and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStatePerform = TouchstripMode == NI.HW.TS_MODE_PERFORM
    LEDHelper.setLEDState(NI.HW.LED_PERFORM, LEDStatePerform and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateNotes = TouchstripMode == NI.HW.TS_MODE_NOTES
    LEDHelper.setLEDState(NI.HW.LED_NOTES, LEDStateNotes and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onTapTempo(Pressed)

    if not NI.APP.isStandalone() then
        return
    end

    if self:onTapTempoInfoBar(Pressed) then
        return
    end

    if Pressed then
        NHLController:onTapTempo()
    end

    self:updateMetroLED()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPadModeButton(Button, Pressed)

    local ShiftPressed = self:getShiftPressed()
    local PageStack = NHLController:getPageStack()
    local TopPage = PageStack:getTopPage()
    local IsOnModePage = MK3Helper.isPadModePage(TopPage)
    local NewModePage = MK3Helper.getPageForPadModeButton(Button)

    if Pressed then

        MK3Helper.setPadModeParametersByButton(Button)

    end

    if Pressed and TopPage ~= NewModePage and (IsOnModePage or not ShiftPressed) then

        if IsOnModePage then

            PageStack:popPage()

        end

        PageStack:pushPage(MK3Helper.getPageForPadModeButton(Button))

    elseif Pressed and TopPage == NewModePage then

        PageStack:popPage()

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onStepButton(Pressed)

    local ShiftPressed = self:getShiftPressed()
    local PageStack = NHLController:getPageStack()
    local TopPage = PageStack:getTopPage()
    local ShouldChangePage = MK3Helper.isPadModePage(TopPage) or TopPage == NI.HW.PAGE_REPEAT

    if Pressed then

        MK3Helper.setPadModeParametersByButton(NI.HW.BUTTON_STEP)

    end

   if Pressed and TopPage ~= NI.HW.PAGE_STEP_STUDIO and (ShouldChangePage or not ShiftPressed) then

        if ShouldChangePage then

            PageStack:popPage()

        end

        PageStack:pushPage(NI.HW.PAGE_STEP_STUDIO)

    elseif Pressed and TopPage == NI.HW.PAGE_STEP_STUDIO then

        PageStack:popPage()

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onFileButton(Pressed)

    local PageStack = NHLController:getPageStack()

    if NHLController:isInModalState() then
        return
    end

    if self:getShiftPressed() then

        if PageStack:getTopPage() ~= NI.HW.PAGE_FILE and PageStack:getTopPage() ~= NI.HW.PAGE_SAVE_AS then

            LEDHelper.updateButtonLED(self, NI.HW.LED_FILE, NI.HW.BUTTON_FILE, Pressed)

        end

        if Pressed then

            local InfoBarTempMode = NHLController:getPageStack():getTopPage() == NI.HW.PAGE_FILE and "FilePageProjectSaved"
            MaschineHelper.saveProject(self:getInfoBar(), InfoBarTempMode)

        end

    else

        MaschineControllerMK3.onPageButton(self, NI.HW.BUTTON_FILE, NI.HW.PAGE_FILE, Pressed)

    end

end


------------------------------------------------------------------------------------------------------------------------

local function updateStepPageScreenButtons(Controller)

    if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_STEP_STUDIO then
        local StepPage = Controller:getPage(NI.HW.PAGE_STEP_STUDIO)
        if StepPage then
            StepPage:updateScreenButtons(false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onFollowButton(Pressed)

    if not Pressed then
        return
    end

    if PadModeHelper.isStepModeEnabled() then
        StepHelper.FollowModeOn = not StepHelper.FollowModeOn
        updateStepPageScreenButtons(self)
    else
        ArrangerHelper.toggleFollowMode()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onWheelButton(Pressed)

    HardwareControllerBase.onWheelButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

local function resetInfoBar(InfoBar)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
        if InfoBar then
            InfoBar:resetTempMode()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onVolumeButton(Pressed)

    HardwareControllerBase.onVolumeButton(self, Pressed)
    resetInfoBar(self:getInfoBar())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onTempoButton(Pressed)

    HardwareControllerBase.onTempoButton(self, Pressed)
    resetInfoBar(self:getInfoBar())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onSwingButton(Pressed)

    HardwareControllerBase.onSwingButton(self, Pressed)
    resetInfoBar(self:getInfoBar())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onStopButton(Pressed)

    if self.ActivePage:onStopButton(Pressed) then
        return
    end

    self.TransportSection:onStop(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

local function setTouchstripMode(Mode)

    local TouchstripModeParameter = NHLController:getContext():getTouchstripModeParameter()
    local NewMode = Mode == TouchstripModeParameter:getValue() and NI.HW.TS_MODE_OFF or Mode
    NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, TouchstripModeParameter, NewMode)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPitchButton(Pressed)

    if Pressed then
        setTouchstripMode(NI.HW.TS_MODE_PITCH)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onModButton(Pressed)

    if Pressed then
        setTouchstripMode(NI.HW.TS_MODE_MOD)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onPerformButton(Pressed)

    if Pressed then

        local ShiftPressed = self:getShiftPressed()

        if ShiftPressed then
            NHLController:getPageStack():pushPage(NI.HW.PAGE_CONTROL)
            NI.DATA.SongAccess.loadPerformanceFX(App, true)
        end

        local TogglePerfomMode = (getTouchstripMode() == NI.HW.TS_MODE_PERFORM and not ShiftPressed)
            or (getTouchstripMode() ~= NI.HW.TS_MODE_PERFORM)

        if TogglePerfomMode then
            setTouchstripMode(NI.HW.TS_MODE_PERFORM)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onNotesButton(Pressed)

    if Pressed then
        setTouchstripMode(NI.HW.TS_MODE_NOTES)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onDuplicateButton(Pressed)

    if self:getShiftPressed() and Pressed then
        NI.DATA.EventPatternAccess.doubleFocusPatternOrClipEvent(App)
    else
        MaschineStudioController.onDuplicateButton(self, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onTouchEvent(TouchID, TouchType, Value)

    self.TouchstripController:onTouchEvent(TouchID, TouchType, Value)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onFixedVelocityButton(Pressed)

    if not Pressed then
        return
    end

    local ShiftPressed = self:getShiftPressed()
    local StepModeEnabled = PadModeHelper.isStepModeEnabled()
    local PageStack = NHLController:getPageStack()
    local TopPage = PageStack:getTopPage()
    local IsPadModePage = MK3Helper.isPadModePage(TopPage)

    if ShiftPressed then

        if not PadModeHelper.is16VelocityMode() then

            MK3Helper.setPadModeParametersByButton(NI.HW.BUTTON_PAD_MODE)
            PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_16_LEVELS)

            if IsPadModePage and TopPage ~= NI.HW.PAGE_SIXTEEN_VEL then

                PageStack:replacePage(TopPage, NI.HW.PAGE_SIXTEEN_VEL)

            end

        else

            PageStack:popPage()

        end

    elseif StepModeEnabled then

        StepHelper.toggleFixedVelocity()

    elseif TopPage == NI.HW.PAGE_SIXTEEN_VEL then

        PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_16_LEVELS)
        PageStack:replacePage(TopPage, NI.HW.PAGE_PAD)

    else

        PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_FIXED)

    end

    updateFixedVelocityLED()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineControllerMK3:onVariationButton(Pressed)

    local PageID = Pressed
        and (self:getShiftPressed() and NI.HW.PAGE_NAVIGATE or NI.HW.PAGE_VARIATION)
        or  MaschineHelper.findFirstPageInStack({NI.HW.PAGE_NAVIGATE, NI.HW.PAGE_VARIATION})

    if not PageID then -- can be nil if other pushed pages resulted in popping these pages before this page button released
        PageID = NI.HW.PAGE_VARIATION
    end

    MaschineControllerMK3.onPageButton(self, NI.HW.BUTTON_VARIATION, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
-- The Instance
ControllerScriptInterface = MaschineControllerMK3()

------------------------------------------------------------------------------------------------------------------------

