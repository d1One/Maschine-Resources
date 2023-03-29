------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnapshotsHelper = class( 'SnapshotsHelper' )

------------------------------------------------------------------------------------------------------------------------

function SnapshotsHelper.setPrevNextSnapshotBank(Next)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then

        local SnapshotsManager = Song:getParameterSnapshotsManager()
        local BankIndex = NI.DATA.ParameterSnapshotsAccess.getFocusSnapshotBankIndex(App)
        local NumBanks = SnapshotsManager:getNumSnapshotBanksParameter():getValue()

        if BankIndex == NumBanks - 1 and Next and NumBanks < 4 then
            NI.DATA.ParameterSnapshotsAccess.addSnapshotBank(App)
        else
            -- select next or previous bank
            BankIndex = BankIndex + (Next and 1 or -1)

            if BankIndex >= 0 and BankIndex < NumBanks then
                NI.DATA.ParameterAccess.setSizeTParameter(
                    App, SnapshotsManager:getFocusSnapshotBankIndexParameter(), BankIndex)
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsHelper.isLockActive()

    return NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW(App)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsHelper.toggleLock()

    NI.DATA.ParameterSnapshotsAccess.setSnapshotActiveHW(App, not SnapshotsHelper.isLockActive())

end

------------------------------------------------------------------------------------------------------------------------
