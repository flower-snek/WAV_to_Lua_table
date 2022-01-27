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

local output_count = 200 -- the number of frequencies you want per unit of time (i.e. i made this for an audio visualizer: 40 means i would be able to make a visualizer with 40 bars)
local trim_before = 100 -- these two variables are for if you want to cut off some bars from the low or high ends of the table
local trim_after  = 10 -- Example: output_count = 50, trim_before = 15, trim_after = 5, there will be 30 values from what would have been value 15 to 45
local samples_per_second = 20 -- the number of samples per second (duh)

local bias = 1.1 -- this value changes how logarithmic the scale is. between 1.05 and 1.2 is probably ideal, but you start getting repeated samples at values greater than 1.15-ish. 1 is linear.

local output_file = "output.lua" -- the output of the program. will just be a table.

local omit_repeats = true -- this will get rid of repeated values. however, it'll make it so that the number of outputs is not what you put in above. also it'll make trimming weird.

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

function map(input, i1, i2, o1, o2)
	slope = (o2 - o1) / (i2 - i1)
	return o1 + slope * (input - i1)
end

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

for ms=0, song_length_ms - ms_spacing, ms_spacing do
	if math.floor(ms) < reader.get_samples_per_channel() then
		io.write(string.format("{%.4f,", ms/1000))
		reader.set_position(math.floor(reader.get_sample_from_ms(math.floor(ms)))) -- double math.floor because thanks wav
		local samples = reader.get_samples(16384)[1] -- if you're using a low bias value (1.1 or less) feel free to lower this number to like 1024 to make things faster
		for i=1, samples.n do
			samples[i] = samples[i] / 32768
		end
		local analyzer = wav.create_frequency_analyzer(samples, reader.get_sample_rate())
		local frequencies = analyzer.get_frequencies()
		local num_frequencies = #frequencies
		for i=trim_before + 1, output_count - trim_after do
			-- map this value from 0, output_count to 0, num_frequencies
			local freqnum = math.floor(map(bias^i, 1, bias^output_count, 1, num_frequencies+1))
			if ((omit_repeats and freqnum ~= math.floor(map(bias^(i+1), 1, bias^output_count, 1, num_frequencies+1))) or not omit_repeats) and frequencies[freqnum] then
				--print(i .. ' ' .. freqnum .. ' ' .. frequencies[freqnum].freq)
				io.write(string.format("%.4f,", (frequencies[freqnum].weight)))
			end
		end
		--[[
		local splice = math.log(num_frequencies) / (output_count-1)
		for i, frequency in ipairs(analyzer.get_frequencies()) do
			if i/splice >= trim_before and i/splice <= (output_count-trim_after) and i % splice <= 1 then
				io.write(string.format("%.4f,", frequency.weight))
				--print(string.format("%.2f: %f", frequency.freq, frequency.weight))
			end
		end
		]]
		io.write("},\n")
		print(string.format("%.2f", 100*ms/song_length_ms).."% done")
	end
end
io.write("}")
io.close(output)

print("Output to " .. output_file)