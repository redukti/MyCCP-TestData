-- This script extracts the EURIBOR 6M rate
local euribor_data = redukti.loadmatrix '../source/EURIBOR.txt'

for i = 2, #euribor_data[1] do
	local date = euribor_data[1][i]
	-- 39084 = 2007/01/02
	-- 41632 = 2013/12/24
	-- Limit data to above range to ensure consistency across data sets
	if date >= 39084 and date < 41632 then
		io.write(string.format('%d\t%f\n', euribor_data[1][i], euribor_data[10][i]/100.0))
	end
end
