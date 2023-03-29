------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SamplingPageBase"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Maschine/Pages/SamplingPageSliceApply"
require "Scripts/Shared/Pages/BrowsePage"

local ATTR_STRETCH_MODE = NI.UTILS.Symbol("StretchMode")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPage = class( 'SamplingPage', SamplingPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPage:__init(Controller)

    -- init base class
    SamplingPageBase.__init(self, Controller, "SamplingPage")

    self.SliceApplyPage = SamplingPageSliceApply(Controller, self)
    self.SampleBrowsePage = BrowsePage(Controller, self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:setupScreen()

    -- call base class
    self.Screen = ScreenMaschine(self)

    -- screen buttons
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"RECORD", "EDIT", "SLICE", "ZONE"}, "HeadTab")
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"<<", ">>", "<<", ">>"}, "HeadButton")

    -- WaveEditor Header
    self.WaveEditorHeaderLabels = {}
    self.WaveEditorHeader = ScreenHelper.createBarWithLabels(
        self.Screen.ScreenRight, self.WaveEditorHeaderLabels, {"" ,""}, "InfoBar", "SampleEditLabel")
        self.WaveEditorHeaderLabels[2]:setAutoResize(true)
        self.WaveEditorHeader:setFlex(self.WaveEditorHeaderLabels[1])

    -- left & right screen stack
    self.StackLeft  = NI.GUI.insertStack(self.Screen.ScreenLeft, "SamplingStackLeft")
    self.StackLeft:style("SamplingPage")
    self.StackRight = NI.GUI.insertStack(self.Screen.ScreenRight, "SamplingStackRight")
    self.StackRight:style("SamplingPage")

    self.Screen.ScreenLeft:setFlex(self.StackLeft)
    self.Screen.ScreenRight:setFlex(self.StackRight)

    -- Parameters
    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenRight)


    -----------------------------------------------------------------------------------
    -- Record screen
    -----------------------------------------------------------------------------------

    self.RecordBarLeft = NI.GUI.insertBar(self.StackLeft, "RecordBarLeft")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "RecordBar")
    self.RecordBarRight = NI.GUI.insertBar(self.StackRight, "RecordBarRight")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "RecordBar")

    self.RecordMeter = NI.GUI.insertMasterLevelMeter(self.RecordBarLeft, "RecordLevelMeter")
    self.RecordMeter:style("RecordMeter")
    self.RecordMeter:setPeakHoldAndDeclineInterval(false, 0.5)

    self.WaveEditorRecord = NI.GUI.insertRecordWaveEditor(self.RecordBarRight, App, "RecordWaveBar")
    self.WaveEditorRecord:showTimeline(false)
    self.WaveEditorRecord:showScrollbar(false)
    self.WaveEditorRecord:setStereo(false)
    self.WaveEditorRecord:setHWWidget()


    -----------------------------------------------------------------------------------
    -- Edit screen
    -----------------------------------------------------------------------------------

    self.EditBarLeft = NI.GUI.insertBar(self.StackLeft, "EditBarLeft")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "EditBar")
    self.EditBarRight = NI.GUI.insertBar(self.StackRight, "EditBarRight")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "EditBar")

    self.Screen.ScreenLeft.EditInfoBar = InfoBar(self.Controller, self.EditBarLeft)

    self.EditWaveEditor = NI.GUI.insertSampleOwnerWaveEditor(self.EditBarRight, App, true, "EditWaveBar")
    self.EditWaveEditor:showTimeline(false)
    self.EditWaveEditor:showScrollbar(false)
    self.EditWaveEditor:setStereo(false)
    self.EditWaveEditor:setHWWidget()

    self.EditBarRight:setFlex(self.EditWaveEditor)


    -----------------------------------------------------------------------------------
    -- Slice Screen
    -----------------------------------------------------------------------------------

    self.SlicingBarLeft = NI.GUI.insertBar(self.StackLeft, "SlicingBarLeft")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "SlicingBar")
    self.SlicingBarRight = NI.GUI.insertBar(self.StackRight, "SlicingBarRight")
        :style(NI.GUI.ALIGN_WIDGET_DOWN, "SlicingBar")

    self.Screen.ScreenLeft.SliceInfoBar = InfoBar(self.Controller, self.SlicingBarLeft)

    self.SliceWaveEditor = NI.GUI.insertSliceWaveEditor(self.SlicingBarRight, App, "SlicingWaveDisplay")
    self.SliceWaveEditor:showTimeline(false)
    self.SliceWaveEditor:showScrollbar(false)
    self.SliceWaveEditor:setStereo(false)
    self.SliceWaveEditor:setAlwaysShowFocusSlice(true)
    self.SliceWaveEditor:setHWWidget()

    self.SlicingBarRight:setFlex(self.SliceWaveEditor)


    -----------------------------------------------------------------------------------
    -- TimeStretch Screen
    -----------------------------------------------------------------------------------

    -- Use Edit Screen


    -----------------------------------------------------------------------------------
    -- Zone Screen
    -----------------------------------------------------------------------------------
    -- So far, use Edit screen since the gui elements are the same

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateScreens(ForceUpdate)

    -- redirect to 'dialog' screens if one is visible
    if self.SliceApplyPage and self.SliceApplyPage.IsVisible then
        --todo: use QEInfoBar
        self.Screen.InfoBar = self.SliceApplyPage.Screen.InfoBar
        self.SliceApplyPage:updateScreens(ForceUpdate)
        return

    elseif self.SampleBrowsePage and self.SampleBrowsePage.IsVisible then
        --todo: use QEInfoBar
        self.Screen.InfoBar = self.SampleBrowsePage.Screen.InfoBar
        self.SampleBrowsePage:updateScreens(ForceUpdate)
        return

    end

    -- right InfoBar styling
    self.WaveEditorHeader:setAttribute(ATTR_STRETCH_MODE, "false")
    self.WaveEditorHeaderLabels[1]:setVisible(true)
    self.WaveEditorHeaderLabels[2]:setVisible(true)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group and self.ScreenMode == SamplingScreenMode.EDIT then
        if SamplingHelper.timeStretchSettingsVisible() then
            self.WaveEditorHeader:setAttribute(ATTR_STRETCH_MODE, "true")
            self.WaveEditorHeaderLabels[1]:setVisible(false)
            self.WaveEditorHeaderLabels[2]:setVisible(false)
        end
        self.StackRight:setActive(not SamplingHelper.timeStretchSettingsVisible())
    else
        self.StackRight:setActive(true)
    end

    SamplingPageBase.updateLeftScreenButtons(self, "HeadTab", "HeadTabRight")
    SamplingPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateRecordScreen(ForceUpdate)

    --todo: QEInfoBar
    self.Screen.InfoBar = nil
    SamplingPageBase.updateRecordScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateEditScreen(ForceUpdate)

    --todo: QEInfoBar
    self.Screen.InfoBar = self.Screen.ScreenLeft.EditInfoBar
    SamplingPageBase.updateEditScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateSliceScreen(ForceUpdate)

    -- todo: QEInfoBar
    self.Screen.InfoBar = self.Screen.ScreenLeft.SliceInfoBar
    SamplingPageBase.updateSliceScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateZoneScreen(ForceUpdate)

    --todo: QEInfoBar
    self.Screen.InfoBar = self.Screen.ScreenLeft.EditInfoBar
    SamplingPageBase.updateZoneScreen(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateWaveEditorRecordHeader()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local Take = SamplingHelper.getFocusTake()

    local Text = {"", ""}

    if Recorder and (Recorder:isWaiting() or Recorder:isRecording()) then
        Text[1] = string.upper(NI.DATA.RecorderAccess.getRecordingInfoString(App, Recorder))

    elseif Take and Take:getSample() then
        Text[1] = Take:getName()
        Text[2] = "LENGTH: " .. string.upper(SamplingHelper.getFocusSampleLengthAsText())
    elseif SamplingHelper.getTakeListCount() == 0 then
        Text[1] = "NO TAKE RECORDED"
    elseif Take and not Take:getSample() then
        Text[1] = "MISSING SAMPLE"
    else
        Text[1] = "NO TAKE SELECTED"
    end

    self.WaveEditorHeaderLabels[1]:setText(Text[1])
    self.WaveEditorHeaderLabels[2]:setText(Text[2])

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:updateWaveEditorHeader()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Sample = NI.DATA.StateHelper.getFocusSample(App)

    if not TransactionSample then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local IsAudio = Sound and Sound:getAudioModule()
        self.WaveEditorHeaderLabels[1]:setText(IsAudio and "NO TAKE LOADED" or "NO SAMPLE LOADED")
        self.WaveEditorHeaderLabels[2]:setText("")
    elseif not Sample then
        self.WaveEditorHeaderLabels[1]:setText("MISSING SAMPLE")
        self.WaveEditorHeaderLabels[2]:setText("")
    else
        local name = NI.DATA.TransactionSampleAlgorithms.getName(TransactionSample, Sample)
        self.WaveEditorHeaderLabels[1]:setText(string.upper(name))
        self.WaveEditorHeaderLabels[2]:setText("LENGTH: " .. string.upper(SamplingHelper.getFocusSampleLengthAsText()))
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:onWheel(Inc)

    if self.SampleBrowsePage.IsVisible then
        return self.SampleBrowsePage:onWheel(Inc)
    end

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        not self:isSoundQuickEditAllowed() then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:isSoundQuickEditAllowed()

    return self.Controller.QuickEdit.NumPadPressed == 0 or (self.ScreenMode ~= SamplingScreenMode.RECORD and self.ScreenMode ~= SamplingScreenMode.SLICE)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if not self:isSoundQuickEditAllowed() then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if not self:isSoundQuickEditAllowed() then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPage:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if not self:isSoundQuickEditAllowed() then
        return true
    end

end



------------------------------------------------------------------------------------------------------------------------
