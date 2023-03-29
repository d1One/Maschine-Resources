local ParameterHelper = require("Scripts/Shared/KH1062/ParameterHelper")
require "Scripts/Maschine/KH1062/ArpParameterController"
require "Scripts/Maschine/KH1062/PluginParameterController"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterCacheController = class( 'ParameterCacheController' )

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:__init(ParameterCacheModel)

    self.ParameterCacheModel = ParameterCacheModel
    local ArpParameterModel = ParameterCacheModel.ParameterOwnerModels[ParameterHelper.FOCUSED_OWNER_PERFORM_ARP]
    self.ParameterOwner = {
        [ParameterHelper.FOCUSED_OWNER_PLUGIN] = {
            Controller = PluginParameterController()
        },
        [ParameterHelper.FOCUSED_OWNER_PERFORM_ARP] = {
            Controller = ArpParameterController(ArpParameterModel)
        }
    }

end

-----------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:withParameterOwner(Fn)

    local Owner = self.ParameterOwner[self.ParameterCacheModel.CurrentParameterOwnerId]

    if Owner then
        Fn(Owner)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:incrementFocusPage()

    self:withParameterOwner(function(Owner)

        if self.ParameterCacheModel:canPageRight() then
            Owner.Controller:incrementFocusPage()
            if self.onPageChanged then
                self.onPageChanged()
            end
        end

    end)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:decrementFocusPage()

    self:withParameterOwner(function(Owner)

        if self.ParameterCacheModel:canPageLeft() then
            Owner.Controller:decrementFocusPage()
            if self.onPageChanged then
                self.onPageChanged()
            end
        end

    end)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:setFocusedParameterOwner(ParameterOwnerID)

    self.ParameterCacheModel.CurrentParameterOwnerId = ParameterOwnerID

end

----------------------------------------------------------------------------------------------------------------------

local function getSectionNameFromParameterInfo(ParameterInfo)

    local Section = ""

    if ParameterInfo then
        Section = ParameterInfo.SectionName or (ParameterInfo.Parameter and ParameterInfo.Parameter:getSectionName()) or ""
    end

    return Section

end

----------------------------------------------------------------------------------------------------------------------

local function getSectionNames(Parameters)

    return ParameterHelper.getSectionNames(function (Index)
        return getSectionNameFromParameterInfo(Parameters[Index])
    end)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:setCachedParameters(Parameters)

    for ParamPos = 1, NI.DATA.CONST_PARAMETERS_PER_PAGE do
        local ParameterInfo = Parameters[ParamPos]
        NI.HW.setCachedParameter(App, ParamPos - 1, ParameterInfo and ParameterInfo.Parameter)
    end
    self.ParameterCacheModel.SectionNames = getSectionNames(Parameters)
    self.ParameterCacheModel.ParameterInfos = Parameters

end

------------------------------------------------------------------------------------------------------------------------

function ParameterCacheController:setPageChangedCallback(Callback)

    self.onPageChanged = Callback

end