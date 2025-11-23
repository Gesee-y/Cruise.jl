struct Node{T} end

Cruise.update!(n::CRPluginNode{<:Node}) = nothing
flip_coin() = rand() > 0.5