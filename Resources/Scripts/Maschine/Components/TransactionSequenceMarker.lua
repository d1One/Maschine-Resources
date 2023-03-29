------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TransactionSequenceMarker = class( 'TransactionSequenceMarker' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function TransactionSequenceMarker:__init()

    self:reset()

end

------------------------------------------------------------------------------------------------------------------------
-- reset / set
------------------------------------------------------------------------------------------------------------------------

function TransactionSequenceMarker:reset()

    self.TransactionSequenceChanged = false

end

------------------------------------------------------------------------------------------------------------------------

function TransactionSequenceMarker:set()

    if not self.TransactionSequenceChanged then
        App:getTransactionManager():finishTransactionSequence()
        self.TransactionSequenceChanged = true
    end

end

------------------------------------------------------------------------------------------------------------------------
