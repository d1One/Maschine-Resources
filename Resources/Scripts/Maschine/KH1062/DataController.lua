require "Scripts/Maschine/KH1062/ArrangerController"
require "Scripts/Maschine/KH1062/IdeaSpaceController"
require "Scripts/Maschine/KH1062/ParameterCacheController"

require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/Helper/PatternHelper"

local ChainAccessHelper = require("Scripts/Shared/KH1062/ChainAccessHelper")
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/MikroMK3ASeries/QuickEditMikroMK3ASeries"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DataController = class( 'DataController' )

function DataController:__init(DataModel)

    self.ArrangerController = ArrangerController()
    self.IdeaSpaceController = IdeaSpaceController()
    self.ChainController = ChainAccessHelper.createChainController(ChainAccessHelper.getFocusSoundSlots)
    self.ParameterCacheController = ParameterCacheController(DataModel.ParameterCacheModel)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:setFocusGroup(OneBasedGroupIndex)

    MaschineHelper.setFocusGroup(OneBasedGroupIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:selectPrevNextSound(SoundIndexDelta)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.GroupAccess.shiftSoundFocus(App, Group, SoundIndexDelta, false, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:createGroup()

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    NI.DATA.SongAccess.createGroup(App, FocusSong, false)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:onQuantize()

    local FiftyPercent = false
    if MaschineHelper.isDrumkitMode() then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, FiftyPercent)
    else
        NI.DATA.EventPatternTools.quantizeNoteEventsInFocusedSound(App, FiftyPercent)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:undo()

    local TransactionManager = App:getTransactionManager()
    if TransactionManager:canUndoMarker() then
        TransactionManager:undoTransactionMarker()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:redo()

    local TransactionManager = App:getTransactionManager()
    if TransactionManager:canRedoMarker() then
        TransactionManager:redoTransactionMarker()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:onToggleRecordAuto()

    NI.DATA.WORKSPACE.toggleAutoWriteEnabledKompleteKontrol(App)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:setFocusGroupDrumKitModeEnabled(Enabled)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Group:getMidiInputKitMode(),
            Enabled and NI.DATA.KitMode.DRUMKIT or NI.DATA.KitMode.OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:setSoundFocus()

    MaschineHelper.setSoundFocus()

end

------------------------------------------------------------------------------------------------------------------------

function DataController:toggleFocusSoundMuteState(SoundIndex)

    MuteSoloHelper.toggleSoundMuteState(SoundIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:toggleFocusSoundSoloState(SoundIndex)

    MuteSoloHelper.toggleSoundSoloState(SoundIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:toggleFocusGroupMuteState()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local FocusGroup = NI.DATA.StateHelper.getFocusGroupIndex(App)
    if FocusGroup ~= NPOS then
        MuteSoloHelper.toggleMuteState(Groups, FocusGroup + 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:toggleFocusGroupSoloState()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song and Group then
        NI.DATA.SongAccess.setMuteExclusive(App, Song, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DataController:setFocusedParameterOwner(ParameterOwnerId)

    self.ParameterCacheController:setFocusedParameterOwner(ParameterOwnerId)

end

------------------------------------------------------------------------------------------------------------------------

function DataController:incrementFocusPage()

    self.ParameterCacheController:incrementFocusPage()

end

------------------------------------------------------------------------------------------------------------------------

function DataController:decrementFocusPage()

    self.ParameterCacheController:decrementFocusPage()

end

------------------------------------------------------------------------------------------------------------------------

function DataController:incrementSongTempo(Delta, IsFineIncrement)

    QuickEditMikroMK3ASeries.incrementSongTempo(Delta, IsFineIncrement)

end
