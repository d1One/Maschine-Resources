------------------------------------------------------------------------------------------------------------------------
-- Maschine Studio Controller
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/HardwareControllerBase"
require "Scripts/Maschine/MaschineStudio/LevelMeterStudio"
require "Scripts/Maschine/MaschineStudio/QuickEditStudio"
require "Scripts/Maschine/MaschineStudio/FootswitchStudio"
require "Scripts/Maschine/Helper/JogwheelLEDHelper"
require "Scripts/Maschine/Components/CapacitiveOverlayNavIcons"

require "Scripts/Shared/Components/CapacitiveOverlayList"
require "Scripts/Shared/Components/SlotStackStudio"
require "Scripts/Shared/Components/TransportSection"
require "Scripts/Shared/Helpers/EventsHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

require "Scripts/Maschine/MaschineStudio/Shared/ArrangerItemStudio"
require "Scripts/Maschine/MaschineStudio/Shared/ClipEditorStudio"
require "Scripts/Maschine/MaschineStudio/Shared/PatternEditorStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MaschineStudioController = class( 'MaschineStudioController', HardwareControllerBase )

------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------

MaschineStudioController.SCREEN_BUTTON_LEDS =
{
    NI.HW.LED_SCREEN_BUTTON_1,
    NI.HW.LED_SCREEN_BUTTON_2,
    NI.HW.LED_SCREEN_BUTTON_3,
    NI.HW.LED_SCREEN_BUTTON_4,
    NI.HW.LED_SCREEN_BUTTON_5,
    NI.HW.LED_SCREEN_BUTTON_6,
    NI.HW.LED_SCREEN_BUTTON_7,
    NI.HW.LED_SCREEN_BUTTON_8
}

MaschineStudioController.SCREEN_BUTTONS =
{
    NI.HW.BUTTON_SCREEN_1,
    NI.HW.BUTTON_SCREEN_2,
    NI.HW.BUTTON_SCREEN_3,
    NI.HW.BUTTON_SCREEN_4,
    NI.HW.BUTTON_SCREEN_5,
    NI.HW.BUTTON_SCREEN_6,
    NI.HW.BUTTON_SCREEN_7,
    NI.HW.BUTTON_SCREEN_8
}

MaschineStudioController.GROUP_LEDS =
{
    NI.HW.LED_GROUP_A,
    NI.HW.LED_GROUP_B,
    NI.HW.LED_GROUP_C,
    NI.HW.LED_GROUP_D,
    NI.HW.LED_GROUP_E,
    NI.HW.LED_GROUP_F,
    NI.HW.LED_GROUP_G,
    NI.HW.LED_GROUP_H
}

MaschineStudioController.JOGWHEEL_RING_LEDS =
{
    NI.HW.LED_JOGWHEEL_RING_1,
    NI.HW.LED_JOGWHEEL_RING_2,
    NI.HW.LED_JOGWHEEL_RING_3,
    NI.HW.LED_JOGWHEEL_RING_4,
    NI.HW.LED_JOGWHEEL_RING_5,
    NI.HW.LED_JOGWHEEL_RING_6,
    NI.HW.LED_JOGWHEEL_RING_7,
    NI.HW.LED_JOGWHEEL_RING_8,
    NI.HW.LED_JOGWHEEL_RING_9,
    NI.HW.LED_JOGWHEEL_RING_10,
    NI.HW.LED_JOGWHEEL_RING_11,
    NI.HW.LED_JOGWHEEL_RING_12,
    NI.HW.LED_JOGWHEEL_RING_13,
    NI.HW.LED_JOGWHEEL_RING_14,
    NI.HW.LED_JOGWHEEL_RING_15
}

MaschineStudioController.LEVELMETER_LEFT_LEDS =
{
    NI.HW.LED_LEVEL_LEFT_1,
    NI.HW.LED_LEVEL_LEFT_2,
    NI.HW.LED_LEVEL_LEFT_3,
    NI.HW.LED_LEVEL_LEFT_4,
    NI.HW.LED_LEVEL_LEFT_5,
    NI.HW.LED_LEVEL_LEFT_6,
    NI.HW.LED_LEVEL_LEFT_7,
    NI.HW.LED_LEVEL_LEFT_8,
    NI.HW.LED_LEVEL_LEFT_9,
    NI.HW.LED_LEVEL_LEFT_10,
    NI.HW.LED_LEVEL_LEFT_11,
    NI.HW.LED_LEVEL_LEFT_12,
    NI.HW.LED_LEVEL_LEFT_13,
    NI.HW.LED_LEVEL_LEFT_14,
    NI.HW.LED_LEVEL_LEFT_15,
    NI.HW.LED_LEVEL_LEFT_16
}

MaschineStudioController.LEVELMETER_RIGHT_LEDS =
{
    NI.HW.LED_LEVEL_RIGHT_1,
    NI.HW.LED_LEVEL_RIGHT_2,
    NI.HW.LED_LEVEL_RIGHT_3,
    NI.HW.LED_LEVEL_RIGHT_4,
    NI.HW.LED_LEVEL_RIGHT_5,
    NI.HW.LED_LEVEL_RIGHT_6,
    NI.HW.LED_LEVEL_RIGHT_7,
    NI.HW.LED_LEVEL_RIGHT_8,
    NI.HW.LED_LEVEL_RIGHT_9,
    NI.HW.LED_LEVEL_RIGHT_10,
    NI.HW.LED_LEVEL_RIGHT_11,
    NI.HW.LED_LEVEL_RIGHT_12,
    NI.HW.LED_LEVEL_RIGHT_13,
    NI.HW.LED_LEVEL_RIGHT_14,
    NI.HW.LED_LEVEL_RIGHT_15,
    NI.HW.LED_LEVEL_RIGHT_16
}

------------------------------------------------------------------------------------------------------------------------

MaschineStudioController.GROUP_BUTTONS =
{
    NI.HW.BUTTON_GROUP_A,
    NI.HW.BUTTON_GROUP_B,
    NI.HW.BUTTON_GROUP_C,
    NI.HW.BUTTON_GROUP_D,
    NI.HW.BUTTON_GROUP_E,
    NI.HW.BUTTON_GROUP_F,
    NI.HW.BUTTON_GROUP_G,
    NI.HW.BUTTON_GROUP_H
}

MaschineStudioController.BUTTON_TO_PAGE =
{
    [NI.HW.BUTTON_CONTROL]      = NI.HW.PAGE_CONTROL,
    [NI.HW.BUTTON_STEP]         = NI.HW.PAGE_STEP,
    [NI.HW.BUTTON_BROWSE]       = NI.HW.PAGE_BROWSE,
    [NI.HW.BUTTON_SAMPLE]       = NI.HW.PAGE_SAMPLING,
    [NI.HW.BUTTON_ARRANGE]      = NI.HW.PAGE_ARRANGER,
    [NI.HW.BUTTON_MIX]          = NI.HW.PAGE_MIXER,

    [NI.HW.BUTTON_SCENE]        = NI.HW.PAGE_SCENE,
    [NI.HW.BUTTON_PATTERN]      = NI.HW.PAGE_PATTERN,
    [NI.HW.BUTTON_PAD_MODE]     = NI.HW.PAGE_PAD,
    [NI.HW.BUTTON_NAVIGATE]     = NI.HW.PAGE_NAVIGATE,
    [NI.HW.BUTTON_DUPLICATE]    = NI.HW.PAGE_DUPLICATE,
    [NI.HW.BUTTON_SELECT]       = NI.HW.PAGE_SELECT,
    [NI.HW.BUTTON_SOLO]         = NI.HW.PAGE_SOLO,
    [NI.HW.BUTTON_MUTE]         = NI.HW.PAGE_MUTE,

    [NI.HW.BUTTON_NOTE_REPEAT]      = NI.HW.PAGE_REPEAT,
    [NI.HW.BUTTON_TRANSPORT_GRID]   = NI.HW.PAGE_GRID,
    [NI.HW.BUTTON_TRANSPORT_EVENTS] = NI.HW.PAGE_EVENTS,
    [NI.HW.BUTTON_STEP]				= NI.HW.PAGE_STEP_STUDIO
}

------------------------------------------------------------------------------------------------------------------------

MaschineStudioController.MODIFIER_PAGES =
{
    NI.HW.PAGE_DUPLICATE,
    NI.HW.PAGE_GRID,
    NI.HW.PAGE_MUTE,
    NI.HW.PAGE_PAD,
    NI.HW.PAGE_NAVIGATE,
    NI.HW.PAGE_PAGE,
    NI.HW.PAGE_SCENE,
    NI.HW.PAGE_PATTERN,
    NI.HW.PAGE_REPEAT,
    NI.HW.PAGE_SELECT,
    NI.HW.PAGE_EVENTS,
    NI.HW.PAGE_SOLO,
    NI.HW.PAGE_VARIATION
}

MaschineStudioController.LEDValues = {
--  LS_OFF          LS_DIM          LS_DIM_FLASH    LS_BRIGHT       LS_FLASH
    {0.0,           0.25,            1,              1,              1}       --  LVG_MAIN
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:__init()

    -- contruct base class
    HardwareControllerBase.__init(self)

    self.LevelMeter = LevelMeterStudio(self)
    self.QuickEdit = QuickEditStudio(self)
    self.Footswitch = FootswitchStudio(self)
    self.CapacitiveList = CapacitiveOverlayList(self)
    self.CapacitiveNavIcons = CapacitiveOverlayNavIcons(self)

    -- create Shared Objects and Maschine pages
    self:createSharedObjects()
    self:createPages()

    self.hasJogwheelControls = function() return true end
    self.hasEditControls = function() return true end

    LEDHelper.LEDValues = MaschineStudioController.LEDValues

    NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:createPages()

    -- register pages
    local Folder = "Scripts/Maschine/MaschineStudio/Pages/"
    local FolderShared = "Scripts/Shared/Pages/"
    local Pages = self.PageManager

    -- main pages
    Pages:register(NI.HW.PAGE_CONTROL,   FolderShared .. "ControlPageStudio",   "ControlPageStudio", true)
    Pages:register(NI.HW.PAGE_BROWSE,    Folder .. "BrowsePageStudio",    "BrowsePageStudio", true)
    Pages:register(NI.HW.PAGE_MODULE,    Folder .. "ModulePageStudio",    "ModulePageStudio", true)
    Pages:register(NI.HW.PAGE_SAMPLING,  Folder .. "SamplingPageStudio",  "SamplingPageStudio", true)
    Pages:register(NI.HW.PAGE_ARRANGER,  Folder .. "ArrangerPageStudio",  "ArrangerPageStudio", true)
    Pages:register(NI.HW.PAGE_MIXER,     Folder .. "MixerPageStudio",     "MixerPageStudio", true)

    -- modifier pages
    Pages:register(NI.HW.PAGE_SCENE,     Folder .. "SceneForwardPageStudio",     "SceneForwardPageStudio", true)
    Pages:register(NI.HW.PAGE_PATTERN,   Folder .. "PatternPageStudio",   "PatternPageStudio", true)
    Pages:register(NI.HW.PAGE_PAD,       Folder .. "PadModePageStudio",   "PadModePageStudio", true)
    Pages:register(NI.HW.PAGE_NAVIGATE,  Folder .. "NavigatePageStudio",  "NavigatePageStudio", true)
    Pages:register(NI.HW.PAGE_DUPLICATE, Folder .. "DuplicatePageStudio", "DuplicatePageStudio", true)
    Pages:register(NI.HW.PAGE_SELECT,    Folder .. "SelectPageStudio",    "SelectPageStudio", true)
    Pages:register(NI.HW.PAGE_SOLO,      Folder .. "SoloPageStudio",      "SoloPageStudio", true)
    Pages:register(NI.HW.PAGE_MUTE,      Folder .. "MutePageStudio",      "MutePageStudio", true)

    Pages:register(NI.HW.PAGE_REPEAT,    Folder .. "RepeatPageStudio",    "RepeatPageStudio", true)
    Pages:register(NI.HW.PAGE_GRID,      Folder .. "GridPageStudio",      "GridPageStudio", true)
    Pages:register(NI.HW.PAGE_EVENTS,    Folder .. "EventsPageStudio",    "EventsPageStudio", true)
    Pages:register(NI.HW.PAGE_VARIATION, Folder .. "VariationPageStudio", "VariationPageStudio", true)

    -- other pages
    Pages:register(NI.HW.PAGE_STEP_MOD,       Folder .. "StepPageModStudio",      "StepPageModStudio", true)
    Pages:register(NI.HW.PAGE_REC_MODE,       Folder .. "RecModePageStudio",      "RecModePageStudio", true)
    Pages:register(NI.HW.PAGE_PATTERN_LENGTH, Folder .. "PatternLengthPageStudio","PatternLengthPageStudio")
    Pages:register(NI.HW.PAGE_LOOP,           Folder .. "LoopPageStudio",         "LoopPageStudio")
    Pages:register(NI.HW.PAGE_BUSY,           FolderShared .. "BusyPageStudio",   "BusyPageStudio")
    Pages:register(NI.HW.PAGE_MACRO,          FolderShared .. "MacroPageStudio",  "MacroPageStudio", true)
    Pages:register(NI.HW.PAGE_STEP_STUDIO,    Folder .. "StepPageStudio",         "StepPageStudio", true)
    Pages:register(NI.HW.PAGE_SNAPSHOTS,      Folder .. "SnapshotsPageStudio",    "SnapshotsPageStudio")
    Pages:register(NI.HW.PAGE_MODAL_DIALOG, FolderShared .. "Dialogs/ModalDialogPage", "ModalDialogPage", true)
    Pages:register(NI.HW.PAGE_SAVE_DIALOG, Folder .. "SaveDialogPageStudio", "SaveDialogPageStudio", true)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:createSharedObjects()

    self.SharedObjects = {}

    -- slot stack: used in the Control Pages, navigate, Module Browser and StepMod Page
    self.SharedObjects.SlotStack = SlotStackStudio(MaschineHelper.getFocusMixingLayerColor)

    -- Arranger: used in the Arranger/Song and the Scene and Pattern pages
    self.SharedObjects.Arranger = ArrangerItemStudio("ArrangerRight")
    self.SharedObjects.ArrangerOverview = ArrangerItemStudio("ArrangerLeft", self.SharedObjects.Arranger)

    -- Clip Editor
    self.SharedObjects.ClipEditor = ClipEditorStudio("ClipEditor")

    -- Pattern Editor: Arranger/Pattern, Arranger/Events, Note Repeat, Events
    self.SharedObjects.PatternEditor = PatternEditorStudio("PatternEditorRight")
    self.SharedObjects.PatternEditorOverview = PatternEditorStudio("PatternEditorLeft", self.SharedObjects.PatternEditor)

    -- insert all shared objects in the root stack - here they remain before their first use
    for Idx, Object in pairs(self.SharedObjects) do
        Object:insertInto(NHLController:getHardwareDisplay():getSharedRoot())
    end

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen button handler
------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:setupButtonHandler()

    -- setup common handlers in base class
    HardwareControllerBase.setupButtonHandler(self)

    --  MaschineMK1 and MaschineMK2 buttons
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_1] = function(Pressed) self:onScreenButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_2] = function(Pressed) self:onScreenButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_3] = function(Pressed) self:onScreenButton(3, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_4] = function(Pressed) self:onScreenButton(4, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_5] = function(Pressed) self:onScreenButton(5, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_6] = function(Pressed) self:onScreenButton(6, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_7] = function(Pressed) self:onScreenButton(7, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_8] = function(Pressed) self:onScreenButton(8, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_CAP_1] = function(Touched) self:onCapTouched(1, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_2] = function(Touched) self:onCapTouched(2, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_3] = function(Touched) self:onCapTouched(3, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_4] = function(Touched) self:onCapTouched(4, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_5] = function(Touched) self:onCapTouched(5, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_6] = function(Touched) self:onCapTouched(6, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_7] = function(Touched) self:onCapTouched(7, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_8] = function(Touched) self:onCapTouched(8, Touched) end

    self.SwitchHandler[NI.HW.BUTTON_GROUP_A] = function(Pressed) self:onGroupButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_B] = function(Pressed) self:onGroupButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_C] = function(Pressed) self:onGroupButton(3, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_D] = function(Pressed) self:onGroupButton(4, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_E] = function(Pressed) self:onGroupButton(5, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_F] = function(Pressed) self:onGroupButton(6, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_G] = function(Pressed) self:onGroupButton(7, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_H] = function(Pressed) self:onGroupButton(8, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_AUTO_WRITE] = function(Pressed) self:onAutoWriteButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TAP] = function(Pressed) self:onTapButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_VOLUME] =  function(On) self:onVolumeButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_SWING]  =  function(On) self:onSwingButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_TEMPO]  =  function(On) self:onTempoButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_ENTER]  =  function(On) self:onEnterButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_BACK]   =  function(On) self:onBackButton(On) end

    self.SwitchHandler[NI.HW.BUTTON_CHANNEL] = function(Pressed) self:onControlButton(Pressed, NI.HW.BUTTON_CHANNEL) end
    self.SwitchHandler[NI.HW.BUTTON_PLUGIN]  = function(Pressed) self:onControlButton(Pressed, NI.HW.BUTTON_PLUGIN) end
    self.SwitchHandler[NI.HW.BUTTON_MACRO]	= function(Pressed) self:onMacroButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_STEP]	= function(Pressed) self:onStepButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_LEVEL_IN1]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_IN1) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_IN2]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_IN2) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_IN3]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_IN3) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_IN4]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_IN4) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_MASTER]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_MASTER) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_GROUP]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_GROUP) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_SOUND]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_SOUND) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL_CUE]  = function(Pressed) self:onLevelSourceButton(Pressed, NI.HW.BUTTON_LEVEL_CUE) end

    self.SwitchHandler[NI.HW.BUTTON_EDIT_COPY]     = function(Pressed) self:onCopyButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_PASTE]    = function(Pressed) self:onPasteButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_NOTE]     = function(Pressed) self:onNoteButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_NUDGE]    = function(Pressed) self:onNudgeButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_UNDO]     = function(Pressed) self:onUndoButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_REDO]     = function(Pressed) self:onRedoButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_QUANTIZE] = function(Pressed) self:onQuantizeButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_EDIT_CLEAR]    = function(Pressed) self:onClearButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_FOOT1_DETECT]    = function(Pressed) self:onFootswitchDetect(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT1_TIP]       = function(Pressed) self:onFootswitchTip(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT1_RING]      = function(Pressed) self:onFootswitchRing(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT2_DETECT]    = function(Pressed) self:onFootswitchDetect(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT2_TIP]       = function(Pressed) self:onFootswitchTip(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_FOOT2_RING]      = function(Pressed) self:onFootswitchRing(2, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PATTERN]      = function(Pressed) self:onPatternButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCENE]      = function(Pressed) self:onSceneButton(Pressed) end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onCustomProcess(ForceUpdate)

    self.CapacitiveList:update()
    HardwareControllerBase.onCustomProcess(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- Timer
------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onControllerTimer()

    if self.LevelMeter then
        self.LevelMeter:onTimer()
    end

    if self.Footswitch then
        self.Footswitch:onTimer()
    end

    if self.ActivePage then
        local Page = self.ActivePage.CurrentPage or self.ActivePage
        if Page and Page.Screen then
            Page.Screen:onTimer()
        end
    end


    -- Capacitive controls and overlay
    self.CapacitiveList:onTimer()
    self.CapacitiveNavIcons:onTimer()

    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()
    local ShowOverlayRoot = self.CapacitiveList:isVisible() or self.CapacitiveNavIcons:isVisible()
    if ShowOverlayRoot ~= OverlayRoot:isVisible() then
        OverlayRoot:setVisible(ShowOverlayRoot)
    end

    if self.hasJogwheelControls() then
        self:updateJogwheel()
    end

    if self.hasEditControls() then
        self:updateEditControlLEDs()
    end

    -- updates CHANNEL/PLUG-IN LEDs
    local Workspace = App:getWorkspace()
    local ChannelMode = not Workspace:getModulesVisibleParameter():getValue()
    LEDHelper.setLEDState(NI.HW.LED_CHANNEL, ChannelMode and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_PLUGIN, ChannelMode and LEDHelper.LS_OFF or LEDHelper.LS_BRIGHT)

    -- updates METRO LED
    self:updateMetroLED()

    -- base class
    HardwareControllerBase.onControllerTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateMetroLED()

    local IsMetroOn = App:getMetronome():getEnabledParameter():getValue()
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_METRO, IsMetroOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPageShow(Show)

    -- reset overlays before showing the page
    self.CapacitiveList:reset()
    self.CapacitiveNavIcons:reset()

    -- call base
    HardwareControllerBase.onPageShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updatePageButtonLEDs()

    -- call base
    HardwareControllerBase.updatePageButtonLEDs(self)

    self:updateMacroButtonLED(self)
    self:updateStepButtonLED(self)

end

------------------------------------------------------------------------------------------------------------------------

local function getLedStateForPage(PageID)

    if NHLController:getPageStack():getTopPage() == PageID then
        return LEDHelper.LS_BRIGHT
    elseif NHLController:getPageStack():isPageInStack(PageID) then
        return LEDHelper.LS_DIM
    else
        return LEDHelper.LS_OFF
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateMacroButtonLED()

    local LedState = NHLController:getPageStack():getTopPage() == NI.HW.PAGE_CONTROL
        and (NI.DATA.ParameterPageAccess.isMacroPageActive(App) and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        or  getLedStateForPage(NI.HW.PAGE_MACRO)

    LEDHelper.setLEDState(NI.HW.LED_MACRO, LedState)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateStepButtonLED()

    LEDHelper.setLEDState(NI.HW.LED_STEP, getLedStateForPage(NI.HW.PAGE_STEP_STUDIO))

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateSwitchLEDs()

    self:updateVolumeTempoSwingButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------
-- Pad/Group Handler
------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPadEvent(PadIndex, Trigger, PadValue)

    if not self.ActivePage then
        return
    end

    -- QuickEdit: always checked
    self.QuickEdit:onPadEvent(PadIndex, Trigger)

    -- PRIO 1: Page
    local Handled = self.ActivePage:onPadEvent(PadIndex, Trigger, PadValue)

    -- then Shift stuff
    if not Handled and self:getShiftPressed() then
        MaschineHelper.onPadEventShift(PadIndex, Trigger, self:getErasePressed(), true)
    else
        self.CachedPadStates[PadIndex] = Trigger
    end

    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onGroupButton(Index, Pressed)

    if not self.ActivePage then
        return
    end

    -- PRIO 1: Page
    if self.ActivePage:onGroupButton(Index, Pressed) then
        return
    end

    -- QuickEdit: always checked
    self.QuickEdit:onGroupButton(Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPageButton(Button, PageID, Pressed)

    if PageID == NI.HW.PAGE_STEP_STUDIO or PageID == NI.HW.PAGE_MACRO then

        -- special handling for these (shortcut) pages because they're part modifier and part non-modifier pages.
        -- they're modifier pages in that they need to go on top of non-modifier pages, and
        -- they're non-modifier pages in that only one of them can be on the stack at a time, and they force all other
        -- modifier pages off the stack.
        if Pressed then
            if NHLController:getPageStack():getTopPage() == PageID then

                NHLController:getPageStack():popPage() -- page is current one, so leave it

            else

                -- pop all modifier pages
                while self:isModifierPageByID(NHLController:getPageStack():getTopPage()) do
                    NHLController:getPageStack():popPage()
                end

                -- if we don't end up with our page at the top, then push it real good
                if NHLController:getPageStack():getTopPage() ~= PageID then
                    NHLController:getPageStack():pushPage(PageID)
                end

            end

        end

        self:updatePageSync()

    else

        -- default behavior
        return HardwareControllerBase.onPageButton(self, Button, PageID, Pressed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:getShiftPageID(Button, CurPageID, Pressed)

    if Button == NI.HW.BUTTON_PATTERN then -- overwrite base class behaviour
        return NI.HW.PAGE_PATTERN
    end

    return HardwareControllerBase.getShiftPageID(self, Button, CurPageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPageButtonShift(Button, Pressed)

    -- [SHIFT] + [NOTE_REPEAT] = Toggle Note Repeat
    if Pressed and Button == NI.HW.BUTTON_NOTE_REPEAT then
        MaschineHelper.toggleArpRepeatLockState()
        LEDHelper.setLEDState(NI.HW.LED_NOTE_REPEAT, LEDHelper.LS_DIM)
        return true
    end
    return HardwareControllerBase.onPageButtonShift(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onControlButton(Pressed, Button)

    local TopPage = NHLController:getPageStack():getTopPage()

    if Pressed then
        -- set modules visible parameter
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(
            App, App:getWorkspace():getModulesVisibleParameter(), Button == NI.HW.BUTTON_PLUGIN)
        App:getWorkspace():saveModulesVisibleState()
    end

    -- do not switch in this case
    if TopPage == NI.HW.PAGE_CONTROL or
        (TopPage == NI.HW.PAGE_NAVIGATE and
        self.ActivePage:isPageNav()) then

        return
    end

    HardwareControllerBase.onPageButton(self, Button, NI.HW.PAGE_CONTROL, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onStepButton(Pressed)

    if Pressed then
        if NHLController:getPageStack():isPageInStack(NI.HW.PAGE_MACRO) then
            -- Step Mode and Macro pages can't be on the stack at the same time.
            NHLController:getPageStack():removePage(NI.HW.PAGE_MACRO)
        end
    end

    self:onPageButton(NI.HW.BUTTON_STEP, NI.HW.PAGE_STEP_STUDIO, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onMacroButton(Pressed)

    if self:getShiftPressed() then
        -- Demo page access (dev only)
        -- return HardwareControllerBase.onPageButton(self, NI.HW.BUTTON_MACRO, NI.HW.PAGE_DEMO, Pressed)
    end

    if Pressed then
        if NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP_STUDIO) then
            -- Step Mode and Macro pages can't be on the stack at the same time.
            NHLController:getPageStack():removePage(NI.HW.PAGE_STEP_STUDIO)
        end
    end

    self:onPageButton(NI.HW.BUTTON_MACRO, NI.HW.PAGE_MACRO, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onLevelSourceButton(Pressed, Button)

    if not Pressed then
        return
    end

    if Pressed and (Button == NI.HW.BUTTON_LEVEL_CUE or Button == NI.HW.BUTTON_LEVEL_MASTER) then
        local Workspace = App:getWorkspace()
         NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Workspace:getMixerCueVisibleParameter(),
            Button == NI.HW.BUTTON_LEVEL_CUE)
    end

    if self.ActivePage and self.ActivePage.onLevelSourceButton and
        self.ActivePage:onLevelSourceButton(Pressed, Button) then
        return
    end

    self.LevelMeter:onLevelSourceButton(Pressed, Button)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onLevelEncoder(EncoderInc)

    -- custom Level encoder handling
    if self.ActivePage and self.ActivePage.onLevelEncoder and
        self.ActivePage:onLevelEncoder(EncoderInc) then
        return
    end

    self.LevelMeter:onLevelEncoder(EncoderInc)

    local InfoBar = self:getInfoBar()
    if InfoBar then
        InfoBar:setTempMode("LevelMeter")
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onWheelEvent(WheelID, WheelInc)

    -- Current page gets 1st priority
    if self.ActivePage and self.ActivePage:onWheel(WheelInc) then
        if self.ActivePage.refreshAccessibleWheelInfo then
            self.ActivePage:refreshAccessibleWheelInfo()
        end
        return
    end

    -- Then QuickEdit...
    if self.QuickEdit:onWheel(WheelInc) then

        local InfoBar = self:getInfoBar()
        if InfoBar then

            -- master tempo: reset tempo taps and set the mode straight to tempo
            if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_TEMPO and self.SwitchPressed[NI.HW.BUTTON_TAP] then

                NHLController:resetTapTempo()
                InfoBar:setTempMode("TEMPO", false) --temp mode, but unlimited time for the display (until tap button is released)

            elseif NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_NOTENUDGE then
                -- do not display anything in case of NoteEdit Mode for now
            else
                self:showQuickEdit()
            end
        end

        -- accessibility
        self.ActivePage:refreshAccessibleWheelInfo()

        return
    end

    -- and finally transport
    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT then
        print("WARNING: JOGWHEEL MODE SHOULD BE DEFAULT HERE :"..NHLController:getJogWheelMode())
    end

    self.TransportSection:onWheel(WheelInc)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onWheelButton(Pressed)

    if self.ActivePage then

        -- PRIO 1: Page
        if self.ActivePage:onWheelButton(Pressed) then
            return
        end

        -- PRIO 2: QE
        self.QuickEdit:onWheelButton(Pressed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPrevNextButton(Pressed, Next)

    -- Prio 1: Transport Erase + Loop Buttons
    local LoopPressed  = self.SwitchPressed[NI.HW.BUTTON_TRANSPORT_LOOP] and self:getShiftPressed()
    if self:getErasePressed() or LoopPressed then
        self.TransportSection:onPrevNext(Pressed, Next)
        return
    end

    if self.ActivePage then

        -- Prio 2: Active Page
        if self.ActivePage:onPrevNextButton(Pressed, Next) then
            return
        end

        -- Prio 3: Quick Edit
        if self.QuickEdit:onPrevNextButton(Pressed, Next) then
            return
        end

    end

    -- Prio 4: Transport Scrub
    self.TransportSection:onPrevNext(Pressed, Next)

end


------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onCapTouched(Cap, Touched)

    if not NHLController:getCapacitiveFeaturesEnabled() then
        return
    end

    if Touched then
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, Cap)
    end

    CapacitiveHelper.onCapTouched(Cap, Touched)

    if self.ActivePage and self.ActivePage.onCapTouched then
        self.ActivePage:onCapTouched(Cap, Touched)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onTapButton(Pressed)

    if not NI.APP.isStandalone() then
        return
    end

    LEDHelper.updateButtonLED(self, NI.HW.LED_TAP, NI.HW.BUTTON_TAP, Pressed)

    if self:onTapTempoInfoBar(Pressed) then
        return
    end

    if self.ActivePage and self.QuickEdit:onTapButton(Pressed) then
        return
    end

    if Pressed then
        NHLController:onTapTempo()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onTapTempoInfoBar(Pressed)

    local InfoBar = self:getInfoBar()
    if InfoBar then
        if Pressed then
            InfoBar:setTempMode("TEMPO", false)
        else
            if InfoBar.Mode == "TEMPO" then
                InfoBar:setTempMode("TEMPO") -- tap button released: reset after a timeout
            else
                return true -- the mode has changed since the button was pressed.... leave
            end
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateJogwheel()

    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_EDIT, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_CHANNEL, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_BROWSE, LEDHelper.LS_OFF)

    local LoopPressed  = self.SwitchPressed[NI.HW.BUTTON_TRANSPORT_LOOP] and self:getShiftPressed()

    -- Priority 1: Erase / Loop Buttons
    if self:getErasePressed() and NI.APP.isStandalone() then
        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)
        return
    end

    -- Priority 2: Quick Edit
    if self.ActivePage and self.QuickEdit:update() then
        return
    end

    -- Priority 3: Active Page
    if self.ActivePage and self.ActivePage.updateJogwheel and self.ActivePage:updateJogwheel() then
        return
    end

    -- Default JW LED behaviour
    JogwheelLEDHelper.updateAllOff(MaschineStudioController.JOGWHEEL_RING_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:getInfoBar()

    if not self.ActivePage then
        return nil
    end

    local Page = self.ActivePage.CurrentPage or self.ActivePage
    return Page and Page.Screen and Page.Screen.ScreenLeft and Page.Screen.ScreenLeft.InfoBar

end

------------------------------------------------------------------------------------------------------------------------
-- EDIT CONTROLS
------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:updateEditControlLEDs()

    local ButtonState
    local HasEvents = ActionHelper.hasEvents()

    -- Copy
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_COPY] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_COPY, HasEvents and ButtonState or LEDHelper.LS_OFF)

    -- Paste
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_PASTE] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_PASTE, ActionHelper.canPaste() and ButtonState or LEDHelper.LS_OFF)

    -- Note (Pitch)
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_NOTE] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_NOTE, HasEvents and ButtonState or LEDHelper.LS_OFF)

    -- Nudge
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_NUDGE] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_NUDGE, HasEvents and ButtonState or LEDHelper.LS_OFF)

    -- Undo
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_UNDO] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_UNDO, ActionHelper.canUndo(self:getShiftPressed()) and ButtonState or LEDHelper.LS_OFF)

    -- Redo
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_REDO] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_REDO, ActionHelper.canRedo(self:getShiftPressed()) and ButtonState or LEDHelper.LS_OFF)

    -- Quantize
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_QUANTIZE] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_QUANTIZE, HasEvents and ButtonState or LEDHelper.LS_OFF)

    -- Clear
    ButtonState = self.SwitchPressed[NI.HW.BUTTON_EDIT_CLEAR] and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    LEDHelper.setLEDState(NI.HW.LED_EDIT_CLEAR, HasEvents and ButtonState or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onCopyButton(Pressed)

    if Pressed and ActionHelper.hasEvents() then
        NI.DATA.NoteEventClipboardAccess.copySelectedNoteEvents(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPasteButton(Pressed)

    if Pressed and ActionHelper.canPaste() then
        NI.DATA.NoteEventClipboardAccess.pasteNoteEvents(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onNoteButton(Pressed)

    -- [SHIFT] + [NOTE] = PAGE_VARIATION
    if self:getShiftPressed() or NHLController:getPageStack():getTopPage() == NI.HW.PAGE_VARIATION then
        self:onPageButton(NI.HW.BUTTON_EDIT_NOTE, NI.HW.PAGE_VARIATION, Pressed)
    elseif ActionHelper.hasEvents() then
        self.QuickEdit:onNoteButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onNudgeButton(Pressed)

    if ActionHelper.hasEvents() then
        self.QuickEdit:onNudgeButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onUndoButton(Pressed)

    if Pressed and self:getShiftPressed() and ActionHelper.canUndo(true) then
        App:getTransactionManager():undoTransaction()					-- Undo single step

    elseif Pressed and ActionHelper.canUndo(false) then
        App:getTransactionManager():undoTransactionMarker()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onRedoButton(Pressed)

    if Pressed and self:getShiftPressed() and ActionHelper.canRedo(true) then
        App:getTransactionManager():redoTransaction()

    elseif Pressed and ActionHelper.canRedo(false) then
        App:getTransactionManager():redoTransactionMarker()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onQuantizeButton(Pressed)

    if Pressed and ActionHelper.hasEvents() then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, self:getShiftPressed())
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onClearButton(Pressed)

    if Pressed and ActionHelper.hasEvents() then
        if self:getShiftPressed() then
            NI.DATA.EventPatternTools.removeModulationEvents(App)
        else
            NI.DATA.EventPatternTools.removeNoteAndAudioEvents(App)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onScreenEncoder(Index, EncoderInc)

    HardwareControllerBase.onScreenEncoder(self, Index, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:openBusyDialog()

    self.CapacitiveList:setEnabled(false)
    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()
    OverlayRoot:setVisible(false)

    HardwareControllerBase.openBusyDialog(self)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:closeBusyDialog()

    HardwareControllerBase.closeBusyDialog(self)
    self.CapacitiveList:setEnabled(true)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onFootswitchDetect(Index, Pressed)

    if self.ActivePage and self.ActivePage.onFootswitchDetect then
        self.ActivePage:onFootswitchDetect(Index, Pressed)
        return
    end

    self.Footswitch:onFootswitchDetect(Index, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onFootswitchTip(Index, Pressed)

    if self.ActivePage and self.ActivePage.onFootswitchTip then
        self.ActivePage:onFootswitchTip(Index, Pressed)
        return
    end

    self.Footswitch:onFootswitchTip(Index, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onFootswitchRing(Index, Pressed)

    if self.ActivePage and self.ActivePage.onFootswitchRing then
        self.ActivePage:onFootswitchRing(Index, Pressed)
        return
    end

    self.Footswitch:onFootswitchRing(Index, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onPatternButton(Pressed)

    -- pressing SHIFT + PATTERN should always show the Clip Page, which requires clips to be focused
    if Pressed and self:getShiftPressed() then

        -- this requests a view change in the RT thread but also an immediate view switch to avoid flickering on the ScenePage
        ArrangerHelper.immediateSwitchToSongView()

        if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) then
            NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)
        end

        -- do not leave the Pattern Page after applying the SHIFT shortcut
        if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_PATTERN then
            return
        end
    end

    -- at the end of HardwareControllerBase.onPageButton the function updatePageSync is called before any other
    -- onCustomProcess which is why we have to update the pattern forwarding page here already to show the correct
    -- state according to the data
    self:getPage(NI.HW.PAGE_PATTERN):updateScreens()

    return HardwareControllerBase.onPatternButton(self, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineStudioController:onSceneButton(Pressed)

    -- pressing SHIFT + SCENE should always show the Section Page, which might require a view switch
    if Pressed and self:getShiftPressed() then

        -- this requests a view change in the RT thread but also an immediate view switch to avoid flickering on the ScenePage
        ArrangerHelper.immediateSwitchToSongView()

        -- at the end of HardwareControllerBase.onPageButton the function updatePageSync is called before any other
        -- onCustomProcess which is why we have to update the pattern forwarding page here already to show the correct
        -- state according to the data
        self:getPage(NI.HW.PAGE_SCENE):updateScreens()

        -- Never leave the Scene Page after applying the SHIFT shortcut
        if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_SCENE then
            return
        end

    end

    return HardwareControllerBase.onPageButton(self, NI.HW.BUTTON_SCENE, NI.HW.PAGE_SCENE, Pressed)

end

-- Create Instance
------------------------------------------------------------------------------------------------------------------------
if not NI.HW.FEATURE.MK3 then
ControllerScriptInterface = MaschineStudioController()
end

------------------------------------------------------------------------------------------------------------------------
