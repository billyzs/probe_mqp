mydaq = daq.createSession('ni');
mydaq.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
t = 0;
tic;
result = zeros(1000, 2);
while t < 1000
    ai1_out = mydaq.inputSingleScan;
    t = t + 1;
    result(t,:) = [toc, ai1_out];
end

figure;
scatter(result(:,1), result(:,2), '.');
xlabel('time (seconds)');
ylabel('Voltage (V)');
title('Free-load voltage collected from a FS-1000 LAT Probe')