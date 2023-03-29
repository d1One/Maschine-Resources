------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/InfoBarHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

local INFOBAR_TIMEOUT_DURATION = 40

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
InfoBarBase = class( 'InfoBarBase' )

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:__init(Controller, ParentBar)

    -- Controller
    self.Controller = Controller

    -- update function
    self.UpdateFunctor = nil

    -- Mode which determins the update function
    self.Mode = "Default"
    self.OriginalMode = nil
    self.TempCountdown = 0

    self.BaseKeyOffset = 0

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:setMode(Mode)

    if Mode == nil then
       Mode = "Default"
    end

	-- reset temp mode if on
	self.TempCountdown = 0
	self.Mode = Mode

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:resetTempMode()

	if self.OriginalMode then
		self:setMode(self.OriginalMode)
	end

	self.OriginalMode = nil
	self:update(true)

end

-----------------------------------------------------------------------------------------------------------------------
-- UseTimer is true by default
function InfoBarBase:setTempMode(TempMode, UseTimer)

    if self.Mode ~= TempMode then

        if self.OriginalMode == nil then
	        self.OriginalMode = self.Mode
    	end

        self:setMode(TempMode)

    end

    self.TempCountdown = (UseTimer or UseTimer == nil) and INFOBAR_TIMEOUT_DURATION or 0

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:update(ForceUpdate)

	if self.UpdateFunctor then
        self.UpdateFunctor(ForceUpdate)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Timer
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:onTimer()

    if self.TempCountdown > 0 then

		self.TempCountdown = self.TempCountdown - 1

		-- Restore Original Mode if countdown is up
		if self.TempCountdown == 0 then
			self:resetTempMode()
			return
		end
    end

	self:update(false)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.getObjectPrefix(Song, LevelTab)

	local Prefix = MaschineHelper.getObjectIndexAsString(Song, LevelTab)

    if Prefix ~= "" then
        Prefix = Prefix .. ". "
    end

	return Prefix

end

------------------------------------------------------------------------------------------------------------------------
-- update mixing object name
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateFocusMixingObjectName(Label, ForceUpdate, ShowPrefix)

    if not Label then
        return
    end

    if not NI.APP.FEATURE.EFFECTS_CHAIN then
        local Slot = NI.DATA.ChainAlgorithms.getFocusSlot(App:getChain())
        if Slot and Slot:getModule() then
            Label:setText(NI.DATA.SlotAlgorithms.getDisplayName(Slot))
        else
            Label:setText("No " .. (NI.DATA.StateHelper.getFocusChainSlots(App):empty() and "INSTRUMENT" or "EFFECT")
                .. " Loaded")
        end
    else
        Label:setText(MaschineHelper.getMixingObjectName(self:getMixingObjectLevel(), ShowPrefix))
    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:getMixingObjectLevel()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
 	return Song and Song:getLevelTab() or NI.DATA.LEVEL_TAB_SONG

 end


------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateFocusSlotName(Label, ForceUpdate, ShowPrefix)

	if not Label then
		return
	end

	local StateCache = App:getStateCache()
	if ForceUpdate or StateCache:isFocusModuleChanged() then

		local Slot = NI.DATA.StateHelper.getFocusSlot(App)
		local Name =  Slot and "" or "(NONE)"

		if Slot then

	        local SlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
            Name = (ShowPrefix and SlotIndex ~= -1 and (tostring(SlotIndex + 1) .. ". ") or "")
				.. NI.DATA.SlotAlgorithms.getDisplayName(Slot)
		end

		Label:setText(Name)

	end

end

------------------------------------------------------------------------------------------------------------------------
-- update focus sound
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateFocusSound(Label, ForceUpdate, ShowPrefix)

	if not Label then
		return
	end

	local StateCache = App:getStateCache()

    if ForceUpdate
		or StateCache:isFocusSoundNameChanged()
		or StateCache:isFocusSoundChanged()
		or StateCache:isSoundsChanged() then

		local Text = ""
		local Sound = NI.DATA.StateHelper.getFocusSound(App)

		if Sound then
			Text = (ShowPrefix and InfoBarBase.getObjectPrefix(NI.DATA.StateHelper.getFocusSong(App), NI.DATA.LEVEL_TAB_SOUND) or  "")
				.. Sound:getDisplayName()
		end

		Label:setText(Text)

	end

end

------------------------------------------------------------------------------------------------------------------------
-- update group name
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateGroupName(Label, ForceUpdate, ShowPrefix)

	if not Label then
		return
	end

	local StateCache = App:getStateCache()
	local Group = NI.DATA.StateHelper.getFocusGroup(App)

	if ForceUpdate
		or (Group and Group:getNameParameter():isChanged())
		or StateCache:isFocusGroupChanged() then

	    local Text = ""

		if Group then
			Text = (ShowPrefix and InfoBarBase.getObjectPrefix(NI.DATA.StateHelper.getFocusSong(App), NI.DATA.LEVEL_TAB_GROUP) or  "")
				.. Group:getDisplayName()
		end

		Label:setText(Text)

	end

end

------------------------------------------------------------------------------------------------------------------------
-- update slot name
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateSlotName(Label, ForceUpdate)

	if not Label then
		return
	end

    local StateCache = App:getStateCache()
    local FocusSlot  = NI.DATA.StateHelper.getFocusSlot(App)
    local PluginHost = FocusSlot and FocusSlot:getPluginHost()

    ForceUpdate = ForceUpdate
        or StateCache:isFocusSlotChanged()
        or (FocusSlot and (FocusSlot:isModuleChanged() or (PluginHost and PluginHost:isChanged())))

    if ForceUpdate then
        Label:setText(MaschineHelper.getFocusSlotNameWithNumber())
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update sound info name (preset name)
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateSoundInfoName(Label, ForceUpdate)

	if not Label then
		return
	end

    local StateCache  = App:getStateCache()
    local FocusSlot   = NI.DATA.StateHelper.getFocusSlot(App)
    local PluginHost  = FocusSlot and FocusSlot:getPluginHost()
    local FocusModule = FocusSlot and FocusSlot:getModule()

    if ForceUpdate
        or StateCache:isFocusSlotChanged()
        or (FocusSlot and (FocusSlot:isModuleChanged() or (PluginHost and PluginHost:isChanged())))
        or (FocusModule and FocusModule:isChanged()) then

        Label:setText(FocusSlot and FocusSlot:getSoundInfoName() or "")

    end

end

------------------------------------------------------------------------------------------------------------------------
-- update pattern name
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updatePatternName(Label, ForceUpdate)

	if not Label then
		return
	end

    local StateCache = App:getStateCache()

    if ForceUpdate
		or StateCache:isFocusPatternChanged()
		or StateCache:isFocusPatternNameChanged() then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        Label:setText(Pattern and Pattern:getNameParameter():getValue() or "NONE")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update song name
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateProjectName(Label, ForceUpdate, CheckModified)

	if not Label then
		return
	end

    local StateCache = App:getStateCache()

    if ForceUpdate
		or StateCache:isProjectChanged()
		or App:getProject():getNameParameter():isChanged() then

        local DisplayName = App:getProject():getCurrentProjectDisplayName()

        if CheckModified and App:hasProjectChanged() then
            DisplayName = DisplayName .. " *"
        end

        Label:setText(DisplayName)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- update song tempo
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updateTempo(Label, ForceUpdate, WithBPM)

	if not Label then
		return
	end

    local TempoParam

    if not NI.APP.FEATURE.ARRANGER then
        TempoParam = App:getWorkspace():getTempoParameter()
    else
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        TempoParam = Song and Song:getTempoParameter()
    end

    if TempoParam and (ForceUpdate or TempoParam:isChanged()) then
		local BPM = WithBPM and " BPM" or ""
        Label:setText(TempoParam:getValueString()..BPM)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update perform grid
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase.updatePerformGrid(Label, ForceUpdate)

	if not Label then
		return
	end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local PerformGridParam = Song and Song:getPerformGridParameter()

    if PerformGridParam and (ForceUpdate or PerformGridParam:isChanged()) then

        Label:setText(PerformGridParameter:getValueString())

    end

end

------------------------------------------------------------------------------------------------------------------------
-- update song play position
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updatePlayPosition(Label, ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if not Label or not Song then
        return
    end

    -- update position not only when playing (MAS2-4871)

    if NI.DATA.SongAlgorithms.isIdeaSpacePlaying(Song) then
        local Scene = Song:getIdeaSpacePlayingScene()
        Label:setText(Scene and Scene:getNameParameter():getValue() or "")
    else
        Label:setText(Song:getTickPositionToString(NI.DATA.TransportAccess.getPlayPosition(App)))
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update base key
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateBaseKey(Label, ForceUpdate)

    if not Label then
        return
    end

    local KeyboardModeOn = PadModeHelper.getKeyboardMode()
    Label:setText(KeyboardModeOn and InfoBarHelper.getRootNote() or InfoBarHelper.getBaseKey())

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateBaseKeyOffset(Label, ForceUpdate)

    if not Label then
        return
    end

    Label:setText(InfoBarHelper.getBaseKeyOffset())

end

------------------------------------------------------------------------------------------------------------------------
-- update QuickEdit
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:getQELevelAsText()

	return self.Controller.QuickEdit:getLevelText()

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateQELevel(Label, ForceUpdate)

 	if not Label then
		return
	end

    if self.Controller.QuickEdit then
        if self.Controller.QuickEdit:isChanged() then
            Label:setText(self:getQELevelAsText())
        end
    else
        Label:setText("")
    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:getQEModeAsText()

	return self.Controller.QuickEdit:getModeText()

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateQEMode(Label, ForceUpdate)

	if not Label then
		return
	end

    if self.Controller.QuickEdit then
		if self.Controller.QuickEdit:isChanged() then
			Label:setText(self:getQEModeAsText())
		end
    else
		Label:setText("")
	end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:getQEValueAsText()

	return self.Controller.QuickEdit:getValueFormatted()

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateQEValue(Label, ForceUpdate)

	if not Label then
		return
	end

    if self.Controller.QuickEdit then

        if self.Controller.QuickEdit:isChanged() then
        	local ValueFormatted = self:getQEValueAsText()
        	if ValueFormatted then
				Label:setText(ValueFormatted)
				self.Controller.QuickEdit:resetChangedFlag()
			end
        end

    else
        Label:setText("")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update LevelMeter
------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateMasterVolume(Label)

	if not Label then
		return
	end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Param = Song and Song:getLevelParameter()

    Label:setText(Param and Param:getAsString(Param:getValue()) or "")

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateCueVolume(Label)

	if not Label then
		return
	end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Param = Song and Song:getCueLevelParameter()

    Label:setText(Param and Param:getAsString(Param:getValue()) or "")

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateGroupVolume(Label)

	if not Label then
		return
	end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Param = Group and Group:getLevelParameter()

    Label:setText(Param and Param:getAsString(Param:getValue()) or "")

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarBase:updateSoundVolume(Label)

	if not Label then
		return
	end

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Param = Sound and Sound:getLevelParameter()

    Label:setText(Param and Param:getAsString(Param:getValue()) or "")

end

------------------------------------------------------------------------------------------------------------------------
