%mvpDriver = MVPDriver(1, 'COM6');

%myModel = MainModel(mvpDriver);

%myController = MainController(myModel);


sg = APTStrainGuage(84813062);
sg.identify();
sg.getPosition()