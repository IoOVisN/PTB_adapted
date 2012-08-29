function test_GAB

% Use to test/develop PsychToolBox routines GAB & MSK

% Option: select one of the following:-
 PboxProgName = 'GAB';
% PboxProgName = 'MSK';


% The following code & notes lifted from PsychToolBox:-

% Open a fullscreen, onscreen window with gray background. Enable 32bpc
% floating point framebuffer via imaging pipeline on it, if this is possible
% on your hardware while alpha-blending is enabled. Otherwise use a 16bpc
% precision framebuffer together with alpha-blending. We need alpha-blending
% here to implement the nice superposition of overlapping gabors. The demo will
% abort if your graphics hardware is not capable of any of this.
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
%[win winRect] = PsychImaging('OpenWindow', screenid, 128);      %SDS: 128 is the background colour
% [win winRect] = PsychImaging('OpenWindow', 1, [0 0 0]);      
 [win winRect] = PsychImaging('OpenWindow', 1, [128 128 128]);     

% Retrieve size of window in pixels:
% [w, h] = RectSize(winRect);       %SDS: now done in animate routine (PGR)

% Query frame duration: We use it later on to time 'Flips' properly for an animation with constant framerate:
ifi = Screen('GetFlipInterval', win);

% Enable alpha-blending, set it to a blend equation useable for linear
% superposition with alpha-weighted source. This allows to linearly
% superimpose gabor patches in the mathematically correct manner, should
% they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
% the 'DrawTextures' can be used to modulate the intensity of each pixel of
% the drawn patch before it is superimposed to the framebuffer image, ie.,
% it allows to specify a global per-patch contrast value:
Screen('BlendFunction', win, GL_ONE, GL_ONE);

% PseudoTrialObject.Class = 'Psytbx';
PseudoTrialObject(1).Class = 'ori'; %
PseudoTrialObject(1).Radius = 240;   % radius value              old ob.Xpos
PseudoTrialObject(1).Angle = 0;     % angle value               old ob.Ypos
PseudoTrialObject(1).FP1 = 1;    % target position           old ob.Xsize
PseudoTrialObject(1).FP2 = 6;    % difficulty level          old ob.Ysize

PseudoTrialObject(2).Class = 'spf'; 
PseudoTrialObject(2).Radius = 280;   % radius value
PseudoTrialObject(2).Angle = 15;     % angle value
PseudoTrialObject(2).FP1 = 8;    % target position
PseudoTrialObject(2).FP2 = 7;    % difficulty level

PseudoTrialObject(3).Class = 'din'; 
PseudoTrialObject(3).Radius = 320;   % radius value
PseudoTrialObject(3).Angle = 30;     % angle value
PseudoTrialObject(3).FP1 = 7;    % target position
PseudoTrialObject(3).FP2 = 8;    % difficulty level

PseudoTrialObject(4).Class = 'din'; 
PseudoTrialObject(4).Radius = 360;   % radius value
PseudoTrialObject(4).Angle = 45;     % angle value
PseudoTrialObject(4).FP1 = 0;    % target position
PseudoTrialObject(4).FP2 = 8;    % difficulty level

% OPTIONS:-
%  PseudoTrialObject.Class = 'spf';   % functional
%  PseudoTrialObject.Class = 'din';  % Not functional in PsychToolBox: requires secondary grating; OR functions as simple direction singleton
%  PseudoTrialObject.Class = 'col';  % Not functional in PsychToolBox: requires neutral background modification
%  PseudoTrialObject.Class = 'ori'; % functional
%  PseudoTrialObject.Class = 'siz';  % Not functional in PsychToolBox: requires alteration of matrix position coding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NB if use 'dir'  the eval command (in mlogic 'load_conditions' routine)
% ...does entirely the wrong thing !!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic     % initialise timing bits & pieces: not needed in monkeylogic implementation
n = 4;
F = 100;
A(1:F) = zeros;

for j=1:n
%    A(j) = toc;
%   feval(PboxProgName, -1, 1, PseudoTrialObject)        % initialising call: mode, N, PseudoTrialObject
    feval(PboxProgName, -1, win, j, PseudoTrialObject(j))   % initialising call: mode, window, N, PseudoTrialObject
end                                                       % ... equivalent @ L2294 PTB_trialholder>psytboxrouter

      % Initially sync to VBL at start of animation loop: 
      % SDS: only doing this for timing measurement purposes: not needed in monkeylogic implementation
    vbl = Screen('Flip', win);
    tstart = vbl;
    count = 0;
for j=1:n  
    for i=1:F;
        feval(PboxProgName, 5, j)       % equivalent @ L354 of 'trialholder': Progname, mode, trial object number
%       Screen('Flip', win);            % equivalent @ L444 within Flip Screen section of 'trialholder' 
        vbl = Screen('Flip', win, vbl + 0.5*ifi);
        A(i) = toc;
        count = count + 1;            % Next loop iteration...
    end
end

% Print the stats:
count;
avgfps = count / (vbl - tstart)

B=A(2:F);
C=A(1:F-1);
out = B-C;
M=mean(out);
fprintf('mean time per frame %1.4i; frames per sec %1.2i', M, 1/M); 

Screen('Closeall')