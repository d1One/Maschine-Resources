------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/InfoBarBase"
require "Scripts/Maschine/Helper/ModuleHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
InfoBarMikro = class( 'InfoBarMikro', InfoBarBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:__init(Controller, ParentBar, Mode)

	-- init base class
	InfoBarBase.__init(self, Controller, ParentBar)

    self.Labels = {}
    self.Bar = ScreenHelper.createBarWithLabels(ParentBar, self.Labels, {"" , ""}, "Infobar", "Infobar")

	self:setMode(Mode)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:setMode(Mode)

    if Mode == nil then
        Mode = "Default"
    end

    self.Mode = Mode

    -- default styles, rarely needs to change
    self.Labels[1]:style("", "InfobarMikro1")
    self.Labels[2]:style("", "InfobarMikro2")

    if Mode == "Default" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateTempoAndPosition(ForceUpdate)
        end

    elseif Mode == "None" then

        self.UpdateFunctor = function(ForceUpdate)
            self.Labels[1]:setText("")
            self.Labels[2]:setText("")
        end

    elseif Mode == "FocusedObject" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusObject(ForceUpdate)
        end

    elseif Mode == "FocusedScene" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateSceneSectionInfo(ForceUpdate)
        end

    elseif Mode == "FocusedPattern" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updatePatternInfo(ForceUpdate)
        end

    elseif Mode == "FocusedSound" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateFocusSound(self.Labels[1], ForceUpdate, true)
        end

    elseif Mode == "FocusedGroup" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateGroupName(self.Labels[1], ForceUpdate, true)
        end

    elseif Mode == "FocusedSlot" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateSlotInfo(ForceUpdate)
        end

    elseif Mode == "PadScreenMode" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateFocusSound(self.Labels[1], ForceUpdate, true)
            self:updateBaseKey(self.Labels[2], ForceUpdate)
        end

    elseif Mode == "BaseKeyOffsetTempMode" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateFocusSound(self.Labels[1], ForceUpdate, true)
            self:updateBaseKeyOffset(self.Labels[2], ForceUpdate)
        end

    elseif Mode == "ProjectSaved" then

        self.UpdateFunctor = function(ForceUpdate)
            self.Labels[1]:setText("PROJECT SAVED")
            self.Labels[2]:setText("")
        end

    elseif self.Mode == "Loop" then

        self.UpdateFunctor = function(ForceUpdate)

            self.Labels[1]:setText("LOOP")
            self.Labels[2]:setText(ArrangerHelper.getLoopActiveAsString())

        end

    elseif self.Mode == "View" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateView(ForceUpdate)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- update tempo and position
------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateTempoAndPosition(ForceUpdate)

    InfoBarBase.updateTempo(self.Labels[1], ForceUpdate)
    self:updatePlayPosition(self.Labels[2], ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- update focus mixing layer object and play position
------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateFocusObject(ForceUpdate)

    self:updateFocusMixingObjectName(self.Labels[1], ForceUpdate, true)
    self:updatePlayPosition(self.Labels[2], ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateSceneSectionInfo(ForceUpdate)

    -- left part
    self:updateSceneSectionName(ForceUpdate)

    -- right part
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Text = ""

    if Song then
        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

        local BankIdx = IdeaSpaceVisible and
            Song:getFocusSceneBankIndexParameter():getValue() or
            Song:getFocusSectionBankIndexParameter():getValue()
        local NumBanks = IdeaSpaceVisible and
            (math.floor(Song:getScenes():size() / 16) + 1) or
            Song:getNumSectionBanksParameter():getValue()

        if NumBanks > 1 then
            -- show focused bank / num banks only if there are >1 banks
            Text = tostring(BankIdx + 1) .. "/" .. tostring(NumBanks)
        end
    end

    self.Labels[2]:setText(Text)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateSceneSectionName(ForceUpdate)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if ForceUpdate
        or StateCache:isFocusSceneChanged()
        or StateCache:isFocusSceneNameChanged()
        or StateCache:isFocusSectionChanged()
        or StateCache:isFocusSectionSceneNameChanged()
        or ArrangerHelper.isIdeaSpaceFocusChanged()
        or (Song and Song:getArrangerState():isViewChanged()) then

        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
        if IdeaSpaceVisible then
            local Scene = NI.DATA.StateHelper.getFocusScene(App)
            self.Labels[1]:setText(Scene and Scene:getNameParameter():getValue() or "NONE")
        else
            local Section = NI.DATA.StateHelper.getFocusSection(App)
            self.Labels[1]:setText(Section and NI.DATA.SectionAlgorithms.getName(Section) or "NONE")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updatePatternInfo(ForceUpdate)

	-- left part
	InfoBarBase.updatePatternName(self.Labels[1], ForceUpdate)

	-- right part
    local Song = NI.DATA.StateHelper.getFocusSong(App)
	local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Text = ""

    if Song and Group then
        local BankIdx = 0
        local NumBanks = 1

        if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
            local ClipBankIdx, MaxClipBankIdx = ClipHelper.getCurrentBank()
            BankIdx, NumBanks = ClipBankIdx + 1, MaxClipBankIdx + 1
        else
            BankIdx = Group:getFocusPatternBankIndexParameter():getValue() + 1
            NumBanks = Song:getNumPatternBanksParameter():getValue()
        end

		if NumBanks > 1 then
			-- show focused bank / num banks only if there are >1 banks
			Text = tostring(BankIdx).."/"..tostring(NumBanks)
		end
	end

	self.Labels[2]:setText(Text)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateSlotInfo(ForceUpdate)

    self.Labels[1]:setText(MaschineHelper.getFocusSlotNameWithNumber())

    -- show number of available plug-ins for current slot (using filters from ModuleHelper)
    -- subtract 1 because empty slot is not respected
    self.Labels[2]:setText(tostring(ModuleHelper.getResultListSize() - 1))

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarMikro:updateView(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if ForceUpdate or
        (Song and Song:getArrangerState():isViewChanged()) or
        (Song and App:getWorkspace():getMixerVisibleParameter():isChanged()) then

        local Text = App:getWorkspace():getMixerVisibleParameter():getValue()
            and "MIXER"
            or (ArrangerHelper.isIdeaSpaceFocused() and "IDEAS" or "SONG")
        self.Labels[1]:setText(Text)
    end

    self:updatePlayPosition(self.Labels[2], ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
