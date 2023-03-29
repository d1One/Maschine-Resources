
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"

------------------------------------------------------------------------------------------------------------------------
-- Browser product grouping (Shift + first knob)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_ProductSorting = class( 'BPU_ProductSorting', BrowsePageUnitBase )

function BPU_ProductSorting:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductSorting:isEnabled()

    local FileType = self.BrowserModel:getFileTypeSelection()
    return FileType == "Instrument" or FileType == "Effect"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductSorting:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    local SortOrder = self.ProductModel:getSortOrder()
    local SortOrderString = self:getParameterValue()
    local MeterValue = 0

    if SortOrder == NI.DB3.ProductModel.BY_CATEGORY then
        MeterValue = 0
    elseif SortOrder == NI.DB3.ProductModel.BY_VENDOR then
        MeterValue = 1
    end

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, SortOrderString)
    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, self:getParameterName())

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_CENTER)
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductSorting:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    local SortOrder = self.ProductModel:getSortOrder()
    local ShouldToggle = (SortOrder == NI.DB3.ProductModel.BY_CATEGORY and -1 or 1) + Delta == 0

    if ShouldToggle then
        self.BrowserController:setProductsOrder(SortOrder == NI.DB3.ProductModel.BY_CATEGORY and
                                                NI.DB3.ProductModel.BY_VENDOR or NI.DB3.ProductModel.BY_CATEGORY, false)
    end

    return ShouldToggle

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductSorting:getParameterName()

    return "SORT BY"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductSorting:getParameterValue()

    local SortOrder = self.ProductModel:getSortOrder()
    local SortOrderString = ""

    if SortOrder == NI.DB3.ProductModel.BY_CATEGORY then
        SortOrderString = "CATEGORY"
    elseif SortOrder == NI.DB3.ProductModel.BY_VENDOR then
        SortOrderString = "VENDOR"
    end

    return SortOrderString

end

------------------------------------------------------------------------------------------------------------------------

