clc; clear all; close all; 
fpos    = get(0,'DefaultFigurePosition'); % figure default position
fpos(3) = 650; % figure window size;Width
fpos(4) = 840; % Height
 
f = figure('Position', fpos,...
           'Menu','None',...
           'Name','APT GUI');
piezoController = actxcontrol('MGPIEZO.MGPiezoCtrl.1', [20 420 600 400 ], f);
 % piezoController.methods('-full');
 % piezoController.SetHWSerialNum(81813026);
set(piezoController, 'HWSerialNum', 81813026);
piezoController.StartCtrl();
piezoController.SetControlMode(0, 1)% 0 = channelID, 1 = Open loop
% piezoController.SetPosOutput(0, 10.0);