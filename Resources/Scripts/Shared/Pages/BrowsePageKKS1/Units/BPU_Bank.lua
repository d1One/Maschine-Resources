
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/BrowseUtils"

------------------------------------------------------------------------------------------------------------------------
-- Bank unit (Bank and Subbank)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_Bank = class( 'BPU_Bank', BrowsePageUnitBase )

function BPU_Bank:__init(Index, Page, BankEntry, BankString)

    BrowsePageUnitBase.__init(self, Index, Page)

    self.BankEntry = BankEntry
    self.BankString = BankString

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:isEnabled()

    -- subtract one because the function checks if the entry above has any children
    return self.BankChainModel:hasSelectedSlotItemChildren(self.BankEntry - 1)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    local SelectedSlotItem = self.BankChainModel:getSelectedSlotItem(self.BankEntry)
    local SlotItemCount = self.BankChainModel:getSlotItemCount(self.BankEntry)

    if SelectedSlotItem > SlotItemCount or SelectedSlotItem < 0 then

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "All")
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, self.BankString)

    else

        local ParameterValue = self.BankChainModel:getSlotItemName(self.BankEntry, SelectedSlotItem)
        local First, Second = BrowseUtils.splitStringLargerThan8(ParameterValue)

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, First)
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, Second)

    end

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_SINGLE)

    local MeterValue = BrowseUtils.getMeterPosition(SelectedSlotItem + 1, SlotItemCount)
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:onEncoderChanged(Value)

    if not self:isEnabled() then
        return false
    end

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    return self:advanceBankFocus(Delta)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:getParameterName()

    return self.BankString

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:getParameterValue()

    local ParameterValue = "All " .. self.BankString
    local SelectedSlotItem = self.BankChainModel:getSelectedSlotItem(self.BankEntry)
    local SlotItemCount = self.BankChainModel:getSlotItemCount(self.BankEntry)


    if SelectedSlotItem <= SlotItemCount and SelectedSlotItem >= 0 then

        ParameterValue = self.BankChainModel:getSlotItemName(self.BankEntry, SelectedSlotItem)

    end

    return ParameterValue

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:advanceBankFocus(Delta)

    local BankChainModel = App:getDatabaseFrontend():getBrowserModel():getBankChainModel()

    local ItemCount = BankChainModel:getSlotItemCount(self.BankEntry)
    local FocusItem = BankChainModel:getSelectedSlotItem(self.BankEntry)

    if FocusItem >= ItemCount or FocusItem < 0 then
        FocusItem = -1
    end

    local NextItem = BrowseUtils.advanceIndex(FocusItem, Delta, ItemCount, true)
    local CanAdvance = NextItem ~= FocusItem

    if CanAdvance then
        App:getBrowserControllerDeferredSearch():setBankChainSelection(self.BankEntry, NextItem)
    end

    return CanAdvance

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Bank:isValueChangeDeferred()

    return true

end

------------------------------------------------------------------------------------------------------------------------
