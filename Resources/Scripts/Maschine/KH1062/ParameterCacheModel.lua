local ParameterHelper = require("Scripts/Shared/KH1062/ParameterHelper")
require "Scripts/Maschine/KH1062/ArpParameterModel"
require "Scripts/Maschine/KH1062/PluginParameterModel"
require "Scripts/Maschine/KH1062/ScaleParameterModel"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterCacheModel = class( 'ParameterCacheModel' )

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:__init(isFocusGroupDrumKitModeEnabled)

    self.ParameterOwnerModels = {
        [ParameterHelper.FOCUSED_OWNER_PLUGIN] = PluginParameterModel(),
        [ParameterHelper.FOCUSED_OWNER_PERFORM_SCALE] = ScaleParameterModel(),
        [ParameterHelper.FOCUSED_OWNER_PERFORM_ARP] = ArpParameterModel(isFocusGroupDrumKitModeEnabled)
    }
    self.CurrentParameterOwnerId = ParameterHelper.FOCUSED_OWNER_PLUGIN
    self.SectionNames = {}
    self.ParameterInfos = {}

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:getFocusParameters()

    return self.ParameterOwnerModels[self.CurrentParameterOwnerId]:getFocusParameters()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:canPageLeft()

    return self.ParameterOwnerModels[self.CurrentParameterOwnerId]:getFocusPageNumber() > 1

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:canPageRight()

    local Owner = self.ParameterOwnerModels[self.CurrentParameterOwnerId]
    return Owner:getFocusPageNumber() < Owner:getFocusPageCount()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:getParameterData(ZeroBasedIndex)

    local Parameter = NI.HW.getCachedParameter(App, ZeroBasedIndex)
    local ParameterInfo = self.ParameterInfos[ZeroBasedIndex + 1]

    local DisplayName, ValueText, UnitText = ParameterHelper.getDisplayStrings(Parameter)
    local DisplayValue = ValueText..UnitText

    if ParameterInfo then
        if ParameterInfo.DisplayName then
            DisplayName = ParameterInfo.DisplayName
        end

        if ParameterInfo.getDisplayValue then
            DisplayValue = ParameterInfo.getDisplayValue(ParameterInfo.Parameter)
        end

    end

    return {
        SectionName = self.SectionNames[ZeroBasedIndex + 1],
        DisplayName = DisplayName ~= "" and DisplayName or nil,
        DisplayValue = DisplayValue
    }

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:getFocusedParameterPageName()

    return self.ParameterOwnerModels[self.CurrentParameterOwnerId]:getFocusPageName()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:getFocusedParameterPageNumber()

    return self.ParameterOwnerModels[self.CurrentParameterOwnerId]:getFocusPageNumber()

end


------------------------------------------------------------------------------------------------------------------------

function ParameterCacheModel:getFocusedParameterPageCount()

    return self.ParameterOwnerModels[self.CurrentParameterOwnerId]:getFocusPageCount()

end