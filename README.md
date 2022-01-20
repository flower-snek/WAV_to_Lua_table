# WAV_to_Lua_table
 Converts a WAV file to a Lua table of frequencies using the LuaWAV library

# HOW TO USE:
 1. Put your wav file into the same directory as these lua files
 2. Open `wav_to_table.lua` in a text editor of your choice
 3. Change the variables to your liking (including input file name, output file name, table size, etc.)
 4. Run `wav_to_table.lua`. It should output a table with the chosen file name.
 
 The output will be a 2D table, with each row looking like the following:
 ```
 {timestamp (seconds), frequency_1, frequency_2, ... ,},
 ```
