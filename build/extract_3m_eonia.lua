-- This script extracts the 3M EONIASWAP rate
local eonia_data = redukti.loadmatrix '../source/EONIASWAP.txt' 

for i=2, #eonia_data[1] do
	local date = eonia_data[1][i]
	-- 39084 = 2007/01/02
	-- 41632 = 2013/12/24
	-- Limit data to above range to ensure consistency across data sets
	if date >= 39084 and date < 41632 then
		io.write(string.format('%d\t%f\n', eonia_data[1][i], eonia_data[5][i]/100.0))
	end
end
