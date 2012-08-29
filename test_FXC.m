function test_FXC

% Use to test/modify module FXC for PsychToolBox, fixation cross


% Open a fullscreen, onscreen window with gray background. Enable 32bpc
% floating point framebuffer via imaging pipeline on it, if this is possible
% on your hardware while alpha-blending is enabled. Otherwise use a 16bpc
% precision framebuffer together with alpha-blending. We need alpha-blending
% here to implement the nice superposition of overlapping gabors. The demo will
% abort if your graphics hardware is not capable of any of this.
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

% [win winRect] = PsychImaging('OpenWindow', screenid, 128);      %SDS: 128 is the background colour
% [win winRect] = PsychImaging('OpenWindow', 1, [0 0 0]);      
[win winRect] = PsychImaging('OpenWindow', 1, [128 128 128]);     

% Query frame duration: We use it later on to time 'Flips' properly for an animation with constant framerate:
ifi = Screen('GetFlipInterval', win);


% PseudoTrialObject.Class = 'Psytbx';
PseudoTrialObject(1).Class = []; %             % TrialObject.Class is not defined for device FXC
PseudoTrialObject(1).Radius = 0;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(1).Angle = 0;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(1).FP1 = 25;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(1).FP2 = 5;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(1).Color = [222 222 222];        % Fixtn cross colour : triplet (0 to 255) 

PseudoTrialObject(2).Class =[];                  % TrialObject.Class is not defined for device FXC
PseudoTrialObject(2).Radius = 10;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(2).Angle = 0;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(2).FP1 = 25;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(2).FP2 = 5;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(2).Color = [0 222 222];        % Fixtn cross colour : triplet (0 to 255) 

PseudoTrialObject(3).Class =[];                   % TrialObject.Class is not defined for device FXC
PseudoTrialObject(3).Radius = 20;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(3).Angle = 72;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(3).FP1 = 25;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(3).FP2 = 5;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(3).Color = [222 222 0];        % Fixtn cross colour : triplet (0 to 255) 

PseudoTrialObject(4).Class =[];                   % TrialObject.Class is not defined for device FXC
PseudoTrialObject(4).Radius = 30;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(4).Angle = 144;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(4).FP1 = 30;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(4).FP2 = 6;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(4).Color = [222 0 222];        % Fixtn cross colour : triplet (0 to 255) 

PseudoTrialObject(5).Class =[];                   % TrialObject.Class is not defined for device FXC
PseudoTrialObject(5).Radius = 40;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(5).Angle = 216;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(5).FP1 = 40;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(5).FP2 = 4;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(5).Color = [0 0 222];        % Fixtn cross colour : triplet (0 to 255) 

PseudoTrialObject(6).Class =[];                   % TrialObject.Class is not defined for device FXC
PseudoTrialObject(6).Radius = 50;                 % Fixtn cross  position : radius : % of half height
PseudoTrialObject(6).Angle = 288;                 % Fixtn cross  position : angle : degrees clockwise from 12  
PseudoTrialObject(6).FP1 = 20;                % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
PseudoTrialObject(6).FP2 = 2;                % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
PseudoTrialObject(6).Color = [222 0 0];        % Fixtn cross colour : triplet (0 to 255) 

% PboxProgName = 'PGR';
% PboxProgName = 'MSK';
PboxProgName = 'FXC';

tic     % initialise timing bits & pieces: not needed in monkeylogic implementation
F=120;
A(1:F) = zeros;

for j=1:6
%    A(j) = toc;
    feval(PboxProgName, -1, win, j, PseudoTrialObject(j))   % initialising call: mode, window, N, PseudoTrialObject
                                                         % ... equivalent @ L2294 PTB_trialholder>psytboxrouter
end
      % Initially sync to VBL at start of animation loop: 
      % SDS: only doing this for timing measurement purposes: not needed in monkeylogic implementation
vbl = Screen('Flip', win);
tstart = vbl;
count = 0;
for j = 1:6
    for i=1:F;
        feval(PboxProgName, 2, j)       % equivalent @ L354 of 'trialholder': Progname, mode, trial object number
    %   Screen('Flip', win);            % equivalent @ L444 within Flip Screen section of 'trialholder' 
        vbl = Screen('Flip', win, vbl + 0.5*ifi);
        A(j,i) = toc;
        count = count + 1;            % Next loop iteration...
    end
end

% Print the stats:
count;
avgfps = count / (vbl - tstart)

for j = 1:6
    B = A(j,2:F);
    C = A(j,1:F-1);
    out = B-C;
    M=mean(out);
    fprintf('mean time per frame %1.4i; frames per sec %1.2i', M, 1/M); 
end
Screen('Closeall')
 
 