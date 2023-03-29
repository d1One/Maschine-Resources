------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/InfoBarBase"
require "Scripts/Shared/Helpers/ColorPaletteHelper"
require "Scripts/Shared/Helpers/QuickEditHelper"

local ATTR_WITHOUT_SOUND_NUMBER = NI.UTILS.Symbol("WithoutSoundNumber")
local CPU_UPDATE_FRAMES = 60

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
InfoBarStudio = class( 'InfoBarStudio', InfoBarBase )

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:__init(Controller, ParentBar, Mode)

    -- init base class
    InfoBarBase.__init(self, Controller, ParentBar)

    self.GroupSoundNumber = NI.GUI.insertLabel(ParentBar, "InfoBarNumber")
    self.GroupSoundNumber:style("", "InfoBar")
    self.GroupSoundName = NI.GUI.insertLabel(ParentBar, "InfoBarName")
    self.GroupSoundName:style("", "")
    NI.GUI.enableCropModeForLabel(self.GroupSoundName)

    self.LevelMeter = NI.GUI.insertLevelMeter(ParentBar, "InfoBarLevelMeter")
    self.LevelMeter:setPeakHoldAndDeclineInterval(false, 0)

    self.ScanWheel = NI.GUI.insertAnimation(ParentBar, "InfoBarScanWheel")
    self.ScanWheel:style("")

    self.CPUFrameCounter = 0
    self.CPUShowWarning = false
    self.CPULevelString = MaschineHelper.getCPULevelString()

    self.CPUWarningIcon = NI.GUI.insertBar(ParentBar, "InfoBarCPUWarning")
    self.CPUWarningIcon:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")
    self.CPUWarningIcon:setActive(false)
    self.CPUValue = NI.GUI.insertLabel(ParentBar, "InfoBarCPUValue")
    self.CPUValue:style(self.CPULevelString, "")
    self.CPUValue:setAutoResize(true)
    self.CPUTitle = NI.GUI.insertLabel(ParentBar, "InfoBarCPUTitle")
    self.CPUTitle:style("CPU", "")
    self.CPUTitle:setAutoResize(true)

    self.ShowCPUMeter = false

    self.LabelValue = NI.GUI.insertLabel(ParentBar, "InfoBarLabelValue")
    self.LabelValue:style("", "")
    self.LabelValue:setAutoResize(true)
    self.LabelTitle = NI.GUI.insertLabel(ParentBar, "InfoBarLabelTitle")
    self.LabelTitle:style("", "")
    self.LabelTitle:setAutoResize(true)

    self.Transport = NI.GUI.insertLabel(ParentBar, "InfoBarTransport")
    self.Transport:style("", "")
    self.Transport:setAutoResize(true)

    ParentBar:setFlex(self.GroupSoundName)

    self:setMode(Mode)

    self.MixingLevelOverride = nil -- To update info bar with a mixing level other than the focused one, set it here.

    if not NI.APP.FEATURE.EFFECTS_CHAIN then

        self.GroupSoundNumber:setActive(false)
        self.GroupSoundName:setAttribute(ATTR_WITHOUT_SOUND_NUMBER, "true")

    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:getMixingObjectLevel()

    if self.MixingLevelOverride then
        return self.MixingLevelOverride
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song:getLevelTab()

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:setActiveInfoBarLabels(isLabelTitleActive, isLabelValueActive, isTransportActive, isCPUActive)

    self.LabelValue:setActive(isLabelValueActive)
    self.LabelTitle:setActive(isLabelTitleActive)
    self.Transport:setActive(isTransportActive)
    self.ShowCPUMeter = NI.APP.isHeadless() and isCPUActive

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:setMode(Mode)

    InfoBarBase.setMode(self, Mode)

    self.MixingLevelOverride = nil

    local DefaultFunctor = function(ForceUpdate)

        local IsRecordingSample = MaschineHelper.isRecordingSample()

        self:setActiveInfoBarLabels(not IsRecordingSample, true, not IsRecordingSample, not IsRecordingSample)

        self:updateFocusMixingObject(ForceUpdate)

        if IsRecordingSample then

            self:updateRecording(ForceUpdate)
        else

            self:updateTempo(ForceUpdate)
            if NI.APP.FEATURE.ARRANGER then

                self:updatePlayPosition(self.Transport, ForceUpdate)

            end

        end

    end

    if self.Mode == "Default" then

        self.UpdateFunctor = DefaultFunctor

    elseif self.Mode == "Group" then

        self.MixingLevelOverride = NI.DATA.LEVEL_TAB_GROUP
        self.UpdateFunctor = DefaultFunctor

    elseif self.Mode == "Sound" then

        self.MixingLevelOverride = NI.DATA.LEVEL_TAB_SOUND
        self.UpdateFunctor = function(ForceUpdate)

            self:updateGroupSoundNumber(ForceUpdate)
            InfoBarBase.updateFocusSound(self.GroupSoundName, ForceUpdate)
        end

    elseif self.Mode == "PadScreenMode" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, true)

            self.LabelTitle:setText(PadModeHelper.getKeyboardMode() and "ROOT NOTE" or "BASE KEY")
            self.LabelValue:setText(PadModeHelper.getKeyboardMode() and InfoBarHelper.getRootNote() or InfoBarHelper.getBaseKey())
        end

    elseif self.Mode == "BaseKeyOffsetTempMode" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self.LabelTitle:setActive(true)
            self.LabelValue:setActive(true)
            self.Transport:setActive(false)
            self.ShowCPUMeter = NI.APP.isHeadless()
            self:setActiveInfoBarLabels(true, true, false, true)

            self.LabelTitle:setText("BASE KEY")
            self.LabelValue:setText(InfoBarHelper.getBaseKeyOffset())
        end

    elseif self.Mode == "LevelMeter" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, true)

            local Caption1, Caption2 = self.Controller.LevelMeter:getSourceCaptions()
            local ValueFormatted = self.Controller.LevelMeter:getSourceValueFormatted()

            self.LabelTitle:setText(Caption1.."  "..Caption2)
            self.LabelValue:setText(ValueFormatted)
        end

    elseif self.Mode == "MasterLevelMeter" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, true)

            local ValueFormatted = NI.UTILS.LevelScale.level2ValueString(NI.DATA.getMasterVolume(App):getValue())

            self.LabelTitle:setText("MASTER VOL")
            self.LabelValue:setText(ValueFormatted)
        end

    elseif self.Mode == "QuickEdit" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, false)

            local QETitle= ""
            local QELevel = self:getQELevelAsText()

            if QELevel ~= "" then

                QETitle = QELevel.." "..self:getQEModeAsText()

            else

                QETitle = self:getQEModeAsText()

            end

            self.LabelTitle:setText(QETitle)
            self.LabelValue:setText(self:getQEValueAsText())
        end

    elseif self.Mode == "QuickEditStep" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, false)

            self.LabelTitle:setText("STEP  "..StepHelper.getWheelModeText(true))
            self.LabelValue:setText(QuickEditHelper.getStepValueText())
        end

    elseif self.Mode == "TEMPO" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, true)

            self.LabelTitle:setText("TEMPO")
            InfoBarBase.updateTempo(self.LabelValue, true, true)
        end

    elseif self.Mode == "ProjectSaved" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(false, true, false, false)

            self.LabelTitle:setText("PROJECT SAVED")
        end

    elseif self.Mode == "FilePageProjectSaved" then

        self.UpdateFunctor = function(ForceUpdate)
            self.MixingLevelOverride = NI.DATA.LEVEL_TAB_SONG
            self:updateGroupSoundNumber(ForceUpdate)

            self:setActiveInfoBarLabels(false, true, false, false)

            InfoBarBase.updateProjectName(self.GroupSoundName, ForceUpdate)
            self.LabelValue:setText("PROJECT SAVED")
        end

    elseif self.Mode == "FilePageProjectName" then

        self.UpdateFunctor = function(ForceUpdate)
            ForceUpdate = ForceUpdate or App:hasProjectChanged()
            self.MixingLevelOverride = NI.DATA.LEVEL_TAB_SONG
            self:updateGroupSoundNumber(ForceUpdate)

            InfoBarBase.updateProjectName(self.GroupSoundName, ForceUpdate, true)
            self:updateTempo(ForceUpdate)
            self:updatePlayPosition(self.Transport, ForceUpdate)
        end

    elseif self.Mode == "Loop" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(true, true, false, false)

            self.LabelTitle:setText("LOOP")
            self.LabelValue:setText(ArrangerHelper.getLoopActiveAsString())
        end

    elseif self.Mode == "KeySwitch" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObject(ForceUpdate)

            self:setActiveInfoBarLabels(false, true, false, false)

            self.LabelValue:setText(self.Controller.KeySwitchNoteName)
       end

    elseif self.Mode == "NoteShift" then

        self.UpdateFunctor = function(ForceUpdate)

            self:updateGroupSoundNumber(ForceUpdate)
            self:updateFocusMixingObjectName(self.GroupSoundName, ForceUpdate)

            self:setActiveInfoBarLabels(false, true, false, false)

            local OctSign = self.Controller.OctaveOffset > 0 and "+" or "" -- minus sign inferred w/ neg numbers
            local Octaves = "OCT: " .. OctSign .. string.format(self.Controller.OctaveOffset)

            local SemiSign = self.Controller.SemitoneOffset > 0 and "+" or ""
            local Semitones = self.Controller.SemitoneOffset ~= 0
                              and "   SEMI: " .. SemiSign .. string.format(self.Controller.SemitoneOffset)
                              or  ""

            self.LabelValue:setText(Octaves .. Semitones)

        end
    end

    self:update(true)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:update(ForceUpdate)

    self:updateLevelMeter()

    self.ScanWheel:setActive(App:getWorkspace():getDatabaseScanInProgressParameter():getValue())

    self:updateCPUMeter(ForceUpdate)

    InfoBarBase.update(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:updateLevelMeter()

    if NI.APP.FEATURE.EFFECTS_CHAIN then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)

        local LevelTabValue = self:getMixingObjectLevel()

        if LevelTabValue == NI.DATA.LEVEL_TAB_GROUP then
            self.LevelMeter:setLevels(Group:getLevel(0), Group:getLevel(1))
        elseif LevelTabValue == NI.DATA.LEVEL_TAB_SOUND then
            self.LevelMeter:setLevels(Sound:getLevel(0), Sound:getLevel(1))
        elseif LevelTabValue == NI.DATA.LEVEL_TAB_SONG then
            self.LevelMeter:setLevels(Song:getLevel(0), Song:getLevel(1))
        end
    else
        LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(App:getWorkspace():getOutputLevel(0), -60, 0)
        LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(App:getWorkspace():getOutputLevel(1), -60, 0)
        self.LevelMeter:setLevels(LevelL, LevelR)
    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:updateCPUMeter(ForceUpdate)

    self.CPUTitle:setActive(self.ShowCPUMeter)
    self.CPUFrameCounter = self.CPUFrameCounter + 1


    if self.CPUFrameCounter >= CPU_UPDATE_FRAMES or ForceUpdate then

        self.CPUFrameCounter = 0
        self.CPULevelString = MaschineHelper.getCPULevelString()
        self.CPUShowWarning = not self.CPUShowWarning and MaschineHelper.isCPUTooHigh()

    end

    self.CPUValue:setText(self.CPULevelString)

    self.CPUWarningIcon:setActive(self.ShowCPUMeter and self.CPUShowWarning)
    self.CPUValue:setActive(self.ShowCPUMeter and not self.CPUShowWarning)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:updatePlayPosition(Label, ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Label or not Song then
        return
    end

    -- update position not only when playing (MAS2-4871)

    InfoBarBase.updatePlayPosition(self, Label, ForceUpdate)

    local ColorIndex = 0
    local Scene = Song:getIdeaSpacePlayingScene()

    if Scene and NI.DATA.SongAlgorithms.isIdeaSpacePlaying(Song) then
        ColorIndex = Scene:getColorParameter():getValue()+1
    end

    Label:setPaletteColorIndex(ColorIndex)
    Label:setActive(true)

end

------------------------------------------------------------------------------------------------------------------------

-- update group/sound number (A1, A2, ... or 1, 2, ... 16)
function InfoBarStudio:updateFocusMixingObject(ForceUpdate)

    self:updateGroupSoundNumber(ForceUpdate)
    self:updateFocusMixingObjectName(self.GroupSoundName, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- Update focus mixing object number with respective color (A1-H8 for Groups, 1-16 for Sounds, "M" for Master/Song level)

function InfoBarStudio:updateGroupSoundNumber(ForceUpdate)

    if not NI.APP.FEATURE.EFFECTS_CHAIN then
        return
    end

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if ForceUpdate or StateCache:isMixingLayerChanged()
        or (Sound and Sound:getColorParameter():isChanged())
        or (Group and Group:getColorParameter():isChanged()) then

        local LabelText
        local ColorIndex
        local LevelTabValue = self:getMixingObjectLevel()
        local SetVisible = LevelTabValue ~= NI.DATA.LEVEL_TAB_SOUND or Group ~= nil

        -- Group Level
        if LevelTabValue == NI.DATA.LEVEL_TAB_GROUP then

            local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
            LabelText        = NI.DATA.Group.getLabel(GroupIndex)
            ColorIndex       = MaschineHelper.getGroupColorByIndex(GroupIndex+1) + 1

        -- Sound Level
        elseif LevelTabValue == NI.DATA.LEVEL_TAB_SOUND then

            local SoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
            LabelText        = tostring(SoundIndex+1)
            ColorIndex       = MaschineHelper.getSoundColorByIndex(SoundIndex+1) + 1

        -- Master Level
        else

            LabelText = "M"
            ColorIndex = 0 -- White

        end

        self:setGroupSoundNumber(SetVisible, LabelText, ColorIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:setGroupSoundNumber(Visible, Text, ColorIndex)

    -- visibility
    self.GroupSoundNumber:setVisible(Visible)
    self.GroupSoundName:setVisible(Visible)

    -- text
    Text = Text and Text or ""
    self.GroupSoundNumber:setText(Text)

    -- color
    ColorIndex = ColorIndex and ColorIndex or 0
    self.GroupSoundNumber:setPaletteColorIndex(ColorIndex)
    self.GroupSoundName:setPaletteColorIndex(ColorIndex)
    self.LevelMeter:setPaletteColorIndex(ColorIndex)

    -- set to layout
    self.GroupSoundNumber:setAlign()
    self.GroupSoundName:setAlign()

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:updateRecording(ForceUpdate)

    if MaschineHelper.isRecordingSample() then

        self.LabelValue:setText("RECORDING...")

    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarStudio:updateTempo(ForceUpdate)

    self.LabelTitle:setText("BPM")

    local ForceUpdate = ForceUpdate or MaschineHelper.isRecordingSampleChanged()
    InfoBarBase.updateTempo(self.LabelValue, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
