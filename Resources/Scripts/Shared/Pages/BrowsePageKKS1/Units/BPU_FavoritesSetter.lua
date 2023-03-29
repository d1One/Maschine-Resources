
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------
-- Favorites setter (4th knob on shift)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_FavoritesSetter = class( 'BPU_FavoritesSetter', BrowsePageUnitBase )

function BPU_FavoritesSetter:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesSetter:isEnabled()

    return self.ResultListModel:getItemCount() > 0

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesSetter:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text
    local isFocusItemFavorite = BrowseHelper.isFocusItemFavorite()

    if self.Controller:isEncoderTouched(self.Index) and isFocusItemFavorite ~= NPOS then
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, isFocusItemFavorite and "ON" or "OFF")
    else
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "SET")
    end

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, "")

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_CENTER)
    self.DisplayPage:setMeterValue(self.Index, isFocusItemFavorite and 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesSetter:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    local isFocusItemFavorite = BrowseHelper.isFocusItemFavorite() and 1 or -1
    local ShouldToggle = isFocusItemFavorite + Delta == 0

    if ShouldToggle then
        self.BrowserController:toggleFavorite(self.ResultListModel:getFocusItem())
    end

    return ShouldToggle

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesSetter:getParameterName()

    return "Set favourite"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesSetter:getParameterValue()

    return self.ResultListModel:isItemFavorite(self.ResultListModel:getFocusItem()) and "ON" or "OFF"

end
