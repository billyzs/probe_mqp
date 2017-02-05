mydaq = daq.createSession('ni');
mydaq.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');

%Proper way to run test of 1000 samples / 1 sec
mydaq.Rate = 1000;
mydaq.DurationInSeconds = 1;
[data,time] = mydaq.startForeground;

figure;
scatter(time, data, '.');
xlabel('time (seconds)');
ylabel('Voltage (V)');
title('Free-load voltage collected from a FS-1000 LAT Probe')
release(mydaq);
% t = 0;
% tic;
% sampleCount = 1000;
% period = .01;
% t = timer('Period', period, 'TasksToExecute', sampleCount,...
%             'TimerFcn',{@sampleCallback, mydaq},...
%             'ExecutionMode', 'fixedRate', 'StopFcn', {@sampleDoneCallback, mydaq, sampleCount, period},...
%             'UserData', zeros(sampleCount, 2));
% start(t)
% while t < 5000
%     ai1_out = mydaq.inputSingleScan;
%     t = t + 1;
%     result(t,:) = [toc, ai1_out];
% end



% mydaq.addDigitalChannel('Dev5', 'Port1/Line0', 'OutputOnly')
% t = timer('Period', 1, 'TasksToExecute', Inf,...
%             'TimerFcn',{@modulationCallback, mydaq},...
%             'ExecutionMode', 'fixedRate');
% isvalid(t)
% start(t);
% %How to control digital output
% %mydaq.addDigitalChannel('Dev5', 'Port1/Line0', 'OutputOnly')
% %mydaq.outputSingleScan([1]) %5V
% %mydaq.outputSingleScan([0]) %0V