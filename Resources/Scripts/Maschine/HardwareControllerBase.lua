------------------------------------------------------------------------------------------------------------------------
-- Hardware Controller Base Class handling all the controller events coming from C++
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/PageManager"
require "Scripts/Shared/Components/Timer"
require "Scripts/Shared/Components/TransportSection"

require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/LedColors"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/WidgetHelper"
require "Scripts/Shared/Helpers/BrowseHelper"

require "Scripts/Maschine/Helper/ModuleHelper"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
HardwareControllerBase = class( 'HardwareControllerBase', Timer )

------------------------------------------------------------------------------------------------------------------------
-- Led groups
------------------------------------------------------------------------------------------------------------------------

HardwareControllerBase.PAD_LEDS =
{
    NI.HW.LED_PAD_1,
    NI.HW.LED_PAD_2,
    NI.HW.LED_PAD_3,
    NI.HW.LED_PAD_4,
    NI.HW.LED_PAD_5,
    NI.HW.LED_PAD_6,
    NI.HW.LED_PAD_7,
    NI.HW.LED_PAD_8,
    NI.HW.LED_PAD_9,
    NI.HW.LED_PAD_10,
    NI.HW.LED_PAD_11,
    NI.HW.LED_PAD_12,
    NI.HW.LED_PAD_13,
    NI.HW.LED_PAD_14,
    NI.HW.LED_PAD_15,
    NI.HW.LED_PAD_16
}

HardwareControllerBase.SCREEN_BUTTON_LEDS =
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


------------------------------------------------------------------------------------------------------------------------
-- PAD groups
------------------------------------------------------------------------------------------------------------------------

HardwareControllerBase.PADS =
{
    NI.HW.PAD_1,
    NI.HW.PAD_2,
    NI.HW.PAD_3,
    NI.HW.PAD_4,
    NI.HW.PAD_5,
    NI.HW.PAD_6,
    NI.HW.PAD_7,
    NI.HW.PAD_8,
    NI.HW.PAD_9,
    NI.HW.PAD_10,
    NI.HW.PAD_11,
    NI.HW.PAD_12,
    NI.HW.PAD_13,
    NI.HW.PAD_14,
    NI.HW.PAD_15,
    NI.HW.PAD_16
}

------------------------------------------------------------------------------------------------------------------------

HardwareControllerBase.BUTTON_TO_PAGE =
{
    [NI.HW.BUTTON_CONTROL]      = NI.HW.PAGE_CONTROL,
    [NI.HW.BUTTON_STEP]         = NI.HW.PAGE_STEP,
    [NI.HW.BUTTON_BROWSE]       = NI.HW.PAGE_BROWSE,
    [NI.HW.BUTTON_SAMPLE]       = NI.HW.PAGE_SAMPLING,

    [NI.HW.BUTTON_SCENE]        = NI.HW.PAGE_SCENE,
    [NI.HW.BUTTON_PATTERN]      = NI.HW.PAGE_PATTERN,
    [NI.HW.BUTTON_PAD_MODE]     = NI.HW.PAGE_PAD,
    [NI.HW.BUTTON_NAVIGATE]     = NI.HW.PAGE_NAVIGATE,
    [NI.HW.BUTTON_DUPLICATE]    = NI.HW.PAGE_DUPLICATE,
    [NI.HW.BUTTON_SELECT]       = NI.HW.PAGE_SELECT,
    [NI.HW.BUTTON_SOLO]         = NI.HW.PAGE_SOLO,
    [NI.HW.BUTTON_MUTE]         = NI.HW.PAGE_MUTE,

    [NI.HW.BUTTON_NOTE_REPEAT]      = NI.HW.PAGE_REPEAT,
    [NI.HW.BUTTON_TRANSPORT_GRID]   = NI.HW.PAGE_GRID
}

------------------------------------------------------------------------------------------------------------------------

HardwareControllerBase.BUTTON_TO_PAGE_SHIFT =
{
    [NI.HW.BUTTON_PATTERN] = NI.HW.PAGE_VARIATION
}

------------------------------------------------------------------------------------------------------------------------

HardwareControllerBase.MODIFIER_PAGES =
{
    NI.HW.PAGE_SCENE,
    NI.HW.PAGE_PATTERN,
    NI.HW.PAGE_PAD,
    NI.HW.PAGE_DUPLICATE,
    NI.HW.PAGE_SELECT,
    NI.HW.PAGE_SOLO,
    NI.HW.PAGE_MUTE,
    NI.HW.PAGE_GRID,
    NI.HW.PAGE_PAGE,
    NI.HW.PAGE_REPEAT,
    NI.HW.PAGE_NAVIGATE,
    NI.HW.PAGE_VARIATION
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:__init()

    -- init base class
    Timer.__init(self)

    self.HWModel = NHLController:getControllerModel()

    -- setup properties
    self.FixedPadIndex  = 0 -- 0-indexed. For 16 velocity mode

    -- create page manager
    self.PageManager = PageManager(self)

    -- add transport section
    self.TransportSection = TransportSection(self)

    -- create visible page
    self.ActivePage = nil

    -- clear all handler
    self:resetHandler()

    -- setup button and encoder handler
    self:setupButtonHandler()
    self:setupEncoderHandler()

    LEDHelper.setLEDState(NI.HW.LED_SHIFT, LEDHelper.LS_OFF)

    -- keeps track of what modifier pages to close when their buttons are released
    self.CloseOnPageButtonRelease = {}

    NHLController:resetJogWheelMode()

    self.CachedPadStates = {}

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen button handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:setupButtonHandler()

    -- Modifier page handler
    for Button, PageID in pairs(self.BUTTON_TO_PAGE) do
        self.SwitchHandler[Button] = function(Pressed) self:onPageButton(Button, PageID, Pressed) end
    end

    -- Modifier page handler with shift pressed
    for Button, PageID in pairs(self.BUTTON_TO_PAGE_SHIFT) do
        self.SwitchHandlerShift[Button] = function(Pressed) self:onPageButton(Button, PageID, Pressed) end
    end

    -- Page buttons with own handlers for specific handling
    self.SwitchHandler[NI.HW.BUTTON_SELECT] = function(Pressed) self:onSelectButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_DUPLICATE] = function(Pressed) self:onDuplicateButton(Pressed) end

    -- Transport button handlers
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_PLAY]     = function(Pressed) self:onPlayButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_RECORD]   = function(Pressed) self:onRecordButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_LOOP]     = function(Pressed) self:onLoopButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_METRO]    = function(Pressed) self:onMetroButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_ERASE]    = function(Pressed) self:onEraseButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_PREV]     = function(Pressed) self:onPrevNextButton(Pressed, false) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_NEXT]     = function(Pressed) self:onPrevNextButton(Pressed, true) end

    self.SwitchHandler[NI.HW.BUTTON_SHIFT]  = function(Pressed) self:onShiftButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL]  = function(Pressed) self:onWheelButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_ALL]    = function(Pressed) self:onAllButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SNAP]   = function(Pressed) self:onSnapButton(Pressed) end

    -- Left/Right button handlers
    self.SwitchHandler[NI.HW.BUTTON_LEFT]  = function(Pressed) self:onLeftRightButton(false, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_RIGHT] = function(Pressed) self:onLeftRightButton(true, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PATTERN] = function(Pressed) self:onPatternButton(Pressed) end
    self.SwitchHandlerShift[NI.HW.BUTTON_PATTERN] = function(Pressed) self:onPatternButton(Pressed) end

end

------------------------------------------------------------------------------------------------------------------------
-- setup handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:setupEncoderHandler()

    -- Main Encoders
    self.EncoderHandler[NI.HW.ENCODER_VOLUME] = function(EncoderInc) self:onVolumeEncoder(EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_TEMPO]  = function(EncoderInc) self:onTempoEncoder(EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SWING]  = function(EncoderInc) self:onSwingEncoder(EncoderInc) end

    -- Default screen knob handlers
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_1] = function(EncoderInc) self:onScreenEncoder(1, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_2] = function(EncoderInc) self:onScreenEncoder(2, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_3] = function(EncoderInc) self:onScreenEncoder(3, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_4] = function(EncoderInc) self:onScreenEncoder(4, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_5] = function(EncoderInc) self:onScreenEncoder(5, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_6] = function(EncoderInc) self:onScreenEncoder(6, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_7] = function(EncoderInc) self:onScreenEncoder(7, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_8] = function(EncoderInc) self:onScreenEncoder(8, EncoderInc) end

    self.EncoderHandler[NI.HW.ENCODER_LEVEL]    = function(EncoderInc) self:onLevelEncoder(EncoderInc) end

end

------------------------------------------------------------------------------------------------------------------------
-- Reset Handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:resetHandler()

    -- table with pressed switches
    self.SwitchPressed = {}

    -- Event Handler for Switches
    self.SwitchHandler = {}
    self.SwitchHandlerShift = {}
    self.SwitchHandlerShiftPressed = {}

    -- Event Handler for Pads
    self.PadEventHandler = nil

    -- Event Handler for Encoders
    self.EncoderHandler = {}

    -- Event Handler for the Wheel (MK2 & Mikro)
    self.WheelEventHandler = nil

end

------------------------------------------------------------------------------------------------------------------------
-- Page Management
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getPage(PageID)

    return self.PageManager:getPage(PageID)

end

------------------------------------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:isButtonPressed(Button)

    return Button and self.SwitchPressed[Button] == true

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getShiftPressed()

    return self:isButtonPressed(NI.HW.BUTTON_SHIFT)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getErasePressed()

    return self:isButtonPressed(NI.HW.BUTTON_TRANSPORT_ERASE)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getWheelButtonPressed()

    return self:isButtonPressed(NI.HW.BUTTON_WHEEL)

end

------------------------------------------------------------------------------------------------------------------------
-- Timer
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onControllerTimer()

    -- call base class
    Timer.onControllerTimer(self)

    local InfoBar = self:getInfoBar()
    if InfoBar then
        InfoBar:onTimer()
    end

    self:updatePadLEDs()

    if self.ActivePage then
        -- update after pad leds for MikroMK2 Group page
        self.ActivePage:updateGroupLEDs()

        if self.ActivePage.onControllerTimer then
            self.ActivePage:onControllerTimer()
        end

        if self.ActivePage.ParameterHandler and self.ActivePage.ParameterHandler.onControllerTimer then
            self.ActivePage.ParameterHandler:onControllerTimer()
        end

    end

    if not NI.UTILS.NativeOSHelpers.isFirstBoot() then

        self.TransportSection:updateTransportLEDs()

    end

    LEDHelper.setLEDState(NI.HW.LED_SHIFT, self:getShiftPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    -- send to NHL
    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updateScreenButtonLEDs(ScreenButtons)

    LEDHelper.updateScreenButtonLEDs(self, ScreenButtons)

end

------------------------------------------------------------------------------------------------------------------------
-- Scripts Reset
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onReset()
end

------------------------------------------------------------------------------------------------------------------------
-- Pad Handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPadEvent(PadIndex, Trigger, PadValue)

    self.CachedPadStates[PadIndex] = Trigger

    if self.ActivePage then

        self.ActivePage:onPadEvent(PadIndex, Trigger, PadValue)
        NHLController:updateLEDs(false)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Switch Handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onSwitchEvent(SwitchID, Pressed)

    -- save pressed state
    self.SwitchPressed[SwitchID] = Pressed

    local Handler      = self.SwitchHandler[SwitchID]
    local HandlerShift = self.SwitchHandlerShift[SwitchID]

    local ShiftPage = self:getModPageID(SwitchID, true)
    local IsShiftPageInStack = ShiftPage and NHLController:getPageStack():isPageInStack(ShiftPage)

    if IsShiftPageInStack
        or Pressed and self:getShiftPressed() and HandlerShift
        or not Pressed and self.SwitchHandlerShiftPressed[SwitchID] then

        self.SwitchHandlerShiftPressed[SwitchID] = Pressed
        HandlerShift(Pressed)

    elseif Handler then

        self.SwitchHandlerShiftPressed[SwitchID] = false
        Handler(Pressed)

    end

    self:updateSwitchLEDs()

    -- transfer leds to controller
    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPageButton(Button, PageID, Pressed)

    local PageStack = NHLController:getPageStack()
    local TopPageID = PageStack:getTopPage()

    -- Current page gets 1st priority
    if self.ActivePage and self.ActivePage:onPageButton(Button, PageID, Pressed) == true then

        return -- current page handled the event

    elseif self:getShiftPressed() then

        if self:onPageButtonShift(Button, Pressed) == true then
            return -- shift handler handled the event
        else
            -- Get Page ID if it's different with [SHIFT] modifier
            PageID = self:getShiftPageID(Button, PageID, Pressed)
        end

    end

    -- manage page stack
    local NewPage = self:getPage(PageID)
    local NewPageIsModifierPage = self:isModifierPage(NewPage)
        or PageID == NI.HW.PAGE_MACRO
        or PageID == NI.HW.PAGE_STEP_STUDIO

    if Pressed then

        if NewPageIsModifierPage and NewPage.IsPinned then
            if TopPageID == PageID then
                self.CloseOnPageButtonRelease[PageID] = true
            else
                -- pop all modifiers
                while self:isModifierPageByID(PageStack:getTopPage()) do
                    PageStack:popPage()
                end
            end
        end

        if (TopPageID == PageID and not NewPageIsModifierPage) or -- Non-modifier page button pressed second time -> close page
           (TopPageID == NI.HW.PAGE_REC_MODE and PageID == NI.HW.PAGE_GRID and
           (self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MK3 or self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MH1071)) then -- Grid button closes rec mode page

            PageStack:popPage()

        else

            if not NewPageIsModifierPage then
                -- non-modifier pages take everything but the root page off the stack
                PageStack:popToBottomPage()
            end

            PageStack:pushPage(PageID)

        end

    else -- button released

        if self.CloseOnPageButtonRelease[PageID] or (NewPageIsModifierPage and not NewPage.IsPinned) then
            PageStack:removePage(PageID)
            self.CloseOnPageButtonRelease[PageID] = false
        end

    end

    -- MAS2-3575: Since updatePageSync() is called only once per timer call in onCustomProcess it may not be enough to
    -- handle two page switches inside one timer call. So call it directly after page switch.
    self:updatePageSync(true)

end

------------------------------------------------------------------------------------------------------------------------
-- Handle page buttons with Shift modifier
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPageButtonShift(Button, Pressed)

    if not Pressed then
        return -- currently not handled
    end

    -- [SHIFT] + [ARRANGE] = Show Song View if in Ideas View (one-directional)
    if Button == NI.HW.BUTTON_ARRANGE and ArrangerHelper.isIdeaSpaceFocused() then
        ArrangerHelper.toggleIdeasView()
        LEDHelper.setLEDState(NI.HW.LED_ARRANGE, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [PAD MODE] = Toggle Keyboard mode
    if Button == NI.HW.BUTTON_PAD_MODE then
        PadModeHelper.toggleKeyboardMode()
        return true
    end

    -- Mikro: [SHIFT] + [VIEW] / App: [SHIFT] + [NAVIGATE]
    if Button == NI.HW.BUTTON_NAVIGATE then
        local MixerVisibleParam = App:getWorkspace():getMixerVisibleParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MixerVisibleParam, not MixerVisibleParam:getValue())
        LEDHelper.setLEDState(NI.HW.LED_NAVIGATE, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [SELECT] = shortcut for event selection
    if Button == NI.HW.BUTTON_SELECT and (self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_STUDIO_MK1) then
        local SelectModeParam = App:getWorkspace():getHWSelectModeParameter()
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, SelectModeParam, true)
        LEDHelper.setLEDState(NI.HW.LED_SELECT, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [MUTE] = choke all sounds
    if Button == NI.HW.BUTTON_MUTE then
        NI.DATA.MaschineAccess.chokeAll(App)
        LEDHelper.setLEDState(NI.HW.LED_MUTE, LEDHelper.LS_BRIGHT)
        return true
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Returns Page ID for a page button + shift button
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getShiftPageID(Button, CurPageID, Pressed)

    -- [SHIFT] + [GRID] = [REC MODE]
    if Button == NI.HW.BUTTON_TRANSPORT_GRID then
        return NI.HW.PAGE_REC_MODE
    end

    -- [SHIFT] + [BROWSE] = [MODULES]
    if Button == NI.HW.BUTTON_BROWSE then
        return NI.HW.PAGE_MODULE
    end

    -- [SHIFT] + [PATTERN] = [VATIATION]
    if Button == NI.HW.BUTTON_PATTERN then
        return NHLController:getPageStack():isPageInStack(NI.HW.PAGE_VARIATION) and NI.HW.PAGE_PATTERN or NI.HW.PAGE_VARIATION
    end

    -- No shift page
    return CurPageID

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onSelectButton(Pressed)

    -- Switch off shift+select mode always on button release
    if not Pressed then
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, App:getWorkspace():getHWSelectModeParameter(), false)
    end

    self:onPageButton(NI.HW.BUTTON_SELECT, NI.HW.PAGE_SELECT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onDuplicateButton(Pressed)

    local TopPageID = NHLController:getPageStack():getTopPage()

    -- If coming from Scene or Pattern screen, set the Duplicate page's mode respectively
    if TopPageID == NI.HW.PAGE_SCENE or TopPageID == NI.HW.PAGE_PATTERN then

        local Mode = TopPageID == NI.HW.PAGE_SCENE
            and (ArrangerHelper.isIdeaSpaceFocused() and DuplicateHelper.SCENE or DuplicateHelper.SECTION)
            or  (NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) and DuplicateHelper.PATTERN or DuplicateHelper.CLIP)

        if Mode then
            DuplicateHelper.setMode(self:getPage(NI.HW.PAGE_DUPLICATE), Mode)
        end
    end

    self:onPageButton(NI.HW.BUTTON_DUPLICATE, NI.HW.PAGE_DUPLICATE, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:showTempPage(Page)

    NHLController:getPageStack():popToBottomPage()
    NHLController:getPageStack():pushPage(Page)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onScreenButton(ButtonIdx, Pressed)

    if self.ActivePage then
        self.ActivePage:onScreenButton(ButtonIdx, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onNavButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onNavButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onEnterButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onEnterButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onBackButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onBackButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onLeftRightButton(Right, Pressed)

    if self.ActivePage then
        self.ActivePage:onLeftRightButton(Right, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onGroupButton(Index, Pressed)

    if self.ActivePage then
        self.ActivePage:onGroupButton(Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPlayButton(Pressed)

    -- active page gets priority
    if self.ActivePage:onPlayButton(Pressed) then
        return
    end

    self.TransportSection:onPlay(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onRecordButton(Pressed)

    if self.ActivePage:onRecordButton(Pressed) then
        return
    end

    self.TransportSection:onRecord(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onLoopButton(Pressed)

    if self.ActivePage:onLoopButton(Pressed) then
        return
    end

    self.TransportSection:onLoop(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onEraseButton(Pressed)

    if self.ActivePage:onEraseButton(Pressed) then
        return
    end

    self.TransportSection:onErase(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onShiftButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onShiftButton(Pressed)
        self.TransportSection:updateTransportLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onWheelButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onWheelButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPrevNextButton(Pressed, Next)

    if self.ActivePage then
        if self.ActivePage:onPrevNextButton(Pressed, Next) then
            return
        end
    end

    self.TransportSection:onPrevNext(Pressed, Next)

end

------------------------------------------------------------------------------------------------------------------------
-- MCMK2 + Studio: Shift + All : SAVE
function HardwareControllerBase:onAllButton(Pressed)

    if Pressed then
        if self.SwitchPressed[NI.HW.BUTTON_SHIFT] then
            MaschineHelper.saveProject(self:getInfoBar())
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
-- MCMK1: Shift + Snap : SAVE
function HardwareControllerBase:onSnapButton(Pressed)

    LEDHelper.setLEDState(NI.HW.LED_SNAP, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    if Pressed and self.SwitchPressed[NI.HW.BUTTON_SHIFT] then
        MaschineHelper.saveProject(self:getInfoBar())
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Encoder Event
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onEncoderEvent(EncoderID, EncoderInc)

    -- call encoder event handler (i.e. self:on[Screen/Volume/Tempo/Swing]Encoder)
    local Handler = self.EncoderHandler[EncoderID]
    if Handler then
        Handler(EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onScreenEncoder(Index, EncoderInc)

    -- forward screen encoder event to current page
    if self.ActivePage then
        self.ActivePage:onScreenEncoder(Index, EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onAutoWriteButton(Pressed)

    local Enable = NI.DATA.WORKSPACE.isAutoWriteEnabledFromHW(App)

    local PinnedParameter = App:getWorkspace():getAutoWritePinnedParameter()
    local Pinned = PinnedParameter:getValue()

    if Pressed then

        Enable = not Pinned or not Enable

        -- toggle pin state
        if self:getShiftPressed() then
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PinnedParameter, not Pinned)
        elseif Pinned then
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PinnedParameter, false)
        end

    elseif not Pinned then
        Enable = false
    end

    NI.DATA.WORKSPACE.setAutoWriteEnabled(App, false, Enable)
    LEDHelper.setLEDState(NI.HW.LED_AUTO_WRITE, Enable and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onVolumeButton(Pressed)

    --forward volume button event to current page
    if self.ActivePage then
        self.ActivePage:onVolumeButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onTempoButton(Pressed)

    --forward volume button event to current page
    if self.ActivePage then
        self.ActivePage:onTempoButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onSwingButton(Pressed)

    --forward volume button event to current page
    if self.ActivePage then
        self.ActivePage:onSwingButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onVolumeEncoder(EncoderInc)

    --forward volume encoder event to current page
    if self.ActivePage then
        self.ActivePage:onVolumeEncoder(EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onTempoEncoder(EncoderInc)

    --forward tempo encoder event to current page
    if self.ActivePage then
        self.ActivePage:onTempoEncoder(EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onSwingEncoder(EncoderInc)

    --forward swing encoder event to current page
    if self.ActivePage then
        self.ActivePage:onSwingEncoder(EncoderInc)
    end
end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onLevelEncoder(EncoderInc)

    --forward level encoder event to current page
    if self.ActivePage then
        self.ActivePage:onLevelEncoder(EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onMetroButton(Pressed)

    if Pressed then
        MaschineHelper.toggleMetronome()
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPatternButton(Pressed)

   local PageID = Pressed
        and (self:getShiftPressed() and NI.HW.PAGE_VARIATION or NI.HW.PAGE_PATTERN)
        or  MaschineHelper.findFirstPageInStack({NI.HW.PAGE_VARIATION, NI.HW.PAGE_PATTERN})

    if not PageID then -- can be nil if other pushed pages resulted in popping these pages before this page button released
        PageID = NI.HW.PAGE_PATTERN
    end

    self:onPageButton(NI.HW.BUTTON_PATTERN, PageID, Pressed)


end

------------------------------------------------------------------------------------------------------------------------
-- Wheel Handler
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onWheelEvent(WheelID, WheelInc)

    -- Current page gets 1st priority
    if self.ActivePage and self.ActivePage:onWheel(WheelInc) then
        return
    end

    -- then Transport
    self.TransportSection:onWheel(WheelInc)

end

------------------------------------------------------------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onDB3ModelChanged(Model)

    if self.ActivePage then
        self.ActivePage:onDB3ModelChanged(Model)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onStateFlagsChanged()

    -- update data and top page
    self:onCustomProcess(false)

    -- transfer leds to controller
    NHLController:updateLEDs(false)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onCustomProcess(ForceUpdate)

    -- update focus sound index
    PadModeHelper.FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)+1

    -- update HW pages if page changed
    self:updatePageSync()

    if NI.DATA.WORKSPACE.getPluginPreferencesChanged(App) then
        ModuleHelper.resetCache()
    end

    if self.ActivePage then
        self.ActivePage:updateScreens(ForceUpdate)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updatePageSync(ForceUpdate)

    local TopPageID = NHLController:getPageStack():getTopPage()

    if ForceUpdate or NHLController:getPageStack():isPageStackChanged() or self.ActivePage == nil then

        local CurrentPageID = self.PageManager:getPageID(self.ActivePage)

        -- The active page was changed
        if TopPageID ~= CurrentPageID then

            self:onPageShow(false)
            self.ActivePage = self:getPage(TopPageID)
            self:onPageShow(true)

        end

        -- update page button LEDs which are depending on current page stack state
        self:syncPageButtonLEDsWithPageStack()

    end

    self:updatePageButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:onPageShow(Show)

    if self.ActivePage then

        -- reset infobar before showing the page
        if self:getInfoBar() then
            self:getInfoBar():resetTempMode()
        end

        self.ActivePage:onShow(Show)
        self:updateSwitchLEDs()

    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:syncPageButtonLEDsWithPageStack()

    self:turnOffAllPageLEDs()

    local TopPageID = NHLController:getPageStack():getTopPage()

    -- Page button leds from pages in stack
    for PageIndex = 1, NHLController:getPageStack():getNumPages() do

        local PageID = NHLController:getPageStack():getPageAt(PageIndex - 1)
        local Page = self:getPage(PageID)

        if Page == nil then
            error("Could not find page for PageID: "..tostring(PageID))
        end

        local LEDLevel = LEDHelper.LS_DIM
        if PageID == TopPageID or (not self:isModifierPageByID(PageID)) then
            -- Top page and non modifier pages are bright.
            LEDLevel = LEDHelper.LS_BRIGHT
        end

        Page:updatePageLEDs(LEDLevel)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Specific page leds that always need updating, doesn't depend on page being in stack

function HardwareControllerBase:updatePageButtonLEDs()

    self:updatePadModeButtonLED()
    self:updateDuplicateButtonLED()
    self:updateNoteRepeatButtonLED(self)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updatePadModeButtonLED()

    local TopPageID = NHLController:getPageStack():getTopPage()
    local LEDState = LEDHelper.LS_OFF

    if TopPageID == NI.HW.PAGE_PAD then

        LEDState = LEDHelper.LS_BRIGHT

    elseif PadModeHelper.getKeyboardMode()
        and not NHLController:getPageStack():isPageInStack(NI.HW.PAGE_DUPLICATE)
        or NHLController:getPageStack():isPageInStack(NI.HW.PAGE_PAD) then

        LEDState = LEDHelper.LS_DIM

    end

    LEDHelper.setLEDState(NI.HW.LED_PAD_MODE, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updateDuplicateButtonLED()

    local TopPageID = NHLController:getPageStack():getTopPage()
    if TopPageID == NI.HW.PAGE_SCENE then

        LEDHelper.setLEDState(NI.HW.LED_DUPLICATE, LEDHelper.LS_DIM)

    elseif TopPageID == NI.HW.PAGE_PATTERN then

        LEDHelper.setLEDState(NI.HW.LED_DUPLICATE, LEDHelper.LS_DIM)

    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updateNoteRepeatButtonLED()

    if NHLController:getPageStack():getTopPage() ~= NI.HW.PAGE_REPEAT then
        LEDHelper.setLEDState(NI.HW.LED_NOTE_REPEAT,
            MaschineHelper.isArpRepeatActive() and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updatePadLEDs()

    if self.ActivePage then

        -- The pad mode PAD_MODE_SELECT_NOTE_EVENTS takes 1st priority because the mode is a shortcut that overrides other pages.
        -- ACHTUNG! If you override this function in another controller class, you should do the same there.
        if NHLController:getPadMode() == NI.HW.PAD_MODE_SELECT_NOTE_EVENTS then
            EventsHelper.updatePadLEDsEvents(self.PAD_LEDS)
        else
            self.ActivePage:updatePadLEDs()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:turnOffAllPageLEDs()

    -- turn off all page leds
    for PageID, PageEntry in pairs(self.PageManager.Pages) do
        if PageEntry.Page then
            PageEntry.Page:updatePageLEDs(LEDHelper.LS_OFF)
        end
    end

    LEDHelper.setLEDState(NI.HW.LED_BROWSE, LEDHelper.LS_OFF)

    if self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 and
       self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MIKRO_MK2 then
        LEDHelper.setLEDState(NI.HW.LED_STEP, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

-- This can be used if specific controllers need some extra update logic for switch leds
function HardwareControllerBase:updateSwitchLEDs()
end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:updateVolumeTempoSwingButtonLEDs()

    local LEDs = {NI.HW.LED_VOLUME, NI.HW.LED_TEMPO, NI.HW.LED_SWING}
    local Buttons = {NI.HW.BUTTON_VOLUME, NI.HW.BUTTON_TEMPO, NI.HW.BUTTON_SWING}
    local LEDStates = {LEDHelper.LS_OFF, LEDHelper.LS_OFF, LEDHelper.LS_OFF}

    local Mode = NHLController:getJogWheelMode()
    if Mode ~= NI.HW.JOGWHEEL_MODE_DEFAULT then
        LEDStates[Mode+1] = LEDHelper.LS_BRIGHT
    end

    for Index, LedID in ipairs (LEDs) do
        local SwitchPressed = self.SwitchPressed[ Buttons[Index] ]
        LEDHelper.setLEDState(LedID, SwitchPressed and LEDHelper.LS_BRIGHT or LEDStates[Index])
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Find ButtonID from PageID
-- If ShiftPage is defined, we search for the ButtonID in BUTTON_TO_PAGE resp. BUTTON_TO_PAGE_SHIFT. If ShiftPage is
-- not defined, we search in both lists
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getModPageControlID(PageID, ShiftPage)

    local FindIDFct = function(List)
        for id, ModPageID in pairs(List) do
            if PageID == ModPageID then
                return id
            end
        end
    end

    local ID = nil
    if ShiftPage == nil or not ShiftPage then
        ID = FindIDFct(self.BUTTON_TO_PAGE)
    end

    if not ID and (ShiftPage == nil or ShiftPage) then
        ID = FindIDFct(self.BUTTON_TO_PAGE_SHIFT)
    end

    return ID

end

------------------------------------------------------------------------------------------------------------------------
-- Find PageID from ButtonID
-- If ShiftPage is defined, we search for the PageID in BUTTON_TO_PAGE resp. BUTTON_TO_PAGE_SHIFT. If ShiftPage is
-- not defined, we search in both lists
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getModPageID(ButtonID, ShiftPage)

    local FindPageIDFct =  function(List)
        for ID, ModPageID in pairs(List) do
            if ButtonID == ID then
                return ModPageID
            end
        end
    end

    local ID
    if ShiftPage == nil or not ShiftPage then
        ID = FindPageIDFct(self.BUTTON_TO_PAGE)
    end

    if not ID and (ShiftPage == nil or ShiftPage) then
        ID = FindPageIDFct(self.BUTTON_TO_PAGE_SHIFT)
    end

    return ID

end

------------------------------------------------------------------------------------------------------------------------
-- Busy Page
------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:setBusyMessage(LeftMessage, RightMessage)

    local BusyPage = self:getPage(NI.HW.PAGE_BUSY)

    if BusyPage then
        BusyPage:setMessage(LeftMessage, RightMessage)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogAudioExport()

    local AudioExportPage = self:getPage(NI.HW.PAGE_AUDIO_EXPORT)

    if AudioExportPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_AUDIO_EXPORT)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogMessage(Title, Message, leftScreenAttribute, Button1Text, Button2Text,
    Button3Text, Button4Text)

    local ModalDialogPage = self:getPage(NI.HW.PAGE_MODAL_DIALOG)

    if ModalDialogPage then
        ModalDialogPage:setContent(Title, Message, leftScreenAttribute, Button1Text, Button2Text, Button3Text, Button4Text)
        NHLController:getPageStack():pushPage(NI.HW.PAGE_MODAL_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogPower()

    local PowerPage = self:getPage(NI.HW.PAGE_POWER)

    if PowerPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_POWER)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogWarningPluginUpdate()

    local WarningPluginUpdatePage = self:getPage(NI.HW.PAGE_WARNING_PLUGIN_UPDATE)

    if WarningPluginUpdatePage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_WARNING_PLUGIN_UPDATE)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogDataTracking()

    local DataTrackingDialogPage = self:getPage(NI.HW.PAGE_DATA_TRACKING_DIALOG)

    if DataTrackingDialogPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_DATA_TRACKING_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogNewDrive()

    local NewDriveDialogPage = self:getPage(NI.HW.PAGE_NEW_DRIVE_DIALOG)

    if NewDriveDialogPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_NEW_DRIVE_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogSave()

    local SaveDialogPage = self:getPage(NI.HW.PAGE_SAVE_DIALOG)

    if SaveDialogPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_SAVE_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogTextInput(Descriptor)

    local TextInputPage = self:getPage(NI.HW.PAGE_TEXT_INPUT_DIALOG)

    if TextInputPage then
        TextInputPage:setStrings(Descriptor.Title, Descriptor.Prefill)
        TextInputPage:setKeyboard(Descriptor.KeyboardType)
        TextInputPage:setPasswordMode(Descriptor.KeyboardMode == NI.HW.TEXT_INPUT_MODE_PASSWORD)
        TextInputPage:setLeftScreenAttribute(Descriptor.LeftScreenAttribute)
        NHLController:getPageStack():pushPage(NI.HW.PAGE_TEXT_INPUT_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogFileBrowser(Descriptor)

    local FileBrowserDialogPage = self:getPage(NI.HW.PAGE_FILE_BROWSER_DIALOG)

    if FileBrowserDialogPage then
        FileBrowserDialogPage:setTitle(Descriptor.Title, Descriptor.LeftScreenAttribute)
        FileBrowserDialogPage:setOkText(Descriptor.ButtonOkText)
        FileBrowserDialogPage:setIgnoredPaths(Descriptor.IgnoredPaths)
        FileBrowserDialogPage:setDirectoriesOnly(Descriptor.IsDirectoriesOnly)
        FileBrowserDialogPage:setTypeFilter(Descriptor.TypeFilter)
        FileBrowserDialogPage:setStartPath(Descriptor.StartPath)
        NHLController:getPageStack():pushPage(NI.HW.PAGE_FILE_BROWSER_DIALOG)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogUSBStorageMode()

    local USBStorageModePage = self:getPage(NI.HW.PAGE_USB_STORAGE_MODE)

    if USBStorageModePage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_USB_STORAGE_MODE)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogExpandYourSound()

    local ExpandYourSoundPage = self:getPage(NI.HW.PAGE_EXPAND_YOUR_SOUND)

    if ExpandYourSoundPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_EXPAND_YOUR_SOUND)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogLearnMaschine()

    local LearnMaschinePage = self:getPage(NI.HW.PAGE_LEARN_MASCHINE)

    if LearnMaschinePage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_LEARN_MASCHINE)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogWarningSystemUpdate()

    local WarningSystemUpdatePage = self:getPage(NI.HW.PAGE_WARNING_SYSTEM_UPDATE)

    if WarningSystemUpdatePage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_WARNING_SYSTEM_UPDATE)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openDialogWarningSystemUpdateReady()

    local WarningSystemUpdateReadyPage = self:getPage(NI.HW.PAGE_WARNING_SYSTEM_UPDATE_READY)

    if WarningSystemUpdateReadyPage then
        NHLController:getPageStack():pushPage(NI.HW.PAGE_WARNING_SYSTEM_UPDATE_READY)
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:openBusyDialog()

    self:setBusyMessage(App:getGenericBusyMessage())

    NHLController:getPageStack():pushPage(NI.HW.PAGE_BUSY)
    self:updatePageSync(true) -- The timer can be disabled while busy loading - make sure the page is displayed
    NHLController:updateLEDs(true)

end


------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:closeBusyDialog()

    if  NHLController:getPageStack():getTopPage() == NI.HW.PAGE_BUSY or
        NHLController:isInModalState()
    then
        NHLController:getPageStack():popPage()
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:isModifierPage(Page)

    return self:isModifierPageByID(self.PageManager:getPageID(Page))

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:isModifierPageByID(PageID)

    for Index = 1, #self.MODIFIER_PAGES do

        if PageID == self.MODIFIER_PAGES[Index] then
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getInfoBar()

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:showQuickEdit()

    if self.ActivePage and self:getInfoBar() then
        self:getInfoBar():setTempMode("QuickEdit")
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:resetCachedPadStates()

    for PadIndex, _ in ipairs(self.PADS) do
        self.CachedPadStates[PadIndex] = false;
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:getAndResetCachedPadState(Index)

    local State = self.CachedPadStates[Index] == true
    self.CachedPadStates[Index] = false
    return State

end

------------------------------------------------------------------------------------------------------------------------

function HardwareControllerBase:printPageStack()

    print("-----top------")
    local NumPages = NHLController:getPageStack():getNumPages()
    for i = NumPages - 1, 0, -1  do
        local id = NHLController:getPageStack():getPageAt(i)
        local Page = self.PageManager:getPage(id)
        print (tostring(Page.Name)..": "..tostring(id))
    end

end

------------------------------------------------------------------------------------------------------------------------
