% ptori_GAB_FXC_a

% TaskObject#1 is FXC(0,0,25,5,[200 200 200])   : standard light grey fixation cross
% TaskObject#2 is FXC(0,0,20,4,[250 0 250])     : smaller fixation cross,  variable coour
% TaskObject#3 is GAB(320,135,1,1,ori)          : gabor array, fixed radius & angle; variable position & level
% TaskObject#4 is FXC(0,0,25,5,[255 255 255])   : standard white fixation cross

 toggleobject(1);       %  1
idle(600)               % 36

 toggleobject([1 4]);   %  1
idle(600)               % 36

 toggleobject([1 4]);   %  1
idle(600)               % 36

 toggleobject([1 4]);   %  1
idle(600)               % 36

 toggleobject([2 3 4]); %  1
idle(1200)              % 72

% showcursor(1)

 toggleobject([2 3]);   %  1

% toggleobject(2);
% idle(500)
% toggleobject([1 2]);    % ON
% idle(1000)
% toggleobject(1);    % OFF
% idle(250)
% toggleobject(1);    % ON
% idle(250)
% toggleobject(1);    % OFF
% idle(250)
% toggleobject([1 3]);    % ON
% eyejoytrack('idle',600)

