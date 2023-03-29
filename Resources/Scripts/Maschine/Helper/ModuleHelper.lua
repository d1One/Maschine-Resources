------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/ModuleHelper"

------------------------------------------------------------------------------------------------------------------------
-- ModuleHelper
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Consts & Members
------------------------------------------------------------------------------------------------------------------------

-- Default Vendor
ModuleHelper.VENDOR_NI = "NI"

-- Plugin formats
ModuleHelper.INTERNAL = "Internal"
ModuleHelper.AU = "Audio Units"
ModuleHelper.VST3 = "VST3"
ModuleHelper.VST2 = "VST"

ModuleHelper.FormatFilters = {}
ModuleHelper.FormatFilters[ModuleHelper.INTERNAL] = 0
ModuleHelper.FormatFilters[ModuleHelper.AU] = NI.HOSTING.PluginFilter.SKIP_NOT_AUv2_PLUGINS
ModuleHelper.FormatFilters[ModuleHelper.VST3] = NI.HOSTING.PluginFilter.SKIP_NOT_VST3_PLUGINS
ModuleHelper.FormatFilters[ModuleHelper.VST2] = NI.HOSTING.PluginFilter.SKIP_NOT_VST2_PLUGINS

-- subtype categories
ModuleHelper.TYPE_INSTRUMENT = 1
ModuleHelper.TYPE_EFFECT     = 2

------------------------------------------------------------------------------------------------------------------------
-- ModuleHelpers main role is to maintain a 3 dimensional array of
-- Instrument/Effect (module) -> Plugin formats -> plugin vendors
-- It also tracks the index into the array structure
------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getInsertMode()

    return App:getWorkspace():getHWInsertModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.closeModulePage(Controller)

    BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_OFF)
    Controller:showTempPage(NI.HW.PAGE_CONTROL)

end

------------------------------------------------------------------------------------------------------------------------
function ModuleHelper.loadModule()

    local StateCache  = App:getStateCache()
    local MixingLayer = NI.DATA.StateHelper.getFocusMixingLayer(App)
    local Slot        = nil
    local Chain       = NI.DATA.StateHelper.getFocusChain(App)

    if ModuleHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF then
        Slot = NI.DATA.StateHelper.getFocusSlot(App)
    end

    if ModuleHelper.getCurrentModuleIndex() == 0 then

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

        if Slots and Slot then
            NI.DATA.ChainAccess.removeSlot(App, Slots, Slot)
        end

    else

        if ModuleHelper.getSelectedFormat() == ModuleHelper.INTERNAL then

            local ModuleInfo = ModuleHelper.getModuleInfoAt(ModuleHelper.getCurrentModuleIndex() - 1)

            if ModuleInfo then
                local ModuleId = ModuleInfo:getId()
                NI.DATA.ChainAccess.createModuleOrLoadDefault(App, ModuleId, Chain, Slot,
                    ModuleHelper.getInsertMode() == NI.DATA.INSERT_MODE_FRESH)

            end

        else

            local TypeFilter = ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and
                NI.HOSTING.PluginFilter.SKIP_NOT_SYNTH_PLUGINS or
                NI.HOSTING.PluginFilter.SKIP_NOT_EFFECT_PLUGINS

            TypeFilter = TypeFilter | ModuleHelper.FormatFilters[ModuleHelper.getSelectedFormat()]

            local Index = ModuleHelper.getCurrentModuleIndex() - 1

            local VendorName = ModuleHelper.getCurrentVendor()
            local IsKomplete = VendorName == "NI"

            local PluginDescriptor

            if IsKomplete then

                local VendorFilter = NI.HOSTING.PluginFilter.SKIP_THIRD_PARTY_PLUGINS
                PluginDescriptor = NI.DATA.PluginHelper.getValidPluginDescriptor(
                    Index, TypeFilter, VendorFilter)

            else

                PluginDescriptor = NI.DATA.PluginHelper.getValidPluginDescriptorByVendor(
                    VendorName, TypeFilter, Index)

            end

            if PluginDescriptor and MixingLayer then
                NI.DATA.PluginHelper.createPluginModule(
                    App, PluginDescriptor, MixingLayer:getChain(), Slot, false,
                    ModuleHelper.getInsertMode() == NI.DATA.INSERT_MODE_FRESH)
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.loadModuleInsertMode()

    NHLController:getPageStack():popToBottomPage()

    ModuleHelper.loadModule()
    BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.moduleNameAt(Index)

    local Name = "(none)"

    if Index ~= 0 then

        if ModuleHelper.getSelectedFormat() == ModuleHelper.INTERNAL then

            local ModuleInfo = ModuleHelper.getModuleInfoAt(Index - 1)
            Name = ModuleInfo and ModuleInfo:getName() or "(none)"

        else

            local TypeFilter = ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and
                NI.HOSTING.PluginFilter.SKIP_NOT_SYNTH_PLUGINS or
                NI.HOSTING.PluginFilter.SKIP_NOT_EFFECT_PLUGINS

            TypeFilter = TypeFilter | ModuleHelper.FormatFilters[ModuleHelper.getSelectedFormat()]

            local VendorName = ModuleHelper.getCurrentVendor()
            local IsKomplete = VendorName == "NI"

            if IsKomplete then

                local VendorFilter = NI.HOSTING.PluginFilter.SKIP_THIRD_PARTY_PLUGINS
                Name = NI.DATA.PluginHelper.getValidPluginDescriptorName(App, not IsKomplete, Index - 1,
                    TypeFilter, VendorFilter)

            else

                local VendorName = VendorName
                Name = NI.DATA.PluginHelper.getValidPluginDescriptorByVendorName(VendorName, TypeFilter,
                                                                                          Index - 1)

            end

        end
    end

    return Name

end
------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.loadResultListItem(Label, Index)

    local Name = ModuleHelper.moduleNameAt(Index)

	Label:setText(Name)
	Label:setSelected(ModuleHelper.getCurrentModuleIndex() == Index)

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getResultListSize()

    local Size = 1

    if ModuleHelper.getSelectedFormat() == ModuleHelper.INTERNAL then

        if ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT then
            Size = NI.DATA.ModuleFactory.getInstrumentInfos():size() + 1
        else
            Size = NI.DATA.ModuleFactory.getEffectInfos():size() + 1
            if ModuleHelper.canAddPerformanceFX() then
                Size = Size + 1
            end
        end

    else

        local TypeFilter = ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and
            NI.HOSTING.PluginFilter.SKIP_NOT_SYNTH_PLUGINS or
            NI.HOSTING.PluginFilter.SKIP_NOT_EFFECT_PLUGINS

        TypeFilter = TypeFilter | ModuleHelper.FormatFilters[ModuleHelper.getSelectedFormat()]

        local VendorName = ModuleHelper.getCurrentVendor()
        local IsKomplete = VendorName == "NI"

        if IsKomplete then

            local VendorFilter = NI.HOSTING.PluginFilter.SKIP_THIRD_PARTY_PLUGINS
            Size = NI.DATA.PluginHelper.getValidPluginDescriptorsSize(TypeFilter, VendorFilter) + 1

        else

            Size = NI.DATA.PluginHelper.getValidPluginDescriptorsByVendorSize(VendorName, TypeFilter) + 1

        end

    end

    return Size

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.refreshResultList(ResultList)

    if ResultList and ModuleHelper.getCurrentModuleIndex() then
        ResultList:setFocusItem(ModuleHelper.getCurrentModuleIndex())
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getModuleInfoAt(Index)

    ModuleInfo = nil

    if ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT then
        ModuleInfo = NI.DATA.ModuleFactory.getInstrumentInfoAt(Index)
    else
        ModuleInfo = NI.DATA.ModuleFactory.getEffectInfoAt(Index)
        if ModuleInfo:getId() == NI.DATA.ModuleInfo.ID_NONE and ModuleHelper.canAddPerformanceFX() then
            ModuleInfo = NI.DATA.ModuleFactory.getPerformanceFXInfo()
        end
    end

    return ModuleInfo

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getCurrentType()

    return BrowseHelper.isInstrumentSlot() and ModuleHelper.CurrentType or ModuleHelper.TYPE_EFFECT

end


function ModuleHelper.setCurrentType(Type)
    -- When changing type ensure other fields are still valid
    ModuleHelper.format = ModuleHelper.INTERNAL
    ModuleHelper.CurrentVendor = ModuleHelper.VENDOR_NI
    ModuleHelper.CurrentType = Type
end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getCurrentVendor()

    return ModuleHelper.CurrentVendor

end


function ModuleHelper.getSelectedFormat()
    return ModuleHelper.format
end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getVendorDisplayName(Vendor)

    return Vendor ~= "" and Vendor or "Other"

end


------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getCurrentVendorIndex()

    return ModuleHelper.getVendorIndexInTypeList(ModuleHelper.getCurrentType(), ModuleHelper.getSelectedFormat(), ModuleHelper.getCurrentVendor())

end

function ModuleHelper.getCurrentFormatIndex()

    for index, value in pairs(ModuleHelper.getPluginFormatsForCurrentType()) do
        if value == ModuleHelper.format then
            return index - 1
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getCurrentModuleIndex()

    if ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()] == nil or
            ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][ModuleHelper.getCurrentVendor()] == nil then
        ModuleHelper.resetCache()
    end

    return ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][ModuleHelper.getCurrentVendor()]

end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.getVendorIndexInTypeList(Type, formatType, VendorName)

    local VendorList = ModuleHelper.VendorNames[Type][formatType]

    for Index = 1, #VendorList do
        if VendorName == VendorList[Index] then
            return Index
        end
    end

    return -1

end

function ModuleHelper.getFormatFilter(Type, FormatType)
    local TypeFilter = Type == ModuleHelper.TYPE_INSTRUMENT and
            NI.HOSTING.PluginFilter.SKIP_NOT_SYNTH_PLUGINS or
            NI.HOSTING.PluginFilter.SKIP_NOT_EFFECT_PLUGINS
    return TypeFilter | ModuleHelper.FormatFilters[FormatType]
end

function ModuleHelper.getAmountOfNIPluginsForFormat(Type, FormatType)
    local FormatTypeFilter = ModuleHelper.getFormatFilter(Type, FormatType)
    local VendorFilter = NI.HOSTING.PluginFilter.SKIP_THIRD_PARTY_PLUGINS

    return NI.DATA.PluginHelper.getValidPluginDescriptorsSize(FormatTypeFilter, VendorFilter)
end

function ModuleHelper.getAmountOf3rdPartyPluginsForFormat(Type, FormatType)
    local FormatTypeFilter = ModuleHelper.getFormatFilter(Type, FormatType)
    local ExtVendorNames = NI.DATA.PluginHelper.getVendors(FormatTypeFilter)

    return ExtVendorNames:size()
end
------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.resetCache()

    -- selected module index
    ModuleHelper.CurrentModuleIndex = {}
    ModuleHelper.CurrentModuleIndex[ModuleHelper.TYPE_INSTRUMENT] = {}
    ModuleHelper.CurrentModuleIndex[ModuleHelper.TYPE_EFFECT] = {}

    ModuleHelper.VendorNames = {}
    ModuleHelper.VendorNames[ModuleHelper.TYPE_INSTRUMENT] = {}
    ModuleHelper.VendorNames[ModuleHelper.TYPE_EFFECT] = {}

    for Type = ModuleHelper.TYPE_INSTRUMENT, ModuleHelper.TYPE_EFFECT do
        for _, FormatValue  in pairs(ModuleHelper.getPossiblePluginFormatsForPlatform()) do
            if FormatValue ~= ModuleHelper.INTERNAL then
                local FormatTypeFilter = ModuleHelper.getFormatFilter(Type, FormatValue)

                local AmountOfNIPlugins = ModuleHelper.getAmountOfNIPluginsForFormat(Type, FormatValue)
                local AmountOf3rdPartyPlugins = ModuleHelper.getAmountOf3rdPartyPluginsForFormat(Type, FormatValue)

                if AmountOfNIPlugins > 0 or AmountOf3rdPartyPlugins > 0 then
                    ModuleHelper.CurrentModuleIndex[Type][FormatValue] = {}
                    ModuleHelper.VendorNames[Type][FormatValue] = {}
                end

                if AmountOfNIPlugins > 0 then
                    ModuleHelper.VendorNames[Type][FormatValue][1] = ModuleHelper.VENDOR_NI
                    ModuleHelper.CurrentModuleIndex[Type][FormatValue][ModuleHelper.VENDOR_NI] = 0
                end

                local ExtVendorNames = NI.DATA.PluginHelper.getVendors(FormatTypeFilter)
                for Index = 1, AmountOf3rdPartyPlugins do
                    local VendorName = ExtVendorNames:at(Index - 1)
                    table.insert(ModuleHelper.VendorNames[Type][FormatValue], VendorName)
                    ModuleHelper.CurrentModuleIndex[Type][FormatValue][VendorName] = 0
                end
            else
                ModuleHelper.CurrentModuleIndex[Type][ModuleHelper.INTERNAL] = {}
                ModuleHelper.VendorNames[Type][ModuleHelper.INTERNAL] = {}

                ModuleHelper.VendorNames[Type][ModuleHelper.INTERNAL][1] = ModuleHelper.VENDOR_NI
                ModuleHelper.CurrentModuleIndex[Type][ModuleHelper.INTERNAL][ModuleHelper.VENDOR_NI] = 0
            end
        end
    end

    -- Default selection
    ModuleHelper.setCurrentType(ModuleHelper.TYPE_INSTRUMENT)
end

function ModuleHelper.getPossiblePluginFormatsForPlatform()
    local pluginFormats = NI.DATA.PluginHelper.getValidPluginFormats();

    local luaTypeFormats = {}
    for index = 1, pluginFormats:size() do
        local formatName = pluginFormats:at(index - 1)
        luaTypeFormats[index] = formatName
    end

    return luaTypeFormats
end

function ModuleHelper.getPluginFormatsForCurrentType()
    local pluginFormats = NI.DATA.PluginHelper.getValidPluginFormats();

    local luaTypeFormats = {}
    local displayIndex = 1
    for index = 1, pluginFormats:size() do
        local formatName = pluginFormats:at(index - 1)
        local amountOfNIPlugins = ModuleHelper.getAmountOfNIPluginsForFormat(ModuleHelper.getCurrentType(), formatName)
        local amountOf3rdPartyPlugins = ModuleHelper.getAmountOf3rdPartyPluginsForFormat(ModuleHelper.getCurrentType(), formatName)
        if amountOfNIPlugins > 0 or amountOf3rdPartyPlugins > 0 then
            luaTypeFormats[displayIndex] = formatName
            displayIndex = displayIndex + 1
        end
    end

    return luaTypeFormats
end

------------------------------------------------------------------------------------------------------------------------

function ModuleHelper.canAddPerformanceFX()

    local FocusMixingLayer = NI.DATA.StateHelper.getFocusMixingLayer(App)
    return NI.DATA.StateHelper.canAddPerformanceFX(FocusMixingLayer)

end


------------------------------------------------------------------------------------------------------------------------

ModuleHelper.resetCache()
