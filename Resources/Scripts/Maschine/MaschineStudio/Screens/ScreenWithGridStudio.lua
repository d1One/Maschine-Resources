------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/ColorPaletteHelper"
require "Scripts/Shared/Helpers/MaschineHelper"


local ATTR_IS_EMPTY = NI.UTILS.Symbol("isEmpty")
local ATTR_IS_PLUS = NI.UTILS.Symbol("isPlus")
local ATTR_IS_FOCUSED = NI.UTILS.Symbol("isFocused")

------------------------------------------------------------------------------------------------------------------------
-- Screen
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenWithGridStudio = class( 'ScreenWithGridStudio', ScreenMaschineStudio )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:__init(Page, LeftLabels, RightLabels, LeftButtonStyles, RightButtonStyles, GridButtonStyle)    -- init base class

    self.LeftLabels = LeftLabels
    self.RightLabels = RightLabels

    self.LeftButtonStyles = LeftButtonStyles or "HeadButton"
    self.RightButtonStyles = RightButtonStyles or "HeadButton"
    self.GridButtonStyle = GridButtonStyle

    ScreenMaschineStudio.__init(self, Page)

    self.IncludeNewGroupSlot = false  -- consider slot of new group to be created in group buttons

    self:enableLevelMeters(false)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:enableLevelMeters(Enable)

    if self.UpdateLevelMeters ~= Enable then
        for Index, PadButton in ipairs (self.PadButtons) do
            PadButton.LevelMeter:setVisible(Enable)
        end

        if self.FocusBank and self.GroupButtons then
            for Index, GroupButton in ipairs (self.GroupButtons) do
                GroupButton.LevelMeter:setVisible(Enable)
            end
        end
    end

    self.UpdateLevelMeters = Enable

end

------------------------------------------------------------------------------------------------------------------------
-- setup gui
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:setupScreen()

    -- call base class
    ScreenMaschineStudio.setupScreen(self)

    self.styleScreen(self, self.ScreenLeft, self.LeftLabels or {"", "", "", ""}, self.LeftButtonStyles, true)
    self.styleScreen(self, self.ScreenRight, self.RightLabels or {"", "", "", ""}, self.RightButtonStyles, false, false)

    -- add grid buttons
    self:createGrid()

	self.GroupBank = -1
	self.FocusGroupIndex = 0
	self.GroupButtons = nil

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:createGrid()

    self.PadButtons = {}

    local ContainerBar = NI.GUI.insertBar(self.ScreenRight.DisplayBar, "Grid")
    ContainerBar:style(NI.GUI.ALIGN_WIDGET_UP, "Grid")
    self.ScreenRight.DisplayBar:setFlex(ContainerBar)

    self.ScreenRight.DisplayBar.Grid = ContainerBar

    -- insert 16 buttons
    for BarIndex = 1, 4 do

        local ButtonBar = NI.GUI.insertBar(ContainerBar, "ButtonBar")
        ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "PadRow")
        for ButtonIndex = 1, 4 do
            local Index = (BarIndex - 1) * 4 + ButtonIndex
            local Pad = NI.GUI.insertBar(ButtonBar, "Pad"..tostring(Index))
            Pad:style(NI.GUI.ALIGN_WIDGET_RIGHT, "GridPad")
            Pad.Label = NI.GUI.insertMultilineTextEdit(Pad, "PadLabel")
            Pad.Label:style("PadLabel")
            Pad.LevelMeter = NI.GUI.insertLevelMeter(Pad, "PadLevelMeter")
            Pad.LevelMeter:setPeakHoldAndDeclineInterval(false, 0)
            Pad:setFlex(Pad.Label)

            self.PadButtons[#self.PadButtons + 1] = Pad
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:onTimer()

    if self.UpdateLevelMeters then
        self:updateLevelMeters()
    end
end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:updateLevelMeters()

    -- update Sounds level meters
    for PadIndex, PadButton in ipairs (self.PadButtons) do
        self:updateSoundLevelMeter(PadButton, PadIndex)
    end

    -- update Groups level meters (if needed)
    if self.FocusBank and self.GroupButtons then
        for GroupIndex, GroupButton in ipairs (self.GroupButtons) do
            self:updateGroupLevelMeter(GroupButton, GroupIndex)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:updateSoundLevelMeter(PadButton, PadIndex)

    local GroupIndex = self.DisplayGroup or NI.DATA.StateHelper.getFocusGroupIndex(App)

    if self.DisplayGroup then
        GroupIndex = GroupIndex - 1
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and GroupIndex and Song:getGroups():at(GroupIndex)
    local Sound = Group and Group.getSounds and Group:getSounds():at(PadIndex - 1) or nil

    if Sound then
        PadButton.LevelMeter:setLevels(Sound:getLevel(0), Sound:getLevel(1))
    else
        PadButton.LevelMeter:resetPeak()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:updateGroupLevelMeter(GroupButton, GroupIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at((GroupIndex - 1) + (self.FocusBank-1) * 8)

    if Group then
        GroupButton.LevelMeter:setLevels(Group:getLevel(0), Group:getLevel(1))
    else
        GroupButton.LevelMeter:resetPeak()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:insertGroupButtons(IncludeNewGroupSlot)

    self.IncludeNewGroupSlot = IncludeNewGroupSlot

    -- insert group buttons
    self.GroupButtons = {}

    self.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, '')

    for Row = 1, 2 do
        local RowBar = NI.GUI.insertBar(self.ScreenLeft.DisplayBar, "GroupRow")
        RowBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "GroupRow")
        for Col = 1, 4 do
            local GroupBar = {}

            GroupBar = NI.GUI.insertBar(RowBar, "GroupBar")
            GroupBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "GroupBar")
            GroupBar.NameShort = NI.GUI.insertLabel(GroupBar, "NameShort")
            GroupBar.NameShort:style("", "GroupNameShort")
            GroupBar.NameLong = NI.GUI.insertMultilineTextEdit(GroupBar, "NameLong")
            GroupBar.NameLong:style("GroupNameLong")
            GroupBar.LevelMeter = NI.GUI.insertLevelMeter(GroupBar, "GroupLevelMeter")
            GroupBar.LevelMeter:setNoAlign(true)
            GroupBar.LevelMeter:setPeakHoldAndDeclineInterval(false, 0)
            GroupBar:setFlex(GroupBar.NameLong)

            self.GroupButtons[#self.GroupButtons + 1] = GroupBar
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:update(ForceUpdate)

	if self.GroupButtons then

		-- update prev/next group buttons. needs to be called before base class updateScreens()
		-- because the screen button LED states depend on the group button states.
		local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(self.IncludeNewGroupSlot) - 1

		-- manage your own group banks (for visualization) or let MaschineHelper do it
		local GroupBank = self.GroupBank >= 0 and self.GroupBank or MaschineHelper.getFocusGroupBank()

		self.ScreenButton[3]:setEnabled(GroupBank > 0)
		self.ScreenButton[4]:setEnabled(GroupBank < MaxPageIndex)

		self.setArrowText(self, 1, "BANK "..GroupBank+1)

		self:updateColors(GroupBank, ForceUpdate)
	end

	-- base class
	ScreenMaschine.update(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- Color Stuff
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:updateColors(GroupBank, ForceUpdate)

   -- use self.DisplayGroup if not nil or 0
   local FocusGroupIndex = self.DisplayGroup or NI.DATA.StateHelper.getFocusGroupIndex(App)
   local Song = NI.DATA.StateHelper.getFocusSong(App)
   local Groups = Song and Song:getGroups()

   if FocusGroupIndex ~= NPOS then
       FocusGroupIndex = FocusGroupIndex + 1
   end

	-- Refresh Color Indexes?

	local RefreshGroups = false
	local RefreshPads = false

	-- Changed Bank
	if ForceUpdate or (self.GroupButtons and self.FocusBank ~= GroupBank+1) or FocusGroupIndex == NPOS then
		self.FocusBank = GroupBank+1
		RefreshGroups = true
	end

	-- Changed Group
	if self.FocusGroupIndex ~= FocusGroupIndex then
		self.FocusGroupIndex = FocusGroupIndex
		RefreshPads = true
	end

	-- Group color changed
	if not RefreshGroups and self.GroupButtons then
		for Index = 0, 7 do
			local Group = Groups:at(Index + (self.FocusBank-1) * 8)
			if Group and Group:getColorParameter():isChanged() then
				RefreshGroups = true
				break;
			end
		end
	end

	-- Sound color changed
	if not RefreshPads then

	    local Group = Groups and Groups:at(self.FocusGroupIndex-1)
	    local Sounds = Group and Group.getSounds and Group:getSounds()

	    if Sounds then
			for Index = 1, Sounds:size() do
				local Sound = Sounds:at(Index-1)

				if Sound and Sound:getColorParameter():isChanged() then
					RefreshPads = true
					break;
				end
			end
		end
	end

	if RefreshGroups or ForceUpdate then
		self:refreshGroupColors()
	end

	if RefreshPads or ForceUpdate then
		self:refreshPadColors()
	end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:refreshGroupColors()

	if self.FocusBank == nil or self.GroupButtons == nil then
		return
	end

	-- iterate over group Widgets
    for Index, Button in ipairs (self.GroupButtons) do

		local ColorIndex = Index + (self.FocusBank-1) * 8

        ColorPaletteHelper.setGroupColor(Button, ColorIndex)
        ColorPaletteHelper.setGroupColor(Button.NameShort, ColorIndex)
        ColorPaletteHelper.setGroupColor(Button.NameLong, ColorIndex)
        ColorPaletteHelper.setGroupColor(Button.LevelMeter, ColorIndex)

        if self.FocusBank and self.GroupButtons then
            self:updateGroupLevelMeter(Button, Index)
        end

        Button:setInvalid(0)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:refreshPadColors()

    -- iterate over pad Widgets
    for Index, PadButton in ipairs (self.PadButtons) do

        ColorPaletteHelper.setSoundColor(PadButton, Index, self.DisplayGroup)
        ColorPaletteHelper.setSoundColor(PadButton.Label, Index, self.DisplayGroup)
        ColorPaletteHelper.setSoundColor(PadButton.LevelMeter, Index, self.DisplayGroup)

        self:updateSoundLevelMeter(PadButton, Index)

        PadButton:setInvalid(0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGridStudio:incrementGroupBank(Delta)

	self.GroupBank = math.bound(self.GroupBank + Delta, 0,
		MaschineHelper.getNumFocusSongGroupBanks(self.IncludeNewGroupSlot)-1)

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function ScreenWithGridStudio:updateGroupButtonsWithFunctor(ButtonStateFunctor)

    -- iterate over LEDs
    for Index, GroupButton in ipairs (self.GroupButtons) do

        -- get text, select and enable state from functor
        local Visible, Enabled, Selected, Focused, Text = ButtonStateFunctor(Index)

        GroupButton:setSelected(Selected)
        GroupButton.NameShort:setSelected(Selected)
        GroupButton.NameLong:setSelected(Selected)
        GroupButton.LevelMeter:setSelected(Selected)

        GroupButton:setEnabled(Enabled)
        GroupButton.NameShort:setEnabled(Enabled)
        GroupButton.NameLong:setEnabled(Enabled)
        GroupButton.LevelMeter:setEnabled(Enabled)

        GroupButton.NameShort:setText(Text == "" and "" or NI.DATA.Group.getLabel(Index + self.GroupBank * 8 - 1))
        GroupButton.NameLong:setText(Text)

        GroupButton:setAttribute(ATTR_IS_EMPTY, not Enabled and Text == "" and "true" or "false")
        GroupButton:setAttribute(ATTR_IS_PLUS, not Enabled and Text == "+" and "true" or "false")

        GroupButton:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")
        GroupButton.NameShort:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")
        GroupButton.NameLong:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")
        GroupButton.LevelMeter:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")

        if Visible ~= nil then
            GroupButton:setVisible(Visible)
        end

    end

end


------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function ScreenWithGridStudio:updatePadButtonsWithFunctor(ButtonStateFunctor)

    -- iterate over LEDs
    for Index, PadButton in ipairs (self.PadButtons) do

        -- get text, select and enable state from functor
        local Visible, Enabled, Selected, Focused, Text = ButtonStateFunctor(Index)

        PadButton:setSelected(Selected)
        PadButton.Label:setSelected(Selected)
        PadButton.LevelMeter:setSelected(Selected)

        PadButton:setEnabled(Enabled)
        PadButton.Label:setEnabled(Enabled)
        PadButton.Label:setText(Text)

        PadButton:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")
        PadButton.Label:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")
        PadButton.LevelMeter:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")

        if Visible ~= nil then
            PadButton:setVisible(Visible)
        end

    end

end

