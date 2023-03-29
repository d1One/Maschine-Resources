
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/BrowseUtils"

------------------------------------------------------------------------------------------------------------------------
-- Attribute unit (Type, Subtype and Mode)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_Attribute = class( 'BPU_Attribute', BrowsePageUnitBase )

function BPU_Attribute:__init(Index, Page, AttributeColumn, AttributeString)

    BrowsePageUnitBase.__init(self, Index, Page)

    self.AttributeColumn = AttributeColumn
    self.AttributeString = AttributeString

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:isEnabled()

    return self.AttributesModel:getAttributeCount(self.AttributeColumn) > 0

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    local FocusAttribute = self.AttributesModel:getFocusAttribute(self.AttributeColumn)
    local AttributeCount = self.AttributesModel:getAttributeCount(self.AttributeColumn)

    if FocusAttribute > AttributeCount or FocusAttribute < 0 then

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "All")
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, self.AttributeString)

    else

        local ParameterValue = self.AttributesModel:getAttributeName(self.AttributeColumn, FocusAttribute)
        local First, Second = BrowseUtils.splitStringLargerThan8(ParameterValue)

        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, First)
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, Second)

    end

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_SINGLE)

    local MeterValue = BrowseUtils.getMeterPosition(FocusAttribute + 1, AttributeCount)
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:onEncoderChanged(Value)

    if not self:isEnabled() then
        return false
    end

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    self:advanceAttributeFocus(Delta)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:advanceAttributeFocus(Delta)

    local Attributes = App:getDatabaseFrontend():getBrowserModel():getAttributesModel()

    local ItemCount = Attributes:getAttributeCount(self.AttributeColumn)
    local FocusItem = Attributes:getFocusAttribute(self.AttributeColumn)

    if FocusItem >= ItemCount then
        FocusItem = -1
    end

    local NextItem = BrowseUtils.advanceIndex(FocusItem, Delta, ItemCount, true)

    if NextItem ~= FocusItem then
        App:getBrowserControllerDeferredSearch():setAttributeSingleSelection(self.AttributeColumn, NextItem)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:getParameterName()

    return self.AttributeString

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:getParameterValue()

    local ParameterValue = "All " .. self.AttributeString
    local FocusAttribute = self.AttributesModel:getFocusAttribute(self.AttributeColumn)
    local AttributeCount = self.AttributesModel:getAttributeCount(self.AttributeColumn)

    if FocusAttribute <= AttributeCount and FocusAttribute >= 0 then

        ParameterValue = self.AttributesModel:getAttributeName(self.AttributeColumn, FocusAttribute)

    end

    return ParameterValue

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Attribute:isValueChangeDeferred()

    return true

end

------------------------------------------------------------------------------------------------------------------------

