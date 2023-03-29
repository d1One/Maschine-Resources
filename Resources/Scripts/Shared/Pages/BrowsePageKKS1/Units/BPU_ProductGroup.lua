
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/BrowseUtils"

------------------------------------------------------------------------------------------------------------------------
-- Product group unit (first knob and its text displays)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_ProductGroup = class( 'BPU_ProductGroup', BrowsePageUnitBase )

function BPU_ProductGroup:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:isEnabled()

    return self.ProductModel:areProductsGrouped()

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:draw()

    if self:isEnabled()==false then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    local SortOrder = self.ProductModel:getSortOrder()

    if self.BrowserModel:getProductGroupSelection() == self.ProductModel.all() then

        -- "Category" instead of "Categories" is by design, as the latter is 10 symbols and doesn't fit.
        local GroupType = SortOrder == NI.DB3.ProductModel.BY_CATEGORY and "Category" or "Vendors"

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "All")
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, GroupType)

    else

        local GroupName = self.BrowserModel:getProductGroupSelection()
        local ParameterValue = GroupName == "Native Instruments" and "NI" or GroupName
        local First, Second = BrowseUtils.splitStringLargerThan8(ParameterValue)

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, First)
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, Second)

    end

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)

    if self.ProductModel:getNumProductGroups() == 0 then
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_LEFT)
    else
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_SINGLE)
    end

    local MeterValue = BrowseUtils.getMeterPosition(
        self.ProductModel:getProductGroupIndexFromName(self.BrowserModel:getProductGroupSelection()),
        self.ProductModel:getNumProductGroups() - 1)
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:onEncoderChanged(Value)

    if self:isEnabled()==false then
        return false
    end

   local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    -- advance Product Group focus

    local SelectedGroupIndex = self.ProductModel:getProductGroupIndexFromName(self.BrowserModel:getProductGroupSelection())
    local NewGroupIndex = BrowseUtils.advanceIndex(SelectedGroupIndex, Delta, self.ProductModel:getNumProductGroups(), false)

    App:getBrowserControllerDeferredSearch():setProductGroupSelection(
        self.ProductModel:getProductGroupNameFromIndex(NewGroupIndex))

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:getParameterName()

    return self.ProductModel:getSortOrder() == NI.DB3.ProductModel.BY_CATEGORY and "Category" or "Vendor"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:getParameterValue()

    local ParameterValue

    if self.BrowserModel:getProductGroupSelection() == self.ProductModel.all() then

        ParameterValue = "All "
        local GroupType = self.ProductModel:getSortOrder() == NI.DB3.ProductModel.BY_CATEGORY and "Categories" or "Vendors"
        ParameterValue = ParameterValue .. GroupType

    else

        ParameterValue = self.BrowserModel:getProductGroupSelection()

    end

    return ParameterValue

end

------------------------------------------------------------------------------------------------------------------------

function BPU_ProductGroup:isValueChangeDeferred()

    return true

end

------------------------------------------------------------------------------------------------------------------------

