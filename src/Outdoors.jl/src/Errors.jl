################## Error codes ##############

export ODError

"""
    @enum ODError begin
        ERR_UNSUPPORTED_FEATURE
        ERR_WINDOW_NOT_CREATED
        ERR_CONTEX_NOT_CREATED
    end

This contain all possible problem that could be emitted by Outdoors, use it them to manage errors in your own personalized way.
"""
@enum ODError begin
    ERR_UNSUPPORTED_FEATURE
    ERR_WINDOW_NOT_CREATED
    ERR_CONTEX_NOT_CREATED
end

## TODO
# writing logs
# Adding more descriptive error in the enumeration 