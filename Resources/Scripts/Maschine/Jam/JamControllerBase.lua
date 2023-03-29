------------------------------------------------------------------------------------------------------------------------
-- Jam Controller Class
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/Timer"
require "Scripts/Maschine/PageManager"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Jam/TransportSectionJam"
require "Scripts/Maschine/Jam/LevelMeter"
require "Scripts/Maschine/Jam/LevelMeterControls"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Maschine/Jam/Pages/MainPage"
require "Scripts/Maschine/Jam/Pages/StepPage"
require "Scripts/Maschine/Jam/ParameterHandlerJam"
require "Scripts/Maschine/Jam/Pages/MutePage"
require "Scripts/Maschine/Jam/Pages/SoloPage"
require "Scripts/Maschine/Jam/Pages/ArpRepeatPage"
require "Scripts/Maschine/Jam/Pages/MixingLayerSelectPage"
require "Scripts/Maschine/Jam/Pages/NotesPage"
require "Scripts/Maschine/Jam/OSOController"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Maschine/Jam/Helper/GamesHelper"
require "Scripts/Maschine/Jam/Helper/GridQuickEdit"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JamControllerBase = class( 'JamControllerBase' )

------------------------------------------------------------------------------------------------------------------------

JamControllerBase.SCENE_BUTTONS =
{
    NI.HW.BUTTON_SCENE_1,
    NI.HW.BUTTON_SCENE_2,
    NI.HW.BUTTON_SCENE_3,
    NI.HW.BUTTON_SCENE_4,
    NI.HW.BUTTON_SCENE_5,
    NI.HW.BUTTON_SCENE_6,
    NI.HW.BUTTON_SCENE_7,
    NI.HW.BUTTON_SCENE_8,
}

JamControllerBase.GROUP_BUTTONS =
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

JamControllerBase.BUTTON_TO_PAGE =
{
    [NI.HW.BUTTON_STEP]           = NI.HW.PAGE_STEP,
    [NI.HW.BUTTON_PAD_MODE]       = NI.HW.PAGE_PAD_MODE,
    [NI.HW.BUTTON_SELECT]         = NI.HW.PAGE_SELECT,
    [NI.HW.BUTTON_SOLO]           = NI.HW.PAGE_SOLO,
    [NI.HW.BUTTON_MUTE]           = NI.HW.PAGE_MUTE,
    [NI.HW.BUTTON_ARP_REPEAT]     = NI.HW.PAGE_ARP_REPEAT,
    [NI.HW.BUTTON_NOTES]          = NI.HW.PAGE_NOTES,
}

JamControllerBase.DPAD_BUTTONS =
{
    NI.HW.BUTTON_DPAD_UP,
    NI.HW.BUTTON_DPAD_RIGHT,
    NI.HW.BUTTON_DPAD_DOWN,
    NI.HW.BUTTON_DPAD_LEFT
}

JamControllerBase.DPAD_LEDS =
{
    NI.HW.LED_DPAD_UP,
    NI.HW.LED_DPAD_RIGHT,
    NI.HW.LED_DPAD_DOWN,
    NI.HW.LED_DPAD_LEFT
}

JamControllerBase.PAD_BUTTONS =
{
    {NI.HW.BUTTON_A1, NI.HW.BUTTON_B1, NI.HW.BUTTON_C1, NI.HW.BUTTON_D1, NI.HW.BUTTON_E1, NI.HW.BUTTON_F1, NI.HW.BUTTON_G1, NI.HW.BUTTON_H1},
    {NI.HW.BUTTON_A2, NI.HW.BUTTON_B2, NI.HW.BUTTON_C2, NI.HW.BUTTON_D2, NI.HW.BUTTON_E2, NI.HW.BUTTON_F2, NI.HW.BUTTON_G2, NI.HW.BUTTON_H2},
    {NI.HW.BUTTON_A3, NI.HW.BUTTON_B3, NI.HW.BUTTON_C3, NI.HW.BUTTON_D3, NI.HW.BUTTON_E3, NI.HW.BUTTON_F3, NI.HW.BUTTON_G3, NI.HW.BUTTON_H3},
    {NI.HW.BUTTON_A4, NI.HW.BUTTON_B4, NI.HW.BUTTON_C4, NI.HW.BUTTON_D4, NI.HW.BUTTON_E4, NI.HW.BUTTON_F4, NI.HW.BUTTON_G4, NI.HW.BUTTON_H4},
    {NI.HW.BUTTON_A5, NI.HW.BUTTON_B5, NI.HW.BUTTON_C5, NI.HW.BUTTON_D5, NI.HW.BUTTON_E5, NI.HW.BUTTON_F5, NI.HW.BUTTON_G5, NI.HW.BUTTON_H5},
    {NI.HW.BUTTON_A6, NI.HW.BUTTON_B6, NI.HW.BUTTON_C6, NI.HW.BUTTON_D6, NI.HW.BUTTON_E6, NI.HW.BUTTON_F6, NI.HW.BUTTON_G6, NI.HW.BUTTON_H6},
    {NI.HW.BUTTON_A7, NI.HW.BUTTON_B7, NI.HW.BUTTON_C7, NI.HW.BUTTON_D7, NI.HW.BUTTON_E7, NI.HW.BUTTON_F7, NI.HW.BUTTON_G7, NI.HW.BUTTON_H7},
    {NI.HW.BUTTON_A8, NI.HW.BUTTON_B8, NI.HW.BUTTON_C8, NI.HW.BUTTON_D8, NI.HW.BUTTON_E8, NI.HW.BUTTON_F8, NI.HW.BUTTON_G8, NI.HW.BUTTON_H8},
}

JamControllerBase.GROUP_LEDS =
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

JamControllerBase.SCENE_LEDS =
{
    NI.HW.LED_SCENE_1,
    NI.HW.LED_SCENE_2,
    NI.HW.LED_SCENE_3,
    NI.HW.LED_SCENE_4,
    NI.HW.LED_SCENE_5,
    NI.HW.LED_SCENE_6,
    NI.HW.LED_SCENE_7,
    NI.HW.LED_SCENE_8
}

JamControllerBase.PAD_LEDS =
{
    {NI.HW.LED_A1, NI.HW.LED_A2, NI.HW.LED_A3, NI.HW.LED_A4, NI.HW.LED_A5, NI.HW.LED_A6, NI.HW.LED_A7, NI.HW.LED_A8},
    {NI.HW.LED_B1, NI.HW.LED_B2, NI.HW.LED_B3, NI.HW.LED_B4, NI.HW.LED_B5, NI.HW.LED_B6, NI.HW.LED_B7, NI.HW.LED_B8},
    {NI.HW.LED_C1, NI.HW.LED_C2, NI.HW.LED_C3, NI.HW.LED_C4, NI.HW.LED_C5, NI.HW.LED_C6, NI.HW.LED_C7, NI.HW.LED_C8},
    {NI.HW.LED_D1, NI.HW.LED_D2, NI.HW.LED_D3, NI.HW.LED_D4, NI.HW.LED_D5, NI.HW.LED_D6, NI.HW.LED_D7, NI.HW.LED_D8},
    {NI.HW.LED_E1, NI.HW.LED_E2, NI.HW.LED_E3, NI.HW.LED_E4, NI.HW.LED_E5, NI.HW.LED_E6, NI.HW.LED_E7, NI.HW.LED_E8},
    {NI.HW.LED_F1, NI.HW.LED_F2, NI.HW.LED_F3, NI.HW.LED_F4, NI.HW.LED_F5, NI.HW.LED_F6, NI.HW.LED_F7, NI.HW.LED_F8},
    {NI.HW.LED_G1, NI.HW.LED_G2, NI.HW.LED_G3, NI.HW.LED_G4, NI.HW.LED_G5, NI.HW.LED_G6, NI.HW.LED_G7, NI.HW.LED_G8},
    {NI.HW.LED_H1, NI.HW.LED_H2, NI.HW.LED_H3, NI.HW.LED_H4, NI.HW.LED_H5, NI.HW.LED_H6, NI.HW.LED_H7, NI.HW.LED_H8},
}

JamControllerBase.PAD_SOUND_LEDS =
{
    NI.HW.LED_E8, NI.HW.LED_F8, NI.HW.LED_G8, NI.HW.LED_H8,
    NI.HW.LED_E7, NI.HW.LED_F7, NI.HW.LED_G7, NI.HW.LED_H7,
    NI.HW.LED_E6, NI.HW.LED_F6, NI.HW.LED_G6, NI.HW.LED_H6,
    NI.HW.LED_E5, NI.HW.LED_F5, NI.HW.LED_G5, NI.HW.LED_H5
}

JamControllerBase.PAD_VELOCITY_LEDS =
{
    NI.HW.LED_A8, NI.HW.LED_B8, NI.HW.LED_C8, NI.HW.LED_D8,
    NI.HW.LED_A7, NI.HW.LED_B7, NI.HW.LED_C7, NI.HW.LED_D7,
    NI.HW.LED_A6, NI.HW.LED_B6, NI.HW.LED_C6, NI.HW.LED_D6,
    NI.HW.LED_A5, NI.HW.LED_B5, NI.HW.LED_C5, NI.HW.LED_D5
}

JamControllerBase.NUM_PAD_ROWS = 8
JamControllerBase.NUM_PAD_COLUMNS = 8

JamControllerBase.PIN_BUTTON = NI.HW.BUTTON_SONG
JamControllerBase.PIN_BUTTON_LED = NI.HW.LED_SONG

JamControllerBase.DEFAULT_LED_BLINK_TIME = 6 -- default led blinking time in timer ticks

JamControllerBase.TOUCH_EVENT_TOUCHED = 0
JamControllerBase.TOUCH_EVENT_MOVED = 1
JamControllerBase.TOUCH_EVENT_RELEASED = 2

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:__init()

    -- table with currently pressed switches
    self.SwitchPressed = {}

    -- Event handlers for switches
    self.SwitchHandler = {}

    -- Event handlers for buttons with modifiers, e.g. Shift button
    self.SwitchModifierPairPressed = {}
    self.SwitchModifierPairHandler = {}
    self.SwitchModifierPairHandlerActive = {}

    -- page manager
    self.PageManager = PageManager(self)

    -- active page and page stack
    self.ActivePage = nil

    -- keeps track of what modifier pages to close when their buttons are released
    self.CloseOnPageButtonRelease = {}

    -- transport controls
    self.TransportSectionJam = TransportSectionJam(self)

    -- parameter handler for on-screen parameters
    self.ParameterHandler = ParameterHandlerJam(self)

    -- OSO browser controller
    self.OSOController = OSOController(self)

    -- encoder mode
    NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    self.SavedEncoderMode = nil

    -- level meter
    self.LevelMeter = LevelMeter()
    self.LevelMeterControls = LevelMeterControls(self, self.LevelMeter)

    -- grid adjust
    self.GridQuickEdit = GridQuickEdit(self)

    -- timer
    self.Timer = Timer()

    -- easter eggs
    self.GamesHelper = GamesHelper()

    self:setupButtonHandlers()
    self:createPages()

    self.TouchstripStates = {
        Touched = {},
        Value = {},
        Delta = {}
    }

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:setupButtonHandlers()

    self.SwitchHandler[NI.HW.BUTTON_SONG] = function(Pressed) self:onSongButton(Pressed) end

    for Index, Button in pairs(self.SCENE_BUTTONS) do
        self.SwitchHandler[Button] = function(Pressed) self:onSceneButton(Index, Pressed) end
    end

    for Index, Button in pairs(self.GROUP_BUTTONS) do
        self.SwitchHandler[Button] = function(Pressed) self:onGroupButton(Index, Pressed) end
    end

    for Row, RowTable in pairs(self.PAD_BUTTONS) do
        for Column, Button in pairs(RowTable) do
            self.SwitchHandler[Button] = function(Pressed) self:onPadButton(Column, Row, Pressed, Button) end
        end
    end

    for Button, PageID in pairs(self.BUTTON_TO_PAGE) do
        self.SwitchHandler[Button] = function(Pressed) self:onPageButton(Button, PageID, Pressed) end
    end

    for Index, Button in pairs(self.DPAD_BUTTONS) do
        self.SwitchHandler[Button] = function(Pressed) self:onDPadButton(Button, Pressed) end
    end

    self.SwitchHandler[NI.HW.BUTTON_SHIFT] = function(Pressed) self:onShiftPressed(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_ARROW_LEFT] = function(Pressed) self:onLeftRightButton(false, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_ARROW_RIGHT] = function(Pressed) self:onLeftRightButton(true, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PLAY] = function(Pressed) self:onPlayButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_RECORD] = function(Pressed) self:onRecordButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_CLEAR] = function(Pressed) self:onClearButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_DUPLICATE] = function(Pressed) self:onDuplicateButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_MACRO] = function(Pressed) self:onMacroButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL] = function(Pressed) self:onLevelButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_AUX] = function(Pressed) self:onAuxButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_AUTO] = function(Pressed) self:onAutoButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PERFORM] = function(Pressed) self:onPerformButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TUNE] = function(Pressed) self:onTuneButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SWING] = function(Pressed) self:onSwingButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_BROWSE] = function(Pressed) self:onBrowseButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL] = function(Pressed) self:onWheelButton(Pressed) end
    self.SwitchHandler[NI.HW.TOUCH_BROWSE] = function(Pressed) self:onWheelTouch(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GRID] = function(Pressed) self:onGridButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TEMPO] = function(Pressed) self:onTempoButton(Pressed) end
    self.SwitchHandler[NI.HW.FOOT_TIP] = function(Pressed) self:onPlayButton(Pressed) end
    self.SwitchHandler[NI.HW.FOOT_RING] = function(Pressed) self:onRecordButton(Pressed) end


    -- Shift + Group_A = Toggle Step Scene Follow
    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_GROUP_A,
        function(Pressed) if Pressed then self:onShiftAButton() end end)

    -- Shift + Group_E = Variation
    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_GROUP_E,
        function(Pressed) if Pressed then self:onVariationButton() end end)

    -- Shift + Group_G = Save
    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_GROUP_G,
        function(Pressed) if Pressed then NI.HW.ProjectFileCommands.saveProject(App) end end)

    -- Shift + Group_H = Instance button
    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_GROUP_H,
        function(Pressed) self:onInstanceButton(Pressed) end)

    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_SELECT,
        function(Pressed) self:onAccentButton(Pressed) end)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:createPages()

    local Folder = "Scripts/Maschine/Jam/Pages/"
    local Pages = self.PageManager

    Pages:register(NI.HW.PAGE_MAIN, Folder .. "MainPage", "MainPage")
    Pages:register(NI.HW.PAGE_STEP, Folder .. "StepPage", "StepPage")
    Pages:register(NI.HW.PAGE_PAD_MODE, Folder .. "PadModePage", "PadModePage")
    Pages:register(NI.HW.PAGE_MUTE, Folder .. "MutePage", "MutePage")
    Pages:register(NI.HW.PAGE_SOLO, Folder .. "SoloPage", "SoloPage")
    Pages:register(NI.HW.PAGE_SNAKE, Folder .. "SnakePage", "SnakePage")
    Pages:register(NI.HW.PAGE_SELECT, Folder .. "SelectPage", "SelectPage")
    Pages:register(NI.HW.PAGE_ARP_REPEAT, Folder .. "ArpRepeatPage", "ArpRepeatPage")
    Pages:register(NI.HW.PAGE_MIXING_LAYER_SELECT, Folder .. "MixingLayerSelectPage", "MixingLayerSelectPage")
    Pages:register(NI.HW.PAGE_PATTERN_LENGTH, Folder .. "PatternLengthPage", "PatternLengthPage")
    Pages:register(NI.HW.PAGE_NOTES, Folder .. "NotesPage", "NotesPage")
    Pages:register(NI.HW.PAGE_SNAPSHOTS, Folder .. "SnapshotsPage", "SnapshotsPage")

    -- Check if page is already populated (can happen when switching instances)
    self:updatePageSync()

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPageShow(Show)

    if self.ActivePage then
        self.GridQuickEdit:setEnabled(false)
        self.ActivePage:onShow(Show)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:updatePageSync(ForceUpdate)

    if ForceUpdate or NHLController:getPageStack():isPageStackChanged() or self.ActivePage == nil or
       ArrangerHelper.isIdeaSpaceFocusChanged() then

        self:updatePageButtonLEDs()

        local CurrentPageID = self.PageManager:getPageID(self.ActivePage)
        local TopPageID     = NHLController:getPageStack():getTopPage()

        -- The active page was changed
        if TopPageID ~= CurrentPageID then

            self.ParameterHandler:onControllerPageChanged()

            self:onPageShow(false)
            self.ActivePage = self.PageManager:getPage(TopPageID)
            self:onPageShow(true)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onCustomProcess(ForceUpdate)

    -- update focus sound index
    PadModeHelper.FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) + 1

    -- Change HW pages if required
    self:updatePageSync()

    if self.ActivePage then
        self.ActivePage:onCustomProcess(ForceUpdate)
    end

    self.ParameterHandler:onCustomProcess(ForceUpdate)
    self.OSOController:onCustomProcess(ForceUpdate)

    self:updateArpRepeatLED()

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onStateFlagsChanged()

    self:onCustomProcess(false)

    -- transfer leds to controller
    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------
-- Called when a SW dialog appears
function JamControllerBase:onBusyState()

    if App:getBusyState() ~= NI.HW.BUSY_TYPE_LOADING then

        -- hide Browser OSO
        App:getOnScreenOverlay():hide()

        -- hide Parameter OSO
        self.ParameterHandler:hideOSO()

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onControllerTimer()

    self.Timer:onControllerTimer()

    self.GamesHelper:onTimer()

    if self.ActivePage then
        self.ActivePage:updateGroupLEDs()
        self.ActivePage:updatePadLEDs()
        self.ActivePage:updateSceneButtonLEDs()
    end

    self:updateSongButtonLED()

    -- dpad button leds
    if MaschineHelper.isOnScreenOverlayVisible() then
        self.OSOController:updateDPadLEDs()
    elseif self.ActivePage then
        self.ActivePage:updateDPadLEDs()
    end

    self.LevelMeter:onTimer()
    self.LevelMeterControls:onTimer()
    self.ParameterHandler:onTimer()
    self.GridQuickEdit:onTimer()
    self.TransportSectionJam:updateLEDs()

    -- send to NHL
    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:setModifierSwitchHandler(ModifierID, SwitchID, Handler)

    if self.SwitchModifierPairHandler[ModifierID] == nil then
        self.SwitchModifierPairHandler[ModifierID] = {}
    end

    if self.SwitchModifierPairPressed[ModifierID] == nil then
        self.SwitchModifierPairPressed[ModifierID] = {}
    end

    if self.SwitchModifierPairHandlerActive[ModifierID] == nil then
        self.SwitchModifierPairHandlerActive[ModifierID] = {}
    end

    self.SwitchModifierPairHandler[ModifierID][SwitchID] = Handler

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isSwitchModifierPairPressed(ModifierID, SwitchID)

    return self.SwitchModifierPairPressed[ModifierID][SwitchID] == true

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isSwitchModifierPairHandlerActive(ModifierID, SwitchID)

    return self.SwitchModifierPairHandlerActive[ModifierID][SwitchID] == true

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onSwitchEvent(SwitchID, Pressed)

    if JamHelper.isQuickEditModeEnabled()
        and ( SwitchID == NI.HW.BUTTON_MACRO
            or SwitchID == NI.HW.BUTTON_AUX
            or SwitchID == NI.HW.BUTTON_CONTROL
            or SwitchID == NI.HW.BUTTON_AUTO
            or SwitchID == NI.HW.BUTTON_PERFORM
            or SwitchID == NI.HW.BUTTON_NOTES
            or SwitchID == NI.HW.BUTTON_LOCK ) then
        return
    end

    local Handler = nil
    local ModifierID = NI.HW.BUTTON_SHIFT -- only modifier button for now

    -- Show game according to sequence
    Handler = self.GamesHelper:checkForSecretCodes(SwitchID, Pressed)

    -- Get modifier button handler if there is one
    if self:isShiftPressed() or self.SwitchModifierPairPressed[ModifierID][SwitchID] == true then

        self.SwitchModifierPairPressed[ModifierID][SwitchID] = Pressed

        if not self.isAnyButtonPressedExcept(self.SwitchModifierPairPressed[ModifierID],
                                             {NI.HW.BUTTON_SHIFT, SwitchID}) then
            Handler = self.SwitchModifierPairHandler[ModifierID][SwitchID]
        end

        self.SwitchModifierPairHandlerActive[ModifierID][SwitchID] = Handler ~= nil

    end

    -- Get non-modifier button handler if we have no handler yet
    if not Handler then
        self.SwitchPressed[SwitchID] = Pressed
        Handler = self.SwitchHandler[SwitchID]
    end

    if Handler then
        Handler(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onWheelTouch(Touched)

    self.SwitchPressed[NI.HW.TOUCH_BROWSE] = Touched

    if App:getOnScreenOverlay():isBrowserVisible() then
        return
    elseif self.ActivePage and self.ActivePage:onWheelTouch(Touched) then
        return
    elseif self.ParameterHandler:onWheelTouch(Touched) then
        return
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onWheelEvent(WheelID, Inc)

    if self.ActivePage and JamArrangerHelper.canShiftSceneOfSection(self) then
        return self:shiftSceneOfSection(Inc)
    elseif self.ActivePage and JamArrangerHelper.canSectionLoopChange(self) then
        return self:incrementSectionLoop(Inc)
    elseif self.OSOController:onWheelEvent(Inc) then
        return
    elseif self.ActivePage and self.ActivePage:onWheelEvent(Inc) then
        return
    elseif self.ParameterHandler:onWheelEvent(Inc) then
        return
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onWheelButton(Pressed)

    if self.OSOController:onWheelButton(Pressed) then
        return
    elseif self.ActivePage and self.ActivePage:onWheelButton(Pressed) then
        return
    elseif self.ParameterHandler:onWheelButton(Pressed) then
        return
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onTouchEvent(TouchID, TouchType, Value)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:printPageStack()

    print("-----top------")
    local NrPages = NHLController:getPageStack():getNumPages()
    for i = NrPages - 1, 0, -1  do
        print ("PageID: "..NHLController:getPageStack():getPageAt(i))
    end
    print("----bottom----")

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:togglePinState(PageID)

    local PageStack = NHLController:getPageStack()
    local IsPinnable = PageStack:isPagePinnable(PageID)
    local TopPageIndex = PageStack:getNumPages() - 1
    local PreviousPageID = PageStack:getPageAt(TopPageIndex - 1) -- Returns PAGE_EMPTY if out of range anyway

    if IsPinnable then

        -- Toggle pin state
        local NewPinState = not PageStack:getPagePinState(PageID)
        PageStack:setPagePinState(PageID, NewPinState)

        self.CloseOnPageButtonRelease[PageID] = not NewPinState

        -- If we pinned the page, remove the page under it
        if NewPinState then
            PageStack:removePage(PreviousPageID) -- removePage never removes the bottom page
        end

        LEDHelper.setLEDState(self.PIN_BUTTON_LED, LEDHelper.LS_BRIGHT)
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:getButtonFromPage(PageID)

    for Button, Page in pairs(self.BUTTON_TO_PAGE) do

        if Page == PageID then
            return Button
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:updatePageButtonLEDs()

    local PageStack = NHLController:getPageStack()
    local TopPageID = PageStack:getTopPage()

    -- turn off all page leds
    for PageID, PageEntry in pairs(self.PageManager.Pages) do
        if PageEntry.Page then
            PageEntry.Page:updatePageLEDs(LEDHelper.LS_OFF)
        end
    end

    -- turn on page leds that are in stack
    for PageIndex = 1, PageStack:getNumPages() do

        local PageID = PageStack:getPageAt(PageIndex - 1)
        local Page = self.PageManager:getPage(PageID)
        if Page == nil then
            error("Could not find page for PageID: "..tostring(PageID))
        end

        local LEDLevel = LEDHelper.LS_DIM
        if PageID == TopPageID then
            -- Top page and non modifier pages are bright.
            LEDLevel = LEDHelper.LS_BRIGHT
        end

        Page:updatePageLEDs(LEDLevel)

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:updateSongButtonLED()

    local TopPageID = NHLController:getPageStack():getTopPage()
    local LEDState = LEDHelper.LS_OFF

    if not ArrangerHelper.isIdeaSpaceFocused() then
        LEDState = TopPageID == NI.HW.PAGE_MAIN and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    end

    LEDHelper.setLEDState(NI.HW.LED_SONG, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:updateArpRepeatLED()

    -- Update Arp/Repeat LED in cases arp lock changes or other controller (de)activates the arp.
    if not NHLController:getPageStack():isPageInStack(NI.HW.PAGE_ARP_REPEAT) then
        LEDHelper.setLEDState(NI.HW.LED_ARP_REPEAT, MaschineHelper.isArpRepeatActive()
            and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onSongButton(Pressed)

    if Pressed then
        self.CanToggleSceneButtonView = not self:isShiftPressed()
            and not self.SwitchPressed[NI.HW.BUTTON_DUPLICATE]
            and not self.SwitchPressed[NI.HW.BUTTON_AUTO]
            and not self.SwitchPressed[NI.HW.BUTTON_IN1]
            and NHLController:getPageStack():isTopPage(NI.HW.PAGE_MAIN)

    else
        if self.CanToggleSceneButtonView then
            ArrangerHelper.toggleIdeasView()
        end

        self.CanToggleSceneButtonView = false
    end

    if not self:onPinButton(Pressed) then
        NHLController:getPageStack():popToBottomPage()
        self:updatePageSync(true)
    end

    if self.ActivePage then
        self.ActivePage:onSongButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPinButton(Pressed)

    if self.ActivePage and self.ActivePage:onPinButton(Pressed) then
        return true
    end

    if not Pressed then
        self:setPinButtonLed(false)
        return false
    end

    local TopPage = NHLController:getPageStack():getTopPage()
    local Button = self:getButtonFromPage(TopPage)

    if self:isButtonPressed(Button) then
        return self:togglePinState(TopPage)
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onBrowseButton(Pressed)

    self.OSOController:onBrowseButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isButtonPressed(Button)

    return Button and self.SwitchPressed[Button] == true

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase.isAnyButtonPressedExcept(PressedTable, Buttons)

    for Button, Pressed in pairs(PressedTable) do

        if Pressed and not table.contains(Buttons, Button) then
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isShiftPressed()

    return self.SwitchPressed[NI.HW.BUTTON_SHIFT] == true

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isWheelPressed()

    return self.SwitchPressed[NI.HW.BUTTON_WHEEL] == true

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onSceneButton(Index, Pressed)

    if self.GridQuickEdit:isEnabled() then

        self.GridQuickEdit:onSceneButton(Index, Pressed)

    elseif self.ActivePage then

        if not Pressed
            and not NHLController:isAnySceneButtonPressed()
            and self.SavedEncoderMode ~= nil then

            -- restore saved encoder mode
            NHLController:setEncoderMode(self.SavedEncoderMode)
            self.SavedEncoderMode = nil
        end

        self.ActivePage:onSceneButton(Index, Pressed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onGroupButton(Index, Pressed)

    if self.ActivePage then
        self.ActivePage:onGroupButton(Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onLevelSourceButton(Button, Pressed)

    if not Pressed then
        return
    end

    if self.ActivePage and self.ActivePage.onLevelSourceButton
        and self.ActivePage:onLevelSourceButton(Button, Pressed) then
        return
    end

    self.LevelMeterControls:onLevelSourceButton(Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPadButton(Column, Row, Pressed, Button)

    if self.ActivePage then

        -- Disable shift functions on keyboard mode while still holding pad mode button
        if NHLController:isPadShiftFunction(Button, Pressed) then
            JamHelper.invokeShiftFunction(Column)
            self.ActivePage:setDuplicateEnabled(false)
        else
            self.ActivePage:onPadButton(Column, Row, Pressed)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:findPageInStack(FilterFunctor)

    local PageStack = NHLController:getPageStack()
    local LastPageIndex = PageStack:getNumPages() - 1

    for i = LastPageIndex, 0, -1  do
        local PageID = PageStack:getPageAt(i)
        if FilterFunctor(PageID) then
            return PageID
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:getPinState(PageID)

    -- Non-Modifier pages can not be unpinned, therefore they are always pinned
    -- If a page is not pinnable, that means it's always pinned
    local PageStack = NHLController:getPageStack()
    return not PageStack:isPagePinnable(PageID) or PageStack:getPagePinState(PageID)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPageButton(Button, PageID, Pressed)

    -- Current active page gets 1st priority
    if self.ActivePage and self.ActivePage:onPageButton(Button, PageID, Pressed) == true then
        return
    elseif self:isButtonPressed(NI.HW.BUTTON_AUTO) then
        return
    end

    local OriginalPageID = PageID
    local ShiftPageID = self:getShiftPageID(Button, PageID, Pressed)

    if Pressed and self:isShiftPressed() then
        PageID = ShiftPageID
    end

    local PageStack = NHLController:getPageStack()
    local IsPinned = self:getPinState(PageID)
    local TopPageID = PageStack:getTopPage()
    local IsTopPagePinned = not PageStack:isPagePinnable(TopPageID) or PageStack:getPagePinState(TopPageID)

    if Pressed then

        if TopPageID ~= PageID and TopPageID ~= ShiftPageID then

             -- Ignore the next release event for non-modifier or pinned pages
            self.CloseOnPageButtonRelease[PageID] = not IsPinned

            -- There can only be a single pinned page in the pagestack, therefore
            -- the previous pinned page is removed before pushing a new one
            local PageToRemoveID = self:findPageInStack(function(PageID) return self:getPinState(PageID) end)

            -- When opening certain pages with the shift button, set Keyboard mode
            if (PageID == NI.HW.PAGE_STEP or PageID == NI.HW.PAGE_PAD_MODE or PageID == NI.HW.PAGE_ARP_REPEAT)
                and PadModeHelper.getKeyboardMode() ~= self:isShiftPressed() then
                PadModeHelper.toggleKeyboardMode()
            end

            if IsPinned and PageToRemoveID then
                PageStack:removePage(PageToRemoveID)
                PageStack:pushPage(PageID)
            else
                if not JamHelper.isStepModulationModeEnabled()
                   or TopPageID ~= NI.HW.PAGE_STEP or PageID ~= NI.HW.PAGE_MIXING_LAYER_SELECT then
                    PageStack:pushPage(PageID)
                end
            end

        elseif self.CloseOnPageButtonRelease[PageID] == nil then
            self.CloseOnPageButtonRelease[TopPageID] = true
        end

    else -- Release

        -- The button for the top page was released
        if TopPageID == PageID or TopPageID == ShiftPageID then

            if self.CloseOnPageButtonRelease[TopPageID] and TopPageID ~= NI.HW.PAGE_MAIN then

                PageStack:popPage()

                -- Avoid showing OSO when returning from non-pinned page to page with OSO
                if not PageStack:getPagePinState(TopPageID) then
                    local NewPage = self.PageManager:getPage(PageStack:getTopPage())
                    if NewPage then
                        NewPage.ActivateOSOOnShow = false
                    end
                end

            end

            -- Reset to default
            self.CloseOnPageButtonRelease[TopPageID] = true

        else

            local OriginalPageInPageStack = PageStack:isPageInStack(OriginalPageID)
            local ShiftPageInPageStack = PageStack:isPageInStack(ShiftPageID)
            local PageToRemoveID = OriginalPageInPageStack and OriginalPageID or ShiftPageID

            -- If both are in the page stack, remove the unpinned one
            if ShiftPageInPageStack and OriginalPageInPageStack then

                PageToRemoveID = PageStack:getPagePinState(OriginalPageID) and ShiftPageID or OriginalPageID

                if PageStack:getPagePinState(OriginalPageID) and PageStack:getPagePinState(ShiftPageID) then
                    print ("You have both a page and it's shift page in the page stack and both are pinned. This should be impossible!")
                end

            end

            if self.CloseOnPageButtonRelease[PageToRemoveID] then
                PageStack:removePage(PageToRemoveID)
            end

            -- Reset to default
            self.CloseOnPageButtonRelease[PageToRemoveID] = true

        end

    end

    self:updatePageSync(true)

end

------------------------------------------------------------------------------------------------------------------------
-- Returns Page ID for a page button + shift button
------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:getShiftPageID(Button, CurPageID, Pressed)

    -- No shift page
    return CurPageID

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onDPadButton(Button, Pressed)

    if self.OSOController:onDPadButton(Button, Pressed) then
        return
    elseif self.ActivePage then
        self.ActivePage:onDPadButton(Button, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onShiftPressed(Pressed)

    LEDHelper.setLEDState(NI.HW.LED_SHIFT, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    if not Pressed then
        NHLController:resetTapTempo()
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onLeftRightButton(Right, Pressed)

    self.TransportSectionJam:onPrevNext(Right, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPlayButton(Pressed)

    self.TransportSectionJam:onPlay(Pressed)

    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onRecordButton(Pressed)

    self.TransportSectionJam:onRecord(Pressed)

    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onDuplicateButton(Pressed)

    if not self:isShiftPressed() then
        if self.ActivePage then
            self.ActivePage:onDuplicateButton(Pressed)
        end
    else
        if Pressed then
            NI.DATA.EventPatternAccess.doubleFocusPatternOrClipEvent(App)
        end

        LEDHelper.updateButtonLED(self, NI.HW.LED_DUPLICATE, NI.HW.BUTTON_DUPLICATE, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:isClearActive()

    return self:isButtonPressed(NI.HW.BUTTON_CLEAR)
        and not self:isShiftPressed()
        and not self:isButtonPressed(NI.HW.BUTTON_PAD_MODE)
        and not self:isButtonPressed(NI.HW.BUTTON_ARP_REPEAT)
        and not self:isButtonPressed(NI.HW.BUTTON_STEP)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onClearButton(Pressed)

    if Pressed and self:isShiftPressed() then
        NI.DATA.EventPatternTools.removeModulationEvents(App)
    end

    if self.ActivePage then
        self.ActivePage:setDuplicateEnabled(false)
    end

    for _, Button in ipairs({NI.HW.BUTTON_PAD_MODE, NI.HW.BUTTON_ARP_REPEAT, NI.HW.BUTTON_STEP}) do
        if self:isButtonPressed(Button) then
            self.CloseOnPageButtonRelease[self.BUTTON_TO_PAGE[Button]] = false
            break
        end
    end

    -- update the Clear page button led
    LEDHelper.updateButtonLED(self, NI.HW.LED_CLEAR, NI.HW.BUTTON_CLEAR, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onMacroButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onLevelButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onAuxButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onControlButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onAutoButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onPerformButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onVariationButton()

    if not JamHelper.isJamOSOVisible(NI.HW.OSO_RANDOMIZER) then
        self.ParameterHandler:showOSO(NI.HW.OSO_RANDOMIZER)
    else
        self.ParameterHandler:hideOSO()
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onShiftAButton()

    if self.ActivePage and self.ActivePage.onShiftAButton
        and self.ActivePage:onShiftAButton() then
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onLockButton(Pressed)

    if self.ActivePage and self.ActivePage:onLockButton() then
        return
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onGridButton(Pressed)

    if Pressed then

        local GridOpen = JamHelper.isJamOSOVisible(NI.HW.OSO_GRID)
        local RecModeOpen = JamHelper.isJamOSOVisible(NI.HW.OSO_REC_MODE)

        -- Rec Mode & Grid functions share the same button,
        -- so if Rec Mode or Grid OSO is already open, and shift isn't pressed, close the OSO.
        -- However if Shift is pressed and Grid OSO is open, then don't close the OSO, but change the OSO mode to Grid.
        if (not GridOpen and not RecModeOpen) or (GridOpen and self:isShiftPressed()) then

            self.ParameterHandler:showOSO(self:isShiftPressed() and NI.HW.OSO_REC_MODE or NI.HW.OSO_GRID)

        elseif GridOpen or RecModeOpen then

            self.ParameterHandler:hideOSO()

        end

    end

    self.GridQuickEdit:setEnabled(Pressed and JamHelper.isJamOSOVisible(NI.HW.OSO_GRID))

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onTempoButton(Pressed)

    if self:isShiftPressed() then -- Tap Tempo

        if not App:canEditTempo() then
            return
        end

        if Pressed then
            NHLController:onTapTempo()
        end

        if not JamHelper.isJamOSOVisible(NI.HW.OSO_TEMPO) then
            LEDHelper.setLEDState(NI.HW.LED_TEMPO, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        end

    elseif Pressed then

        if not JamHelper.isJamOSOVisible(NI.HW.OSO_TEMPO) then
            self.ParameterHandler:showOSO(NI.HW.OSO_TEMPO)
        else
            self.ParameterHandler:hideOSO()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onTuneButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onSwingButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onAccentButton(Pressed)

    if self.ActivePage and self.ActivePage.onAccentButton then
        self.ActivePage:onAccentButton(Pressed)
    elseif not Pressed then
        -- make sure we don't miss a release in case the active page does not handle Accent events
        LEDHelper.setLEDState(NI.HW.LED_SELECT, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:onInstanceButton(Pressed)

    self.OSOController:onInstanceButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:setPinButtonLed(Pressed)

    local TopPage = NHLController:getPageStack():getTopPage()
    local LEDState = (Pressed or TopPage == NI.HW.PAGE_MAIN) and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
    LEDHelper.setLEDState(self.PIN_BUTTON_LED, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:anyTouchstripTouched()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:storeEncoderMode()

    local EncoderMode = NHLController:getEncoderMode()
    if EncoderMode ~= NI.HW.ENC_MODE_NONE and EncoderMode ~= NI.HW.ENC_MODE_LEVEL then
        self.SavedEncoderMode = EncoderMode
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:incrementSectionLoop(Inc)

    self:storeEncoderMode()
    self.LevelMeterControls:resetMode()

    if NHLController:getEncoderMode() ~= NI.HW.ENC_MODE_NONE then
        print("WARNING: Attempting to change Song's Loop with Encoder when encoder mode is not reset.")
    end

    return JamArrangerHelper.moveSectionLoopPoint(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerBase:shiftSceneOfSection(Inc)

    self:storeEncoderMode()
    self.LevelMeterControls:resetMode()

    if NHLController:getEncoderMode() ~= NI.HW.ENC_MODE_NONE then
        print("WARNING: Attempting to change Scene of Section with Encoder when encoder mode is not reset.")
    end

    return ArrangerHelper.shiftSceneOfFocusSection(Inc)

end

------------------------------------------------------------------------------------------------------------------------
