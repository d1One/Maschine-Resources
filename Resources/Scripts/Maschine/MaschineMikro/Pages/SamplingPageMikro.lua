------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/ParameterHandlerMikro"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Maschine/MaschineMikro/Pages/BrowsePageMikro"
require "Scripts/Maschine/MaschineMikro/Pages/SamplingPageSliceApplyMikro"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageMikro = class( 'SamplingPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "SamplingPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SAMPLE }

    self.IsPinned = true

    -- set screen modes
    self.ScreenMode = nil -- modes: 0 = Record, 1 = Edit, 2 = Slice, 3 = Zone (all defined in SamplingHelper)

    -- set parameter widgets
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    self.SamplerEditFuncIndex = 1
    self.AudioModuleEditFuncIndex = 1
    self.FlashTick = 0
    self.SlicePadPage = 0
    self.RecordingPadPage = 0

    self.SampleBrowsePage = BrowsePageMikro(Controller, self)
    self.SliceApplyPage = SamplingPageSliceApplyMikro(Controller, self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:getFocusModuleEditFuncIndex()

    if NI.DATA.StateHelper.getFocusSampler(App, nil) ~= nil then
        return self.SamplerEditFuncIndex
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) ~= nil then
        return self.AudioModuleEditFuncIndex
    else
        return 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:setFocusModuleEditFuncIndex(Index)

    if NI.DATA.StateHelper.getFocusSampler(App, nil) ~= nil then
        self.SamplerEditFuncIndex = Index
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) ~= nil then
        self.AudioModuleEditFuncIndex = Index
    end

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:setupScreen()

    -- create screen
    self.Screen = ScreenMikro(self) -- PARAMETER_MODE_MULTI

    -- insert status bar
    self.StatusLabel = {}
    self.StatusBar = ScreenHelper.createBarWithLabels(self.Screen.InfoGroupBar, self.StatusLabel, {""}, "Status", "Status")

    self.Screen:addNavModeScreen()

    -- empty strings would make buttons invisible, but currently it is not specified that way
    self.Screen:styleScreenButtons({"", "", ""}, "HeadButtonRow", "HeadButton")
    ScreenHelper.setWidgetText(self.Screen.NavButtons, {"", "REC", "EDIT", "SLICE", "ZONE", ""})

    self.Screen:setNavMode(false)
    self.Screen.NavButtons[1]:setVisible(false)
    self.Screen.NavButtons[6]:setVisible(false)

    -- record level meter widget
    self.RecordBar = NI.GUI.insertBar(self.Screen.SamplingPageStack, "RecordBar")
    self.RecordBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "RecordBarStyle")
    self.RecordMeter = NI.GUI.insertMasterLevelMeter(self.RecordBar, "RecordLevelMeter")
    self.RecordMeter:style("RecordMeter")
    self.RecordMeter:setPeakHoldAndDeclineInterval(false, 0.5)

    -- wave editor bar
    self.WaveEditBar = NI.GUI.insertBar(self.Screen.SamplingPageStack, "WaveEditBar")
    self.WaveEditBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "WaveEditBarStyle")
    self.WaveEditor = NI.GUI.insertSampleOwnerWaveEditor(self.WaveEditBar, App, true, "SampleOwnerWaveEditor")
    self.WaveEditor:setHWWidget()
    self.WaveEditor:showTimeline(false)
    self.WaveEditor:showScrollbar(false)
    self.WaveEditor:setStereo(false)

    -- slicing wave editor bar
    self.SlicingBar = NI.GUI.insertBar(self.Screen.SamplingPageStack, "SlicingBar")
    self.SlicingBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "WaveEditBarStyle")
    self.SliceWaveEditor = NI.GUI.insertSliceWaveEditor(self.SlicingBar, App, "SliceWaveEditor")
    self.SliceWaveEditor:setAlwaysShowFocusSlice(true)
    self.SliceWaveEditor:setHWWidget()
    self.SliceWaveEditor:showTimeline(false)
    self.SliceWaveEditor:showScrollbar(false)
    self.SliceWaveEditor:setStereo(false)

    -- set screen mode
    self.RecHistOnPads = App:getWorkspace():getRecHistOnPadsParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:inNavMode()

    return self.Screen:getNavMode() ~= 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onTimer()

    if self.IsVisible then

        if self.ScreenMode == SamplingScreenMode.RECORD then
            self:updateRecordScreen(false, true)
            self:updateWaveEditorRecordHeader()

        elseif self.ScreenMode == SamplingScreenMode.SLICE then
            local SlicePlaying = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App)
            if SlicePlaying ~= self.IsSlicePlaying then
                self.IsSlicePlaying = SlicePlaying
                self:updateSliceScreen(true)
            end
        end

        self.Controller:setTimer(self, 2)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:setMode(Mode)

    if self.ScreenMode ~= Mode then
        self.ScreenMode = Mode
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateScreens(ForceUpdate)

    if self.SampleBrowsePage and self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:updateScreens(ForceUpdate)
        return
    elseif self.SliceApplyPage and self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:updateScreens(ForceUpdate)
        return
    end

    -- Default ScreenButton States: visible
    self.Screen.ScreenButton[1]:setVisible(true)
    self.Screen.ScreenButton[2]:setVisible(true)
    self.Screen.ScreenButton[3]:setVisible(true)

    -- If the focus object changes, updateScreens() is called and we need to make sure
    -- the screen state of the HW is in sync with the SW
    SamplingHelper.checkScreenMode(self)

    if self:inNavMode() then

        self:updateNavModeScreen(ForceUpdate)
        PageMikro.updateScreens(self, ForceUpdate) -- call base
        return

    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    self.Screen.SamplingPageStack:setVisible(Group ~= nil)

    if not Group then

        PageMikro.updateScreens(self, ForceUpdate) -- call base
        return

    elseif self.ScreenMode == SamplingScreenMode.RECORD then

        self.Screen.SamplingPageStack:setTop(self.RecordBar)
        self:updateRecordScreen(ForceUpdate, false)
        self:updateWaveEditorRecordHeader()

    elseif self.ScreenMode == SamplingScreenMode.EDIT or self.ScreenMode == SamplingScreenMode.ZONE then

        App:getWaveScrollHelper():setWidget(self.WaveEditor)
        self:updateEditZoneScreen(ForceUpdate)
        self:updateWaveEditorHeader()

    elseif self.ScreenMode == SamplingScreenMode.SLICE then

        App:getWaveScrollHelper():setWidget(self.SliceWaveEditor)
        self:updateSliceScreen(ForceUpdate)
        self:updateWaveEditorHeader()

    end

    PageMikro.updateScreens(self, ForceUpdate) -- call base

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateRecordScreen(ForceUpdate, FromTimer)

    if self:inNavMode() then
        return
    end

    local StateCache = App:getStateCache()

    -- Update Current Page
    if ForceUpdate or NI.DATA.ParameterCache.isValid(App) and StateCache:isFocusSampleChanged() then
        local FocusTakeIndex = SamplingHelper.getFocusTakeIndex()
        self.RecordingPadPage = FocusTakeIndex and math.floor(FocusTakeIndex / 16) or 0
    end

    -- Custom pad mode behaviour (play recording)
    NHLController:setPadMode(self.RecHistOnPads and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_SOUND)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    if Recorder then
        -- set the visual threshold indicator (something between 0 - 100)
        local ThresholdParam = Recorder:getDetectThreshold()

        if ForceUpdate or ThresholdParam:isChanged() then
            local ThresholdVal = 1 - (ThresholdParam:getValue() / (ThresholdParam:getMax() - ThresholdParam:getMin())) * -1
            self.RecordMeter:setVolume(ThresholdVal, true)
         end

         -- update the input levels
         self.RecordMeter:setLevels(Recorder:getLevelGUIReadout())

    else
        self.RecordMeter:setVolume(0, true)
    end

    -- update record screen buttons
    local RecordMode = Recorder and (Recorder:isWaiting() or Recorder:isRecording())

    if ForceUpdate or (Recorder and FromTimer) then

        local Button1Text

        if Recorder then
            if Recorder:isWaiting() then
                Button1Text = "START"

                if FromTimer then
                    self.FlashTick = self.FlashTick + 1
                    LEDHelper.setLEDState(NI.HW.LED_F1, (self.FlashTick % 8 < 4) and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
                end

            elseif Recorder:isRecording() then
                Button1Text = "STOP"
                LEDHelper.setLEDState(NI.HW.LED_F1, LEDHelper.LS_DIM)
            else
                Button1Text = "START"
            end
        end

        self.Screen.ScreenButton[1]:setText(Button1Text or "")
        self.Screen.ScreenButton[1]:setSelected(RecordMode)

    end

    local ShiftPressed = self.Controller:getShiftPressed()

    if not ShiftPressed then
        self.Screen.ScreenButton[1]:setVisible(true)
        local IsAuto = Recorder and Recorder:getRecordingModeParameter():getValue() == NI.DATA.MODE_AUTO or false
        if IsAuto then
            self.Screen.ScreenButton[1]:setEnabled(NI.DATA.RecorderAlgorithms.hasValidMidiOutputSelected(Recorder))
        else
            self.Screen.ScreenButton[1]:setEnabled(Recorder ~= nil)
        end

        local CanPrev, CanNext = SamplingHelper.canPrevNextTake()

        if self.RecHistOnPads and not RecordMode then
            self.Screen.ScreenButton[2]:setVisible(false)
            self.Screen.ScreenButton[2]:setEnabled(false)
        else
            self.Screen.ScreenButton[2]:setVisible(true)
            self.Screen.ScreenButton[2]:setText(RecordMode and "CANCEL" or "PREV")
            self.Screen.ScreenButton[2]:setEnabled(RecordMode or CanPrev)
        end

        local Button3Text
        local Button3Enabled
        local Button3Visible

        if RecordMode then
            Button3Text = ""
            Button3Enabled = false
            Button3Visible = false
        elseif self.RecHistOnPads then
            Button3Text = "DELETE"
            Button3Enabled = SamplingHelper.getFocusRecording() ~= nil
            Button3Visible = true
        else
            Button3Text = "NEXT"
            Button3Enabled = CanNext
            Button3Visible = true
        end

        self.Screen.ScreenButton[3]:setText(Button3Text)
        self.Screen.ScreenButton[3]:setEnabled(Button3Enabled)
        self.Screen.ScreenButton[3]:setVisible(Button3Visible)
        self.Screen.ScreenButton[3]:setSelected(false)
    else

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[1]:setVisible(false)

        self.Screen.ScreenButton[2]:setEnabled(false)
        self.Screen.ScreenButton[2]:setVisible(false)

        self.Screen.ScreenButton[3]:setEnabled(true)
        self.Screen.ScreenButton[3]:setText("TAKES")
        self.Screen.ScreenButton[3]:setSelected(self.RecHistOnPads)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateWaveEditorRecordHeader()

    local Take = SamplingHelper.getFocusTake()

    if Take and Take:getSample() then
        self.Screen.Title[1]:setText(Take:getName())
    elseif SamplingHelper.getTakeListCount() == 0 then
        self.Screen.Title[1]:setText("NO TAKE RECORDED")
    elseif Take and not Take:getSample() then
        self.Screen.Title[1]:setText("MISSING SAMPLE")
    else
        self.Screen.Title[1]:setText("NO TAKE SELECTED")
    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local RecordMode = Recorder and (Recorder:isWaiting() or Recorder:isRecording())

    if RecordMode then
        self.StatusLabel[1]:setText(string.upper(NI.DATA.RecorderAccess.getRecordingInfoString(App, Recorder)))
    end

    self.Screen.ParameterBar[1]:setActive(not RecordMode)
    self.Screen.ParameterBar[2]:setActive(not RecordMode)
    self.StatusBar:setActive(RecordMode)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateEditZoneScreen(ForceUpdate)

    NHLController:setPadMode(NI.HW.PAD_MODE_SOUND)

    self.Screen.SamplingPageStack:setTop(self.WaveEditBar)

    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    if self.ScreenMode == SamplingScreenMode.ZONE then
        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"PREV", "NEXT", "ADD"}, false)
        local NumZones = SamplingHelper.getNumZones()
        self.Screen.ScreenButton[1]:setEnabled(Sample ~= nil and NumZones > 0 and SamplingHelper.getFocusZoneIndex() > 0)
        self.Screen.ScreenButton[2]:setEnabled(Sample ~= nil and NumZones > 0 and SamplingHelper.getFocusZoneIndex() < NumZones-1)

        local ShiftPressed = self.Controller:getShiftPressed()
        self.Screen.ScreenButton[3]:setText(ShiftPressed and "REMOVE" or "ADD")
        self.Screen.ScreenButton[3]:setEnabled(not ShiftPressed or (ShiftPressed and NumZones > 0))

    elseif SamplingHelper.timeStretchSettingsVisible() then

        self:setFocusModuleEditFuncIndex(SamplingHelper.EditFuncStretch)
        local InRange = SamplingHelper.areTimeStretchParamsInRange()
        ScreenHelper.setWidgetText(self.Screen.ScreenButton,
            {"", SamplingHelper.EditFuncNamesShort[self:getFocusModuleEditFuncIndex()], "APPLY" }, false)
        self.Screen.ScreenButton[2]:setSelected(true)
        self.Screen.ScreenButton[3]:setEnabled(InRange)

    else

        ScreenHelper.setWidgetText(self.Screen.ScreenButton,
            {"<-", SamplingHelper.EditFuncNamesShort[self:getFocusModuleEditFuncIndex()], "->"}, false)
        self.Screen.ScreenButton[2]:setSelected(false)
        self.Screen.ScreenButton[1]:setEnabled(Sample ~= nil)
        self.Screen.ScreenButton[2]:setEnabled(Sample ~= nil)
        self.Screen.ScreenButton[3]:setEnabled(Sample ~= nil)

    end

    -- Update Wave
    self.WaveEditor:setSelectionMarkerVisible(self.ScreenMode == SamplingScreenMode.EDIT)
    self.WaveEditor:setVisible(Sample ~= nil)
    self.WaveEditor:setInvalid(0)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateWaveEditorHeader()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    if not TransactionSample then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local IsAudio = Sound and Sound:getAudioModule()
        self.Screen.Title[1]:setText(IsAudio and "NO TAKE LOADED" or "NO SAMPLE LOADED")
    elseif not Sample then
        self.Screen.Title[1]:setText("MISSING SAMPLE")
    else
        local name = NI.DATA.TransactionSampleAlgorithms.getName(TransactionSample, Sample)
        self.Screen.Title[1]:setText(string.upper(name))
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:IsPadSlicingEnabled()
    return SamplingHelper.getSlicingMode() == NI.DATA.MODE_MANUAL and not self:getSliceEditMode()
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateSliceScreen(ForceUpdate)

    self.Screen.SamplingPageStack:setTop(self.SlicingBar)

    -- Custom pad mode behaviour (play Slice)
    NHLController:setPadMode(NI.HW.PAD_MODE_NONE)

    local SliceLabel = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App) and "SLICE" or "SPLIT"
    local RemoveLabel = self.Controller:getShiftPressed() and "DEL ALL" or "REMOVE"

    ScreenHelper.setWidgetText(self.Screen.ScreenButton,
        self:getSliceEditMode() and {"EDIT", SliceLabel, RemoveLabel} or {"EDIT", "APPL.TO", "APPLY"}, false)

    local Zone = NI.DATA.StateHelper.getFocusZone(App, nil)
    local Sample = Zone and Zone:getSample()
    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)

    local HasSample = Sample ~= nil

    self.Screen.ScreenButton[1]:setEnabled(HasSample)
    self.Screen.ScreenButton[2]:setEnabled(HasSample)
    self.Screen.ScreenButton[3]:setEnabled(HasSample)

    -- update slice pad page
    self.SlicePadPage = SamplingHelper.updateSlicePadPage(self.SlicePadPage, ForceUpdate, self:IsPadSlicingEnabled())

     -- Update Wave
    self.SliceWaveEditor:setInvalid(0)
    self.SliceWaveEditor:setVisible(TransactionSample ~= nil)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateNavModeScreen(ForceUpdate)

    -- update nav screen

    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"", "", ""}, false)

    for Idx = 2, 5 do
        self.Screen.NavButtons[Idx]:setSelected(self.ScreenMode == Idx - 2)
    end

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    self.Screen.NavButtons[4]:setVisible(Sampler ~= nil)
    self.Screen.NavButtons[5]:setVisible(Sampler ~= nil)

    local PageVector = App:getSamplingParameters():getPagesForTab(self.ScreenMode)
    local FocusPage = PageVector and PageVector:getFocusPage() or nil
    local FocusPageIndex = PageVector and PageVector:getFocusPageIndex():getValue() or 0
    local PageName = FocusPage and FocusPage:getPageName() or ""

    self.Screen.NavParamSelectLabels[1]:setVisible(FocusPageIndex > 0)
    self.Screen.NavParamSelectLabels[2]:setText(PageName)
    self.Screen.NavParamSelectLabels[3]:setVisible(PageVector and FocusPageIndex < PageVector:getNumPages()-1)

    self.Screen.NavTitle[1]:setText(SamplingHelper.SamplingTabNames[self.ScreenMode + 1])

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateParameters(ForceUpdate)

    if self.SampleBrowsePage and self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:updateParameters(ForceUpdate)
        return
    elseif self.SliceApplyPage and self.SliceApplyPage.IsVisible then
        self.Screen.ParameterLabel[1]:setVisible(false)
        self.Screen.ParameterLabel[3]:setVisible(false)
        self.SliceApplyPage:updateParameters(ForceUpdate)
        return
    end

    local StateCache = App:getStateCache()

    if self.ScreenMode == SamplingScreenMode.SLICE then
        self:updateSliceParameters(ForceUpdate)
    else

        if self.ScreenMode == SamplingScreenMode.RECORD and self.Controller:getShiftPressed() then

            if self.RecHistOnPads then
                local NumBanks = SamplingHelper.getNumRecordingPages()
                self.Screen.ParameterLabel[2]:setText("BANK " .. tostring(self.RecordingPadPage + 1) .. "/" .. tostring(NumBanks ~= 0 and NumBanks or 1))
            else
                self.Screen.ParameterLabel[2]:setText("")
            end

        else
            -- get parameters from focused parameter page
            local TabIdx = self.ScreenMode
            local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
            local ParamsPage = App:getSamplingParameters():getPagesForTab(TabIdx):getFocusPage()
            local NumParams = ParamsPage and ParamsPage:getNumParameters() or 0

            local FocusParam = ParamsPage and ParamsPage:getParameterFocus() or nil
            local FocusParamIdx = FocusParam and FocusParam:getValue() or 0

            -- set the parameters
            self.ParameterHandler:setParameters({}, true)

            if not SamplingHelper.isRecorderWaitingOrRecording() then
                for Idx = 0, NumParams - 1 do
                    table.insert(self.ParameterHandler.Parameters, ParamsPage:getParameter(Idx))
                end
            end

            -- set focused parameter index
            self.ParameterHandler.ParameterIndex = FocusParamIdx + 1

            self.ParameterHandler:updateParameterNameValue()

        end

    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local RecordMode = Recorder and (Recorder:isWaiting() or Recorder:isRecording())
    local ShiftPressed = self.Controller:getShiftPressed()

    self.Screen.ParameterLabel[4]:setVisible(true)

    if self.ScreenMode == SamplingScreenMode.RECORD and RecordMode then
        self.Screen.ParameterLabel[1]:setVisible(false)
        self.Screen.ParameterLabel[3]:setVisible(false)

    elseif self.ScreenMode == SamplingScreenMode.RECORD and ShiftPressed then
        self.Screen.ParameterLabel[1]:setVisible(self.RecHistOnPads and self.RecordingPadPage > 0)
        self.Screen.ParameterLabel[3]:setVisible(self.RecHistOnPads and self.RecordingPadPage < SamplingHelper.getNumRecordingPages() - 1)
        self.Screen.ParameterLabel[4]:setVisible(false)

    elseif self.ScreenMode == SamplingScreenMode.SLICE and ShiftPressed then

        local NumSlicePages = SamplingHelper.getNumSlicePages()

        local CanPrev = self.SlicePadPage > 0
        local CanNext = self.SlicePadPage < NumSlicePages-1

        self.Screen.ParameterLabel[1]:setVisible(CanPrev)
        self.Screen.ParameterLabel[3]:setVisible(CanNext)
        self.Screen.ParameterLabel[4]:setVisible(true)
        self.Screen.ParameterLabel[4]:setVisible(false)

    else
        self.Screen.ParameterLabel[1]:setVisible(self.ParameterHandler.ParameterIndex > 1)
        self.Screen.ParameterLabel[3]:setVisible(self.ParameterHandler.ParameterIndex < #self.ParameterHandler.Parameters)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateSliceParameters(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()
    local NumSlicePages = SamplingHelper.getNumSlicePages()
    local EditMode = self:getSliceEditMode()

    if not self.SlicePadPage or NumSlicePages < self.SlicePadPage then
        self.SlicePadPage = NumSlicePages-1
    end

    if ShiftPressed then

        local LabelText = NumSlicePages > 0
                          and "Bank: "..tostring(self.SlicePadPage+1).."/"..tostring(NumSlicePages)
                          or ""
        self.Screen.ParameterLabel[2]:setText(LabelText)
        return

    end

    -- get parameters from focused parameter page
    local TabIdx = self.ScreenMode
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    -- set the parameters
    self.ParameterHandler:setParameters({}, true)

    if EditMode then
        local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)

        self.ParameterHandler:setParameters({"SLICE", "START", "END"}, true)
        self.ParameterHandler.ParameterIndex = math.bound(self.ParameterHandler.ParameterIndex, 1, 3)
        local ParamIndex = self.ParameterHandler.ParameterIndex

        self.Screen.ParameterLabel[2]:setText(tostring(ParamIndex).."/3: "..self.ParameterHandler.Parameters[ParamIndex])


        local Slices = TransactionSample and TransactionSample:getSliceContainer()
        local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS
        local NumSlices = Slices and Slices:getNumSlices()

        if ParamIndex == 1 then
            self.Screen.ParameterLabel[4]:setText(NumSlices and FocusSliceIndex ~= NPOS
                and (tostring(FocusSliceIndex+1).."/"..NumSlices) or "-/-")
        elseif ParamIndex == 2 then
            if Slices then
                local SliceRange = Slices:getFocusSliceFrameRange()
                self.Screen.ParameterLabel[4]:setText(tostring(SliceRange:getMin()))
            end
        elseif ParamIndex == 3 then
            if Slices then
                local SliceRange = Slices:getFocusSliceFrameRange()
                self.Screen.ParameterLabel[4]:setText(tostring(SliceRange:getMax()))
            end
        end

    else

        local ParamsPage = Group and App:getSamplingParameters():getPagesForTab(TabIdx):getFocusPage() or nil
        local NumParams = ParamsPage and ParamsPage:getNumParameters() or 0
        local FocusParam = ParamsPage and ParamsPage:getParameterFocus() or nil
        local FocusParamIdx = FocusParam and FocusParam:getValue() or 0

        for Idx = 0, NumParams - 1 do
            table.insert(self.ParameterHandler.Parameters, ParamsPage:getParameter(Idx))
        end

        -- set focused parameter index
        self.ParameterHandler.ParameterIndex = FocusParamIdx + 1

        self.ParameterHandler:updateParameterNameValue()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updatePadLEDs()

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:updatePadLEDs()
        return
    elseif self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:updatePadLEDs()
        return
    end

    if self:inNavMode() then

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local ColorIndex = Sound and Sound:getColorParameter():getValue() or 16

        for Index, LedID in ipairs (self.Controller.PAD_LEDS) do

            local LedState = LEDHelper.LS_OFF

            if Index >= 13 and Index <= 16 then

                if (Index - 13 == self.ScreenMode) then
                    LedState = LEDHelper.LS_BRIGHT
                elseif Index - 13 > NI.DATA.WORKSPACE.getLastSamplingTab(App) then
                    LedState = LEDHelper.LS_OFF
                else
                    LedState = LEDHelper.LS_DIM
                end

            else
                LedState = LEDHelper.LS_OFF
            end

            LEDHelper.setLEDState(LedID, LedState, ColorIndex)
        end
    elseif self.ScreenMode == SamplingScreenMode.RECORD and self.RecHistOnPads then
        SamplingHelper.updateRecordPagePadLeds(self.Controller.PAD_LEDS, self.RecordingPadPage)

    elseif self.ScreenMode == SamplingScreenMode.SLICE then
        SamplingHelper.updateSlicePagePadLeds(self.Controller.PAD_LEDS, self.SlicePadPage,
            self:IsPadSlicingEnabled())

    else
        -- call base class
        PageMikro.updatePadLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateGroupLEDs()

    if self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:updateGroupLEDs()
        return
    end

    PageMikro.updateGroupLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:updateGroupPageButtonLED(LEDLevel, ForceUpdate)

    if self.SliceApplyPageMikro and self.SliceApplyPageMikro.IsVisible then
        self.SliceApplyPageMikro:updateGroupPageButtonLED(LEDLevel, ForceUpdate)
        return
    end

    PageMikro.updateGroupPageButtonLED(self, LEDLevel, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handlers
------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onShow(Show)

    local PadModeNone = not Show
                            and (self.ScreenMode == SamplingScreenMode.RECORD or self.ScreenMode == SamplingScreenMode.SLICE)
    NHLController:setPadMode(PadModeNone and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)

    if Show then
        self.Controller:setTimer(self, 2)
    else
        self.SliceApplyPage:onShow(false)
        self.SampleBrowsePage:onShow(false)
    end

    -- redirect to Dialog screen if visible
    if self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onShow(Show)
        return
    elseif self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onShow(Show)
        return
    end

    -- call base class
    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onNavButton(Pressed)

    LEDHelper.setLEDState(NI.HW.LED_NAV, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

    if Pressed and self.Screen and self.Screen.NavGroupBar then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    else
        local PadModeNone = self.ScreenMode == SamplingScreenMode.RECORD or self.ScreenMode == SamplingScreenMode.SLICE
        NHLController:setPadMode(PadModeNone and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    self.Screen:setNavMode(Pressed)
    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onWheelButton(Pressed)

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onWheelButton(Pressed)
        return
    end

    PageMikro.onWheelButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onDB3ModelChanged(Model)

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onDB3ModelChanged(Model)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onWheel(Inc)

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:onWheel(Inc)

    elseif self.SliceApplyPage.IsVisible then
        return self.SliceApplyPage:onWheel(Inc)
    end

    if self.Controller:getShiftPressed() and
        (self.ScreenMode == SamplingScreenMode.RECORD or self.ScreenMode == SamplingScreenMode.SLICE) then
        return
    end

    if self:inNavMode() then

        local CurrentTab = NI.DATA.WORKSPACE.getSamplingTab(App)
        local NextTab = CurrentTab + Inc
        NI.DATA.WORKSPACE.setSamplingTab(App, NextTab >= 0 and NextTab or 0) -- Prevent underflow when bridging to size_t
        return true

    elseif self:getSliceEditMode() then

        local ParamIndex = self.ParameterHandler.ParameterIndex
        if ParamIndex == 1 then
            SamplingHelper.shiftFocusSliceIndex(Inc)

        elseif ParamIndex == 2 then
            Inc = Inc / 10
            SamplingHelper.moveFocusSlice(true, Inc, self.Controller:getWheelButtonPressed(), self.SliceWaveEditor:getFramesPerPixel())

        elseif ParamIndex == 3 then
            Inc = Inc / 10
            SamplingHelper.moveFocusSlice(false, Inc, self.Controller:getWheelButtonPressed())

        end

        return true

    else

        -- normal mode: call base class
        return PageMikro.onWheel(self, Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onScreenButton(ButtonIdx, Pressed)

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onScreenButton(ButtonIdx, Pressed)
        return
    elseif self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onScreenButton(ButtonIdx, Pressed)
        return
    elseif self:inNavMode() then
        return
    end

    if Pressed then

        local ShiftPressed = self.Controller:getShiftPressed()

        if self.ScreenMode == SamplingScreenMode.RECORD then

            local Recorder   = NI.DATA.StateHelper.getFocusRecorder(App)
            local RecordMode = Recorder and (Recorder:isWaiting() or Recorder:isRecording())

            if ShiftPressed then
                local Workspace = App:getWorkspace()
                NI.DATA.ParameterAccess.setBoolParameter(App, Workspace:getRecHistOnPadsParameter(), not Workspace:getRecHistOnPadsParameter():getValue())
                self.RecHistOnPads = Workspace:getRecHistOnPadsParameter():getValue()
            else
                if ButtonIdx == 1 then
                    SamplingHelper.toggleRecording()
                elseif ButtonIdx == 2 and RecordMode then
                    SamplingHelper.requestCancelRecording()
                elseif ButtonIdx == 2 or ButtonIdx == 3 and not RecordMode and not self.RecHistOnPads then
                    SamplingHelper.onPrevNextTake(ButtonIdx == 2 and -1 or 1)
                elseif ButtonIdx == 3 and not RecordMode and self.RecHistOnPads then
                    SamplingHelper.removeFocusTake()
                end
            end

        elseif self.ScreenMode == SamplingScreenMode.EDIT then

            local Sample = NI.DATA.StateHelper.getFocusSample(App)

            if ButtonIdx == 1 or ButtonIdx == 3 then

                if SamplingHelper.timeStretchSettingsVisible() then
                    if ButtonIdx == 3 and SamplingHelper.areTimeStretchParamsInRange() then
                        SamplingHelper.applyEditFunction(SamplingHelper.EditFuncStretch)
                    end
                elseif Sample then
                    local Delta = ButtonIdx == 1 and -1 or 1
                    self:setFocusModuleEditFuncIndex(math.wrap(self:getFocusModuleEditFuncIndex() + Delta, 1, SamplingHelper.getNumEditFunctions()))
                    self.Screen.ScreenButton[2]:setText(SamplingHelper.EditFuncNamesShort[self:getFocusModuleEditFuncIndex()])
                end

            elseif ButtonIdx == 2 then

                --Do not deselect the stretch button, when settings are open
                self.Screen.ScreenButton[ButtonIdx]:setSelected(SamplingHelper.timeStretchSettingsVisible() == true)

                if self:getFocusModuleEditFuncIndex() == SamplingHelper.EditFuncStretch then
                    SamplingHelper.toggleTimeStretchSettings()
                else
                    SamplingHelper.applyEditFunction(self:getFocusModuleEditFuncIndex())
                end

            end

        elseif self.ScreenMode == SamplingScreenMode.SLICE then

            local EditMode = self:getSliceEditMode()

            local Zone = NI.DATA.StateHelper.getFocusZone(App, nil)
            local Sample = Zone and Zone:getSample()

            if ButtonIdx == 1 then

                if Sample then
                    self.Screen.ScreenButton[1]:setSelected(not EditMode)
                    self.Screen.ScreenButton[2]:setSelected(false)
                    self:updateScreens(true)
                end

            elseif ButtonIdx == 2 then
                if EditMode then
                     SamplingHelper.sliceFocusSlice()
                    self.SliceWaveEditor:refreshSlices()
                elseif Sample ~= nil then
                    self.SliceApplyPage.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
                    self.Screen.ParameterLabel[1]:setVisible(false)
                    self.Screen.ParameterLabel[3]:setVisible(false)
                    self.SliceApplyPage:onShow(true)
                end
            elseif ButtonIdx == 3 then
                if EditMode then

                    if ShiftPressed then
                        SamplingHelper.removeAllSlices()
                    else
                        SamplingHelper.removeFocusSlice()
                    end
                else
                    SamplingHelper.applySlicing()
                end
            end

        elseif self.ScreenMode == SamplingScreenMode.ZONE then

            if ButtonIdx == 1 or ButtonIdx == 2 then
                SamplingHelper.selectPrevNextZone(ButtonIdx == 2)
            else
                if self.Controller:getShiftPressed() then
                    SamplingHelper.removeFocusZone()
                else
                    self.SampleBrowsePage.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
                    self.SampleBrowsePage:onShow(true)
                end
            end

        end

    end

    -- call base class (i.e. select/deselect button)
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onLeftRightButton(Right, Pressed)

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onLeftRightButton(Right, Pressed)
        return
    elseif self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onLeftRightButton(Right, Pressed)
        return
    end

    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local RecordMode = Recorder and (Recorder:isWaiting() or Recorder:isRecording())

    if not Pressed or (self.ScreenMode == SamplingScreenMode.RECORD and RecordMode) or (not Sample and self.ScreenMode ~= SamplingScreenMode.RECORD) then
        return
    end

    local Increment = Right and 1 or -1
    local TabIdx = self.ScreenMode

    if self:inNavMode() then

        SamplingHelper.onLeftRightButton(self, Right)
        --NI.DATA.SamplingParametersAccess.focusPageOffset(App, TabIdx, Increment)

    else
        if TabIdx == SamplingScreenMode.SLICE and self.Controller:getShiftPressed() then
            local NumSlicePages = SamplingHelper.getNumSlicePages()
            local CanPrev = self.SlicePadPage > 0
            local CanNext = self.SlicePadPage < NumSlicePages-1

            if (Right and CanNext) or ((not Right) and CanPrev) then
                self.SlicePadPage = self.SlicePadPage + Increment
                self:updateScreens()
            end

        elseif self:getSliceEditMode() then

            self.ParameterHandler.ParameterIndex = math.bound(self.ParameterHandler.ParameterIndex + Increment, 1, 3)
            self:updateParameters()

        elseif TabIdx == SamplingScreenMode.RECORD and self.Controller:getShiftPressed() then

            if self.RecHistOnPads then
                local NumBanks = SamplingHelper.getNumRecordingPages()
                CanPrev = self.RecordingPadPage > 0
                CanNext = self.RecordingPadPage < NumBanks-1

                if Increment == 1 and CanNext or Increment == -1 and CanPrev then
                    SamplingHelper.setFocusTake((self.RecordingPadPage + Increment) * 16 + 1)
                end

                self:updateParameters()
            end

        else

            if Right then
                NI.DATA.SamplingParametersAccess.focusNextParameter(App, TabIdx)
            else
                NI.DATA.SamplingParametersAccess.focusPrevParameter(App, TabIdx)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onPadEvent(PadIndex, Trigger, PadValue)
        return
    end

    if self:inNavMode() then

        local NewTab = PadIndex - 13
        local FirstTab = NI.DATA.WORKSPACE.getFirstSamplingTab()
        local LastTab = NI.DATA.WORKSPACE.getLastSamplingTab(App)

        if (Trigger and math.inRange(NewTab, FirstTab, LastTab)) then
            NI.DATA.WORKSPACE.setSamplingTab(App, NewTab)
        end

    elseif Trigger and self.ScreenMode == SamplingScreenMode.RECORD and self.RecHistOnPads then

        SamplingHelper.setFocusTake(PadIndex + self.RecordingPadPage * 16, true)

    elseif Trigger and self.ScreenMode == SamplingScreenMode.SLICE then

        local NumSlices, FocusSliceIndex =  SamplingHelper.getNumSlicesAndFocusSliceIndex()
        FocusSliceIndex = FocusSliceIndex ~= NPOS and FocusSliceIndex+1 or NPOS

        local SliceIndex = PadIndex + self.SlicePadPage * 16

        if SliceIndex < NumSlices+1 then
            SamplingHelper.setFocusSlice(SliceIndex, true)
            self:updateSliceScreen(true)

        elseif SliceIndex == NumSlices+1 and
            SamplingHelper.isLastSliceFocused() and
            self.IsSlicePlaying and
            self:IsPadSlicingEnabled() then

            -- split
            SamplingHelper.sliceFocusSlice()
            self.SliceWaveEditor:refreshSlices()
        end

    else -- EDIT and ZONE

        if self.ScreenMode == SamplingScreenMode.EDIT and NI.DATA.StateHelper.getFocusAudioModule(App) ~= nil then
            if Trigger then
                PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)
            end
        else
            PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:onGroupButton(Pressed)

    if self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onGroupButton(Pressed)
        return
    end

    PageMikro.onGroupButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:getSliceEditMode()

    return self.ScreenMode == SamplingScreenMode.SLICE and self.Screen.ScreenButton[1]:isSelected()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikro:getSliceApplyToMode()

    return self.ScreenMode == SamplingScreenMode.SLICE
                                and not self:getSliceEditMode()
                                and self.Screen.ScreenButton[2]:isSelected()

end

------------------------------------------------------------------------------------------------------------------------
