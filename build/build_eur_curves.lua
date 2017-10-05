-- This script generates the EONIA and EURIBOR curves 
-- EONIA curve:
-- It uses the data from EONIASWAPS index for maturities from 1W upto 2 years
-- It uses the Eonia ON rates
-- It uses the 30Y EUR Bond yield data and uses it as a proxy to obtain EURIBOR rates for 30Y maturities 
-- It uses the spread between EONIA 3M swap and EURIBOR 3M rate, and EONIA 6M swap and EURIBOR 6M rate to create a 30Y rate for EONIA
-- It applies a fixed set of percentage moves to fill out the tenors between 2 years and 30 years (this is just based on attempt to make curve look okay)
-- EURIBOR
-- For EURIBOR curve the EURIBOR rates upto 12M are used 
-- Then we simply apply pct moves to the rates until the 30Y Bond yield rate
-- If the rates decrease from 1/2 year to 30y then we simply do a linear interpolation of rates

local tab : integer[] = { 1,
    7,
    14,
    21,
    30,
    60,
    91,
    121,
    152,
    182,
    212,
    243,
    273,
    304,
    334,
    365,
    456,
    547,
    638,
    730,
    1095,
    1460,
    1825,
    2190,
    2555,
    2920,
    3285,
    3650,
    4380,
    5475,
    7300,
    9125,
    10950
  }

-- Following percentage moves are based on fraction of the difference between the
-- 2 year rate and the 30 year rate for each tenor in between
-- The non-linear moves are just designed to make the curve look 'nice'
local pct_moves : number[] = {
0.089851941222222,
0.19191704855315,
0.28726241504853,
0.37814675859122,
0.46575758514396,
0.5473320234162,
0.62396689177219,
0.69478029163246,
0.81408987255701,
0.9483295471217,
1.0436398796432,
1.0400498668641,
1.0
}

-- Following percentage moves are based on fraction of the difference between the
-- 1 year rate and the 30 year rate for each tenor in between
-- The non-linear moves are just designed to make the curve look 'nice'
local pct_moves2: number[] = {
0.01322,
0.02635142328016,
0.05678444,
0.11536520114586,
0.19332000447112,
0.2920324631361,
0.37913596828283,
0.46241606826977,
0.5424467288982,
0.61620841661843,
0.68416426307676,
0.74566471093178,
0.8525152575391,
0.97000531277664,
1.0454710651324,
1.0394118884246,
1.0
}

-- Do linear interpolation 
local function lininterp(firstx: number, lastx: number, firsty: number, lasty: number, x: number)
    assert(x >= firstx and x <= lastx, 'x is not in range')
    local slope: number = (lasty - firsty) / (lastx - firstx)
    return firsty + slope * (x - firstx)
end

-- Compute a spread between two rates
local function get_spread(file1, file2) 
	local eonia3m_data = redukti.loadcsv { file = file1, conversion = 'in' }
	local euribor3m_data = redukti.loadcsv { file = file2, conversion = 'in' }

	local data1 : number[] = table.numarray(43000, 0.0)
	local data2 : number[] = table.numarray(43000, 0.0)
	local spread : number[] = table.numarray(43000, 0.0)

	for i = 1, #eonia3m_data do
		data1[@integer (eonia3m_data[i][1])] = @number(eonia3m_data[i][2])
	end

	for i = 1, #euribor3m_data do
		data2[@integer (euribor3m_data[i][1])] = @number(euribor3m_data[i][2])
	end

	for i = 1, #data1 do
		if data1[i] ~= 0.0 and data2[i] ~= 0.0 then
			local s: number = data1[i] - data2[i]
			spread[i] = s
		end
	end
	return spread
end

-- This function derives the 30Y EONIA SWAP rate by applying a spread on the EUR 30Y bond rate
local function get_30y_rate(spread3m: number[], spread6m: number[], boundary: integer)
	-- Load the Bond yields
	local sr30y = redukti.loadcsv { file = 'sr30y.txt', conversion = 'in' }
	local data1 : number[] = table.numarray(43000, 0.0)
	local rate : number[] = table.numarray(43000, 0.0)

	for i = 1, #sr30y do
		data1[@integer (sr30y[i][1])] = @number(sr30y[i][2])
	end

	for i = 1, #data1 do
		if data1[i] ~= 0.0  then
			if i <= boundary and spread3m[i] ~= 0.0 then
				rate[i] = data1[i] + spread3m[i]
			elseif i > boundary and spread6m[i] ~= 0.0 then
				rate[i] = data1[i] + spread6m[i]
			else
				local s3 = spread3m[i]
				local s6 = spread6m[i]
				local br = data1[i]
				print('Missing rate for ' .. i)
			end
		end
	end	

	return rate
end

-- This function gets the EONIA overnight rates
local function get_eonia()	
	local eonia = redukti.loadcsv { file = 'eonia.txt', conversion = 'in' }
	local data1 : number[] = table.numarray(43000, 0.0)

	for i = 1, #eonia do
		data1[@integer (eonia[i][1])] = @number(eonia[i][2])
	end

	return data1
end

-- Creates a lookup from date to table column
local function build_date_index(t: table) 
	local index: integer[] = table.intarray(43000, 0)
	-- local index = {}
	for i=2, #t[1] do
		index[@integer( t[1][i]//1 )] = i
	end
	return index
end

local function build_curves(curve_type)
	assert(curve_type == 'eonia' or curve_type =='euribor', 'Only euribor or eonia curves can be generated')

	-- Below we are getting the spread between EONIASWAP 6M and EURIBOR 6M
	-- Since EONIASWP 6M is lower then the spread is usually going to be
	-- negative
	local spread6m: number[] = get_spread('eonia6m.txt', 'euribor6m.txt')
	-- Same as above except this is for 3M
	local spread3m: number[] = get_spread('eonia3m.txt', 'euribor3m.txt')
	-- EURIBOR.txt has raw data for EURIBOR
	local euribor_data = redukti.loadmatrix '../source/EURIBOR.txt'
	-- Create a lookup table to help us quickly locate data in EURIBOR
	-- given a date
	local euribor_index = build_date_index(euribor_data)

	local rate_30y: number[] = get_30y_rate(spread3m, spread6m, 39000)
	local eonia: number[] = get_eonia() -- overnight rates
	-- EONIASWAP.txt has raw data for EONIASWAP index
	local eoniaswap = redukti.loadmatrix '../source/EONIASWAP.txt'

	local curves = {}
	local dates = {}
	local n: integer = 0
	for i = 2, #eoniaswap[1] do
		local date: integer = @integer( eoniaswap[1][i] )
        -- index is column in euribor data of same date 
		local index = curve_type == 'eonia' and 1 or euribor_index[date] 
		if index and eonia[date] ~= 0.0 and rate_30y[date] ~= 0.0 then
			n = n + 1
			-- Negate the spread as we want to go from Eonia to euribor
			local spread: number
			local spread2: number
			if curve_type == 'euribor' then
				spread = -spread3m[date]
				spread2 = -spread6m[date]
			end
			local tenors: integer = 33
			local rates: number[] = table.numarray(tenors, 0.0)
			--local tenor: integer
			-- Compute upto 12m
			-- The ON rate is simply the EONIA rate
			rates[1] = eonia[date]
			local idx: integer = 2
			-- The EURIBOR data is only upto 1 year
			assert(tab[16] == 365)
			for j = 2, 16 do 
				if curve_type == 'euribor' then
					rates[idx] = euribor_data[j][i]/100.0 
				else
					rates[idx] = eoniaswap[j][i]/100.0 
				end
				idx = idx + 1
			end
			-- We will need to interpolate between 1y and 30y for EURIBOR
			-- And between 2y and 30y for EONIA
            local moves : number[] = pct_moves2
            if curve_type == 'eonia' then
                moves = pct_moves
				-- EURIBOR does not have data between 1y and 2y
				-- So we interpolate
    			for j = 17, 20 do 
				    rates[idx] = eoniaswap[j][i]/100.0 
				    idx = idx + 1
			    end       
            end
			-- From >2y to 30y is all interpolation
			local twoy_tenor = idx - 1
			local thirty_rate: number = rate_30y[date] + spread2			
			if thirty_rate <= rates[twoy_tenor] then
				-- make it flat for now
				--for k = twoy_tenor+1, tenors do
				--	rates[idx] = thirty_rate
				--	idx = idx + 1
				--end
				-- Linearly interpolate down
				local firstx: number = @number( tab[twoy_tenor] )
				local lastx: number = @number( tab[tenors] )
				local firsty = rates[twoy_tenor]
				local lasty = thirty_rate 
				for k = twoy_tenor+1, tenors do
					local x: number = @number( tab[k] )
					rates[idx] = lininterp(firstx, lastx, firsty, lasty, x)
					idx = idx + 1
				end
			else 
				local diff = thirty_rate - rates[twoy_tenor]
				-- print('diff ' .. diff)
				for k = twoy_tenor+1, tenors do
					--print('move ' .. pct_moves[k-20] * diff)
					rates[idx] = rates[twoy_tenor] + moves[k-twoy_tenor] * diff;
					idx = idx + 1
				end
			end
			table.insert(dates, date)
			curves[date] = rates
		end	
	end

	io.write('0')
	for i = 1, #dates do
		io.write(string.format('\t%d', dates[i]))
	end
	io.write('\n')

	local start_tenor : integer = 0
	local tenors : integer = 33
	for j = 1, tenors do
		io.write(string.format('%d', tab[start_tenor+j]))
		for i = 1, #dates do
			local rates: number[] = @number[] ( curves[dates[i]] )
			io.write(string.format('\t%f', rates[j]))
		end
		io.write('\n')
	end
end

local curve_type = 'euribor'
if arg[1] then
	curve_type = arg[1]
end

--print(arg[1])
--print(curve_type)
build_curves(curve_type)
