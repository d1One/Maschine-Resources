
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/BrowseUtils"

------------------------------------------------------------------------------------------------------------------------
-- Preset unit (last knob + text)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_Preset = class( 'BPU_Preset', BrowsePageUnitBase )

function BPU_Preset:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Preset:draw()

    -- text

    local ParameterValue = self.ResultListModel:getItemName(self.ResultListModel:getFocusItem())
    local FirstRow, SecondRow = BrowseUtils.splitStringLargerThan8(ParameterValue)
    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, FirstRow)
    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, SecondRow)

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)

    if self.ResultListModel:getItemCount() <= 1 then
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_LEFT)
    else
        self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_SINGLE)
    end

    local MeterValue = BrowseUtils.getMeterPosition(self.ResultListModel:getFocusItem(),
                                             (self.ResultListModel:getItemCount() - 1))
    self.DisplayPage:setMeterValue(self.Index, MeterValue)

    if self.ResultListModel:getItemCount() == 0 then
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "NO")
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, "RESULTS")
    end

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Preset:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    local ItemCount = self.ResultListModel:getItemCount()
    local FocusItem = self.ResultListModel:getFocusItem()
    local NextItem = BrowseUtils.advanceIndex(FocusItem, Delta, ItemCount, false)
    local HasFocusItemChanged = FocusItem ~= NextItem

    self.BrowserController:changeResultListFocus(NextItem - FocusItem, false, NI.DB3.BrowserController.SOURCE_DEFAULT, false)

    if BrowseHelper.canPrehear() and HasFocusItemChanged then
        NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
    end

    return HasFocusItemChanged

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Preset:getParameterName()

    return "Preset"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_Preset:getParameterValue()

    local ParameterValue = "NO RESULTS"

    if self.ResultListModel:getItemCount() > 0 then
        ParameterValue = self.ResultListModel:getItemName(self.ResultListModel:getFocusItem())
    end

    return ParameterValue

end

------------------------------------------------------------------------------------------------------------------------
