clc; clear all; close all; 
piezoController = actxcontrol('MGPIEZO.MGPiezoCtrl.1', [50,50,500,500]);
 % piezoController.methods('-full');
 % piezoController.SetHWSerialNum(81813026);
set(piezoController, 'HWSerialNum', 81813026);
piezoController.StartCtrl();
% piezoController.SetPosOutput(0, 10.0); 
piezoController.StopCtrl();