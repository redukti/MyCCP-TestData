local fxratesdata = redukti.loadcsv { file='../source/eurofxref-hist.csv', heading=true, conversion='d-------n----------------------------------' }

for i = 2,#fxratesdata do
    io.write(fxratesdata[i][1])
    io.write('\t')
    io.write(fxratesdata[i][9])
    io.write('\n')    
end
