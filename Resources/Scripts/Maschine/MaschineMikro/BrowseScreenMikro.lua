------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/ScreenMikro"

------------------------------------------------------------------------------------------------------------------------
-- Main Control screen for Mikro
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowseScreenMikro = class( 'BrowseScreenMikro', ScreenMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BrowseScreenMikro:__init(Page)

    -- init base class
    ScreenMikro.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function BrowseScreenMikro:setupScreen()

    -- standard mikro screen
    ScreenMikro.setupScreen(self)
    self.ParameterBar[3] = ScreenHelper.createResultListItem(self.InfoGroupBar, "", "")
    self.ParameterBar[3]:setActive(false)

    -- multi value screen with additional options
    ScreenMikro.addNavModeScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseScreenMikro:setNavMode(SetNav)

    if SetNav then
        ScreenHelper.setWidgetText(self.ScreenButton, {"", "", "PLUG-IN"})
    end

    ScreenMikro.setNavMode(self, SetNav)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseScreenMikro:getNavMode()

    return self.NavGroupBar:isVisible() and 1 or 0

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function BrowseScreenMikro:update(ForceUpdate)

    local StateCache     = App:getStateCache()
    local Workspace      = App:getWorkspace()

    local PluginMode     = Workspace:getModulesVisibleParameter():getValue()

    if self:getNavMode() == 1 then

        self.ScreenButton[3]:setSelected(true)

        -- update parameter page name (bottom white box)
        local ParamCache        = StateCache:getParameterCache()

        self.NavButtons[1]:setVisible(PluginMode)
        self.NavButtons[6]:setVisible(PluginMode)

		-- update visibility of parameter page arrows
		local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
		self.NavParamSelectLabels[1]:setVisible(NumPages > 1)
		self.NavParamSelectLabels[3]:setVisible(NumPages > 1)

        local FocusSlotValid = NI.DATA.StateHelper.getFocusSlotIndex(App) ~= -1
        local FocusSlotIdx	 = NI.DATA.StateHelper.getFocusSlotIndex(App) + 1 -- 1-indexed
        local FocusSlotName	 = FocusSlotValid
                                and NI.DATA.SlotAlgorithms.getDisplayName(NI.DATA.StateHelper.getFocusSlot(App))
                                or "(NONE)"

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

        self.NavParamSelectLabels[1]:setVisible(false)
        self.NavParamSelectLabels[2]:setText("")
        self.NavParamSelectLabels[3]:setVisible(false)

    end

    -- call base class
    ScreenMikro.update(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
