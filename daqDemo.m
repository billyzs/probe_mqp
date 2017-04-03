% aptDriver = APTDriver();
% aptDriver.enable();
% aptDriver.setMoveMode('Absolute');
mydaq = daq.createSession('ni');
ch = mydaq.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
ch.Range = [-2.5, 2.5];
%mydaq.addlistener('DataAvailable',@plotData); 
% mydaq.addlistener('DataAvailable', @(src,event) plot(event.TimeStamps, event.Data));

%Proper way to run test of 1000 samples / 1 sec
sequence_count = 1;
rate = 1000; % hz
duration = 30; % seconds
mydaq.Rate = rate;
mydaq.DurationInSeconds = duration;
numMovements = 1;
data = zeros(duration * rate * numMovements, 1);
time = zeros(duration * rate * numMovements, 1);
numSamples = 0;
displacement = 1;
prevTime = 0;
% mydaq.NotifyWhenDataAvailableExceeds = 100;
% mydaq.IsContinuous = true;
 figure;
 xlabel('time (seconds)');
 ylabel('Voltage (V)');
 title('Voltage from a FS-1000 LAT Probe')
% mydaq.startBackground;

for count = 1:numMovements;
    % stationary:
    [data1,time1] = mydaq.startForeground;
    data(numSamples+1:numSamples+size(data1,1)) = data1;
    time(numSamples+1:numSamples+size(data1,1)) = time1 + prevTime;
    prevTime = prevTime + time1(end);
    numSamples = numSamples + size(data1,1);
    % up & down:
%     aptDriver.move(displacement);
    displacement = displacement + 1;
    filename = sprintf('intermediate%i.mat', count);
    save(filename, 'data1', 'time1', 'displacement');
end
hold on;
scatter(time, data, '.'); 
% save('prolongedCollection.mat', 'data', 'time');
% [data1,time1] = mydaq.startForeground;
% 
% aptDriver.move(10);
% 
% [data2,time2] = mydaq.startForeground;
% 
% time2 = time1(end) + time2;
% 
% aptDriver.move(-10);
% 
% [data3,time3] = mydaq.startForeground;
% 
% time3 = time2(end) + time3;
% 
% aptDriver.move(10);
% 
% [data4,time4] = mydaq.startForeground;
% 
% time4 = time3(end) + time4;
% 
% aptDriver.move(-10);
% 
% [data5,time5] = mydaq.startForeground;
% 
% time5 = time4(end) + time5;
% 
% figure;
% hold on
% scatter(time1,data1, '.r');
% hold on
% scatter(time2,data2, '.g');
% hold on
% scatter(time3,data3, '.b');
% hold on
% scatter(time4,data4, '.y');
% hold on
% scatter(time5,data5, '.m');
% xlabel('time (seconds)');
% ylabel('Voltage (V)');
% %ylim([2.4 2.435]);
% title('Free-load voltage collected from a FS-1000 LAT Probe')


% 
data_average =[];
count = 0;
sum = 0;
data_size = size(data);
for i = 1:data_size(1);
    count = count + 1;
    sum = sum + data(i);
    if (count == 100)
        
        data_average = [data_average; sum / count];
        count = 0;
        sum = 0;
        
    end
    
end

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
% 
% scatter(result(:,1), result(:,2), '.');

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
%% SECTION FOR CONTINUOUS MODE
mydaq = daq.createSession('ni');
ch = mydaq.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
%chFn = mydaq.addAnalogInputChannel('Dev5', 'ai0', 'Voltage');
%chFn.range = [-10, 10];
voltageRange = [-2.5,2.5];
graphRange = [0, 2.5];
ch.Range = voltageRange;
mydaq.addlistener('DataAvailable',@(src, event)plotData(src,event,graphRange)); 
%mydaq.addlistener('DataAvailable', @(src,event) plot(event.TimeStamps, event.Data); ylim([-10,10]));

%Proper way to run test of 1000 samples / 1 sec
sequence_count = 1;
rate = 1000; % hz
duration = 60; % seconds
mydaq.Rate = rate;
mydaq.DurationInSeconds = duration;
mydaq.NotifyWhenDataAvailableExceeds = 100;
mydaq.IsContinuous = true;
figure;
xlabel('time (seconds)');
ylabel('Voltage (V)');
title('Voltage from a FS-1000 LAT Probe')
mydaq.startBackground

%% 
% nboot = 1000;
% [xpdf, n, b] = compute_xpdf(data);
% [dip, p_value, xlow, xup] = HartigansDipSignifTest(xpdf, nboot); 
% figure;
% bar(b)
% title(sprintf('Probability of unimodal %.2f', p_value))
% 
% print -dpng modality.png