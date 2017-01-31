mydaq = daq.createSession('ni');
mydaq.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');

while 1
    ai1_out = mydaq.inputSingleScan
end