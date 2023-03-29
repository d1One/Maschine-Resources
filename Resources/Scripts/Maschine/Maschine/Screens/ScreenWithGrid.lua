------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------
-- Screen
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenWithGrid = class( 'ScreenWithGrid', ScreenMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGrid:__init(Page, ButtonTextsLeft, ButtonTextsRight)    -- init base class

    self.ButtonTextsLeft = ButtonTextsLeft
    self.ButtonTextsRight = ButtonTextsRight

    ScreenMaschine.__init(self, Page)

    self.IncludeNewGroupSlot = false  -- consider slot of new group to be created in group buttons
end

------------------------------------------------------------------------------------------------------------------------
-- setup gui
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGrid:setupScreen()

    -- call base class
    ScreenMaschine.setupScreen(self)

    self.ScreenButton = {}

    self:addScreenButtonBar(self.ScreenLeft, self.ButtonTextsLeft or {"", "", "", ""}, "HeadButton")

    -- add transport bar
    self.InfoBar = InfoBar(self.Page.Controller, self.ScreenLeft)

    self:addScreenButtonBar(self.ScreenRight, self.ButtonTextsRight or {"", "", "", ""}, "HeadButton")

    self.ButtonPad = {}

    self.Grid = ScreenHelper.createBarWith16Buttons(self.ScreenRight, self.ButtonPad,
                {"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""}, "Pad")

    self.GroupBank = -1

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGrid:insertGroupButtons(IncludeNewGroupSlot)

    self.IncludeNewGroupSlot = IncludeNewGroupSlot

    -- insert spacer
    local Spacer = NI.GUI.insertLabel(self.ScreenLeft, "Spacer")
    Spacer:style("", "Spacer6px")

    -- insert group buttons
    self.GroupButtons = {}

    if self.ScreenButton[3] and self.ScreenButton[4] then
		self.ScreenButton[3]:style("PREV", "ScreenButton")
		self.ScreenButton[4]:style("NEXT", "ScreenButton")
	end

    ScreenHelper.createBarWithButtons(self.ScreenLeft, self.GroupButtons, {"g1", "g2", "g3", "g4"}, "PadRow1", "Pad")
    ScreenHelper.createBarWithButtons(self.ScreenLeft, self.GroupButtons, {"g5", "g6", "g7", "g8"}, "PadRow2", "Pad")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ScreenWithGrid:update(ForceUpdate)

	-- update prev/next group buttons. needs to be called before base class updateScreens()
	-- because the screen button LED states depend on the group button states.
	local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(self.IncludeNewGroupSlot) - 1

	-- manage your own group banks (for visualization) or let MashineHelper do it
	local GroupBank = self.GroupBank >= 0 and self.GroupBank or MaschineHelper.getFocusGroupBank()

	if GroupBank >= 0 and self.GroupButtons and self.ScreenButton[3] and self.ScreenButton[4] then
		self.ScreenButton[3]:setEnabled(GroupBank > 0)
		self.ScreenButton[4]:setEnabled(GroupBank < MaxPageIndex)
	end

	-- base class
	ScreenMaschine.update(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenWithGrid:incrementGroupBank(Delta)

	self.GroupBank = math.bound(self.GroupBank + Delta, 0,
		MaschineHelper.getNumFocusSongGroupBanks(self.IncludeNewGroupSlot)-1)

end

------------------------------------------------------------------------------------------------------------------------

--Functor: Visible, Enabled, Selected, Focused, Text
function ScreenWithGrid:updateGroupButtonsWithFunctor(ButtonStateFunctor)

    ScreenHelper.updateButtonsWithFunctor(self.GroupButtons, ButtonStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

--Functor: Visible, Enabled, Selected, Focused, Text
function ScreenWithGrid:updatePadButtonsWithFunctor(ButtonStateFunctor)

    ScreenHelper.updateButtonsWithFunctor(self.ButtonPad, ButtonStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------
