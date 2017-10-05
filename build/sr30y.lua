-- This script extracts the 30Y EUR Bond yield rates

local bond_data = redukti.loadcsv { file='../source/eur_sr_30y.csv', conversion='dn' }

for i=1, #bond_data do
	if bond_data[i][1] and bond_data[i][2] and bond_data[i][1] ~= 0 then
		local date = bond_data[i][1]
		-- 39084 = 2007/01/02
		-- 41632 = 2013/12/24
		-- Limit data to above range to ensure consistency across data sets
		if date >= 39084 and date < 41632 then
			io.write(string.format('%d\t%f\n', bond_data[i][1], bond_data[i][2]/100.0))
		end
	end
end