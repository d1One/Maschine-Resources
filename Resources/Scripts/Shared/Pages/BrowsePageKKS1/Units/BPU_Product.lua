
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/BrowseUtils"

------------------------------------------------------------------------------------------------------------------------
-- Product unit (second knob)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_Product = class( 'BPU_Product', BrowsePageUnitBase )

function BPU_Product:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Product:draw()

    local SelectedSlotItem = self.BankChainModel:getSelectedSlotItem(BANK_CHAIN_ENTRY_1)
    local SlotItemCount = self.BankChainModel:getSlotItemCount(BANK_CHAIN_ENTRY_1)

    -- text

    if SelectedSlotItem > SlotItemCount or SelectedSlotItem < 0 then

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "All")
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, "Products")

    else

        local ParameterValue = self.BankChainModel:getSelection():getName()
        local First, Second = BrowseUtils.splitStringLargerThan8(ParameterValue)

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, First)
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, Second)

    end

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)

    if SlotItemCount == 0 then
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_LEFT)
    else
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_SINGLE)
    end

    local MeterValue = BrowseUtils.getMeterPosition(SelectedSlotItem + 1, SlotItemCount)
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Product:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    -- advance Product focus

    local ProductModel = self.BrowserModel:getProductModel()
    local NextItem = ProductModel:getNextProduct(Delta)

    App:getBrowserControllerDeferredSearch():setBankChainSelection(NextItem)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Product:getParameterName()

    return "Product"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Product:getParameterValue()

    local ParameterValue = "All Products"
    local SelectedSlotItem = self.BankChainModel:getSelectedSlotItem(BANK_CHAIN_ENTRY_1)
    local SlotItemCount = self.BankChainModel:getSlotItemCount(BANK_CHAIN_ENTRY_1)

    if SelectedSlotItem <= SlotItemCount and SelectedSlotItem >= 0 then

        ParameterValue = self.BankChainModel:getSelection():getName()

    end

    return ParameterValue
end

------------------------------------------------------------------------------------------------------------------------

function BPU_Product:isValueChangeDeferred()

    return true

end

------------------------------------------------------------------------------------------------------------------------
