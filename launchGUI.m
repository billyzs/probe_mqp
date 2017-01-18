%mvpDriver = MVPDriver(1, 'COM6');
%aptDriver = APTDriver();
%pause(4);
%aptStrainGuage = APTStrainGuage(84813062);
%aptStrainGuage.identify();

%pause(4);

mvpDriver = 1;
aptDriver = 1;
aptStrainGuage = 1;
myModel = MainModel(mvpDriver,aptDriver,aptStrainGuage);

myController = MainController(myModel);
myModel.startPollingTimer();
