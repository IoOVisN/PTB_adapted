%mse_gm_fx (timing script)

% *** ADDS MASK ***
% *** ADDS FXC ***   (Cogent fixation device) 


% sample line from conditions file ptori_GAB_FXC_a:
% Condition	Frequency	Block	Timing File	TaskObject#1                TaskObject#2                TaskObject#3            TaskObject#4                TaskObject#5
% 1         1           1       mse_gm_fx	FXC(0,0,25,5,[200 200 200])	FXC(0,0,20,4,[250 0 250])	GAB(ori,320,135,1,1)	FXC(0,0,25,5,[255 255 255])	GAB(msk,320,135,-1,0)


% trial error reports use text or numeric code 0 - 8:
% 0. 'correct'          1. 'no response'    2. 'late response'
% 3. 'break fixation'   4. 'no fixation'    5. 'early response' 
% 6. 'incorrect'        7. 'lever break'    8. 'ignored'


% give names to the TaskObjects defined in the conditions file: e.g. 'cgcol'
fixtn_1 = 1; % dimmer cross
fixtn_2 = 4; % brighter cross
gabors = 3;
mask = 5;
fixtn_c = 2; % variable colour cross
target_item = TaskObject(gabors).FP1;   % Can use this to fine tune the mechanics of the task. See Note B
level = TaskObject(gabors).FP2;

% define time intervals (in ms):
wait_for_fix = 2000;
initial_fix = 2000;
flash = 500;
sample_time = 500;
delay = 1500;
max_reaction_time = 1500;
saccade_time = 80;
hold_target_time = 1000;
fix_radius = 1;   %  in degrees



% 'acquiretarget' == 0 if the joystick-position does not enter the specified radius around a target object within the allowed duration,
%                   ...otherwise == ordinal number of the acquired object, immediately this object is acquired.

% 'holdtarget'    == 0 immediately, if the joystick-position exits the threshold radius around the target object before the specified duration has elapsed,
%                   ...otherwise == 1.

% 'showcursor'    controls a persistent flag within eyejoytrack; when the flag is 'on' 'acquiretarget' & 'holdtarget' will display cursor for as long as they are operational; 
%                       timing file   || 'showcursor' calls eyejoytrack(-2, cflag); 
%                       eyejoytrack   ||  cflag  sets ScreenData.Showcursor
%                       eyejoytrack   ||  ScreenData.Showcursor & 'joytrack' flag set 'YesShowCursor' ==1
%                       eyejoytrack   ||  'YesShowCursor' flags a call to toggleobject(-4, cxpos cypos)
%                      toggleobject   ||  the presence of coordinates in the -4 mode sets flag 'update_cursor' ==1
%                      toggleobject   || 'update_cursor' triggers blit command to draw cursor
%
%              ... But afterwards, direct toggleobject calls, and 'idle' calls to toggleobject will not display cursor, as  update_cursor is always reset ==0

% 'setmouse'    'on' or  'off'; switch on to substitute mouse coordinates for joystick coordinates; i.e joystick is neutralised and mouse is activated 

% NOTE A:
% Assumes that the target position is the first in the list of item coordinates;
% Hence, the 'ontarget' returns from eyejoyrack (here relabelled A_FIX, H_FIX, A_TAR & H_TAR)
% are treated as on-target if ==1, and off-target if == 2 to 8

% NOTE B:
% The timing file can be more flexible if it 'knows' exactly which item has been selected,
% ...as opposed to a logical target v non-target distinction.
% A_TAR (ontarget) reports the ordinal position of acquired item in the specified  sequence:
% ... if an XGL target, this is the list of specified targets in the 'acquiretarget' command;
% ... if a Cogent target, this is the list of positions help in TaskObject(i).XPos (and TaskObject(i).YPos), 'i' being the task object specified to be the target

% mse_gm
% 1 target 7 distractors
% acquire target & hold - - - cursor vanishes, mask appears and all items persist for specified time;
% acquire non-target & hold - - - cursor vanishes, mask appears and all items persist for a shorter specified time, then ring flashes once;

setmouse('on')          % use mouse rather than joystick coordinates
toggleobject(fixtn_1);    % switch on fixation point
showcursor('on')        % activate currsor display; showcursor(1)  is equivalent form of command

A_FIX = eyejoytrack('acquiretarget', fixtn_1, fix_radius, wait_for_fix);
if ~A_FIX,
    trialerror(4); % no fixation
    toggleobject(fixtn_1)
    return
end
H_FIX = eyejoytrack('holdtarget', fixtn_1, fix_radius, flash);
if ~H_FIX ,
    trialerror(3); % broke fixation
    toggleobject(fixtn_1)
    return
end

toggleobject([fixtn_1 fixtn_2]);    % toggle fixation: fixtn_1 OFF, fixtn_2 ON

H_FIX = eyejoytrack('holdtarget', fixtn_2, fix_radius, flash);  % could also specify fixtn_1 here, as position is the same... 
if ~H_FIX ,
    trialerror(3); % broke fixation
    toggleobject(fixtn_2)
    return
end

toggleobject([fixtn_1 fixtn_2]);    % toggle fixation: fixtn_1 ON, fixtn_2 OFF

H_FIX = eyejoytrack('holdtarget', fixtn_1, fix_radius, flash);
if ~H_FIX ,
    trialerror(3); % broke fixation
    toggleobject(fixtn_1)
    return
end

toggleobject([fixtn_1 fixtn_2]);    % toggle fixation: fixtn_1 OFF, fixtn_2 ON

H_FIX = eyejoytrack('holdtarget', fixtn_2, fix_radius, flash);
if ~H_FIX ,
    trialerror(3); % broke fixation
    toggleobject(fixtn_2)
    return
end

toggleobject([fixtn_1 fixtn_2 gabors]) % toggle fixation:  fixtn_1 & gabors ON
% showcursor('on')  % not necessary to turn on again; 'showcursor' controls a persistent flag within eyejoytrack

A_TAR = eyejoytrack('acquiretarget', gabors, fix_radius,max_reaction_time);
if ~A_TAR,
    trialerror(2); % no or late response (did not land on either the target or distractor)
    disp('error: did not acquire any target')
    toggleobject([fixtn_1 gabors]) %ALL OFF
    return
% elseif A_TAR ==2 || A_TAR ==3 || A_TAR ==4  % NB this is the ordinal position of the chosen item in the items vector
% elseif A_TAR ==1   % see NOTE A
% elseif A_TAR == TaskObject(items).FP1;  % see NOTE B
elseif A_TAR == target_item               % see NOTE B
    disp('OK: acquired target')
    trialerror(0);  % "correct"
    toggleobject([gabors mask])           % gabors off, mask on
    H_DEC = eyejoytrack('holdtarget', mask, fix_radius, hold_target_time);
    if ~H_DEC,
        trialerror(5); % broke fixation
        toggleobject([fixtn_1 mask]) %ALL OFF
        return
    end
    toggleobject([fixtn_1 fixtn_2]);    % toggle fixation: fixtn_1 OFF, fixtn_2 ON
    eyejoytrack('idle',2000)
    toggleobject([fixtn_2 mask])  %ALL OFF
    
else  % i.e A_TAR == any other item, i.e a decoy  
    disp('OK: acquired NON-target')
    trialerror(6);  % "incorrect"
    toggleobject([gabors mask])         % gabors off, mask on
    H_DEC = eyejoytrack('holdtarget', mask, fix_radius, hold_target_time);
    if ~H_DEC,
        trialerror(5); % broke fixation
        toggleobject([fixtn_1 mask]) %ALL OFF
        return
    end
    eyejoytrack('idle',1000)
    toggleobject([fixtn_1 fixtn_c mask])   % Switch Fixation & mask OFF;
    eyejoytrack('idle',500)            % ...this to distinguish error trial from correct trial
    toggleobject([fixtn_1 fixtn_c])
    eyejoytrack('idle',500)            % ...this to distinguish error trial from correct trial
    toggleobject([fixtn_1 fixtn_c])
    eyejoytrack('idle',500)            % ...this to distinguish error trial from correct trial
    toggleobject([fixtn_1 fixtn_c])
    eyejoytrack('idle',500)            % ...this to distinguish error trial from correct trial
    toggleobject([fixtn_1 fixtn_c])
    eyejoytrack('idle',500)
    toggleobject([fixtn_c])            % switch off
end
    
%     
%     trialerror(6); % chose the wrong (second) object among the options [target distractor]
%     disp('error: did acquire a non-target')
%     chosen = items(A_TAR);
%     H_DEC = eyejoytrack('holdtarget', chosen, fix_radius, hold_target_time);
%     if ~H_DEC,
%         trialerror(5); % broke fixation
%         toggleobject([fixtn items]) 
%         return
%     end
%     toggleobject(chosen)% OFF
%     idle(500)
%     toggleobject(chosen)% ON
%     idle(500)
%     toggleobject(chosen)% OFF
%     idle(500)
%     toggleobject(chosen)% ON
%     idle(500)
%     toggleobject([fixtn items]) % All OFF
%     return
% else   % i.e A_TAR ==1   
%     chosen = items(A_TAR);
%     H_DEC = eyejoytrack('holdtarget', chosen, fix_radius, hold_target_time);
%     if ~H_DEC,
%         trialerror(5); % broke fixation
%         toggleobject([fixtn items]) 
%         return
%     end
%     toggleobject(items) % OFF
%     idle(500)
%     toggleobject(items) % ON
%     idle(500)
%     toggleobject(items) % OFF
%     idle(500)
%     toggleobject(items) % ON
%     idle(500)
%     toggleobject(items) % OFF
%     idle(500)
%     toggleobject(items) % ON
%     idle(500)
%     toggleobject([fixtn items]) % OFF
% end

