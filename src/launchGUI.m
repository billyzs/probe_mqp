function launchGUI()
    clear
    CleanUpMemory()
    addpath('src')
    imaqreset;
    mvpDriver = MVPDriver(1, 'COM4');

    aptDriver = APTDriver();
    pause(4);
    %mvpDriver.enable();
    aptStrainGuage = APTStrainGuage(84813062);
    aptStrainGuage.identify();
    newportDriver = NewportDriver(3);
    newportDriver.enable();

    probe = ForceProbe();
    % 
    pause(4);
    % 
%      mvpDriver = 1;
%      aptDriver = 1;
%      aptStrainGuage = 1;
%      newportDriver = 1;
%      probe = 1;
    myModel = MainModel(mvpDriver,aptDriver,aptStrainGuage, newportDriver, probe);

    myController = MainController(myModel);
end