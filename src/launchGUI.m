
clear
% CleanUpMemory()
addpath('src')
imaqreset;
mvpDriver = MVPDriver(1, 'COM4');

aptDriver = APTDriver();
pause(4);
%mvpDriver.enable();
% aptStrainGuage = APTStrainGuage(84813062);
% aptStrainGuage.identify();
% Enable and disable the newport and force probe early to prevent hangs in
% code during runtime.
newportDriver = NewportDriver(3);
newportDriver.enable();
newportDriver.disable();

probe = ForceProbe();
probe.connect();
probe.disconnect();

% 

%      mvpDriver = 1;
%       aptDriver = 1;
       aptStrainGuage = 1;
%       newportDriver = 1;
%       probe = 1;
myModel = MainModel(mvpDriver,aptDriver,aptStrainGuage, newportDriver, probe);
myView = MainView(myModel);
