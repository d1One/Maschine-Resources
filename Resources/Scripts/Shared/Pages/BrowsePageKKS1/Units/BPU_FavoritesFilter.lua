
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------
-- Favorites Filter (Shift + third knob)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_FavoritesFilter = class( 'BPU_FavoritesFilter', BrowsePageUnitBase )

function BPU_FavoritesFilter:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesFilter:draw()

    local isFavoritesFilterEnabled = BrowseHelper.isFavoritesFilterEnabled()

    -- text

    if self.Controller:isEncoderTouched(self.Index) then
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW,
                                 isFavoritesFilterEnabled and "ON" or "OFF")
    else
        self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "FILTER")
    end

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, "FAVORITE")

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_CENTER)
    self.DisplayPage:setMeterValue(self.Index, isFavoritesFilterEnabled and 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesFilter:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    local FilterEnabledNum = BrowseHelper.isFavoritesFilterEnabled() and 1 or -1

    local ShouldToggle = FilterEnabledNum + Delta == 0

    if ShouldToggle then
        BrowseHelper.toggleFavoritesFilter()
    end

    return ShouldToggle

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesFilter:getParameterName()

    return "Filter by favorites"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_FavoritesFilter:getParameterValue()

    return BrowseHelper.isFavoritesFilterEnabled() and "ON" or "OFF"

end

------------------------------------------------------------------------------------------------------------------------
