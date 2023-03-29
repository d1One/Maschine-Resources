------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageBase = class( 'SamplingPageBase', PageMaschine )

local RECORDER_STOPPED = 0
local RECORDER_WAITING = 1
local RECORDER_RECORDING = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:__init(Controller, Page)

    -- init base class
    PageMaschine.__init(self, Page,  Controller)

    self.IsPinned = true

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SAMPLE }

    -- set screen modes
    self.ScreenMode = nil -- modes: 0 = Record, 1 = Edit, 2 = Slice, 3 = Zone (all defined in SamplingHelper)
    self.RecHistOnPads = App:getWorkspace():getRecHistOnPadsParameter():getValue()

    self.SamplerEditFuncIndex = 1
    self.AudioModuleEditFuncIndex = 1
    self.TimeStretchSettings = nil

    self.RecordingPadPage = 0
    self.SlicePadPage = 0

    self.SliceApplyPage = nil
    self.SampleBrowsePage = nil

    self.SlicePageIndex = 1

    self.PreviousText = "PREV"
    self.CachedRecorderState = RECORDER_STOPPED

    -- setup screen
    self:setupScreen()

    self.IsSlicePlaying = false

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:getFocusModuleEditFuncIndex()

    if NI.DATA.StateHelper.getFocusSampler(App, nil) then
        return self.SamplerEditFuncIndex
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) then
        return self.AudioModuleEditFuncIndex
    else
        return 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:setFocusModuleEditFuncIndex(Index)

    if NI.DATA.StateHelper.getFocusSampler(App, nil) then
        self.SamplerEditFuncIndex = Index
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) then
        self.AudioModuleEditFuncIndex = Index
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:setMode(Mode)

    local ModeChanged = self.ScreenMode ~= Mode
    self.ScreenMode = Mode

    if ModeChanged then
        self:updateScreens(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase.getRecorderState()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if Recorder then
        if Recorder:isWaiting() then
            return RECORDER_WAITING
        elseif Recorder:isRecording() then
            return RECORDER_RECORDING
        end
    end

    return RECORDER_STOPPED
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onTimer()

    if self.IsVisible then

        -- there's one case where a parameter disappears from the second page and we end up with a blank page
        if self.ParameterHandler.PageIndex > 0 and self.ParameterHandler.NumPages == 1 then
            NI.DATA.SamplingParametersAccess.focusPageOffset(App, self.ScreenMode, -1)
        end

        if self.ScreenMode == SamplingScreenMode.RECORD then
            self:updateRecorder()

            -- refresh record tab buttons if recorder state changes
            if SamplingPageBase.getRecorderState() ~= self.CachedRecorderState then
                self:updateRecordPageScreenButtons()
            end
        end

        if self.ScreenMode == SamplingScreenMode.SLICE then
            local IsPlaying = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App)
            if IsPlaying ~= self.IsSlicePlaying then
                self.IsSlicePlaying = IsPlaying
                self:updateSlicePageScreenButtons()
                self:updateSliceScreen(true)
            end

            local AnalysisState = SamplingHelper.getAnalysisState()
            if AnalysisState == NI.DATA.ANALYSIS_STARTED then
                SamplingHelper.refreshAnalysisProgress()
            elseif AnalysisState == NI.DATA.ANALYSIS_FINISHED then
                SamplingHelper.sliceNoUndo()
            end
        end

        if self.SliceApplyPage.IsVisible and self.SliceApplyPage.onTimer then
            self.SliceApplyPage:onTimer()
        end


        self.Controller:setTimer(self, 2)
    end

    PageMaschine.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateScreens(ForceUpdate)

    -- If the focus object changes, updateScreens() is called and we need to make sure
    -- the screen state of the HW is in sync with the SW
    SamplingHelper.checkScreenMode(self)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    self.StackLeft:setVisible(Group ~= nil)
    self.StackRight:setVisible(Group ~= nil)

    if Group then

        if self.ScreenMode == SamplingScreenMode.RECORD then

            self.StackLeft:setTop(self.RecordBarLeft)
            self.StackRight:setTop(self.RecordBarRight)
            self:updateRecordScreen(ForceUpdate)

        elseif self.ScreenMode == SamplingScreenMode.EDIT then

            self.StackLeft:setTop(self.EditBarLeft)
            if SamplingHelper.timeStretchSettingsVisible() then
                self:setFocusModuleEditFuncIndex(SamplingHelper.EditFuncStretch)
                self.Screen.ScreenRight.ParamBar:setActive(true)
            else
                self.StackRight:setTop(self.EditBarRight)
            end
            App:getWaveScrollHelper():setWidget(self.EditWaveEditor)
            self:updateEditScreen(ForceUpdate)

        elseif self.ScreenMode == SamplingScreenMode.SLICE then

            self.StackLeft:setTop(self.SlicingBarLeft)
            self.StackRight:setTop(self.SlicingBarRight)
            App:getWaveScrollHelper():setWidget(self.SliceWaveEditor)
            self:updateSliceScreen(ForceUpdate)

        elseif self.ScreenMode == SamplingScreenMode.ZONE then

            self.StackLeft:setTop(self.ZoneBarLeft or self.EditBarLeft)
            self.StackRight:setTop(self.EditBarRight)
            App:getWaveScrollHelper():setWidget(self.EditWaveEditor)
            self:updateZoneScreen(ForceUpdate)

        end

    else

        ScreenHelper.setWidgetText({self.Screen.ScreenButton[5], self.Screen.ScreenButton[6],
            self.Screen.ScreenButton[7], self.Screen.ScreenButton[8]}, {"", "", "", ""})

    end

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateLeftScreenButtons(StyleForMiddleButtons, StyleForRightButton)

    -- update screen button (tab) states
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local AudioModule = NI.DATA.StateHelper.getFocusAudioModule(App)
    for tab = 1, 4 do
        self.Screen.ScreenButton[tab]:setSelected(self.ScreenMode == tab - 1)
        self.Screen.ScreenButton[tab]:setVisible(Sampler ~= nil or (AudioModule ~= nil and tab < 3))
    end

    -- The Audio module has only the RECORD and EDIT tabs, so we need to adapt the style
    -- of the EDIT button to look like the last button in the row.
    if NI.DATA.StateHelper.getFocusSampler(App, nil) then
        self.Screen.ScreenButton[2]:style("EDIT", StyleForMiddleButtons)
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) then
        self.Screen.ScreenButton[2]:style("EDIT", StyleForRightButton)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateRecordScreen(ForceUpdate)

    self.CachedRecorderState = SamplingPageBase.getRecorderState()

    if ForceUpdate then
        self:updateRecorder()
    end

     -- Custom pad mode behaviour (play recording)
    NHLController:setPadMode(self.RecHistOnPads and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_SOUND)

    -- Update Current Page
    local StateCache = App:getStateCache()
    if ForceUpdate or NI.DATA.ParameterCache.isValid(App) and StateCache:isFocusSampleChanged() then
        local FocusTakeIndex = SamplingHelper.getFocusTakeIndex()
        self.RecordingPadPage = FocusTakeIndex and math.floor(FocusTakeIndex / 16) or 0
    end

    -- screen buttons
    self:updateRecordPageScreenButtons()

    -- update waveform
    self.WaveEditorRecord:setInvalid(0)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateEditScreen(ForceUpdate)

    NHLController:setPadMode(NI.HW.PAD_MODE_SOUND)
    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    local ApplyEnabled = Sample ~= nil

    if self:getFocusModuleEditFuncIndex() == SamplingHelper.EditFuncStretch then
        if not SamplingHelper.areTimeStretchParamsInRange() then
            ApplyEnabled = false
        end
    end

    -- screen buttons
    self:updateEditPageScreenButtons(ApplyEnabled)

    -- Update Header
    self:updateWaveEditorHeader()

    -- Update Wave
    self.EditWaveEditor:setInvalid(0)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateSliceScreen(ForceUpdate)

    -- update slice pad page
    self.SlicePadPage = SamplingHelper.updateSlicePadPage(self.SlicePadPage, ForceUpdate, true)

    -- Custom pad mode behaviour (play Slice)
    NHLController:setPadMode(NI.HW.PAD_MODE_NONE)

    -- screen buttons
    self:updateSlicePageScreenButtons()

    -- Update Header
    self:updateWaveEditorHeader()

    -- Update Wave
    self.SliceWaveEditor:setInvalid(0)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateZoneScreen(ForceUpdate)

    NHLController:setPadMode(NI.HW.PAD_MODE_SOUND)

    self:updateZonePageScreenButtons()

    -- Update Header
    self:updateWaveEditorHeader()

    -- Update Wave
    self.EditWaveEditor:setInvalid(0)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateParameters(ForceUpdate)

    local Parameters = {}

    self.ParameterHandler.UseNoParamsCaption = false
    self.ParameterHandler.NumParamsPerPage = 4

    self.ParameterHandler.ParameterWidgets[1]:setVisible(true)
    self.ParameterHandler.ParameterWidgets[2]:setVisible(true)
    self.ParameterHandler.ParameterWidgets[3]:setVisible(true)
    self.ParameterHandler.ParameterWidgets[4]:setVisible(true)

    self.ParameterHandler.CustomSections = {}
    self.ParameterHandler.CustomNames = {}
    self.ParameterHandler.CustomValues = {}

    if self.ScreenMode == SamplingScreenMode.SLICE then
        -- In Slice mode, cook own params
        self:updateSliceParams()
        self.ParameterHandler:update(ForceUpdate)
        self:refreshAccessibleEncoderInfo()
        return
    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local PageVector = Group and App:getSamplingParameters():getPagesForTab(self.ScreenMode) or nil
    local ParamsPage = PageVector and PageVector:getFocusPage() or nil
    local FocusPageIdx = PageVector and PageVector:getFocusPageIndex():getValue() or 0

    self.ParameterHandler.NumPages = PageVector and PageVector:getNumPages() or 0
    self.ParameterHandler.PageIndex = FocusPageIdx + 1

    for ParamIndex = 1, 8 do
        local Parameter = ParamsPage and ParamsPage:getParameter(ParamIndex - 1)
        self.ParameterHandler.CustomSections[ParamIndex] = ""

        if Parameter then
            Parameters[ParamIndex] = Parameter
        else
            self.ParameterHandler.ParameterWidgets[ParamIndex]:setName("")
            self.ParameterHandler.ParameterWidgets[ParamIndex]:setValue("")
        end
    end

    local IsPageDisabled = self.ScreenMode == SamplingScreenMode.RECORD and SamplingHelper.isRecorderWaitingOrRecording()

    -- set page name
    if ParamsPage then
        self.ParameterHandler.CustomSections[1] = ParamsPage:getPageName()
    end

    self.ParameterHandler:setParameters(Parameters)
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onDB3ModelChanged(Model)

    if self.SampleBrowsePage.IsVisible then
        self.SampleBrowsePage:onDB3ModelChanged(Model)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onPrevNextButton(Pressed, Right)

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:onPrevNextButton(Pressed, Right)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onWheel(Inc)

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:onWheel(Inc)
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onWheelButton(Pressed)

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:onWheelButton(Pressed)
    end

    return false

end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateJogwheel()

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:updateJogwheel()
    end

    return false
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onLeftRightButton(Right, Pressed)

    if self.SampleBrowsePage.IsVisible then

        self.SampleBrowsePage:onLeftRightButton(Right, Pressed)

    elseif not self.SliceApplyPage.IsVisible then
        if Pressed and self.ScreenMode ~= SamplingScreenMode.SLICE then
            SamplingHelper.onLeftRightButton(self, Right)

        elseif Pressed then

            self.ParameterHandler:onPrevNextParameterPage(Right and 1 or -1)
            self.SlicePageIndex = self.ParameterHandler.PageIndex
            self:updateScreens(true)
        end

        LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
            self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenButton(ButtonIdx, Pressed)

    if self.SliceApplyPage.IsVisible then
        -- Redirect to Dialog Screen
        return self.SliceApplyPage:onScreenButton(ButtonIdx, Pressed)
    elseif self.SampleBrowsePage.IsVisible then
        -- Redirect to Browse page
        return self.SampleBrowsePage:onScreenButton(ButtonIdx, Pressed)
    end

    if Pressed then

        if ButtonIdx >= 1 and ButtonIdx <= 4 then

            -- Select tab
            self:selectSamplingTab(ButtonIdx)

        elseif self.ScreenMode == SamplingScreenMode.RECORD then

            self:onScreenButtonRecord(ButtonIdx)

        elseif self.ScreenMode == SamplingScreenMode.EDIT then

            self:onScreenButtonEdit(ButtonIdx)

        elseif self.ScreenMode == SamplingScreenMode.SLICE then

            self:onScreenButtonSlice(ButtonIdx)

        elseif self.ScreenMode == SamplingScreenMode.ZONE then

            self:onScreenButtonZone(ButtonIdx)

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenEncoder(Idx, Inc)

    if self.SliceApplyPage.IsVisible then

        -- redirect to Dialog screen if visible
        return self.SliceApplyPage:onScreenEncoder(Idx, Inc)

    elseif self.SampleBrowsePage.IsVisible then

        -- redirect to Browse page
        return self.SampleBrowsePage:onScreenEncoder(Idx, Inc)

    elseif SamplingHelper.timeStretchSettingsVisible() and self.ScreenMode == SamplingScreenMode.EDIT then

        -- call base
        return PageMaschine.onScreenEncoder(self, Idx, Inc)

    end

    -- recording params, page 1: disabled when recording
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local PageVector = Group and App:getSamplingParameters():getPagesForTab(self.ScreenMode) or nil
    local ParamsPage = PageVector and PageVector:getFocusPage() or nil
    if ParamsPage and ParamsPage:isDisabledWhenRecording() and
        self.ScreenMode == SamplingScreenMode.RECORD and
        SamplingHelper.isRecorderWaitingOrRecording() then
        return
    end


    if Idx == 5 then

        SamplingHelper.zoomWaveForm(Inc, self.Controller:getShiftPressed(), self.ScreenMode == SamplingScreenMode.RECORD)

    elseif Idx == 6 then

        SamplingHelper.scrollWaveForm(Inc, self.Controller:getShiftPressed(), self.ScreenMode == SamplingScreenMode.RECORD)

    elseif self.ScreenMode == SamplingScreenMode.SLICE and self.SlicePageIndex == 2 then
        -- Slice Edit 'Custom' Params
        if Idx == 1 then
            -- Select Slice
            if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                SamplingHelper.shiftFocusSliceIndex(Inc > 0 and 1 or -1)
            end

        elseif Idx == 3 then
            -- Move Slice Start
            SamplingHelper.moveFocusSlice(true, Inc, self.Controller:getShiftPressed(), self.SliceWaveEditor:getFramesPerPixel() * 10)

        elseif Idx == 4 then
            -- Move Slice End
            SamplingHelper.moveFocusSlice(false, Inc, self.Controller:getShiftPressed())

        end
    else
        -- call base
        PageMaschine.onScreenEncoder(self, Idx, Inc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updatePadLEDs()

    if self.SliceApplyPage.IsVisible then

        -- redirect to Dialog screen
        return self.SliceApplyPage:updatePadLEDs()

    elseif self.SampleBrowsePage.IsVisible then

        -- redirect to Browse page
        return self.SampleBrowsePage:updatePadLEDs()

    elseif self.ScreenMode == SamplingScreenMode.RECORD and self.RecHistOnPads then

        SamplingHelper.updateRecordPagePadLeds(self.Controller.PAD_LEDS, self.RecordingPadPage)

    elseif self.ScreenMode == SamplingScreenMode.SLICE then

        SamplingHelper.updateSlicePagePadLeds(self.Controller.PAD_LEDS, self.SlicePadPage,
                        true)

    else

        PageMaschine.updatePadLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateGroupLEDs()

    if self.SliceApplyPage.IsVisible then

        self.SliceApplyPage:updateGroupLEDs()

    else

        PageMaschine.updateGroupLEDs(self)

    end


end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onPadEvent(PadIndex, Trigger, PadValue)

    if self.SliceApplyPage.IsVisible then
        return self.SliceApplyPage:onPadEvent(PadIndex, Trigger, PadValue)
    end

    if self.ScreenMode == SamplingScreenMode.RECORD and self.RecHistOnPads then
        if Trigger then
            SamplingHelper.setFocusTake(PadIndex + self.RecordingPadPage * 16, true)
        end
        return true

    elseif self.ScreenMode == SamplingScreenMode.SLICE then
        if Trigger then
            local NumSlices, FocusSliceIndex =  SamplingHelper.getNumSlicesAndFocusSliceIndex()
            FocusSliceIndex = FocusSliceIndex ~= NPOS and FocusSliceIndex+1 or NPOS

            local SliceIndex = PadIndex + self.SlicePadPage * 16

            if SliceIndex < NumSlices+1 then
                if FocusSliceIndex ~= SliceIndex then
                    SamplingHelper.setFocusSlice(SliceIndex, true)
                else
                    SamplingHelper.preHearSlice(SliceIndex)
                end

                self:updateSliceScreen(true)

            elseif SliceIndex == NumSlices+1 and SamplingHelper.isLastSliceFocused() and self.IsSlicePlaying then

                -- split
                SamplingHelper.sliceFocusSlice()
                self.SliceWaveEditor:refreshSlices()
            end

        end
        return true

    else -- EDIT and ZONE and RECORD (no hist)

        PageMaschine.onPadEvent(self, PadIndex, Trigger, PadValue)
    end


end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onShow(Show)

    NHLController:setPadMode(Show and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)

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
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onGroupButton(GroupIndex, Pressed)

    -- redirect to SliceApply screen if visible
    if self.SliceApplyPage.IsVisible then
        self.SliceApplyPage:onGroupButton(GroupIndex, Pressed)
        return
    end

    PageMaschine.onGroupButton(self, GroupIndex, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateRecordPageScreenButtons()

    local ShiftPressed = self.Controller:getShiftPressed()
    local StateCache = App:getStateCache()
    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local RecordMode = Recorder:getRecordingModeParameter():getValue()
    local isRecording = Recorder and (Recorder:isWaiting() or Recorder:isRecording())

    -- Start/Stop/Wait, Cancel / DELETE....................................................................

    local Texts = { ShiftPressed and "TAKES" or "START", ShiftPressed and NI.APP.isHeadless() and "RENAME" or "DELETE" }

    if Recorder then
        if Recorder:isWaiting() then
            Texts = {"WAITING", "CANCEL"}
        elseif Recorder:isRecording() then
            Texts = {"STOP", "CANCEL"}
        end
    end

    self.Screen:unsetArrowText(1, Texts[1], Texts[2])

    if RecordMode == NI.DATA.MODE_AUTO then
        self.Screen.ScreenButton[5]:setEnabled(NI.DATA.RecorderAlgorithms.hasValidMidiOutputSelected(Recorder))
    else
        self.Screen.ScreenButton[5]:setEnabled(true)
    end
    self.Screen.ScreenButton[5]:setVisible(true)
    self.Screen.ScreenButton[6]:setSelected(false)
    self.Screen.ScreenButton[6]:setActive(true)

    if not isRecording and ShiftPressed then
        self.Screen.ScreenButton[5]:setSelected(self.RecHistOnPads)
        self.Screen.ScreenButton[6]:setEnabled(NI.APP.isHeadless() and SamplingHelper.getFocusRecording() ~= nil)
        self.Screen.ScreenButton[6]:setVisible(NI.APP.isHeadless())
    else
        self.Screen.ScreenButton[5]:setSelected(false)
        self.Screen.ScreenButton[6]:setVisible(true)
        self.Screen.ScreenButton[6]:setEnabled(isRecording or SamplingHelper.getFocusRecording() ~= nil)
    end

    --Prev / Next.........................................................................

    self.Screen.ScreenButton[7]:setVisible(not isRecording)
    self.Screen.ScreenButton[8]:setVisible(not isRecording)

    if not isRecording then

        local CanPrev, CanNext = false, false

        if ShiftPressed then
            if self.RecHistOnPads then
                -- recording banks
                local NumBanks = SamplingHelper.getNumRecordingPages()
                CanPrev = self.RecordingPadPage > 0
                CanNext = self.RecordingPadPage < NumBanks-1
                self.Screen:setArrowText(2, "BANK " .. tostring(self.RecordingPadPage + 1))
            else
                self.Screen:unsetArrowText(2)
                self.Screen.ScreenButton[7]:setVisible(false)
                self.Screen.ScreenButton[8]:setVisible(false)
            end

        else
            -- recordings
            self.Screen:unsetArrowText(2, self.PreviousText, "NEXT")
            CanPrev, CanNext = SamplingHelper.canPrevNextTake()
        end

        -- set button selected to false in case the sampling edit stretch setting was selected
        self.Screen.ScreenButton[7]:setSelected(false)
        self.Screen.ScreenButton[7]:setEnabled(CanPrev)
        self.Screen.ScreenButton[8]:setEnabled(CanNext)

    end

    -- Call base
    PageMaschine.updateScreenButtons(self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateEditPageScreenButtons(ApplyEnabled)

    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    local EditFuncIndex = self:getFocusModuleEditFuncIndex()

    self.Screen:setArrowText(1, SamplingHelper.EditFuncNames[EditFuncIndex])
    self.Screen:unsetArrowText(2, "SETTINGS", "APPLY")

    self.Screen.ScreenButton[5]:setSelected(false)
    self.Screen.ScreenButton[5]:setActive(true)
    self.Screen.ScreenButton[5]:setVisible(true)
    self.Screen.ScreenButton[5]:setEnabled(ApplyEnabled)

    self.Screen.ScreenButton[6]:setSelected(false)
    self.Screen.ScreenButton[6]:setActive(true)
    self.Screen.ScreenButton[6]:setVisible(true)
    self.Screen.ScreenButton[6]:setEnabled(ApplyEnabled)

    self.Screen.ScreenButton[7]:setSelected(SamplingHelper.timeStretchSettingsVisible() == true)
    self.Screen.ScreenButton[7]:setActive(true)
    self.Screen.ScreenButton[7]:setVisible(EditFuncIndex == SamplingHelper.EditFuncStretch)
    self.Screen.ScreenButton[7]:setEnabled(EditFuncIndex == SamplingHelper.EditFuncStretch and Sample ~= nil)

    self.Screen.ScreenButton[8]:setEnabled(ApplyEnabled)
    self.Screen.ScreenButton[8]:setVisible(true)
    self.Screen.ScreenButton[8]:setActive(true)

    -- Call base
    PageMaschine.updateScreenButtons(self)

end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateSlicePageScreenButtons()

    local ShiftPressed = self.Controller:getShiftPressed()
    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    self.Screen.ScreenButton[5]:setEnabled(Sample ~= nil)
    self.Screen.ScreenButton[6]:setEnabled(Sample ~= nil)
    self.Screen.ScreenButton[7]:setEnabled(Sample ~= nil)
    self.Screen.ScreenButton[8]:setEnabled(Sample ~= nil)

    self.Screen.ScreenButton[5]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[6]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[7]:setVisible(true)
    self.Screen.ScreenButton[8]:setVisible(true)

    self.Screen.ScreenButton[7]:setActive(true)
    self.Screen.ScreenButton[7]:setSelected(false)
    self.Screen.ScreenButton[8]:setActive(true)

    if ShiftPressed then
        self.Screen:unsetArrowText(1)
        self.Screen:setArrowText(2, "BANK "..self.SlicePadPage+1)
        local NumSlicePages = SamplingHelper.getNumSlicePages(true)
        self.Screen.ScreenButton[7]:setEnabled(self.SlicePadPage > 0)
        self.Screen.ScreenButton[8]:setEnabled(self.SlicePadPage < NumSlicePages-1)

    else
        local RemoveAllText = NI.HW.FEATURE.SCREEN_TYPE_STUDIO and "DELETE ALL" or "DEL ALL"

        self.Screen:unsetArrowText(1, self.IsSlicePlaying and "SLICE" or "SPLIT", "REMOVE")
        self.Screen:unsetArrowText(2, RemoveAllText, "APPLY...")
    end

    -- Call base
    PageMaschine.updateScreenButtons(self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateZonePageScreenButtons()

    self.Screen.ScreenButton[5]:setSelected(false)

    self.Screen:unsetArrowText(1, "REMOVE", "ADD")
    self.Screen:unsetArrowText(2, self.PreviousText, "NEXT")

    self.Screen.ScreenButton[5]:setVisible(true)
    self.Screen.ScreenButton[5]:setEnabled(SamplingHelper.getNumZones() > 0)

    self.Screen.ScreenButton[6]:setVisible(true)
    self.Screen.ScreenButton[6]:setEnabled(true)
    self.Screen.ScreenButton[6]:setActive(true)
    self.Screen.ScreenButton[6]:setSelected(false)

    if SamplingHelper.getNumZones() > 0 and SamplingHelper.getFocusZoneIndex() == NPOS then
        return
    end

    local CanPrev, CanNext = SamplingHelper.canPrevNextZone()

    self.Screen.ScreenButton[7]:setVisible(true)
    self.Screen.ScreenButton[7]:setEnabled(CanPrev)
    self.Screen.ScreenButton[7]:setSelected(false)

    self.Screen.ScreenButton[8]:setVisible(true)
    self.Screen.ScreenButton[8]:setEnabled(CanNext)

    -- Call base
    PageMaschine.updateScreenButtons(self)

end

local FlashTick = 0

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateRecorder()

    local StateCache = App:getStateCache()
    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    if Recorder then

        local RecordMode = Recorder:getRecordingModeParameter():getValue()
        self.RecordMeter:setSliderVisible(RecordMode == NI.DATA.MODE_DETECT)

        -- set the visual threshold indicator (something between 0 - 100)
        local ThresholdParam = Recorder:getDetectThreshold()

        if RecordMode == NI.DATA.MODE_DETECT then
            local ThresholdVal = 1 - (ThresholdParam:getValue() / (ThresholdParam:getMax() - ThresholdParam:getMin())) * -1
            self.RecordMeter:setVolume(ThresholdVal, true)
        end

        -- update the input levels
        self.RecordMeter:setLevels(Recorder:getLevelGUIReadout())
        if Recorder:isWaiting() then
            FlashTick = FlashTick + 1
            LEDHelper.setLEDState(NI.HW.LED_SCREEN_BUTTON_5, (FlashTick % 8 < 4) and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
        end

    else
        self.RecordMeter:setVolume(0, true)
    end

    -- update Header
    self:updateWaveEditorRecordHeader()

end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenButtonZone(ButtonIdx)

    if ButtonIdx == 5 then

        SamplingHelper.removeFocusZone()

    elseif ButtonIdx == 6 then

        self.SampleBrowsePage.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
        self.SampleBrowsePage:onShow(true)

    elseif ButtonIdx == 7 then

        SamplingHelper.selectPrevNextZone(false)

    elseif ButtonIdx == 8 then

        SamplingHelper.selectPrevNextZone(true)

    end

end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenButtonSlice(ButtonIdx)

    local Sample = NI.DATA.StateHelper.getFocusSample(App)
    if Sample == nil then
        return
    end

    -- <, >
    if self.Controller:getShiftPressed() then

        local NumSlicePages = SamplingHelper.getNumSlicePages(self.IsSlicePlaying)
        local CanPrev = self.SlicePadPage > 0
        local CanNext = self.SlicePadPage < NumSlicePages-1
        local DoNext = ButtonIdx == 8

        if (DoNext and CanNext) or (not DoNext and CanPrev) then
            self.SlicePadPage = self.SlicePadPage + (DoNext and 1 or -1)
        end

        return
    end


    if ButtonIdx == 5 then
        SamplingHelper.sliceFocusSlice()
        self.SliceWaveEditor:refreshSlices()

    elseif ButtonIdx == 6 then
        SamplingHelper.removeFocusSlice()

    elseif ButtonIdx == 7 then
        SamplingHelper.removeAllSlices()

    elseif ButtonIdx == 8 then
        self.SliceApplyPage.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
        self.SliceApplyPage:onShow(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenButtonEdit(ButtonIdx)

    if NI.DATA.StateHelper.getFocusSample(App) == nil then
        return
    end

    if ButtonIdx == 5 or ButtonIdx == 6 then

        local Delta = ButtonIdx == 5 and -1 or 1
        local CurrentIndex = self:getFocusModuleEditFuncIndex()
        local MaxIndex = SamplingHelper.getNumEditFunctions()
        self:setFocusModuleEditFuncIndex(math.wrap(CurrentIndex + Delta, 1, MaxIndex))

        if self:getFocusModuleEditFuncIndex() ~= SamplingHelper.EditFuncStretch then
            SamplingHelper.showTimeStretchSettings(false)
        end

        self:updateEditScreen(true)

    elseif ButtonIdx == 7 then

        if self:getFocusModuleEditFuncIndex() == SamplingHelper.EditFuncStretch then
            SamplingHelper.toggleTimeStretchSettings()
        end

    elseif ButtonIdx == 8 then

        if self:getFocusModuleEditFuncIndex() ~= SamplingHelper.EditFuncStretch or SamplingHelper.areTimeStretchParamsInRange() then
            SamplingHelper.applyEditFunction(self:getFocusModuleEditFuncIndex())
        end

    end

end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:onScreenButtonRecord(ButtonIdx)

    local Workspace = App:getWorkspace()

    if ButtonIdx == 5 then

        if self.Controller:getShiftPressed() then
            NI.DATA.ParameterAccess.setBoolParameter(App, Workspace:getRecHistOnPadsParameter(), not Workspace:getRecHistOnPadsParameter():getValue())
            self.RecHistOnPads = Workspace:getRecHistOnPadsParameter():getValue()
        elseif self.Screen.ScreenButton[5]:isEnabled() then
            if NI.DATA.StateHelper.getFocusRecorder(App) then
                SamplingHelper.toggleRecording()
                self:updateRecordScreen(true) -- cant wait for timer
            end
        end

    elseif ButtonIdx == 6 then

        if SamplingHelper.isRecorderWaitingOrRecording() then
            -- cancel recording
            SamplingHelper.requestCancelRecording()
            self:updateRecordScreen(true) -- cant wait for timer

        elseif self.Controller:getShiftPressed() and NI.APP.isHeadless() then
            -- rename focus sample
            local Take = SamplingHelper.getFocusTake()
            local TransactionSample = Take and Take:getTransactionSample() or nil
            if TransactionSample then
                NI.GUI.DialogAccess.openSampleRenameDialog(App, TransactionSample)

            end

        elseif not self.Controller:getShiftPressed() and self.Screen.ScreenButton[6]:isVisible() then
            -- delete focus Sample
            SamplingHelper.removeFocusTake()
        end

    elseif (ButtonIdx == 7 or ButtonIdx == 8) and self.Screen.ScreenButton[ButtonIdx]:isEnabled() then

        if self.Controller:getShiftPressed() then
            -- shift: Prev/Next Page
            local Increment = ButtonIdx == 7 and -1 or 1
            SamplingHelper.setFocusTake((self.RecordingPadPage + Increment) * 16 + 1)
        else
            -- Prev/Next Sample
            SamplingHelper.onPrevNextTake(ButtonIdx == 7 and -1 or 1)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:selectSamplingTab(TabIdx)
    NI.DATA.WORKSPACE.setSamplingTab(App, TabIdx - 1)
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageBase:updateSliceParams()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    if not TransactionSample or not Sample then
        self.ParameterHandler.NumPages = 1
        return
    end

    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS
    local NumSlices = Slices and Slices:getNumSlices()

    local CustomSections = {}
    local CustomNames = {}
    local CustomValues = {}
    local Parameters = {}

    local function getTimeParams(Slices)
        return Slices and Slices:getBpmModeParameter(),
            Slices and (Slices:getBpmModeParameter():getValue() == NI.DATA.BPM_MODE_AUTO and
                    Slices:getAutoBpmParameter() or Slices:getManualBpmParameter())
        end

    self.ParameterHandler.NumPages = 3
    self.ParameterHandler.PageIndex = math.bound(self.SlicePageIndex, 1, self.ParameterHandler.NumPages)

    --..................................................................................
    -- Slice modes
    local SliceMode = Slices and Slices:getSliceModeParameter():getValue()
    local AnalysisState = SamplingHelper.getAnalysisState()
    if self.ParameterHandler.PageIndex == 1 then

        CustomSections[1] = "Slicer"
        if SliceMode == NI.DATA.MODE_DETECT then

            Parameters[1] = Slices:getSliceModeParameter()

            if AnalysisState == NI.DATA.ANALYSIS_PARAMETERS_SWAPPED then
                Parameters[2] = Slices:getDensityParameter()
                Parameters[3] = Slices:getZeroCrossingParameter()
            else
                Parameters[2] = Slices:getInProgressParameter()
            end

        elseif SliceMode == NI.DATA.MODE_SPLIT then

            CustomSections[1] = "Slicer"
            Parameters[1] = Slices:getSliceModeParameter()
            Parameters[2] = Slices:getSplitCountParameter()

        elseif SliceMode == NI.DATA.MODE_GRID then

            CustomSections[1] = "Slicer"
            Parameters[1] = Slices:getSliceModeParameter()
            Parameters[2] = Slices:getGridNoteLengthParameter()
            Parameters[3], Parameters[4] = getTimeParams(Slices)

        elseif SliceMode == NI.DATA.MODE_MANUAL then

            CustomSections[1] = "Slicer"
            Parameters[1] = Slices:getSliceModeParameter()
            Parameters[2] = AnalysisState == NI.DATA.ANALYSIS_PARAMETERS_SWAPPED and
                                        App:getWorkspace():getAutoSnapParameter() or Slices:getInProgressParameter()
        end

    --..................................................................................
    -- Edit
    elseif self.ParameterHandler.PageIndex == 2 then

        CustomSections = {"Edit", "", "", ""}
        CustomNames = {"SLICE", "", "START", "END"}

        CustomValues[1] = NumSlices and FocusSliceIndex ~= NPOS and (tostring(FocusSliceIndex+1).."/"..NumSlices) or "-/-"

        if Slices then
            local SliceRange = Slices:getFocusSliceFrameRange()
            CustomValues[3] = tostring(SliceRange:getMin())
            CustomValues[4] = tostring(SliceRange:getMax())
        end

    --..................................................................................
    -- Apply
    elseif self.ParameterHandler.PageIndex == 3 then

        CustomSections[1] = "Apply"
        Parameters[1] = App:getWorkspace():getSamplingSliceToMonoParameter()
        Parameters[2] = App:getWorkspace():getSlicerApplyModeParameter()

        if App:getWorkspace():getSlicerApplyModeParameter():getValue() ~=
            NI.DATA.Workspace.SLICER_APPLYMODE_NO_PATTERN and
            SliceMode ~= NI.DATA.MODE_GRID then
            Parameters[3], Parameters[4] = getTimeParams(Slices)
        end
    end


    self.ParameterHandler.Parameters = Parameters
    self.ParameterHandler.CustomSections = CustomSections
    self.ParameterHandler.CustomNames = CustomNames
    self.ParameterHandler.CustomValues = CustomValues

    -- update left/right screen buttons
    LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
        self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)

end
