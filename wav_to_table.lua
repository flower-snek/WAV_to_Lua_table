----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

--[[
	ALL CREDIT FOR wav.lua GOES TO THE ORIGINAL CREATOR (their name is at the top of that file!)
	HOW TO USE:
	Put this lua and the wav.lua into the same folder as the .wav file you want to convert to a table
	Modify the below variables to your liking
	Run this lua file (I did it in command line with `lua wav_to_table.lua`)
	The output will be a table of tables. Each 1D table will look like the following:
	{timestamp (ms), frequency_1, frequency_2, ... , frequency_[output_count]}
]]--

local wav_file_name = "hold you back.wav" -- the name of the wav file

local output_count = 35 -- the number of frequencies you want per unit of time(i.e. i made this for an audio visualizer: 40 means i would be able to make a visualizer with 40 bars)
						-- currently maxes out at 1024, which should be more than enough, if you need more for some reason go to a line i'll mark with a bunch of !!!!!!!! and change the 1024 to a larger power of two
local trim_before = 0 -- these two variables are for if you want to cut off some bars from the low or high ends of the table
local trim_after  = 0 -- Example: output_count = 50, trim_before = 15, trim_after = 5, there will be 30 values from what would have been value 15 to 45
local samples_per_second = 15 -- the number of samples per second (duh)

local output_file = "output.lua" -- the output of the program. will just be a table.

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

dofile("wav.lua")


-- Read audio file
local reader = wav.create_context(wav_file_name, "r")
--[[
print("Filename: " .. reader.get_filename())
print("Mode: " .. reader.get_mode())
print("File size: " .. reader.get_file_size())
print("Channels: " .. reader.get_channels_number())
print("Sample rate: " .. reader.get_sample_rate())
print("Byte rate: " .. reader.get_byte_rate())
print("Block align: " .. reader.get_block_align())
print("Bitdepth: " .. reader.get_bits_per_sample())
print("Samples per channel: " .. reader.get_samples_per_channel())
print("Sample at 500ms: " .. reader.get_sample_from_ms(500))
print("Milliseconds from 3rd sample: " .. reader.get_ms_from_sample(3))
print(string.format("Min- & maximal amplitude: %d <-> %d", reader.get_min_max_amplitude()))
reader.set_position(256)
print("Sample 256, channel 2: " .. reader.get_samples(1)[2][1])
]]
-- all the above stuff and some of the below stuff is from the base test.lua file that came with the wav.lua, I'm keeping it for documentation's sake

-- get song length:
local song_length_ms = (reader.get_samples_per_channel() / reader.get_sample_rate()) * 1000
print("Song length (ms): " .. song_length_ms)

local ms_spacing = 1000/samples_per_second

local output = io.open(output_file, "w")
io.output(output)
io.write("{")

for ms=0, song_length_ms, ms_spacing do
	io.write(string.format("{%.4f,", ms/1000))
	reader.set_position(math.floor(reader.get_sample_from_ms(math.floor(ms)))) -- double math.floor because thanks wav
	local samples = reader.get_samples(1024)[1] -- !!!!!!!!!!!!!!!!!!!!
	for i=1, samples.n do
		samples[i] = samples[i] / 32768
	end
	local analyzer = wav.create_frequency_analyzer(samples, reader.get_sample_rate())
	local num_frequencies = #analyzer.get_frequencies()
	local splice = num_frequencies / (output_count-1)
	for i, frequency in ipairs(analyzer.get_frequencies()) do
		if i/splice >= trim_before and i/splice <= (output_count-trim_after) and i % splice <= 1 then
			io.write(string.format("%.4f,", frequency.weight))
			--print(string.format("%.2f: %f", frequency.freq, frequency.weight))
		end
	end
	
	io.write("},\n")
	print(string.format("%.2f", 100*ms/song_length_ms).."% done")
end
io.write("}")
io.close(output)

print("Output to " .. output_file)