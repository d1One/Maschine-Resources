------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/ScreenMikro"
require "Scripts/Shared/Helpers/LevelButtonsHelper"

------------------------------------------------------------------------------------------------------------------------
-- Main Control screen for Mikro
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlScreenMikro = class( 'ControlScreenMikro', ScreenMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:__init(Page)

    -- init base class
    ScreenMikro.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:setupScreen()

    -- standard mikro screen
    ScreenMikro.setupScreen(self)

    -- multi value screen with additional options
    ScreenMikro.addNavModeScreen(self)

    -- Override update functor for transport bar in this screen
    self.InfoBar.UpdateFunctor = function(Force) self:updateInfoBar(Force) end

    self.LevelButtons = LevelButtonsHelper(self.ScreenButton)

end

------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:setNavMode(SetNav)
    ScreenMikro.setNavMode(self, SetNav)
end

------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:getNavMode()

    if self.NavGroupBar:isVisible() then
        return self.ScreenButton[3]:isSelected() and 2 or 1
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:update(ForceUpdate)

    local StateCache = App:getStateCache()

    local NavMode = self:getNavMode()
    if NavMode > 0 then

        local Workspace = App:getWorkspace()
        local PluginMode = Workspace:getModulesVisibleParameter():getValue()

        ScreenHelper.setWidgetText(self.ScreenButton, {"", "CHNL.", "PLUG-IN"})

        self.ScreenButton[1]:setSelected(false)
        self.ScreenButton[2]:setSelected(not PluginMode)
        self.ScreenButton[3]:setSelected(PluginMode)

        -- update top 4 boxes
        self.NavButtons[2]:setText(PluginMode and "1" or "IN")
        self.NavButtons[3]:setText(PluginMode and "2" or "OUT")
        self.NavButtons[4]:setText(PluginMode and "3" or "GRV")
        self.NavButtons[5]:setText(PluginMode and "4" or "MCR")

        -- update parameter page name (bottom white box)
        local ParamCache = StateCache:getParameterCache()
        local ParameterOwner = ParamCache:getFocusParameterOwner()
        local PageGroupParameter = Workspace:getPageGroupParameter()
        local PageParameter = ParamCache:getPageParameter()

        if ParameterOwner and PageGroupParameter and PageParameter then
            local GroupValue = PageGroupParameter:getValue()
            local PageValue = ParamCache:getValidPageParameterValue()
            local PageName = ParameterOwner:getPageDisplayName(GroupValue, PageValue)
            local SongFocus = NI.DATA.StateHelper.getFocusSong(App)


            if SongFocus then
                local LevelTab = SongFocus:getLevelTab()
                if not (PageValue == 0 and GroupValue == 0 and LevelTab == 0) then
                    self.NavParamSelectLabels[2]:setText(PageName)
                end
            else
                self.NavParamSelectLabels[2]:setText("")
            end
        else
            self.NavParamSelectLabels[2]:setText("[No Parameter Page]")
        end


        self.NavButtons[1]:setVisible(PluginMode)
        self.NavButtons[6]:setVisible(PluginMode)

		-- update visibility of parameter page arrows
		local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()

        if PluginMode then	-- Plug-in / Module mode

            local FocusSlotValid = NI.DATA.StateHelper.getFocusSlotIndex(App) ~= -1
            local FocusSlotIdx	 = NI.DATA.StateHelper.getFocusSlotIndex(App) + 1 -- 1-indexed
            local FocusSlotName	 = FocusSlotValid and NI.DATA.SlotAlgorithms.getDisplayName(NI.DATA.StateHelper.getFocusSlot(App)) or "(NONE)"

            -- update NavButtons
            local ChainSlots = NI.DATA.StateHelper.getFocusChainSlots(App)
            local NumSlots = ChainSlots and ChainSlots:size() or 0

            if FocusSlotValid then
                NumSlots = NumSlots + 1 -- +1 for the "NEW" slot
            end

            local NumPages = math.ceil(math.max(0, (NumSlots / 4) - 1))
            local CurPage = FocusSlotValid and math.max(0, math.floor((FocusSlotIdx - 1) / 4)) -- pages are 0-indexed
                                            or math.max(0, math.floor((NumSlots) / 4))

            self.NavButtons[1]:setEnabled(CurPage > 0)
            self.NavButtons[6]:setEnabled(CurPage < NumPages)

            for Idx = 1,4 do
                local CurSlotIdx = Idx + (4 * CurPage)

                local IsEnabled = false
                local IsSelected = false

                local Slots      = NI.DATA.StateHelper.getFocusChainSlots(App)
                local Slot       = Slots and Slots:at(CurSlotIdx - 1)
                local IsBypassed = Slot and Slot:getActiveParameter():getValue() == false or false

                if FocusSlotValid then
                    IsEnabled = CurSlotIdx <= NumSlots
                    IsSelected = CurSlotIdx == FocusSlotIdx
                else
                    IsEnabled = CurSlotIdx <= NumSlots + 1
                    IsSelected = CurSlotIdx == NumSlots + 1
                end

                self.NavButtons[Idx+1]:setEnabled(IsEnabled and not IsBypassed)
                self.NavButtons[Idx+1]:setSelected(IsSelected)


                self.NavButtons[Idx+1]:setText(IsEnabled and tostring(CurSlotIdx) or "")

                if FocusSlotValid and CurSlotIdx == NumSlots then
                    self.NavButtons[Idx+1]:setText("+")

                elseif not FocusSlotValid and CurSlotIdx == NumSlots+1 then
                    self.NavButtons[Idx+1]:setText("+")
                end

            end

            -- update title
            self.NavTitle[1]:setText(FocusSlotName)

        else -- Channel mode

            if PageGroupParameter then

                self.NavTitle[1]:setText(PageGroupParameter:getValueString())

                -- update page selection states. +2 in order to match up with button nav indices
                local SelectedPageGroup = PageGroupParameter:getValue() + 2
                for Idx = 2,5 do
                    self.NavButtons[Idx]:setEnabled(true)
                    self.NavButtons[Idx]:setSelected(SelectedPageGroup == Idx)
                end
            end

        end

    else -- Non-nav mode

        self.LevelButtons:updateButtons()

        -- title
        self.InfoBar:updateFocusMixingObjectName(self.Title[1], ForceUpdate, true)

        -- transport
        self.InfoBar:update(ForceUpdate)

    end

    -- call base class
    ScreenMikro.update(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlScreenMikro:updateInfoBar(ForceUpdate)

	local PluginMode = App:getWorkspace():getModulesVisibleParameter():getValue()
	local LeftText = ""

	if PluginMode then

		local StateCache	 = App:getStateCache()
        local SlotValid = NI.DATA.StateHelper.getFocusSlotIndex(App) ~= -1

		if SlotValid then
			local SlotIdx	 = NI.DATA.StateHelper.getFocusSlotIndex(App) + 1 -- 1-indexed
			local SlotName	 = NI.DATA.SlotAlgorithms.getDisplayName(NI.DATA.StateHelper.getFocusSlot(App))

			LeftText = tostring(SlotIdx) .. ". " .. SlotName
		else
			LeftText = "(NONE)"
		end

	else
		LeftText = App:getWorkspace():getPageGroupParameter():getValueString()
	end

	self.InfoBar.Labels[1]:setText(LeftText)
	self.InfoBar:updatePlayPosition(self.InfoBar.Labels[2], ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
