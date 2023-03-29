require "Scripts/Shared/Helpers/CapacitiveHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

require "Scripts/Shared/KompleteKontrol2"

require "Scripts/Maschine/KompleteKontrolS2/KK2SpeechAssist"
require "Scripts/Maschine/KompleteKontrolS2/Pages/ArpPageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/BrowsePageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/BrowsePageKKS2MH1071"
require "Scripts/Maschine/KompleteKontrolS2/Pages/MixerPageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/PatternPageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/ScenePageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/ControlPageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/SetupPageKKS2"
require "Scripts/Maschine/KompleteKontrolS2/Pages/ModulePageKKS2"

require "Scripts/Maschine/Components/CapacitiveOverlayNavIcons"
require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/Helper/ParameterHelper"

require "Scripts/Maschine/KompleteKontrolS2/Helper/GroupOverlayHelper"
require "Scripts/Maschine/KompleteKontrolS2/Helper/QuantizeOverlayHelper"
require "Scripts/Maschine/KompleteKontrolS2/Helper/TempoOverlayHelper"

require "Scripts/Maschine/MaschineStudio/Shared/PatternEditorStudio"


local class = require 'Scripts/Shared/Helpers/classy'
KompleteKontrol2MAS = class( 'KompleteKontrol2MAS', KompleteKontrol2 )

local LINEAR_VELOCITY = 3
local FIXED_VELOCITY = 7

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:__init()

    self.CapacitiveNavIcons = CapacitiveOverlayNavIcons(self)
    KompleteKontrol2.__init(self)

    local function onScreenEncoderTrackOverlayBind(Index, EncoderInc)
        return self:onScreenEncoderTrackOverlay(Index, EncoderInc)
    end

    local function onScreenButtonTrackOverlayBind(Index, Pressed)
        return self:onScreenButtonTrackOverlay(Index, Pressed)
    end

    local function onWheelTrackOverlayBind(Value)
        return self:onWheelTrackOverlay(Value)
    end

    self.Overlays[NI.HW.BUTTON_TRACK] = PageOverlay(self,
        {
            OnSetupFunc = GroupOverlayHelper.onSetup,
            OnUpdateFunc = GroupOverlayHelper.onUpdate,
            ParameterDataFunc = GroupOverlayHelper.getParameterData,
            OnScreenEncoderFunc = onScreenEncoderTrackOverlayBind,
            ScreenButtonDataFunc = GroupOverlayHelper.getButtonData,
            OnScreenButtonFunc = onScreenButtonTrackOverlayBind,
            OnLeftRightButtonFunc = GroupOverlayHelper.onLeftRightButton,
            OnShowFunc = GroupOverlayHelper.onShow,
            UpdateLEDsFunc = GroupOverlayHelper.updateLEDs,
            OnClearFunc = GroupOverlayHelper.onClear,
            OnWheelFunc = onWheelTrackOverlayBind,
            OnWheelDirectionFunc = GroupOverlayHelper.onWheelDirection,
            OnGetWheelDirectionInfoFunc = GroupOverlayHelper.getWheelDirectionInfo,
            GetScreenButtonInfoFunc = GroupOverlayHelper.getScreenButtonInfo,
            GetScreenEncoderInfoFunc = GroupOverlayHelper.getScreenEncoderInfo,
            GetCurrentPageSpeechAssistanceMessageFunc = GroupOverlayHelper.getCurrentPageSpeechAssistanceMessage
        })

    local function onScreenEncoderQuantizeOverlayBind(Index, EncoderInc)
        return self:onScreenEncoderQuantizeOverlay(Index, EncoderInc)
    end

    local function onScreenButtonQuantizeOverlayBind(Index, Pressed)
        return self:onScreenButtonQuantizeOverlay(Index, Pressed)
    end

    local function onWheelQuantizeOverlayBind(Value)
        return self:onWheelQuantizeOverlay(Value)
    end

    local function onWheelButtonQuantizeOverlayBind(Pressed)
        return self:onWheelButtonQuantizeOverlay(Pressed)
    end

    self.Overlays[NI.HW.BUTTON_QUANTIZE] = PageOverlay(self,
        {
            ParameterDataFunc = QuantizeOverlayHelper.getParameterData,
            OnScreenEncoderFunc = onScreenEncoderQuantizeOverlayBind,
            GetScreenEncoderInfoFunc = QuantizeOverlayHelper.getScreenEncoderInfo,
            ScreenButtonDataFunc = QuantizeOverlayHelper.getButtonData,
            OnScreenButtonFunc = onScreenButtonQuantizeOverlayBind,
            GetScreenButtonInfoFunc = QuantizeOverlayHelper.getScreenButtonInfo,
            UpdateLEDsFunc = QuantizeOverlayHelper.updateLEDs,
            OnWheelFunc = onWheelQuantizeOverlayBind,
            OnWheelButtonFunc = onWheelButtonQuantizeOverlayBind
        })

    local function onScreenEncoderTempoOverlayBind(Index, EncoderInc)
        return self:onScreenEncoderTempoOverlay(Index, EncoderInc)
    end

    local function onWheelTempoOverlayBind(Value)
        return self:onWheelTempoOverlay(Value)
    end

    self.Overlays[NI.HW.BUTTON_TRANSPORT_TEMPO] = PageOverlay(self,
        {
            ParameterDataFunc = TempoOverlayHelper.getParameterData,
            OnScreenEncoderFunc = onScreenEncoderTempoOverlayBind,
            GetScreenEncoderInfoFunc = TempoOverlayHelper.getScreenEncoderInfo,
            UpdateLEDsFunc = TempoOverlayHelper.updateLEDs,
            OnWheelFunc = onWheelTempoOverlayBind
        })

    self.SpeechAssist = KK2SpeechAssist(self)
    self.SharedObjects.SlotStack.GetPictureColor = MaschineHelper.getFocusMixingLayerColor

    self.HWKompletePreferences = NI.HW.getPreferencesKompleteKontrolS()
    self.HWKompletePreferences:read(NHLController)

    self.PreviousVelocityCurve = self.HWKompletePreferences:getVelocityCurve()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:setupButtonHandler()

    KompleteKontrol2.setupButtonHandler(self)

    self.SwitchHandler[NI.HW.BUTTON_MIX]                 = function(Pressed) self:onMixButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRACK]               = function(Pressed) self:onOverlayButton(NI.HW.BUTTON_TRACK,
                                                                                                  Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_QUANTIZE]            = function(Pressed) self:onQuantizeButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SONG]                = function(Pressed) self:onSceneButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_PATTERN]             = function(Pressed) self:onPatternButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_MUTE]                = function(Pressed) self:onMuteButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_NAVIGATE_BROWSE]     = function(Pressed) self:onBrowseButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SOLO]                = function(Pressed) self:onSoloButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_PLAY]      = function(Pressed) self:onPlayButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_RECORD]    = function(Pressed) self:onRecordButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_STOP]      = function(Pressed) self:onStopButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_METRONOME] = function(Pressed) self:onMetronomeButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_TEMPO]     = function(Pressed)
                                                           self:onOverlayButton(NI.HW.BUTTON_TRANSPORT_TEMPO, Pressed)
                                                           end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPORT_LOOP]      = function(Pressed) self:onLoopButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_UNDO]                = function(Pressed) self:onUndoRedo(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_AUTOWRITE]           = function(Pressed) self:onAutoWrite(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_CLEAR]               = function(Pressed) self:onClear(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_KEYMODE]             = function(Pressed) self:onKeyMode(Pressed) end

    if NI.APP.isNoHardwareService() then
        self.SwitchHandler[NI.HW.BUTTON_FIXED_VEL] = function(Pressed) self:onFixedVelocityButton(Pressed) end
        self.SwitchHandler[NI.HW.BUTTON_SETUP] = function(Pressed) self:onSetupButton(Pressed) end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:handleSwitchEvent(SwitchID, Pressed)

    if not self.SpeechAssist:isTrainingMode() or self.SpeechAssist:GetButtonInfo(SwitchID).PerformInTrainingMode then

        KompleteKontrol2.handleSwitchEvent(self, SwitchID, Pressed)

    end

    self.SpeechAssist:onSwitchEvent(SwitchID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onMixButton(Pressed)

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_MIXER then
        self:changePage(NI.HW.PAGE_MIXER)
    end

    self:onPageButton(NI.HW.PAGE_MIXER, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:createPages()

    self.PageList[NI.HW.PAGE_CONTROL] = ControlPageKKS2(self)
    self.PageList[NI.HW.PAGE_MIXER] = MixerPageKKS2(self)
    self.PageList[NI.HW.PAGE_ARP] = ArpPageKKS2(self)
    self.PageList[NI.HW.PAGE_MODULE] = ModulePageKKS2(self)

    self.PageList[NI.HW.PAGE_BROWSE]  = NI.APP.isNativeOS() and BrowsePageKKS2MH1071(self) or BrowsePageKKS2(self)

    self.PageList[NI.HW.PAGE_SCENE] = ScenePageKKS2(self)
    self.PageList[NI.HW.PAGE_PATTERN] = PatternPageKKS2(self)
    self.PageList[NI.HW.PAGE_SETUP] = SetupPageKKS2(self)

    KompleteKontrol2.createPages(self)

    self.PageList[NI.HW.PAGE_CONTROL].SetupParametersFunc = ParameterHelper.setupFocusModuleParameters
    self.PageList[NI.HW.PAGE_SCALE].SetupParametersFunc = ParameterHelper.setupMaschineScaleParameters
    self.PageList[NI.HW.PAGE_ARP].SetupParametersFunc = ParameterHelper.setupMaschineArpParameters

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:updateSoloMuteLEDs()

    local MuteLEDState = LEDHelper.LS_DIM
    local SoloLEDState = MaschineHelper.getFocusSongGroupCount() > 1 and LEDHelper.LS_DIM or LEDHelper.LS_OFF
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    if GroupIndex == NPOS then
        LEDHelper.setLEDState(NI.HW.LED_MUTE, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_SOLO, LEDHelper.LS_OFF)
        return
    end

    Selected, Enabled, ColorIndex = MuteSoloHelper.getGroupMuteByIndexLEDStates(GroupIndex + 1)

    if not Selected then
        MuteLEDState = LEDHelper.LS_BRIGHT
    else
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Song and Group and NI.DATA.SongAccess.isMuteExclusive(Song, Group) then
            SoloLEDState = LEDHelper.LS_BRIGHT
        end
    end

    LEDHelper.setLEDState(NI.HW.LED_MUTE, MuteLEDState, ColorIndex)
    LEDHelper.setLEDState(NI.HW.LED_SOLO, SoloLEDState, ColorIndex)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:updatePageSync(Force)

    if Force then
        self:changePage(NI.HW.PAGE_CONTROL)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:openBusyDialog()

    KompleteKontrol2.openBusyDialog(self)

    if self.SpeechAssist then -- Can be called before KompleteKontrol2KK is intialised.
        self.SpeechAssist:onBusyDialogOpened()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenEncoder(Index, EncoderInc)

    local ValueChanged = false

    if not self.SpeechAssist:isTrainingMode() then
        ValueChanged = KompleteKontrol2.onScreenEncoder(self, Index, EncoderInc)
    end

    self.SpeechAssist:onEncoderEvent(Index, ValueChanged)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenButton(Index, Pressed)

    -- Clicking a screen button can change the page or disabled state, so query the page ID, state before it has changed
    local PageOrOverlay = self:getActivePageOrOverlay()
    local isButtonDisabled = false
    local HasScreen = PageOrOverlay.Screen
    local Button = PageOrOverlay.Screen and PageOrOverlay.Screen.ScreenButton and PageOrOverlay.Screen.ScreenButton[Index] or nil
    local ButtonText = Button and Button:getText() or ""
    local MixerInactive = not (self.ActivePageID == NI.HW.PAGE_MIXER)

    -- SUBTLE: ScreenButtons with no name probably represent custom headers, as in the mixer
    --         or track overlay - isEnabled() may not be correct for these, so skip this.
    if ButtonText:len() > 0 then
        isButtonDisabled = MixerInactive and (not HasScreen or not Button:isEnabled())
    end

    if not self.SpeechAssist:isTrainingMode() then
        KompleteKontrol2.onScreenButton(self, Index, Pressed)
    end

    if Pressed then
        self.SpeechAssist:onScreenButton(Index, PageOrOverlay, isButtonDisabled)
    end

end

------------------------------------------------------------------------------------------------------------------------


function KompleteKontrol2MAS:onWheelEvent(WheelID, Value)

    if not self.SpeechAssist:isTrainingMode() then
        KompleteKontrol2.onWheelEvent(self, WheelID, Value)
    end

    self.SpeechAssist:onWheelEvent(WheelID, Value)
end


------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onQuantizeButton(Pressed)

    if not self:getShiftPressed() then
        self:onOverlayButton(NI.HW.BUTTON_QUANTIZE, Pressed)

    elseif Pressed then

        if MaschineHelper.isDrumkitMode() then
            NI.DATA.EventPatternTools.quantizeNoteEvents(App, false)
        else
            NI.DATA.EventPatternTools.quantizeNoteEventsInFocusedSound(App, false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:updatePresetButtonLEDs()

    if self.ActivePage and self.ActivePage.updatePresetButtonLEDs then

        self.ActivePage:updatePresetButtonLEDs()
    else
        local CanPreset = NI.DATA.StateHelper.getFocusSlot(App) ~= nil

        LEDHelper.updateButtonLED(self, NI.HW.LED_NAVIGATE_PRESET_UP, NI.HW.BUTTON_NAVIGATE_PRESET_UP, CanPreset)
        LEDHelper.updateButtonLED(self, NI.HW.LED_NAVIGATE_PRESET_DOWN, NI.HW.BUTTON_NAVIGATE_PRESET_DOWN, CanPreset)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onSceneButton(Pressed)

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_SCENE then
        self:changePage(NI.HW.PAGE_SCENE)
    end

    self:onPageButton(NI.HW.PAGE_SCENE, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onPatternButton(Pressed)

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_PATTERN then
        self:changePage(NI.HW.PAGE_PATTERN)
    end

    self:onPageButton(NI.HW.PAGE_PATTERN, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onSetupButton(Pressed)

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_SETUP then
        self:changePage(NI.HW.PAGE_SETUP)
    end

    self:onPageButton(NI.HW.PAGE_SETUP, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onFixedVelocityButton(Pressed)

    self.HWKompletePreferences = NI.HW.getPreferencesKompleteKontrolS()

    local CurrentVelocityCurve = self.HWKompletePreferences:getVelocityCurve()
    if Pressed and CurrentVelocityCurve == FIXED_VELOCITY then
        self.HWKompletePreferences:setVelocityCurve(self.PreviousVelocityCurve == FIXED_VELOCITY and LINEAR_VELOCITY or
            self.PreviousVelocityCurve)

    elseif Pressed then
        self.PreviousVelocityCurve = CurrentVelocityCurve
        self.HWKompletePreferences:setVelocityCurve(FIXED_VELOCITY)

    end

    self.HWKompletePreferences:write(NHLController)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onBrowseButton(Pressed)

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_MODULE and self:getShiftPressed() then
        self:changePage(NI.HW.PAGE_MODULE)
    elseif Pressed and self.ActivePageID ~= NI.HW.PAGE_BROWSE then
        self:changePage(NI.HW.PAGE_BROWSE)
    end

    self:onPageButton(NI.HW.BUTTON_BROWSE, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onControllerTimer()

    self.CapacitiveNavIcons:onTimer()

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onTimer(self)
    else
        self.CapacitiveList:onTimer()
    end

    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()
    local ShowOverlayRoot = self.ActiveOverlay and self.ActiveOverlay:isVisible() or self.CapacitiveList:isVisible()
                            or self.CapacitiveNavIcons:isVisible()
    if ShowOverlayRoot ~= OverlayRoot:isVisible() then
        OverlayRoot:setVisible(ShowOverlayRoot)
    end

    self:updateTransportLEDs()

    if self.ActivePageID ~= NI.HW.PAGE_MIXER then
        self.updateSoloMuteLEDs()
    end

    if NI.APP.isNoHardwareService() then
        LEDHelper.setLEDState(NI.HW.LED_FIXED_VEL,
            self.HWKompletePreferences:getVelocityCurve() == FIXED_VELOCITY and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

    end

    --need to call this last as it overwrites some LEDs to OFF when busy
    KompleteKontrol2.onControllerTimer(self)

    self.SpeechAssist:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onDB3ModelChanged(Model)

    KompleteKontrol2.onDB3ModelChanged(self, Model)

    self.SpeechAssist:onDB3ModelChanged()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onControlButton(Pressed, Button)

    local TopPage = NHLController:getTopPage()

    if Pressed then
        -- set modules visible parameter
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(
            App, App:getWorkspace():getModulesVisibleParameter(), Button == NI.HW.BUTTON_CONTROL)
        App:getWorkspace():saveModulesVisibleState()
    end

    KompleteKontrol2.onControlButton(self, Pressed, Button)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onMuteButton(Pressed)

    if self.SpeechAssist:isTrainingMode() then
        return
    end

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_MIXER then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil
        local FocusGroup = NI.DATA.StateHelper.getFocusGroupIndex(App)
        if FocusGroup ~= NPOS then
            MuteSoloHelper.toggleMuteState(Groups, FocusGroup + 1)
        end
    else
        self.ActivePage:onPageButton(NI.HW.BUTTON_MUTE, self.ActivePageID, Pressed)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onSoloButton(Pressed)

    if self.SpeechAssist:isTrainingMode() then
        return
    end

    if Pressed and self.ActivePageID ~= NI.HW.PAGE_MIXER and MaschineHelper.getFocusSongGroupCount() > 1 then

        local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
        if FocusGroupIndex ~= NPOS then
            MuteSoloHelper.toggleGroupSoloState(FocusGroupIndex + 1)
        end
    else
        self.ActivePage:onPageButton(NI.HW.BUTTON_SOLO, self.ActivePageID, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:createSharedObjects()

    self.SharedObjects.PatternEditor = PatternEditorStudio("PatternEditorRight")
    self.SharedObjects.PatternEditorOverview = PatternEditorStudio("PatternEditorLeft", self.SharedObjects.PatternEditor)

    KompleteKontrol2.createSharedObjects(self)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:changePage(PageID)

    self.CapacitiveNavIcons:reset()
    KompleteKontrol2.changePage(self, PageID)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:updateLEDs()

    if App:isBusy() then
        if not NI.APP.isStandalone() then

            LEDHelper.turnOffLEDs({
                NI.HW.LED_UNDO,
                NI.HW.LED_GRID,
                NI.HW.LED_AUTOWRITE,
                NI.HW.LED_MUTE,
                NI.HW.LED_SOLO,
                NI.HW.LED_SONG,
                NI.HW.LED_PATTERN,
                NI.HW.LED_SETUP,
                NI.HW.LED_TRACK,
                NI.HW.LED_KEYMODE,
                NI.HW.LED_CLEAR,
                NI.HW.LED_MIX
                })
        end
    else
        local SongMode = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
        LEDHelper.setLEDState(NI.HW.LED_SONG, (SongMode and self.ActivePageID == NI.HW.PAGE_ARRANGE)
                                                and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
        LEDHelper.setLEDState(NI.HW.LED_PATTERN, (not SongMode and self.ActivePageID == NI.HW.PAGE_ARRANGE)
                                                    and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

        if NI.APP.isNoHardwareService() then
            LEDHelper.setLEDState(NI.HW.LED_SETUP,
                self.ActivePageID == NI.HW.PAGE_SETUP and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

        end

        local CanUndoOrRedoFunc = self:getShiftPressed() and ActionHelper.canRedo or ActionHelper.canUndo

        LEDHelper.updateButtonLED(self, NI.HW.LED_UNDO, NI.HW.BUTTON_UNDO, CanUndoOrRedoFunc(false))

        local AutoWriteEnabled = NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App)
        LEDHelper.setLEDState(NI.HW.LED_AUTOWRITE, AutoWriteEnabled and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

        local KeyModeOn = MaschineHelper.isDrumkitMode()
        LEDHelper.setLEDState(NI.HW.LED_KEYMODE, KeyModeOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

        -- overlay buttons are always dimmed
        local HasEvents = MaschineHelper.isDrumkitMode() and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents()
        local CanQuantize = HasEvents and GridHelper.isSnapEnabled(GridHelper.STEP)
        LEDHelper.updateButtonLED(self, NI.HW.LED_QUANTIZE, NI.HW.BUTTON_QUANTIZE, (not self:getShiftPressed())
                                                                                   or CanQuantize)

        LEDHelper.updateButtonLED(self, NI.HW.LED_TRACK, NI.HW.BUTTON_TRACK, true)
        LEDHelper.updateButtonLED(self, NI.HW.LED_TRANSPORT_TEMPO, NI.HW.BUTTON_TRANSPORT_TEMPO, true)

    end

    KompleteKontrol2.updateLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:updateTransportLEDs()

    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_PLAY, MaschineHelper.isPlaying() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_RECORD, MaschineHelper.isRecording() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    local StopBright = not self.SpeechAssist:isTrainingMode() and self.SwitchPressed[NI.HW.BUTTON_TRANSPORT_STOP]
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_STOP, StopBright and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_LOOP, NI.DATA.TransportAccess.isLoopActive(App) and LEDHelper.LS_BRIGHT
                                                    or LEDHelper.LS_DIM)
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_METRONOME, App:getMetronome():getEnabledParameter():getValue()
                                                         and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onPlayButton(Pressed)

    if Pressed then

        local ShiftPressed = self:getShiftPressed()

        if ShiftPressed then
            NI.DATA.TransportAccess.restartTransport(App)

        else
            NI.DATA.TransportAccess.togglePlay(App)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onStopButton(Pressed)

    if Pressed and App:getWorkspace():getPlayingParameter():getValue() then
        NI.DATA.TransportAccess.togglePlay(App)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onRecordButton(Pressed)

    if Pressed then

        if self:getShiftPressed() then

            -- count-in is handled by the host in plugin case
            if NI.APP.isStandalone() then
                NI.DATA.TransportAccess.startEventRecording(App, true, false)
            end
        else
            if MaschineHelper.isRecording() then
                NI.DATA.TransportAccess.stopEventRecording(App)
            else
                NI.DATA.TransportAccess.startEventRecording(App, false, false)
            end
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onLoopButton(Pressed)

    if Pressed then
        NI.DATA.TransportAccess.toggleLoop(App)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onMetronomeButton(Pressed)

    if Pressed then
        MaschineHelper.toggleMetronome()
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onUndoRedo(Pressed)

    if not Pressed then
        return
    end

    local ShiftPressed = self:getShiftPressed()

    if ShiftPressed and ActionHelper.canRedo(false) then
        App:getTransactionManager():redoTransactionMarker()

    elseif not ShiftPressed and ActionHelper.canUndo(false) then
        App:getTransactionManager():undoTransactionMarker()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onAutoWrite(Pressed)
    if Pressed then
        if self:getShiftPressed() then
            NI.DATA.EventPatternTools.removeModulationEvents(App)

        else
            NI.DATA.WORKSPACE.toggleAutoWriteEnabledKompleteKontrol(App)
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onClear(Pressed)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onClear(Pressed)
    end

    if self.ActivePage and self.ActivePage.onClear then
        self.ActivePage:onClear(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onKeyMode(Pressed)

    if Pressed then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            local KeyModeOn = Group:getMidiInputKitMode():getValue() == NI.DATA.KitMode.DRUMKIT
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Group:getMidiInputKitMode(),
                KeyModeOn and NI.DATA.KitMode.OFF or NI.DATA.KitMode.DRUMKIT)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:getActivePageID()

    return self.ActivePageID

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenButtonTrackOverlay(Index, Pressed)

    GroupOverlayHelper.onScreenButton(Index, Pressed)

    local PageOrOverlay = self:getActivePageOrOverlay()
    self.SpeechAssist:onScreenButton(Index, PageOrOverlay, false)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenEncoderTrackOverlay(Index, EncoderInc)

    GroupOverlayHelper.onScreenEncoder(Index, EncoderInc)

    self.SpeechAssist:onEncoderEvent(Index, true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onWheelTrackOverlay(Value)

    GroupOverlayHelper.onWheel(Value)

    self.SpeechAssist:onEncoderEvent(1, true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenButtonQuantizeOverlay(Index, Pressed)

    QuantizeOverlayHelper.onScreenButton(Index, Pressed)

    local PageOrOverlay = self:getActivePageOrOverlay()
    self.SpeechAssist:onScreenButton(Index, PageOrOverlay, false)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenEncoderQuantizeOverlay(Index, EncoderInc)

    QuantizeOverlayHelper.onScreenEncoder(Index, EncoderInc)

    self.SpeechAssist:onEncoderEvent(Index, true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onWheelQuantizeOverlay(Value)

    QuantizeOverlayHelper.onWheel(Value)

    self.SpeechAssist:onEncoderEvent(2, true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onWheelButtonQuantizeOverlay(Pressed)

    QuantizeOverlayHelper.onWheelButton(Pressed)

    local PageOrOverlay = self:getActivePageOrOverlay()
    self.SpeechAssist:onScreenButton(1, PageOrOverlay, false)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onScreenEncoderTempoOverlay(Index, EncoderInc)

    TempoOverlayHelper.onScreenEncoder(Index, EncoderInc)

    self.SpeechAssist:onEncoderEvent(Index, true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2MAS:onWheelTempoOverlay(Value)

    TempoOverlayHelper.onWheel(Value)

    self.SpeechAssist:onEncoderEvent(1, true)
end

------------------------------------------------------------------------------------------------------------------------
-- The Instance
ControllerScriptInterface = KompleteKontrol2MAS()
