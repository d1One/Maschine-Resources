------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SamplingPageBase"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Components/Looper"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Maschine/MaschineStudio/Pages/SamplingPageSliceApplyStudio"
require "Scripts/Maschine/MaschineStudio/Pages/BrowsePageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageStudio = class( 'SamplingPageStudio', SamplingPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:__init(Controller)

    -- init base class
    SamplingPageBase.__init(self, Controller, "SamplingPageStudio")

    self.SliceApplyPage = SamplingPageSliceApplyStudio(Controller, self)
    self.SampleBrowsePage = BrowsePageStudio(Controller, self)

    self.PreviousText = "PREVIOUS"

    self.Looper = Looper()
    self.Looper.Enabled = true

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onTimer()

    SamplingPageBase.onTimer(self)
    self.Looper:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:setupScreen()

    -- call base class
    self.Screen = ScreenMaschineStudio(self)

    -- SCREEN LEFT

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"RECORD", "EDIT", "SLICE", "ZONE"},
        {"HeadTabLeft", "HeadTabCenter", "HeadTabCenter", "HeadTabRight"}, false)

    --todo: use QEInfoBar
    self.SamplerInfoBar = self.Screen.ScreenLeft.InfoBar


    -- SCREEN RIGHT

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"<<", ">>", "<<", ">>"}, "HeadButton", false)

    self.InfoBarRight = NI.GUI.insertBar(self.Screen.ScreenRight, "InfoBarRight")
    self.InfoBarRight:style(NI.GUI.ALIGN_WIDGET_RIGHT, "InfoBar")
    self.SampleName = NI.GUI.insertLabel(self.InfoBarRight, "InfoBarSampleName")
    self.SampleName:style("", "")
    NI.GUI.enableCropModeForLabel(self.SampleName)
    self.SampleLengthValue = NI.GUI.insertLabel(self.InfoBarRight, "InfoBarSampleLengthValue")
    self.SampleLengthValue:style("", "")
    self.SampleLengthValue:setAutoResize(true)
    self.SampleLengthTitle = NI.GUI.insertLabel(self.InfoBarRight, "InfoBarSampleLengthTitle")
    self.SampleLengthTitle:style("LENGTH", "")
    self.SampleLengthTitle:setAutoResize(true)

    self.InfoBarRight:setFlex(self.SampleName)

    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.Screen.ScreenRight.ParamBar = NI.GUI.insertBar(self.Screen.ScreenRight, "ParamBar")
    self.Screen.ScreenRight.ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(self.Screen.ScreenRight.ParamBar)


    -- left & right screen stack
    self.StackLeft = NI.GUI.insertStack(self.Screen.ScreenLeft.DisplayBar, "SamplingStackLeft")
    self.StackLeft:style("SamplingPage")
    self.StackRight = NI.GUI.insertStack(self.Screen.ScreenRight.DisplayBar, "SamplingStackRight")
    self.StackRight:style("SamplingPage")

    self.Screen.ScreenLeft.DisplayBar:setFlex(self.StackLeft)
    self.Screen.ScreenRight.DisplayBar:setFlex(self.StackRight)

    -----------------------------------------------------------------------------------
    -- Record screen
    -----------------------------------------------------------------------------------
    self.RecordBarLeft = NI.GUI.insertBar(self.StackLeft, "RecordBarLeft")
    self.RecordBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "RecordBarLeftStyle")
    self.RecordBarRight = NI.GUI.insertBar(self.StackRight, "RecordBarRight")
    self.RecordBarRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "RecordBarRight")

    self.RecordMeter = NI.GUI.insertMasterLevelMeter(self.RecordBarLeft, "RecordLevelMeter")
    self.RecordMeter:style("RecordMeter")
    self.RecordMeter:setPeakHoldAndDeclineInterval(false, 0.5)

    self.RecordHistory = NI.GUI.insertRecordingHistory(self.RecordBarLeft, App, "RecordingHistory")

    self.RecordBarLeft:setFlex(self.RecordHistory)

    self.WaveEditorRecord = NI.GUI.insertRecordWaveEditor(self.RecordBarRight, App, "RecordWaveBar")
    self.WaveEditorRecord:showTimeline(false)
    self.WaveEditorRecord:showScrollbar(false)
    self.WaveEditorRecord:setHWWidget()

    self.RecordBarRight:setFlex(self.WaveEditorRecord)

    -----------------------------------------------------------------------------------
    -- Edit screen
    -----------------------------------------------------------------------------------
    self.EditBarLeft = NI.GUI.insertBar(self.StackLeft, "EditBarLeft")
    self.EditBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "EditBar")
    self.EditBarRight = NI.GUI.insertBar(self.StackRight, "EditBarRight")
    self.EditBarRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "EditBar")

    self.EditWaveEditorOV = NI.GUI.insertSampleOwnerWaveEditor(self.EditBarLeft, App, true, "EditWaveBarOV")
    self.EditWaveEditorOV:showTimeline(false)
    self.EditWaveEditorOV:showScrollbar(false)
    self.EditWaveEditorOV:setHWOverview()
    self.EditWaveEditorOV:setHWWidget()
    self.EditBarLeft:setFlex(self.EditWaveEditorOV)

    self.EditWaveEditor = NI.GUI.insertSampleOwnerWaveEditor(self.EditBarRight, App, true, "EditWaveBar")
    self.EditWaveEditor:showTimeline(false)
    self.EditWaveEditor:showScrollbar(false)
    self.EditWaveEditor:setHWWidget()
    self.EditBarRight:setFlex(self.EditWaveEditor)

    -----------------------------------------------------------------------------------
    -- Slice Screen
    -----------------------------------------------------------------------------------
    self.SlicingBarLeft = NI.GUI.insertBar(self.StackLeft, "SlicingBarLeft")
    self.SlicingBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "SlicingBar")
    self.SlicingBarRight = NI.GUI.insertBar(self.StackRight, "SlicingBarRight")
    self.SlicingBarRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "SlicingBar")

    self.SliceWaveEditorOV = NI.GUI.insertSliceWaveEditor(self.SlicingBarLeft, App, "SlicingWaveDisplayOV")
    self.SliceWaveEditorOV:showTimeline(false)
    self.SliceWaveEditorOV:showScrollbar(false)
    self.SliceWaveEditorOV:setAlwaysShowFocusSlice(true)
    self.SliceWaveEditorOV:setHWOverview()
    self.SliceWaveEditorOV:setHWWidget()
    self.SlicingBarLeft:setFlex(self.SliceWaveEditorOV)

    self.SliceWaveEditor = NI.GUI.insertSliceWaveEditor(self.SlicingBarRight, App, "SlicingWaveDisplay")
    self.SliceWaveEditor:showTimeline(false)
    self.SliceWaveEditor:showScrollbar(false)
    self.SliceWaveEditor:setHWWidget()
    self.SliceWaveEditor:setAlwaysShowFocusSlice(true)

    self.SlicingBarRight:setFlex(self.SliceWaveEditor)

    -----------------------------------------------------------------------------------
    -- TimeStretch Screen
    -----------------------------------------------------------------------------------

    --Use Edit Screen

    -----------------------------------------------------------------------------------
    -- Zone Screen
    -----------------------------------------------------------------------------------
    self.ZoneBarLeft = NI.GUI.insertBar(self.StackLeft, "ZoneBarLeft")
    self.ZoneBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "ZoneBar")
    self.ZoneMapEditor = NI.GUI.insertZoneMapEditor(self.ZoneBarLeft, App, "ZoneMapEditor")
    self.ZoneMapEditor:setHWScreen(true)
    self.ZoneBarLeft:setFlex(self.ZoneMapEditor)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateScreens(ForceUpdate)

    -- redirect to 'dialog' screens if one is visible
    if self.SliceApplyPage and self.SliceApplyPage.IsVisible then
        --todo: use QEInfoBar
        self.Screen.ScreenLeft.InfoBar = self.SliceApplyPage.Screen.ScreenLeft.InfoBar
        self.Controller.CapacitiveNavIcons:Enable(false)
        self.SliceApplyPage:updateScreens(ForceUpdate)
        return

    elseif self.SampleBrowsePage and self.SampleBrowsePage.IsVisible then

        self.Controller.CapacitiveNavIcons:Enable(false)
        self.SampleBrowsePage:updateScreens(ForceUpdate)
        return
    else
        --todo: use QEInfoBar
        self.Screen.ScreenLeft.InfoBar = self.SamplerInfoBar
    end

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self.Screen.ScreenRight.ParamBar:setActive(false)

    SamplingPageBase.updateLeftScreenButtons(self, "HeadTabCenter", "HeadTabRight")
    SamplingPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateWaveEditorRecordHeader()

    local Take = SamplingHelper.getFocusTake()
    local hasTake = Take ~= nil

    self.SampleName:setVisible(hasTake)
    self.SampleLengthValue:setVisible(hasTake)
    self.SampleLengthTitle:setVisible(hasTake)

    if hasTake then

        self.SampleName:setText(Take:getName())
        self.SampleLengthValue:setText(SamplingHelper.getFocusSampleLengthAsText())

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateWaveEditorHeader()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Sample = NI.DATA.StateHelper.getFocusSample(App)
    local isValid = TransactionSample ~= nil and Sample ~= nil

    self.SampleName:setVisible(isValid)
    self.SampleLengthValue:setVisible(isValid)
    self.SampleLengthTitle:setVisible(isValid)

    if isValid then

        local Name = NI.DATA.TransactionSampleAlgorithms.getName(TransactionSample, Sample)

        self.SampleName:setText(Name)
        self.SampleLengthValue:setText(SamplingHelper.getFocusSampleLengthAsText())

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateRecordScreen(ForceUpdate)

    local StateCache = App:getStateCache()
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Sound and NI.DATA.ParameterCache.isValid(App)
        and (ForceUpdate or StateCache:isFocusSampleChanged() or Sound:getColorParameter():isChanged()) then
        self.RecordMeter:setPaletteColorIndex(Sound:getColorParameter():getValue()+1)
    end

    self.Controller.CapacitiveNavIcons:Enable(
        not SamplingHelper.isRecorderWaitingOrRecording() and SamplingHelper.getTakeListCount() > 0)

    SamplingPageBase.updateRecordScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateEditScreen(ForceUpdate)

    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    self.EditWaveEditorOV:setVisible(Sample ~= nil)

    self.Controller.CapacitiveNavIcons:Enable(Sample ~= nil and not SamplingHelper.timeStretchSettingsVisible())

    SamplingPageBase.updateEditScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateSliceScreen(ForceUpdate)

    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    self.SliceWaveEditorOV:setVisible(Sample ~= nil)

    self.Controller.CapacitiveNavIcons:Enable(Sample ~= nil)

    SamplingPageBase.updateSliceScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateZoneScreen(ForceUpdate)

    self.Controller.CapacitiveNavIcons:Enable(NI.DATA.StateHelper.getFocusSample(App) ~= nil)

    SamplingPageBase.updateZoneScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:updateParameters(ForceUpdate)

    SamplingPageBase.updateParameters(self, ForceUpdate)

    local IsPageDisabled = self.ScreenMode == SamplingScreenMode.RECORD and SamplingHelper.isRecorderWaitingOrRecording()
    self.Controller.CapacitiveList:assignParametersToCaps(IsPageDisabled and {} or self.ParameterHandler.Parameters)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onLevelEncoder(EncoderInc)

    local Source = App:getWorkspace():getHWLevelMeterSourceParameter():getValue()

    if Source ~= NI.DATA.LEVEL_SOURCE_INPUT then
        return false
    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local ThresholdParam = Recorder and Recorder:getDetectThreshold()
    local RecordMode = Recorder and Recorder:getRecordingModeParameter():getValue()

    if ThresholdParam and RecordMode == NI.DATA.MODE_DETECT then
        EncoderInc = EncoderInc > 0 and 1 or -1
        NI.DATA.ParameterAccess.setFloatParameter(App, ThresholdParam, ThresholdParam:getValue() + EncoderInc)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onLevelSourceButton(Pressed, Button)

    local Source = LevelMeterStudio.ButtonToStereoSource[Button]
    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    -- Don't modify the level source if we are already recording.
    if not Pressed or Source == nil or SamplingHelper.isRecorderWaitingOrRecording() then
        return false
    end

    local RecorderSourceParam = Recorder:getRecordingSourceParameter()
    local StereoInputParam = Recorder:getExtStereoInputsParameter()
    local MonoInputParam = Recorder:getExtMonoInputsParameter()

    local RecorderSource = RecorderSourceParam:getValue()
    local MonoSource = MonoInputParam:getValue()
    local StereoSource = StereoInputParam:getValue()

    -- Switch to Stereo Input if set to Internal
    if RecorderSource == NI.DATA.SOURCE_INTERNAL then
        RecorderSource = NI.DATA.SOURCE_EXTERNAL_STEREO
        NI.DATA.ParameterAccess.setEnumParameter(App, RecorderSourceParam, NI.DATA.SOURCE_EXTERNAL_STEREO)
    end

    if RecorderSource == NI.DATA.SOURCE_EXTERNAL_STEREO then
        StereoSource = Source

    -- switch to StereoLeft or toggle between Left + Right
    elseif RecorderSource == NI.DATA.SOURCE_EXTERNAL_MONO then
        local StereoLeft = Source * 2
        local StereoRight = StereoLeft + 1

        MonoSource = MonoSource == StereoLeft and StereoRight or StereoLeft
    end

    -- set parameters
    local HWSourceParameter = App:getWorkspace():getHWLevelMeterSourceParameter()

    if RecorderSource == NI.DATA.SOURCE_EXTERNAL_STEREO then

        NI.DATA.ParameterAccess.setValues(App, "SW + HW Input Sources",
            StereoInputParam, StereoSource, HWSourceParameter, NI.DATA.LEVEL_SOURCE_INPUT)

    elseif RecorderSource == NI.DATA.SOURCE_EXTERNAL_MONO then

        NI.DATA.ParameterAccess.setValues(App, "SW + HW Input Sources",
            MonoInputParam, MonoSource, HWSourceParameter, NI.DATA.LEVEL_SOURCE_INPUT)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:isSoundQEAllowed()

    if (self.ScreenMode == SamplingScreenMode.RECORD or self.ScreenMode == SamplingScreenMode.SLICE) then
        return false
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onFootswitchDetect(Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onFootswitchTip(Index, Pressed)

    self.Looper:onFootswitch(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageStudio:onFootswitchRing(Index, Pressed)

    self.Looper:onFootswitch(Pressed)

end

------------------------------------------------------------------------------------------------------------------------
