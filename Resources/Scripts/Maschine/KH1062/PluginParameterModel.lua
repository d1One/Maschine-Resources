require "Scripts/Shared/Helpers/MaschineHelper"
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PluginParameterModel = class( 'PluginParameterModel' )

------------------------------------------------------------------------------------------------------------------------

function PluginParameterModel:__init()

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterModel:getFocusParameters()

    local Parameters = {}
    for Index = 1, NI.DATA.CONST_PARAMETERS_PER_PAGE do
        Parameters[Index] = { Parameter = MaschineHelper.getFocusedSoundSlotParameter(Index - 1) }
    end
    return Parameters

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterModel:getFocusPageName()

    local FocusSound = MaschineHelper.getFocusedSoundSlot()
    local Owner = FocusSound and FocusSound:getModule()
    local FocusPageIndex = MaschineHelper.getFocusedSoundSlotParameterPage()
    return Owner and FocusPageIndex ~= NPOS and Owner:getPageName(0, FocusPageIndex) or ""

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterModel:getFocusPageNumber()

    return MaschineHelper.getFocusedSoundSlotParameterPage() + 1

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterModel:getFocusPageCount()

    return MaschineHelper.getFocusedSoundSlotNumParameterPages()

end
