------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"
require "Scripts/Maschine/Helper/SettingsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabGeneral = class( 'SettingsTabGeneral', SettingsTab )

local PARAMETER_PAGE_INDEX_GENERAL = 1
local PARAMETER_PAGE_INDEX_DEFAULTS = 2
local PARAMETER_PAGE_INDEX_COLORS = 3

local ENCODER_INDEX_RELOAD_PROJECT = 1
local ENCODER_INDEX_AUTOSAVE = 2
local ENCODER_INDEX_QUANTIZE = 3
local ENCODER_INDEX_DUPLICATE_WITH_PATTERNS = 5
local ENCODER_INDEX_LINK_SCENE_ON_DUPLICATE = 6
local ENCODER_INDEX_PATTERN_DEFAULT_LENGTH = 7
local ENCODER_INDEX_PATTERN_AUTOGROW = 8

local ENCODER_INDEX_SCENE_COLOR = 1
local ENCODER_INDEX_GROUP_COLOR = 2
local ENCODER_INDEX_SOUND_COLOR = 3
local ENCODER_INDEX_LOAD_WITH_COLOR = 4

------------------------------------------------------------------------------------------------------------------------

function SettingsTabGeneral:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_GENERAL, "GENERAL", SettingsTab.WITH_PARAMETER_BAR)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabGeneral:addContextualBar(ContextualStack)

    local TwoColumns = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconGeneral = NI.GUI.insertBar(FirstColumn, "BigIconGeneral")
    BigIconGeneral:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabGeneral:updateParameters(Controller, ParameterHandler)

    self.PageIndex = ParameterHandler.PageIndex
    ParameterHandler.NumPages = 3

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local SongSignatureDenominatorParam = Song and Song:getDenominatorParameter() or nil
    local Metronome = App:getMetronome()
    local Workspace = App:getWorkspace()

    if ParameterHandler.PageIndex == PARAMETER_PAGE_INDEX_GENERAL then

        local Params =
        {
            Metronome:getEnabledParameter(),
            Metronome:getVolumeParameter(),
            Metronome:getTimeSignatureParameter(SongSignatureDenominatorParam:getValue()),
            Metronome:getAutoEnableParameter(),
            Metronome:getCountInLengthParameter(),
            Song:getNumeratorParameter(),
            Song:getDenominatorParameter()
        }

        local Sections = { "Metronome", "", "", "", "Count-In", "Time Signature", "", "" }

        ParameterHandler:setParameters(Params)
        ParameterHandler:setCustomSections(Sections)
        Controller.CapacitiveList:assignParametersToCaps(Params)

    elseif ParameterHandler.PageIndex == PARAMETER_PAGE_INDEX_DEFAULTS then

        local Params = {}
        if NI.APP.isStandalone() then
            Params[ENCODER_INDEX_AUTOSAVE] = Workspace:getAutoSaveParameter()
        end
        Params[ENCODER_INDEX_QUANTIZE] = Workspace:getQuantizeModeParameter()
        Params[ENCODER_INDEX_DUPLICATE_WITH_PATTERNS] = Workspace:getDuplicateWithPatternsParameter()
        Params[ENCODER_INDEX_LINK_SCENE_ON_DUPLICATE] = Workspace:getLinkSceneOnDuplicateParameter()

        local Values = {}
        if NI.APP.isStandalone() then
            Values[ENCODER_INDEX_RELOAD_PROJECT] = SettingsHelper.getLoadLastProjectAtStartup() and "On" or "Off"
            Values[ENCODER_INDEX_AUTOSAVE] = Workspace:getAutoSaveParameter():getValue() and "On" or "Off"
        end
        Values[ENCODER_INDEX_DUPLICATE_WITH_PATTERNS] = Workspace:getDuplicateWithPatternsParameter():getValue() and "Scn & Ptn" or "Scene"
        Values[ENCODER_INDEX_PATTERN_DEFAULT_LENGTH] = SettingsHelper.getPatternDefaultLength()
        Values[ENCODER_INDEX_PATTERN_AUTOGROW] = SettingsHelper.getPatternAutoGrow() and "On" or "Off"

        local ListValues = {}
        ListValues[ENCODER_INDEX_DUPLICATE_WITH_PATTERNS] = { "Scene", "Scn & Ptn" }

        local SectionNameProject = NI.APP.isStandalone() and "Project" or ""
        local Sections = { SectionNameProject, "", "Quantize", "", "Scene / Section", "", "Pattern", "" }

        local ParamNameReload = NI.APP.isStandalone() and "RELOAD" or ""
        local ParamNameBackup = NI.APP.isStandalone() and "AUTO BACKUP" or ""
        local Names = { ParamNameReload, ParamNameBackup, "", "", "DUPLICATE", "LINK WHEN DUPL", "LENGTH", "GROW" }

        ParameterHandler:setParameters(Params)
        ParameterHandler:setCustomNames(Names)
        ParameterHandler:setCustomValues(Values)
        ParameterHandler:setCustomSections(Sections)
        Controller.CapacitiveList:assignListsToCaps(ListValues, Values)

    elseif ParameterHandler.PageIndex == PARAMETER_PAGE_INDEX_COLORS then

        local Values = {}
        Values[ENCODER_INDEX_SCENE_COLOR] = SettingsHelper.getCurrentSceneColorName()
        Values[ENCODER_INDEX_GROUP_COLOR] = SettingsHelper.getCurrentGroupColorName()
        Values[ENCODER_INDEX_SOUND_COLOR] = SettingsHelper.getCurrentSoundColorName()
        Values[ENCODER_INDEX_LOAD_WITH_COLOR] = SettingsHelper.isLoadWithColors() and "On" or "Off"

        local ListValues = {}
        ListValues[ENCODER_INDEX_SCENE_COLOR] = SettingsHelper.getSceneColorsAsStrings()
        ListValues[ENCODER_INDEX_GROUP_COLOR] = SettingsHelper.getGroupColorsAsStrings()
        ListValues[ENCODER_INDEX_SOUND_COLOR] = SettingsHelper.getSoundColorsAsStrings()

        local ListColors = {}
        ListColors[ENCODER_INDEX_SCENE_COLOR] = SettingsHelper.getPaletteIndexes()
        ListColors[ENCODER_INDEX_GROUP_COLOR] = SettingsHelper.getPaletteIndexes()
        ListColors[ENCODER_INDEX_SOUND_COLOR] = SettingsHelper.getPaletteIndexes()

        local Sections = { "Colors" }
        local Names = { "SCENE", "GROUP", "SOUND", "LOAD COLORS" }

        ParameterHandler:setParameters({})
        ParameterHandler:setCustomNames(Names)
        ParameterHandler:setCustomValues(Values)
        ParameterHandler:setCustomSections(Sections)
        Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabGeneral:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if not EncoderSmoothed then

        return

    end

    if Page == PARAMETER_PAGE_INDEX_DEFAULTS then

        if Index == ENCODER_INDEX_RELOAD_PROJECT then

            SettingsHelper.setLoadLastProjectAtStartup(Next)

        elseif Index == ENCODER_INDEX_PATTERN_DEFAULT_LENGTH then

            if Controller:getShiftPressed() then

                NI.DATA.EventPatternAccess.incDecPatternDefaultLengthFine(App, Next)

            else

                NI.DATA.EventPatternAccess.incDecPatternDefaultLengthCoarse(App, Next)

            end

        elseif Index == ENCODER_INDEX_PATTERN_AUTOGROW then

            SettingsHelper.setPatternAutoGrow(Next)

        end

    elseif Page == PARAMETER_PAGE_INDEX_COLORS then

        if Index == ENCODER_INDEX_SCENE_COLOR  then

            SettingsHelper.selectPrevNextSceneColor(Next)
            NI.DATA.ProjectAccess.onDefaultColorsChanged(App)

        elseif Index == ENCODER_INDEX_GROUP_COLOR then

            SettingsHelper.selectPrevNextGroupColor(Next)
            NI.DATA.ProjectAccess.onDefaultColorsChanged(App)

        elseif Index == ENCODER_INDEX_SOUND_COLOR then

            SettingsHelper.selectPrevNextSoundColor(Next)
            NI.DATA.ProjectAccess.onDefaultColorsChanged(App)

        elseif Index == ENCODER_INDEX_LOAD_WITH_COLOR then

            SettingsHelper.setLoadWithColors(Next)

        end

    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------
