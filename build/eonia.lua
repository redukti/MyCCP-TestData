-- This script exy=tracts the EONI overnight rates
local eonia_data = redukti.loadcsv { file='../source/EONIA-HISTORY.txt', conversion='dn' }

for i=1, #eonia_data do
	if eonia_data[i][1] and eonia_data[i][2] and eonia_data[i][2] ~= 0 then
		local date = eonia_data[i][1]
		-- 39084 = 2007/01/02
		-- 41632 = 2013/12/24
		-- Limit data to above range to ensure consistency across data sets
		if date >= 39084 and date < 41632 then
			io.write(string.format('%d\t%f\n', eonia_data[i][1], eonia_data[i][2]/100.0))
		end
	end
end