mvpDriver = MVPDriver(1, 'COM6');

myModel = MainModel(mvpDriver);

myController = MainController(myModel);
