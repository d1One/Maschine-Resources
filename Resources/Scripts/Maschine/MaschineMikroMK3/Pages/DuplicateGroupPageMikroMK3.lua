------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"
require "Scripts/Shared/Components/PadMapper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicateGroupPageMikroMK3 = class( 'DuplicateGroupPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

local PAD_MAPPING = PadMapper()

PAD_MAPPING:map(1, 8, {GroupPadHelperMikroMK3.defaultBankNavigationFunctions()})
PAD_MAPPING:map(9, 16, {{ Action = function (self, PadIndex) self:selectGroup(PadIndex) end }})

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "DuplicateGroupPageMikroMK3", Controller)
    self.updateScreens = function() self:updateScreen() end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:onShow(Show)

    self:reset()
    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:reset()

    self.Mode = DuplicateHelper.GROUP
    self.SourceIndex = -1
    self.SourceGroupIndex = -1
    -- its necessary to assign GroupBank to -1 before,
    -- because GroupBank value is used in MaschineHelper.getFocusGroupBank()
    self.Screen.GroupBank = -1
    self.Screen.GroupBank = MaschineHelper.getFocusGroupBank(self)

    DuplicateHelper.setMode(self, DuplicateHelper.GROUP)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedGroup()
    self:setBottomRowToPatternParameter()

end


---------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:setBottomRowToPatternParameter()

    local FocusedParameter = NHLController:focusedParameter()

    if not FocusedParameter or not FocusedParameter:maschineParameter() then
        return
    end

    if FocusedParameter:name() == "Duplicate Group With Patterns" then

        self.Screen:setParameterName("Copy Patterns")
        self.Screen:setParameterValue(FocusedParameter:valueStringShort())

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    if not Trigger then
        return
    end

    local Handler = PAD_MAPPING:find(PadIndex, self)
    if not Handler then
        return
    end

    Handler.Action(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:selectGroup(PadIndex)

    local GroupIndex = GroupPadHelperMikroMK3.setFocusGroupByPad(self, PadIndex)
    -- GroupIndex is zero based for this function
    DuplicateHelper.onGroupButton(self, GroupIndex - 1)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:selectBank(PadIndex)

    local BankIndex = PadIndex - 1
    if BankIndex < MaschineHelper.getNumFocusSongGroupBanks(true) then
        MaschineHelper.setFocusGroupBankAndGroup(nil, BankIndex, true, true)  -- BankIndex >= 0
        self.Screen.GroupBank = BankIndex
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateGroupPageMikroMK3:updatePadLEDs()

    local selectedPadFunction = function (Index)
        return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, true)
    end

    GroupPadHelperMikroMK3.showGroupPads(self, self.Controller.PAD_LEDS, self.Controller.GROUP_LEDS, selectedPadFunction)

    local CanPasteGroup = self.Mode ~= DuplicateHelper.GROUP_SELECT and self.SourceIndex >= 0

    if CanPasteGroup then
        DuplicateHelper:blinkGroupLed(self)
    end

end

------------------------------------------------------------------------------------------------------------------------
