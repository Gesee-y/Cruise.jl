###########################################################################################################################
###################################################### WRITER #############################################################
###########################################################################################################################

"""
    TextWriter(text::Vector{String}; auto=true, strong_punc_delay=0.2, soft_punc_delay=0.1)

Creates a text writer for displaying text sequentially with typewriter-like effects.
- `text`: Vector of strings to display.
- `auto`: If true, text advances automatically; otherwise, waits for user input.
- `strong_punc_delay`: Delay (in seconds) after strong punctuation (., !, ?).
- `soft_punc_delay`: Delay (in seconds) after soft punctuation (,, ;).
"""
mutable struct TextWriter
	text::Vector{String}
	current_text::String
	current_index::Int
	meta::Dict{Symbol, String}
	auto::Bool

	## Constructors

	TextWriter(text::Vector{String}; auto=true) = new(text, "", 0, Dict{Symbol, String}(:speed => "0.1"), auto)
end

function write_text(writer::TextWriter)
	texts = writer.text
	for i in eachindex(texts)
		writer.current_text = texts[i]
		writer.current_index = i
		write_a_text(writer, i)
		writer.auto || readline()
	end
end

function write_a_text(writer::TextWriter, index::Int)
	strong_punc = ('.', '!', '?')
    soft_punc = (',', ';')
    text = writer.text[index]
    i = 1
    prev_char = ' '
    while i <= length(text)
    	char = text[i]

    	if char == '{' && prev_char != '/'
    		key, val, i = _get_meta(text, i)
    		writer.meta[key] = val
    	else
            print(char)
        end

        process_all_metadata(writer)
        
        sleep_time = 0
        if char in strong_punc
            sleep_time = 0.2
        elseif char in soft_punc
            sleep_time = 0.1
        end

        sleep_time > 0 && precise_sleep(sleep_time)

        prev_char = char
        i += 1
    end
    println()
end

function _get_meta(text::String, i::Int)
	key_idx = findnext(':',text, i)
	key_idx == nothing && error("Metadata not specified.")
    val_idx = findnext('}',text, i)
    val_idx == nothing && error("Metadata not closed")
	
	key = text[i+1:key_idx-1]
	val = text[key_idx+1:val_idx-1]

	return (Symbol(key), String(val), val_idx)
end

function process_all_metadata(writer::TextWriter)
	meta = writer.meta
	for key in keys(meta)
		process_metadata(meta, Val(key), meta[key])
	end
end

process_metadata(meta,::Val{:pause}, v::String) = begin
	precise_sleep(parse(Float64, v))
	delete!(meta, :pause)
end

process_metadata(meta, ::Val{:speed}, v::String) = precise_sleep(parse(Float64, v))

function precise_sleep(val::Real;sec=true)
	factor = sec ? 10 ^ 9 : 1
    t = UInt(val * factor)
    
    t1 = time_ns()
    while true
        if time_ns() - t1 >= t
            break
        end
        yield()
    end
end