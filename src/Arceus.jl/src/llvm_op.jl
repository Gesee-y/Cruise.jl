######################################################## LLVM Operations ########################################################

"""
    has_bmi2()

Returns true if the the BMI bit manipulation set 2 is supported by the CPU
"""
function has_bmi2()
    CPUInfo = zeros(Int32, 4)
    ccall(:jl_cpuidex, Cvoid, (Ptr{Cint}, Cint, Cint), CPUInfo, 7, 0)
    CPUInfo[2] & 0x100 != 0
end

"""
    fallback_pext(query::UInt64, mask::UInt64)::UInt64

A fallback to use pext the CPU that doesn't support it
"""
function fallback_pext(q::UInt64, mask::UInt64)::UInt64
    result = 0
    pos = 0
    while mask != 0
        tz = trailing_zeros(mask)
        result |= ((q >> tz) & 1) << pos
        mask &= mask - 1 # Clear lowest set bit
        pos += 1
    end
    return result
end


pdep(x::UInt32, y::UInt32) = ccall("llvm.x86.bmi.pdep.32", llvmcall, UInt32, (UInt32, UInt32), x, y)
pdep(x::UInt64, y::UInt64) = ccall("llvm.x86.bmi.pdep.64", llvmcall, UInt64, (UInt64, UInt64), x, y)

pext(x::UInt32, y::UInt32) = ccall("llvm.x86.bmi.pext.32", llvmcall, UInt32, (UInt32, UInt32), x, y)
pext(x::UInt64, y::UInt64) = ccall("llvm.x86.bmi.pext.64", llvmcall, UInt64, (UInt64, UInt64), x, y)

ctpop(x::UInt64) = ccall("llvm.x86.bmi.ctpop.i64", llvmcall, UInt64, (UInt64,), x)

const PEXT_AVAILABLE = has_bmi2()
const PEXT_FUNC = PEXT_AVAILABLE ? pext : fallback_pext