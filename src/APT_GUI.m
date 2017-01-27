clear; close all; clc;
global h; % make h a global variable so it can be used outside the main
          % function. Useful when you do event handling and sequential           move
%% Create Matlab Figure Container
fpos    = get(0,'DefaultFigurePosition'); % figure default position
fpos(3) = 650; % figure window size;Width
fpos(4) = 840; % Height
 
f = figure('Position', fpos,...
           'Menu','None',...
           'Name','APT GUI');
%% Create ActiveX Controller

%%APTPZMOTOR.APTPZMototCtrl.1
%% or
%%MGPIEZO.MGPiezoCtrl.1 I think this one works better
%hPiezo = actxcontrol('MGPIEZO.MGPiezoCtrl.1',[20 420 600 400 ], f);
hStrain = actxcontrol('MGPIEZO.MGPiezoCtrl.1',[20 20 600 400 ], f);

%% Initialize
% Start Control
%hPiezo.StartCtrl;

hStrain.StartCtrl;
% Set the Serial Number
%SNPiezo = 81813026; % put in the serial number of the hardware
%set(hPiezo,'HWSerialNum', SNPiezo);

%SNStrain = 84813062; % put in the serial number of the hardware
%set(hStrain,'HWSerialNum', SNStrain);

%hPiezo.methods('-full');
pause(6);
% Indentify the device
%hPiezo.Identify;
%hStrain.Identify;
pause(5); % waiting for the GUI to load up;
%'setting position'
%hPiezo.SetPosOutput(1,5);
%% Controlling the Hardware
%h.MoveHome(0,0); % Home the stage. First 0 is the channel ID (channel 1)
                 % second 0 is to move immediately
%h.setPosOutput(
return                 
%% Event Handling
h.registerevent({'MoveComplete' 'MoveCompleteHandler'});
 
%% Sending Moving Commands
timeout = 10; % timeout for waiting the move to be completed
%h.MoveJog(0,1); % Jog
 
% Move a absolute distance
h.SetAbsMovePos(0,7);
h.MoveAbsolute(0,1==0);
 
t1 = clock; % current time
while(etime(clock,t1)<timeout) 
% wait while the motor is active; timeout to avoid dead loop
    s = h.GetStatusBits_Bits(0);
    if (IsMoving(s) == 0)
      pause(2); % pause 2 seconds;
      h.MoveHome(0,0);
      disp('Home Started!');
      break;
    end
end


