function TrialData = PT_trialholder(TaskObject, ScreenInfo, DaqInfo, EyeTransform, JoyTransform, BehavioralCodes, TrialRecord, trialtype)
global SIMULATION_MODE

% This is the code into which a timing script is embedded (by
% "embedtimingfile") to create the run-time trial function.  
% 
% See www.monkeylogic.net for more information.
%
% Created by WA 6/15/06
% modified 12/20/06 -WA (new DAQ structure incorporated)
% modified 1/19/08 -WA (new video routines to check vertical blank status) 
% modified 4/03/08 -WA (fixed bug re: sending multiple codes to 'eventmarker')
% modified 7/23/08 -WA (getkeypress now properly restores run-time priority)
% modified 7/25/08 -WA (now saves absolute trial start time)
% modified 8/10/08 -WA (joystick cursor now properly centered)
% last modified 8/24/08 -MS & WA (movie presentation & translation added)

% Modified July 2012 SDS: to accommodate PsychToolBox 'SDS X_MLVIDEO'
% Modified  Aug 2012 SDS: enable mouse to replace joystick 'mouse for joystick' (- but retains DAQ joystick functionality)
% Modified  Aug 2012 SDS: Eyelink to replace DAQ.eye signal 'SDS:  EYELINK/DAQ'

Codes = []; %#ok<NASGU>
rt = NaN; %#ok<NASGU>
AIdata = []; %#ok<NASGU>

%flush keyboard buffer
mlkbd('flush');

%start DAQ objects for Eye & Joystick
if ~isempty(DaqInfo.AnalogInput),
    %set(DaqInfo.AnalogInput,'DataMissedFcn',@data_missed);
    start(DaqInfo.AnalogInput);
    while ~isrunning(DaqInfo.AnalogInput), end
    trialtime(-1, ScreenInfo); %initialize trial timer
    axes(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'replica'));
    drawnow; %flush all pending graphics
    while ~DaqInfo.AnalogInput.SamplesAvailable, end
else
    trialtime(-1, ScreenInfo); %initialize trial timer   %SDS 'trialtime' subroutine L 1797
end
%%% initialize video subroutines:                     %SDS - these are possible "timing file" commands
TaskObject = psytboxrouter(TaskObject, ScreenInfo.Ptr, ScreenInfo.PixelsPerDegree);            % SDS ADDED EXTRA
toggleobject(-1, TaskObject, ScreenInfo, DaqInfo);
set_frame_order(-1, TaskObject);
reposition_object(-1, TaskObject, ScreenInfo);
set_object_path(-1, TaskObject, ScreenInfo);
set_iti(-1);
showcursor(-1, ScreenInfo);
%%% initialize i/o subroutines:                       %SDS - these are possible "timing file" commands
eyejoytrack(-1, TaskObject, DaqInfo, ScreenInfo, EyeTransform, JoyTransform);
idle(-1, ScreenInfo);
joystick_position(-1, DaqInfo, ScreenInfo, JoyTransform);
eye_position(-1, DaqInfo, ScreenInfo, EyeTransform);
simulation_positions(-1);
get_analog_data(-1, DaqInfo, EyeTransform, JoyTransform);   %SDS subfunction L 1361
getkeypress(-1, ScreenInfo);
hotkey(-1);
goodmonkey(-1, DaqInfo);
user_text(-1, ScreenInfo);
user_warning(-1, ScreenInfo);
bhv_variable(-1);
%%% initialize end-trial subroutine;
end_trial(-1, DaqInfo, ScreenInfo, EyeTransform, JoyTransform, trialtype);
%%% initialize eventmarker subroutine
eventmarker(-1, DaqInfo, BehavioralCodes);

if trialtype == 0,          % regular task trial
    eventmarker(9);
    eventmarker(9);
    eventmarker(9);
elseif trialtype == 1,      %WA: initialization trial  %SDS: not needed in PT_adapted version; NB, it's not a trial - it just runs the 'intialization' video clip
    user_warning('off');
    mov = 1;
    t = (1000*TaskObject(mov).NumFrames/ScreenInfo.RefreshRate) - 50;
    toggleobject(mov,'eventmarker',13);     %SDS  this command (with idle(t)) runs the 'initializing' video
    goodmonkey(-2); %will test output only if reward line exists
    idle(t);
    toggleobject(mov,'eventmarker',14);
    end_trial;
    return
elseif trialtype == 2,      % benchmark trial
    user_warning('off');
    disp('<<< MonkeyLogic >>> Entering benchmark mode...'); %mltimetest.m takes over from here
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EASY ESCAPE
hotkey('esc', 'escape_screen;');          %SDS: hotkey subroutine @ L 2065
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EYE OFFSET
hotkey('c', 'eye_position(-2);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
hotkey('r', 'goodmonkey(100);');
hotkey('-', 'goodmonkey(-4,-10);');
hotkey('=', 'goodmonkey(-4,10);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WARNINGS
hotkey('w', 'user_warning(-2);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION MODE
SIMULATION_MODE = TrialRecord.SimulationMode;

hotkey('numrarr', 'simulation_positions(1,1,1);');
hotkey('numlarr', 'simulation_positions(1,1,-1);');
hotkey('numuarr', 'simulation_positions(1,2,1);');
hotkey('numdarr', 'simulation_positions(1,2,-1);');

hotkey('rarr', 'simulation_positions(1,3,1);');
hotkey('larr', 'simulation_positions(1,3,-1);');
hotkey('uarr', 'simulation_positions(1,4,1);');
hotkey('darr', 'simulation_positions(1,4,-1);');

hotkey('space', 'simulation_positions(2,5,-Inf);');
hotkey('bksp', 'simulation_positions(2,5,Inf);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if trialtype ~=2 %SDS amend - crashes at this point in latency test because CurrentConditionInfo & CurrentConditionGenInfo have yet to be created
    Info = TrialRecord.CurrentConditionInfo;       %#ok<NASGU>
    GenInfo = TrialRecord.CurrentConditionGenInfo; %#ok<NASGU>
end
user_text('');

try
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%INSERT TRIAL POINT********************************************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%end_trial subroutine called by run-time script (necessary code inserted by
%embedtimingfile.m at this point and at any "return" statement)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
catch ME
    if strcmp(ME.identifier,'ML:TrialAborted'),
        toggleobject(-5);
        end_trial(-2,9);
        TrialData = end_trial;
        TrialData.ReactionTime = NaN;
        TrialData.TrialRecord = TrialRecord;
        return;
    else
        rethrow(ME);
    end
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tflip, framenumber] = toggleobject(stimuli, varargin)             % till line 465
persistent   TrialObject  ScreenData DAQ togglecount ObjectStatusRecord yrasterthresh ltb lastframe activemovies win ifi vbl
% taken from TaskObject & ScreenInfo
tflip = [];
framenumber = [];
movie_advance_only = 0;
update_cursor = 0;
CoGo = 0;                           % SDS - ADDED EXTRA  'CoGo' is a flag to select a Cogent or an XGL flip command (L424)
if stimuli == -1,      %initialize  % SDS - 'toggleobject' is initialized on every trial
    TrialObject = varargin{1};
    ScreenData = varargin{2};
    DAQ = varargin{3};
% SDS X_MLVIDEO
%     mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);
%     mlvideo('flip', ScreenData.Device);
%     BC = ScreenData.BackgroundColor;    % PsychToolBox always clears to background colour, set in initial 'OpenWindow' command
      win = ScreenData.Ptr;
      vbl = Screen('flip',win);
      ifi = Screen('GetFlipInterval', win);  %SDS: (alternatively, ifi is already stored as ScreenData.Framelength)
% SDS X_MLVIDEO_end
    if ScreenData.PhotoDiode > 1,
        ScreenData.PdStatus = 0;
    end
    ltb = length(TrialObject);
    togglecount = 0;
    ObjectStatusRecord = [];
    yrasterthresh = floor(0.8*ScreenData.Ysize);
    lastframe = 0;
    activemovies = false(ltb, 1);   % SDS - all task objects are given an 'activemovies=0' flag, that acts to start movie at startframe
    return
elseif stimuli == -2,                %trial exit data
    tflip = ObjectStatusRecord;
    return
elseif stimuli == -3,                %call from reposition_object or set_object_path
    stimnum = varargin{1};
    TrialObject(stimnum) = varargin{2};
    statrec = double(cat(1, TrialObject.Status));
    if varargin{3},                  %called from reposition_object, not set_object_path
        togglecount = togglecount + 1;
        statrec(stimnum) = 2;
        ObjectStatusRecord(togglecount).Time = round(trialtime);
        ObjectStatusRecord(togglecount).Status = statrec;
        ObjectStatusRecord(togglecount).Data{1} = [TrialObject(stimnum).XPos TrialObject(stimnum).YPos];
        if TrialObject(stimnum).Status,
            toggleobject([stimnum stimnum], 'fast');
        end
    end
    return
elseif stimuli == -4,               %WA: update movies and/or subject's cursor only  %SDS NO - this implements all 'idle' calls 
    movie_advance_only = 1;         %SDS  -4 call optionally includes cursor position coordinates (as selected by showcursor command via eyejoytrack...)
    if ~isempty(varargin),
        cursorpos = varargin{1};
        update_cursor = 1;
    end
elseif stimuli == -5,               %WA: turn off all TrialObjects with status.  Called when trial is aborted.
    for i = ltb:-1:1,
        ob = TrialObject(i);
        if ob.Status,
            toggleobject(i);
        end
    end
    return;
end

fastdraw = 0; %WA: will draw to subject screen but not control screen if == 1
behavioralcode = 0;
statselect = 0;
setstartframe = 0;
setstartposition = 0;

if ~isempty(varargin) && ~movie_advance_only,           %SDS ends L308
    numargs = length(varargin);
    if mod(numargs, 2),
        error('ToggleObject requires all arguments beyond the first to come in parameter/value pairs');
    end
    for k = 1:2:numargs,                                %SDS ends L307
        v = varargin{k};
        a = varargin{k+1};
        if ~ischar(v),
            error('ToggleObject requires all arguments beyond the first to come in parameter/value pairs');
        end
        if strcmpi(v, 'status'),
            statselect = 1;
            statval = 0;
            if ischar(a),
                if strcmpi(a, 'on'),
                    statval = 1;
                elseif ~strcmpi(a, 'off'),
                    error('Unrecognized value %s for Toggleobject parameter "status"', a);
                end
            elseif a,
                statval = 1;
            end
            for i = 1:length(stimuli),
                TrialObject(stimuli(i)).Status = statval;
            end
        elseif strcmpi(v, 'drawmode'),  %SDS: call from 'showcursor'  timing file command
            if ischar(a) && strcmpi(a, 'fast'),
                fastdraw = 1;
            elseif ~ischar(a) && a,
                fastdraw = 1;
            end
        elseif strcmpi(v, 'eventmarker'),
            if ischar(a),
                error('Value for <Toggleobject: EventMarker> must be numeric');
            end
            behavioralcode = a;
        elseif strcmpi(v, 'moviestartframe'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: MovieStartFrame> must be numeric');
            end
            if length(a) == 1 || length(a) == length(stimuli),
                [TrialObject(stimuli).StartFrame] = deal(a);
            else
                error('Number of values for <ToggleObject: MovieStartFrame> must be equal to the number of specified stimuli, or scalar');
            end
            setstartframe = 1;
        elseif strcmpi(v, 'moviestep'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: MovieStep> must be numeric');
            end
            if length(a) == 1 || length(a) == length(stimuli),
                [TrialObject(stimuli).FrameStep] = deal(a);
                if ~setstartframe && any(a < 0),
                    stimsubset = stimuli(a < 0);
                    for i = 1:length(stimsubset),
                        TrialObject(stimsubset(i)).StartFrame = TrialObject(stimsubset(i)).NumFrames; %start playing backwards from last frame
                    end
                end
            else
                error('Number of values for <ToggleObject: MovieStep> must be equal to the number of specified stimuli, or scalar');
            end
        elseif strcmpi(v, 'startposition'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: StartPosition> must be numeric');
            end
            if length(a) == 1 || length(a) == length(stimuli),
                [TrialObject(stimuli).StartPosition] = deal(a);
            else
                error('Number of values for <ToggleObject: StartPosition> must be equal to the number of specified stimuli, or scalar');
            end
            setstartposition = 1;
        elseif strcmpi(v, 'positionstep'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: PositionStep> must be numeric');
            end
            if length(a) == 1 || length(a) == length(stimuli),
                [TrialObject(stimuli).PositionStep] = deal(a);
                if ~setstartposition && any(a < 0),
                    stimsubset = stimuli(a < 0);
                    for i = 1:length(stimsubset),
                        TrialObject(stimsubset(i)).StartPosition = TrialObject(stimsubset(i)).NumPositions; %start translating backwards from last position
                    end
                end
            else
                error('Number of values for <ToggleObject: PositionStep> must be equal to the number of specified stimuli, or scalar');
            end
        else
            error('Unrecognized option "%s" calling ToggleObject', v);
        end
    end
end
                                                     % SDS - if not an 'idle' call, it does this...
if ~statselect && stimuli(1) && ~movie_advance_only, %(i.e., if ~stimuli(1) redraw only, without toggling)
    for i = 1:length(stimuli),
        stimnum = stimuli(i);
        TrialObject(stimnum).Status = ~TrialObject(stimnum).Status;   %SDS - status is set to 0 initially; this command switches status
    end                                                               %SDS - this is why it's called 'toggleobject'...

end

if stimuli(1) || movie_advance_only,
    togglecount = togglecount + 1;
end

initmovies = false(ltb, 1);
posarray = zeros(ltb, 2);
% SDS X_MLVIDEO
% mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);  
% PsychToolBox 'flip' command automatically clears buffer (unless instructed otherwise)
% ... therefore no action needed here. 
% SDS X_MLVIDEO_end
[t currentframe] = trialtime;
% while currentframe == lastframe, %WA: to avoid queueing flips in the same frame %SDS:  PsychToolBox now controls frame rate
%     [t currentframe] = trialtime;				%SDS:  PsychToolBox amend
% end											%SDS:  PsychToolBox amend

for i = ltb:-1:1,  %SDS high to low... so low items such as fixation point (=object no.1) get superimposed on anything else     
    ob = TrialObject(i);
    if ob.Status,
        if ob.Modality == 1, %SDS - PsychToolBox device           %%% SDS ADDED EXTRA %%%
            if ~movie_advance_only && ~activemovies(i)
                initmovies(i) = 1; % treating PsychToolBox device as a movie; 'initmovies' is reset to zero each trial (L320) 
                                   % ... this will set 'activemovies' == 1,  below (@ L465); 'activemovies' is reset == 0 when task object has status reset == 0 (@ L405)
            elseif currentframe - lastframe > 1,
                eventmarker(200); %SDS: not sure what this achieves...
                fprintf('Warning: skipped %i frame(s) of %s at %3.1f ms\n', (currentframe - lastframe - 1), ob.Name, trialtime);
                user_warning('Skipped %i frame(s) of %s at %3.1f ms', (currentframe - lastframe - 1), ob.Name, trialtime);
            end
            PboxProgName = ob.Name;
            if strcmpi(PboxProgName, 'GAB')
                if ob.FP1 >= 0                  % SDS   zero is no target; 1 to 8 is target position
                    feval(PboxProgName, 2, i);   % SDS  (PboxProgName, mode, task object no.) mode 1 = single central gabor; mode 2 = full array
                elseif ob.FP1 == -1
                    feval(PboxProgName, 3, i);   % SDS  (PboxProgName, mode, task object no.) mode 3 = full mask array, COUNTERPHASING GRATING
                elseif ob.FP1 == -2
                    feval(PboxProgName, 4, i);   % SDS  (PboxProgName, mode, task object no.) mode 4 = full mask array, DRIFTING GRID 
                elseif ob.FP1 == -3
                    feval(PboxProgName, 5, i);   % SDS  (PboxProgName, mode, task object no.) mode 5 = full mask array, COUNTERPHASING GRID
                end
            elseif strcmpi(PboxProgName, 'FXC')
                feval(PboxProgName, 2, i);
            else
                feval(PboxProgName, 2, i);
            end
            CoGo = 1;
         
% SDS X_MLVIDEO            
%         elseif ob.Modality == 1, %static video object
%             mlvideo('blit', ScreenData.Device, ob.Buffer, ob.XsPos, ob.YsPos, ob.Xsize, ob.Ysize);
%             [tflip fn2] = trialtime;      %SDS temp
%         elseif ob.Modality == 2, %movie
%             if ~movie_advance_only && ~activemovies(i), % initialize movie
%                 ob.Status = ob.StartFrame;
%                 ob.CurrentPosition = ob.StartPosition;
%                 initmovies(i) = 1;
%             else %advance frame(s) and / or position(s)
%                 if currentframe - lastframe > 1,
%                     eventmarker(200);
%                     fprintf('Warning: skipped %i frame(s) of %s at %3.1f ms\n', (currentframe - lastframe - 1), ob.Name, trialtime);
%                     user_warning('Skipped %i frame(s) of %s at %3.1f ms', (currentframe - lastframe - 1), ob.Name, trialtime);
%                 end
%                 indx = round(ob.FrameStep*(currentframe - ob.InitFrame)) + ob.StartFrame -1;
%                 modulus = max(length(ob.FrameOrder),ob.NumFrames);
%                 indx = mod(indx, modulus) + 1;
%                 
%                 if ~isempty(ob.FrameEvents),
%                     f_list = ob.FrameEvents(1,:);
%                     e_list = ob.FrameEvents(2,:);
%                     f = find(f_list == indx);
%                     if ~isempty(f),
%                         behavioralcode = e_list(f(1));
%                     end
%                 end
%                 
%                 if indx > length(ob.FrameOrder),
%                     ob.Status = indx;
%                 else
%                     ob.Status = ob.FrameOrder(indx);
%                 end
%                 ob.Status = mod(ob.Status, ob.NumFrames) + 1;
%                 indx = round(ob.PositionStep*(currentframe - ob.InitFrame)) + ob.StartPosition;
%                 ob.CurrentPosition = mod(indx, ob.NumPositions) + 1;
%             end
%             mlvideo('blit', ScreenData.Device, ob.Buffer(ob.Status), ob.XsPos(ob.CurrentPosition), ob.YsPos(ob.CurrentPosition), ob.Xsize, ob.Ysize);
%             TrialObject(i) = ob; %update persistent TrialObject array
%             %Save for ObjectStatusRecord:
%             xpos = ob.XPos(ob.CurrentPosition);
%             ypos = ob.YPos(ob.CurrentPosition);
%             posarray(i, 1:2) = [xpos ypos];
% SDS X_MLVIDEO_end
        elseif ob.Modality == 3 && ~movie_advance_only, % sound
            play(ob.PlayerObject);
            TrialObject(i).Status = 0;
        elseif ob.Modality == 4 && ~movie_advance_only, % analog stimulation
            trigger(DAQ.AnalogOutput);
            TrialObject(i).Status = 0;
        elseif ob.Modality == 5 && ~movie_advance_only, % TTL (digital) output
            putvalue(DAQ.(ob.Class), 1);
        end
    elseif ~ob.Status && ~movie_advance_only,  %SDS - i.e inactive (status=0) objects in non 'idle' calls to toggleobject...
        if ob.Modality == 1 || 2, % reset activemovies flag for that movie % SDS: Modality ==1 is PsychToolBox; ==2 used to be movie, now redundant
            activemovies(i) = 0;
        elseif ob.Modality == 3, % can abort sound manually
            stop(ob.PlayerObject);
        elseif ob.Modality == 5, % TTL must be turned off manually
            putvalue(DAQ.(ob.Class), 0);
        end
    end
end

%PhotoDiode
if ScreenData.PhotoDiode > 1,
    pdflip = any(cat(1, TrialObject.Modality) < 3);
    if pdflip,
        if ~ScreenData.PdStatus,
% SDS X_MLVIDEO
%            mlvideo('blit', ScreenData.Device, ScreenData.PdBuffer, ScreenData.PdX, ScreenData.PdY, ScreenData.PdXsize, ScreenData.PdYsize);
            ScreenData.PdStatus = 1;
        else
            ScreenData.PdStatus = 0;
        end
    end
end

%Subject's Joystick Cursor
if update_cursor,
% SDS X_MLVIDEO
%    mlvideo('blit', ScreenData.Device, ScreenData.CursorBuffer, cursorpos(1), cursorpos(2), ScreenData.CursorXsize, ScreenData.CursorYsize);
    curs = [cursorpos(1)-5, cursorpos(1)-15; cursorpos(2)-15, cursorpos(2)-5; cursorpos(1)+5, cursorpos(1)+15; cursorpos(2)+15, cursorpos(2)+5];
    Screen('FrameOval',win,[],curs,2,2)
end

% FLIP SCREEN
%%% SDS ADDED EXTRA %%%  % SDS X_MLVIDEO

% [VBLTimestamp ... ... ...] = Screen('Flip', windowPtr [, when] [, dontclear] [, dontsync] [, multiflip]);
% VBLTimestamp = a high-precision estimate of the system time (in seconds) when the actual flip has happened
%  "when" specifies when to flip: If set to zero (default), it will flip on the next possible retrace.
% ...If set to a value when > 0, it will flip at the first retrace after system time 'when' has been reached;

% "dontsync" If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened.
% If set to 1, Flip will still synchronize stimulus onset to the vertical% retrace, but will *not* wait for the flip to happen;
% ...Flip returns immediately and all returned timestamps are invalid.

% MLvideo('waitflip', .., ..)'waitflip'option flips when it's ok to draw based upon two criteria: 1) not vertical blank and 2) raster-line <= thresh;

% SDS X_MLVIDEO
if behavioralcode, %WA: syncs the code with the screen flip
%     mlvideo('waitflip', ScreenData.Device, yrasterthresh);
      [tflip framenumber] = trialtime;
      vbl = Screen('Flip', win, vbl + 0.5 * ifi);
      [tflip fn1] = trialtime;
%     while ~mlvideo('verticalblank', ScreenData.Device), end
      eventmarker(behavioralcode);
else %either movie update, cursor re-position, or no behavioral code
%     mlvideo('flip', ScreenData.Device);
      [tflip framenumber] = trialtime;
      vbl = Screen('Flip', win, vbl + 0.5 * ifi);  %SDS here or above, might be a more approp
      [tflip fn1] = trialtime;
end
% SDS X_MLVIDEO_end
if CoGo
    fprintf('%i %i %i |*|', currentframe, framenumber, fn1);        %SDS temp - to monitor framenumber across phases of the trial
else
    fprintf('%i %i |*|', currentframe, framenumber);  
end
CoGo = 0;

lastframe = framenumber;
%disp(sprintf('T = %i ms;   Frame = %i', round(tflip), framenumber)) % commented WA
                                                             
%WA: send update to eyejoytrack so it knows about the user's call to toggleobject
if ~movie_advance_only,
    eyejoytrack(-5, TrialObject, framenumber);
end

%movie record-keeping
if any(initmovies),
    [TrialObject(initmovies).InitFrame] = deal(framenumber);
    activemovies = activemovies | initmovies;
    disp('activemovies activated')
end

%update ObjectStatusRecord (used to play-back trials from BHV file)
ObjectStatusRecord(togglecount).Time = round(trialtime);
statrec = cat(1, TrialObject.Status);
if any(activemovies),
    framearray = zeros(ltb, 1);
    fnum = statrec(activemovies);
    statrec(activemovies) = 3;
    framearray(activemovies) = fnum;
    ObjectStatusRecord(togglecount).Status = statrec;
    ObjectStatusRecord(togglecount).Data{1} = framearray;
    ObjectStatusRecord(togglecount).Data{2} = reshape(posarray, numel(posarray), 1);
    if movie_advance_only,
        return
    end
else
    ObjectStatusRecord(togglecount).Status = statrec;
    ObjectStatusRecord(togglecount).Data{1} = [];
end

%Update control-screen objects
if ~fastdraw,
    for i = 1:ltb,
        ob = TrialObject(i);
        if ob.Modality == 1 || ob.Modality == 2  %WA: visual object or movie or cogent device;  %SDS  Modality ==1 has been re-assigned to PsychToolBox
            if ob.Status >= 1,
%               set(ob.ControlObjectHandle, 'xdata', ob.XPos, 'ydata', ob.YPos);
%               set(ob.ControlObjectHandle, 'xdata', ob.XPos, 'ydata', ob.YPos, 'markersize', Msize);               %SDS: NB 'markersize' input must be scalar                
                set(ob.ControlObjectHandle, 'xdata', ob.XPos, 'ydata', ob.YPos, 'markersize', ob.Xsize(1)*0.3572);  %SDS: see 'initcontrolscreen' L259 for origin of 0.3572 factor                
            else
                set(ob.ControlObjectHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
            end
        elseif ob.Modality == 4 || ob.Modality == 5, %analog stimulation or TTL
            if ob.Status >= 1,
                set(ob.ControlObjectHandle, 'position', [ob.XPos ob.YPos 0]);
            else
                set(ob.ControlObjectHandle, 'position', [ScreenData.OutOfBounds ScreenData.OutOfBounds 0]);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eventmarker_long(codenumber, varargin)
persistent bitspercode

if codenumber == -1,
    bitspercode = varargin{1};
    return
elseif any(codenumber ~= floor(codenumber)) || any(codenumber <= 0),
    error('Eventmarker value must be a positive integer');
end

vec = dec2binvec(codenumber);
num = ceil(length(vec)/bitspercode);
codelist = zeros(1,num+2);
codelist(1)   = 254;
codelist(end) = 255;
for i = 1:num,
    a = (i-1)*bitspercode + 1;
    b = i*bitspercode;
    if b > length(vec),
        b = length(vec);
    end
    thiscode = false(1,bitspercode);
    thiscode(1:(b-a+1)) = vec(a:b);
    codelist(i+1) = binvec2dec(thiscode);
end
for i = 1:length(codelist),
    eventmarker(codelist(i));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Codes = eventmarker(codenumber, varargin)
persistent numcodes CodeNumbers CodeTimes DaqDIO digoutflag z databits strobebit sbval numdatabits target

tstamp = round(trialtime);

if codenumber == -1, %set trial-start time
    target = 3;
    numcodes = 0;
    maxcodes = 4096;
    CodeNumbers = zeros(maxcodes, 1);
    CodeTimes = CodeNumbers;
    DAQ = varargin{1};
    digoutflag = 0;
    if isfield(DAQ.BehavioralCodes, 'DIO'),
        digoutflag = 1;
        DaqDIO = DAQ.BehavioralCodes.DIO;
        databits = DAQ.BehavioralCodes.DataBits.Index;
        databits = cat(2, databits{:});
        numdatabits = length(databits);
        eventmarker_long(-1,numdatabits);
        strobebit = DAQ.BehavioralCodes.StrobeBit.Index;
        z = zeros(1, numdatabits+1);
        putvalue(DaqDIO, z);
    end
    sbval = DAQ.StrobeBitEdge - 1; %falling edge -> 0 or rising edge -> 1
    return
elseif codenumber == -2, %return codes at end of trial
    Codes.CodeTimes = CodeTimes(1:numcodes);
    Codes.CodeNumbers = CodeNumbers(1:numcodes);
    return
elseif any(codenumber ~= floor(codenumber)),
    error('Eventmarker value must be a positive integer');
elseif strcmpi(codenumber,'default'),
    target = 3;
elseif strcmpi(codenumber,'explicit'),
    target = 0;
elseif strcmpi(codenumber,'bhv'),
    target = 1;
elseif strcmpi(codenumber,'strobe'),
    target = 2;
end

if ~isempty(varargin),
    codeflags = varargin{1};
else
    if target == 0,
        return
    end
    codeflags = 3*ones(1,length(codenumber));
end
if target ~= 0,
    codeflags = bitand(codeflags,target);
end

for i = 1:length(codenumber),
    % Output codenumber on digital port
    if digoutflag && bitand(codeflags(i),2),
        bvec = dec2binvec(codenumber(i), numdatabits);
        if length(bvec) > numdatabits,
            error('Too few digital lines (%i) allocated for event marker value %i', numdatabits, codenumber);
        end
        bvec([databits strobebit]) = [bvec ~sbval];
        putvalue(DaqDIO, bvec);
        bvec(strobebit) = sbval;
        putvalue(DaqDIO, bvec);
    end

    % store codes in array to be saved to disk on local machine
    if bitand(codeflags(i),1),
        numcodes = numcodes + 1;
        CodeNumbers(numcodes) = codenumber;
        CodeTimes(numcodes) = tstamp;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% till line 1224; samples eye position L 991
function [ontarget, rt] = eyejoytrack(fxn1, varargin)
global SIMULATION_MODE
persistent TrialObject DAQ AI ScreenData eTform jTform ControlObject totalsamples ejt_totaltime min_cyclerate...
    joyx joyy eyex eyey joypresent eyepresent mousepresent eyetarget_index eyetarget_record ...                  %SDS added 'mousepresent'
    buttonspresent analogbuttons buttonnumber buttonx buttonsdio ...
    lastframe benchmark benchdata benchcount benchdata2 benchcount2 benchmax win %#ok<PUSE>

t1 = trialtime;
ontarget = 0;
rt = NaN;
                            %SDS 'if' runs till L707
if fxn1 == -1,              %SDS eyejoytrack initialized at L45; eyejoytrack(-1, TaskObject, DaqInfo, ScreenInfo, EyeTransform, JoyTransform);
    ejt_totaltime = 0;
    min_cyclerate = Inf;
    totalsamples = 0;
    lastframe = 0;
    benchmark = 0;
    benchdata = [];
    benchcount = 0;
    benchdata2 = benchdata;
    benchcount2 = benchcount;
    benchmax = 30000;
    TrialObject = varargin{1};
    DAQ = varargin{2};
    AI = [];
    if isempty(DAQ.AnalogInput2),
        if ~isempty(DAQ.AnalogInput),
            AI = DAQ.AnalogInput;
        end
    else
        AI = DAQ.AnalogInput2; %use a second board for on-line sampling (much faster sample updates)
    end
    ScreenData = varargin{3};
    win = ScreenData.Ptr;       %SDS added extra; needed for mouse
    eTform = varargin{4};
    jTform = varargin{5};
	ControlObject.EyeTargetHandle = findobj('tag', 'fixcircle');
	ControlObject.EyeTraceHandle = findobj('tag', 'eyetrace');
    ControlObject.JoyTargetHandle = findobj('tag', 'target');
    ControlObject.JoyTraceHandle = findobj('tag', 'trace');
    ControlObject.ButtonLines = findobj('tag', 'ButtonLine');
    ControlObject.ButtonCircles = findobj('tag', 'ButtonCircle');
    ControlObject.ButtonThresh = findobj('tag', 'ButtonThresh');
    %SDS:  EYELINK/DAQ
%     if isempty(DAQ.EyeSignal),
%         eyex = [];
%         eyey = [];
%         eyepresent = 0;
%     else
%         eyex = DAQ.AnalogInput.EyeX.Index;
%         eyey = DAQ.AnalogInput.EyeY.Index;
%         eyepresent = 1;
%     end
    eyepresent = 1;  %SDS ...make this dependent on some flag from control panel (To Do)
    %SDS:  EYELINK/DAQ_end
    if isempty(DAQ.Joystick),
        joyx = [];
        joyy = [];
        joypresent = 0;
    else
        joyx = DAQ.AnalogInput.JoyX.Index;
        joyy = DAQ.AnalogInput.JoyY.Index;
        joypresent = 1;
    end
    if isempty(DAQ.Buttons),
        buttonx = [];
        buttonspresent = 0;
    else
        buttonspresent = DAQ.Buttons.ButtonsPresent;
        analogbuttons = strcmpi(DAQ.Buttons.Subsystem, 'analog');
        if analogbuttons,
            for i = 1:length(buttonspresent),
                buttonnumber = buttonspresent(i);
                bname = sprintf('Button%i', buttonnumber);
                buttonx(buttonnumber) = DAQ.AnalogInput.(bname).Index;
            end
        else
            buttonsdio = DAQ.Buttons.DIO;
            for i = 1:length(buttonspresent),
                buttonnumber = buttonspresent(i);
                bname = sprintf('Button%i', buttonnumber);
                buttonx(buttonnumber) = buttonsdio.(bname).Index;
            end
        end
    end
    data = [];
    count = 0;
    if joypresent % || eyepresent, %SDS:  EYELINK/DAQ (ignore 'eyepresent' flag)
        while isempty(data) && count < 1000,
            data = getsample(DAQ.AnalogInput);   % SDS  samples DAQ device
            count = count + 1;
        end
        if isempty(data),
            error('*** Unable to acquire data from analog input object ***')
        end
    end
    eyetarget_index = 0;
    eyetarget_record = cell(100, 1);
    mousepresent = 0;                                                            %SDS amend  mouse for joystick [added]
    return
elseif fxn1 == -2, %call from showcursor
    ScreenData.ShowCursor = varargin{1};
    return
elseif fxn1 == -3, %update from reposition_object or set_object_path
    stimnum = varargin{1};
    TrialObject(stimnum) = varargin{2};
    return
elseif fxn1 == -4, %call from end_trial
    if eyetarget_index,
        ontarget = cat(1, eyetarget_record{:});
    else
        ontarget = [];
    end
    if ejt_totaltime,
        rt = [min_cyclerate round(1000*totalsamples/ejt_totaltime)]; %returns the cycle-rate
    else
        rt = 0;
    end
    return
elseif fxn1 == -5, %update from ToggleObject
    TrialObject = varargin{1};
    lastframe = varargin{2};
    return
elseif fxn1 == -6, %benchmarking
    b = varargin{1};
    if b, %turn ON benchmarking & initialize bench arrays
        benchmark = 1;
        benchdata = zeros(benchmax, 1);
        benchcount = 0;
        benchdata2 = benchdata;
        benchcount2 = benchcount;
    else %turn OFF benchmarking
        benchmark = 0;
    end
    ontarget = cell(2, 1); %needed to convert from numeric to cell
    ontarget{1} = benchdata(1:benchcount); %retrieve current benchmark data
    ontarget{2} = benchdata2(1:benchcount2);
    return
elseif fxn1 == -7, %SDS: call from setmouse (timing file command)  SDS: mouse for joystick
    mousepresent = varargin{1};
    joypresent = ~varargin{1}; %SDS: effectively substitutes mouse input for joystick input
    return    
end
      
eyetrack = 0;       %SDS  hereon, functionality for non-initialization calls to eyejoytrack
joytrack = 0;
buttontrack = 0;
eyestatus = 0;
joystatus = 0;
bstatus = 0;
eyefirst = 0;
joyfirst = 0;
%buttonfirst = 0; %only need if can have fxn3... which one can't for now.

idle = 0;  %SDS: (till L841 (+78)) 'single mode' syntax:  [ontarget rt] = eyejoytrack(fxn, object_number, threshold, duration)
if strcmp(fxn1, 'idle'),
    idle = 1;
    if eyepresent %   ~isempty(eyex),  %SDS:  EYELINK/DAQ:  use 'eyepresent' flag rather than 'eyex' DAQ index 
        eyetrack = 1;
    end
    if ~isempty(joyx),
        joytrack = 1;
    end
    maxtime = varargin{1};
else
    tob1 = varargin{1};             %SDS: varargin{1} is trial object number (e.g. fixation_point); can specify multiple objects as targets
    trad1 = varargin{2};            %SDS: varargin{2} is threshold, (e.g. fix_radius)
    if length(trad1) < length(tob1),
        trad1 = trad1 * ones(size(tob1));   %SDS caters for multiple fixation points
    end
    maxtime = varargin{3};          %SDS: varargin{3} is duration, (e.g. wait_for_fix)
    if strcmpi(fxn1, 'acquirefix'),
        eyetrack = 1;
        eyeop = 0; %less than
        eyeobject = TrialObject(tob1);
        eyerad = trad1';
        eyefirst = 1;
        eyeobindex = tob1;
    elseif strcmpi(fxn1, 'holdfix'),
        if length(tob1) > 1,
            error('*** Must specify exactly one object on which to hold fixation ***');
        end
        eyetrack = 1;
        eyeop = 1; %greater than
        eyeobject = TrialObject(tob1);
        eyerad = trad1';
        eyefirst = 1;
        eyeobindex = tob1;
    elseif strcmpi(fxn1, 'acquiretarget'),
        joytrack = 1;
        joyop = 0; %less than
        joyobject = TrialObject(tob1);
        joyrad = trad1';
        joyfirst = 1;
        joyobindex = tob1;
    elseif strcmpi(fxn1, 'holdtarget'),
        if length(tob1) > 1,
            error('*** Must specify exactly one object on which to hold target ***');
        end
        joytrack = 1;
        joyop = 1; %greater than
        joyobject = TrialObject(tob1);
        joyrad = trad1';
        joyfirst = 1;
        joyobindex = tob1;
    elseif strcmpi(fxn1, 'acquiretouch'),
        buttontrack = 1;
        buttonop = 0;
        bthresh = trad1;
        buttonindex = tob1;
    elseif strcmpi(fxn1, 'holdtouch'),
        buttontrack = 1;
        buttonop = 1;
        bthresh = trad1;
        buttonindex = tob1;
    else
        error('Undefined eyejoytrack function "%s".',fxn1);
    end
end

numsigs = 1;        %SDS: (till L942 (+71)) 'dual mode' syntax:   [ontarget rt] = eyejoytrack(fxn1, object1_number, threshold1, fxn2, object2_number, threshold2 , duration)
if length(varargin) > 3,
    numsigs = 2;
    fxn2 = maxtime;     %SDS i.e. varargin{3} from L793, hence fxn2 which is one of 'acquirefix', 'holdfix', 'acquiretarget'  etc
    tob2 = varargin{4};
    trad2 = varargin{5};
    if length(trad2) < length(tob2),
        trad2 = trad2 * ones(size(tob2));
    end
    maxtime = varargin{6};
    if strcmpi(fxn2, 'acquirefix'),
        if eyetrack,
            error('*** Eye tracking criteria double-set in one "eyejoytrack" command ***');
        end
        eyetrack = 1;
        eyeop = 0; %less than
        eyeobject = TrialObject(tob2);
        eyerad = trad2';
        eyeobindex = tob2;
    elseif strcmpi(fxn2, 'holdfix'),
        if eyetrack,
            error('*** Eye tracking criteria double-set in one "eyejoytrack" command ***');
        end
        if length(tob2) > 1,
            error('*** Must specify exactly one object on which to hold fixation ***');
        end
        eyetrack = 1;
        eyeop = 1; %greater than
        eyeobject = TrialObject(tob2);
        eyerad = trad2';
        eyeobindex = tob2;
    elseif strcmpi(fxn2, 'acquiretarget'),
        if joytrack,
            error('*** Joystick tracking criteria double-set in one "eyejoytrack" command ***');
        end
        joytrack = 1;
        joyop = 0; %less than
        joyobject = TrialObject(tob2);
        joyrad = trad2';
        joyobindex = tob2;
    elseif strcmpi(fxn2, 'holdtarget'),
        if joytrack,
            error('*** Joystick tracking criteria double-set in one "eyejoytrack" command ***');
        end
        if length(tob2) > 1,
            error('*** Must specify exactly one object on which to hold target ***');
        end
        joytrack = 1;
        joyop = 1; %greater than
        joyobject = TrialObject(tob2);
        joyrad = trad2';
        joyobindex = tob2;
    elseif strcmpi(fxn2, 'acquiretouch'),
        if buttontrack,
            error('*** Button tracking criteria double-set in one "eyejoytrack" command ***');
        end
        buttontrack = 1;
        buttonop = 0;
        bthresh = trad2;
        buttonindex = tob2;
    elseif strcmpi(fxn2, 'holdtouch'),
        if buttontrack,
            error('*** Button tracking criteria double-set in one "eyejoytrack" command ***');
        end
        buttontrack = 1;
        buttonop = 1;
        bthresh = trad2;
        buttonindex = tob2;
    else
        error('Undefined eyejoytrack function "%s".',fxn2);
    end
end

% make certain requested inputs are present
if eyetrack && ~eyepresent,
    error('*** No eye-signal inputs defined in I/O menu ***');
end
if joytrack && ~joypresent && ~mousepresent,    %SDS amend: mouse for joystick
    error('*** No joystick inputs defined in I/O menu OR, timingfile lacks "setmouse" command ***');
end
if buttontrack,
    if ~any(buttonspresent),
        error('*** No buttons defined in I/O menu ***');
    end
    if min(buttonindex) < 1 || any(floor(buttonindex) ~= buttonindex),
        error('*** Buttons must be referenced by positive integers ***');
    end
    if max(buttonindex) > length(buttonx) || any(buttonx(buttonindex) == 0),
        error('*** At least one requested Button has not been assigned to a DAQ object ***');
    end
end

%Check to see if intermittent video updates are required...
% moviesplaying = any(cat(1, TrialObject.Status) & cat(1, TrialObject.Modality) == 2); %SDS  any non-zero value in TO.Status AND one value in TO.Modality ==2
moviesplaying = 0;  %SDS QUERY temporary fix; this allows control screen updates at all times - requires further testing...
psyboxplaying = any(cat(1, TrialObject.Status) & cat(1, TrialObject.Modality) == 1); %SDS  ADDED EXTRA LINE  NB Modality ==1 is reassigned to PsychToolBox
yesshowcursor = (eyetrack || joytrack) && ScreenData.ShowCursor;					 %SDS  AMEND	(eyetrack || ...)
if psyboxplaying || yesshowcursor % || moviesplaying                                 %SDS  AMEND || psyboxplaying
    videoupdates = 1;
    drawnowok = 0;
else
    videoupdates = 0;
    drawnowok = 1;
end

%create button indicators
if any(buttonspresent),
    numbuttons = length(buttonspresent);
    degsep = 2;
    bindx = (2:degsep:degsep*numbuttons) - numbuttons - 1;
    bscreenlims = get(ControlObject.ButtonLines(1), 'ydata');
    bscreenmin = min(bscreenlims);
    bscreenmax = max(bscreenlims);
    bscreenrange = bscreenmax - bscreenmin;
    if analogbuttons,
        bvalscale = AI.Channel.InputRange(1);
    else
        bvalscale = [0 1];
    end
    bvalmin = min(bvalscale);
    bvalrange = max(bvalscale) - bvalmin;
    buttonhandle = zeros(max(buttonspresent), 1);
    for i = 1:numbuttons,
        buttonnumber = buttonspresent(i);
        set(ControlObject.ButtonLines(i), 'xdata', [bindx(i) bindx(i)]);
        buttonhandle(buttonnumber) = ControlObject.ButtonCircles(i);
        set(buttonhandle(buttonnumber), 'xdata', bindx(i), 'ydata', bscreenmin+mean(bscreenrange));
    end
end

%set targets
eye_position(-4,NaN,NaN);  %SDS: persistent variables 'exTarget' & 'eyTarget' in "eye_position" subroutine set to NaN
if ~idle,
    if eyetrack,
        numeyeobjects = length(eyeobject);
        eyestatus = 0;
        ex = {eyeobject.XPos}';  %NB curly brackets: cell array
        ey = {eyeobject.YPos}';
        eyetarget_index = eyetarget_index + 1;
        eyetarget_record{eyetarget_index} = [ex ey];
        esize = num2cell(2*eyerad*ScreenData.PixelsPerDegree*ScreenData.ControlScreenRatio(1)/ScreenData.PixelsPerPoint); %SDS: the size of fixation radius on control screen
        if ~moviesplaying,
            set(ControlObject.EyeTargetHandle(eyeobindex)', {'xdata'}, ex, {'ydata'}, ey, {'markersize'}, esize);
        end
        ex = cat(1, ex{:});  % converts to column vector
        ey = cat(1, ey{:});
        if numeyeobjects > 1 && ~moviesplaying,
            set(ControlObject.EyeTargetHandle(eyeobindex(2:numeyeobjects))', 'markeredgecolor', (ScreenData.EyeTargetColor/2));
        end
        eye_position(-4,ex,ey);  %SDS stores 'ex' & 'ey' as persistent variables 'exTarget' & 'eyTarget' in "eye_position" subroutine
    end
    if joytrack,
        numjoyobjects = length(joyobject);
        joystatus = 0;
        jx = {joyobject.XPos}';
        jy = {joyobject.YPos}';
        jsize = num2cell(2*joyrad*ScreenData.PixelsPerDegree*ScreenData.ControlScreenRatio(1)/ScreenData.PixelsPerPoint);
        if ~moviesplaying,
            set(ControlObject.JoyTargetHandle(joyobindex)', {'xdata'}, jx, {'ydata'}, jy, {'markersize'}, jsize);
        end
        jx = cat(1, jx{:});
        jy = cat(1, jy{:});
        if numjoyobjects > 1 && ~moviesplaying,
            set(ControlObject.JoyTargetHandle(joyobindex(2:numjoyobjects))', 'markeredgecolor', (ScreenData.JoyTargetColor/2));
        end
    end
    if buttontrack,
        if isempty(bthresh),
            if analogbuttons,
                bthresh = 3;
            else
                bthresh = 0.5;
            end
        end
        if length(bthresh) == 1,
            bthresh = ones(numbuttons, 1)*bthresh;
        elseif length(bthresh) > numbuttons,
            error('*** More threshold values supplied than there are buttons available ***')
        end
        if ~moviesplaying,
            for i = 1:numbuttons,
                xpos = bindx(i);
                ypos = (bthresh(i) - bvalmin)/bvalrange;
                ypos = bscreenmin + (ypos*bscreenrange);
                set(ControlObject.ButtonThresh(i), 'xdata', xpos, 'ydata', ypos);
            end
        end
    end
end

tupdate = 0;
userawjoy = ScreenData.UseRawJoySignal;
useraweye = ScreenData.UseRawEyeSignal;

earlybreak = 0;
t2 = trialtime - t1;                %SDS t1 is time at start of currrent call to eyejoytrack

while t2 < maxtime,                 %SDS  'while' runs till 1179
    totalsamples = totalsamples + 1;
    if ~isempty(AI),
        data = getsample(AI);       %SDS samples DAQ device
    end
    if eyepresent,
        if SIMULATION_MODE,
            sim_vals = simulation_positions(0);
            xp_eye = sim_vals(3);
            yp_eye = sim_vals(4);
        else                                         %SDS:  EYELINK/DAQ
            [x,y,pupilsize] = EyeLinkCoordonees(1);                     % samples eye coordinates: data in pixels, i.e. PsychToolBox screen coords
%             xp_eye = data(eyex);                                  %SDS  samples eye x position;  data in degrees, origin at screen centre
%             yp_eye = data(eyey);                                  %SDS  samples eye y position;  data in degrees, origin at screen centre
            x_eye = x.c;                                                   %SDS  eye x position  - data in pixels, i.e. PsychToolBox screen coords
            y_eye = y.c;                                                   %SDS  eye y position  - data in pixels, i.e. PsychToolBox screen coords
            xp_eye = (x_eye - ScreenData.Xsize/2)/ScreenData.PixelsPerDegree;      %SDS:  'xp_eye' data in degrees, origin at screen centre    
            yp_eye = (ScreenData.Ysize/2 - y_eye)/ScreenData.PixelsPerDegree;      %SDS:  'yp_eye' data in degrees, origin at screen centre  
                                                    %SDS:  EYELINK/DAQ_end
            if ~useraweye,
                [xp_eye yp_eye] = tformfwd(eTform, xp_eye, yp_eye);
                [exOff eyOff] = eye_position(-3);   %SDS  retrieve exOff & eyOff  (persistent values held in eye_position subroutine)
                xp_eye = xp_eye + exOff;
                yp_eye = yp_eye + eyOff;
            end 
        end

        if ~idle && eyetrack,
            eye_dist = realsqrt((xp_eye - ex).^2 + (yp_eye - ey).^2);  %SDS - computes distance of eye from target: 'ex' & 'ey' are in degrees, origin at screen centre, as stipulated in conditions file
            if eyeop, %holdfix                                         %SDS  'ex' & 'ey' are single item coordinates in standard monkeylogic, but will be vectors for PTB devices with multiple display item
                eyestatus = eye_dist > eyerad;                         %SDS  'eyestatus' flags target outside threshold; is a logical vector of 1s & 0s  when specifying PTB display with multiple targets 
                eyestatus = ~any(~eyestatus);  %SDS added extra        %SDS  [1 1 0 1]' becomes 0;    [1 1 1 1]'  becomes 1;  0 remains 0;    1 remains 1;            
            else      %acquirefix                                      %SDS  if multiple items nominated as targets, 'ex' & 'ey' are vectors, hence eye_dist is also a vector...
                eyestatus = eye_dist <= eyerad;                        %SDS  'eyestatus' vector lists item(s) inside threshold from eye position i.e. ordinal position within list of specified target objects;
            end
        end
    end
    
    if joypresent,
        if SIMULATION_MODE,
            sim_vals = simulation_positions(0);
            xp_joy = sim_vals(1);
            yp_joy = sim_vals(2);
        else
            xp_joy = data(joyx);   %SDS: samples joystick position; data in degrees, origin at screen centre
            yp_joy = data(joyy);   %SDS: samples joystick position; data in degrees, origin at screen centre
        end

        if ~userawjoy,
            [xp_joy yp_joy] = tformfwd(jTform, xp_joy, yp_joy);
        end
        if ~idle && joytrack,
            joy_dist = realsqrt((xp_joy - jx).^2 + (yp_joy - jy).^2);
            if joyop, %holdtarget
                joystatus = joy_dist > joyrad;
            else %acquiretarget
                joystatus = joy_dist <= joyrad;
            end
        end
    end
    if mousepresent,      %SDS: mouse for joystick...
            [x_mou, y_mou] = GetMouse(win);               %SDS:  'x_mou' & 'y_mou' data in pixels, origin at screen top-left;     
                                                          %SDS:  ..other screen may be to left OR right, hence negative x, or x > screen x size is possible;
                                                          %SDS   ..y is always =>0, but max y can exceed screen y size if  other screen is larger.
            if x_mou > ScreenData.Xsize
                x_mou = ScreenData.Xsize; %SDS: if cursor is offscreen in x axis  draw it at the edge
            elseif x_mou < 0
                x_mou = 0;
            end
            if y_mou > ScreenData.Ysize
                y_mou = ScreenData.Ysize; %SDS: if cursor is below offscreen draw it at the bottom
            end

            xp_mou = (x_mou - ScreenData.Xsize/2)/ScreenData.PixelsPerDegree;      %SDS:  'xp_mou' data in degrees, origin at screen centre    
            yp_mou = (ScreenData.Ysize/2 - y_mou)/ScreenData.PixelsPerDegree;      %SDS:  'yp_mou' data in degrees, origin at screen centre    
            xp_joy = xp_mou;                                                       %SDS:  substitute mouse coordinates for joystick coordinates
            yp_joy = yp_mou;                                                       %SDS:  substitute mouse coordinates for joystick coordinates

        if ~idle && joytrack,
            joy_dist = realsqrt((xp_joy - jx).^2 + (yp_joy - jy).^2); %SDS 'jx' & 'jy' are in degrees, origin at screen centre, as stipulated in conditions file
            if joyop, %holdtarget                        %SDS  'jx' & 'jy' are single item coordinates in standard monkeylogic, but will be vectors for PTB devices with multiple display items
                joystatus = joy_dist > joyrad;           %SDS  'joystatus' flags target outside threshold; is a vector when specifying PTB display with multiple targets
                joystatus = ~any(~joystatus);            %SDS  [1 1 0 1]' becomes 0;    [1 1 1 1]'  becomes 1;  0 remains 0;    1 remains 1;  %SDS added extra 
            else %acquiretarget                          %SDS  if multiple items nominated as targets, 'jx' & 'jy' are vectors, hence joy_dist is also a vector...
                joystatus = joy_dist <= joyrad;          %SDS  'joystatus' vector lists item(s) inside threshold from joy position i.e. ordinal position within list of specified target objects;
            end
        end
    end

    if any(buttonspresent),
        if analogbuttons,
            allbvals = data(buttonx);
        else
            allbvals = getvalue(buttonsdio);
        end
        if ~idle && buttontrack,
            if SIMULATION_MODE,
                sim_vals = simulation_positions(0);
                bval = sim_vals(5);
            else
                if analogbuttons,
                    bval = allbvals(buttonindex);
                else
                    bval = allbvals(buttonx(buttonindex));
                end
            end
            if buttonop, %holdtouch
                bstatus = bval < bthresh;
            else %acquiretouch
                bstatus = bval > bthresh;
            end
        end
    end

    if any(eyestatus) || any(joystatus) || any(bstatus),
        t = trialtime - t1;
        rt = round(t);
        t2 = maxtime;
        if eyetrack,
            etargetnumber = find(eyestatus);
            eyestatus = any(eyestatus);
        end
        if joytrack,
            jtargetnumber = find(joystatus);
            joystatus = any(joystatus);
        end
        if buttontrack,
            btargetnumber = find(bstatus);
            bstatus = any(bstatus);
        end
        if numsigs == 1 && eyetrack,
            ontarget = ~eyeop*etargetnumber;
        elseif numsigs == 1 && joytrack,
            ontarget = ~joyop*jtargetnumber;
        elseif numsigs == 1 && buttontrack,
            ontarget = ~buttonop*btargetnumber;
        elseif numsigs == 2,
            if eyetrack && joytrack,
                if eyestatus && ~joystatus,
                    ontarget = [~eyeop*etargetnumber joyop];
                elseif ~eyestatus && joystatus,
                    ontarget = [eyeop ~joyop*jtargetnumber];
                else %both 
                    ontarget = [~eyeop*etargetnumber ~joyop*jtargetnumber];
                end
                if ~eyefirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            elseif eyetrack && buttontrack,
                if eyestatus && ~bstatus,
                    ontarget = [~eyeop*etargetnumber buttonop];
                elseif ~eyestatus && bstatus,
                    ontarget = [eyeop ~buttonop*btargetnumber];
                else %both
                    ontarget = [~eyeop*etargetnumber ~buttonop*btargetnumber];
                end
                if ~eyefirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            elseif joytrack && buttontrack, %seems strange a task would need this, but you never know...
                if joystatus && ~bstatus,
                    ontarget = [~joyop*etargetnumber buttonop];
                elseif ~joystatus && bstatus,
                    ontarget = [joyop ~buttonop*btargetnumber];
                else %both
                    ontarget = [~joyop*etargetnumber ~buttonop*btargetnumber];
                end
                if ~joyfirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            end
        end
        earlybreak = 1;
    else
        [t currentframe] = trialtime;
        if benchmark,
            benchcount = benchcount + 1;
            benchdata(benchcount) = t;
            if videoupdates && currentframe > lastframe,
                benchcount2 = benchcount2 + 1;
                benchdata2(benchcount2) = t;
            end
        end
        if videoupdates % && currentframe > lastframe,      %SDS AMEND - current frame increment is checked within 'toggleobject', so not needed here
            if yesshowcursor,
                if joypresent     %SDS amend  mouse for joystick
%                   cxpos = floor(ScreenData.Half_xs + (ScreenData.PixelsPerDegree*xp_joy) - (ScreenData.CursorXsize/2)); %SDS coords in pixels, adjsuted for XGL screens..
%                   cypos = floor(ScreenData.Half_ys - (ScreenData.PixelsPerDegree*yp_joy) - (ScreenData.CursorYsize/2)); %SDS ... XGL screen origin top left, all positive
                                            %SDS: the screen cursor correction implies that the position reference for XGL refers to the top-left corner of the item being drawn.
                    cxpos = floor(ScreenData.Half_xs + ScreenData.PixelsPerDegree*xp_joy);  %SDS: PTB coordinate origin is screen top left; % SD.Half_xs is SD.Xsize/2, set in mlogic main routine L420
                    cypos = floor(ScreenData.Half_ys - ScreenData.PixelsPerDegree*yp_joy);  %SDS: PTB coordinate origin is screen top left; % SD.Half_ys is SD.Ysize/2, set in mlogic main routine L421
                elseif mousepresent                                     %SDS amend  mouse for joystick [added]
                    cxpos = floor(x_mou); %SDS: coords in pixels        %SDS amend  mouse for joystick [added]
                    cypos = floor(y_mou); %SDS: coords in pixels        %SDS amend  mouse for joystick [added]
                elseif eyepresent                                       %SDS:  EYELINK/DAQ [added]
                    cxpos = floor(x_eye); %SDS: coords in pixels        %SDS:  EYELINK/DAQ [added]
                    cypos = floor(y_eye); %SDS: coords in pixels        %SDS:  EYELINK/DAQ [added]
                end
                [tflip lastframe] = toggleobject(-4, [cxpos cypos]); 
%                 [tflip lastframe] = toggleobject(-4, [1000 777]); %SDS amend just to test (Screen Coords: origin top left, all positive (just like PsychToolBox))
            else
                [tflip lastframe] = toggleobject(-4);   %SDS  calls toggle to advance one frame
            end
            drawnowok = 1; %can only update the control screen if just completed a video update (should still have enough time before the next flip)
        end
        dt = (t - t1) - t2;
        this_cyclerate = round(1000/dt);
        min_cyclerate = min(min_cyclerate,this_cyclerate);
        t2 = t - t1;
        if t2 > tupdate && drawnowok, %control screen updates are always required, but need not occur every frame
            if eyepresent,
                set(ControlObject.EyeTraceHandle, 'xdata', xp_eye, 'ydata', yp_eye);
            end
            if joypresent,
                set(ControlObject.JoyTraceHandle, 'xdata', xp_joy, 'ydata', yp_joy);
            end
            if mousepresent,        %SDS AMEND mouse for joystick
                set(ControlObject.JoyTraceHandle, 'xdata', xp_mou, 'ydata', yp_mou);
            end
            if any(buttonspresent),
                for i = 1:numbuttons,
                    buttonnumber = buttonspresent(i);
                    if SIMULATION_MODE,
                        sim_vals = simulation_positions(0);
                        bval = sim_vals(5);
                        if bval >= 0,
                            by = 1;
                        else
                            by = 0;
                        end
                    else
                        by = (allbvals(i) - bvalmin)/bvalrange;
                    end
                    by = bscreenmin + (by*bscreenrange);
                    set(ControlObject.ButtonCircles(buttonnumber), 'ydata', by);
                end
            end
            tupdate = t2+ScreenData.UpdateInterval;
            drawnow;    %SDS drawnow causes figure windows and their children to update 
            if videoupdates,
                drawnowok = 0;
            end
            kb = mlkbd('getkey');
            if ~isempty(kb),
                hotkey(kb);
            end
        end
    end
end

if ~earlybreak && ~idle,
    if numsigs == 1,
        if eyetrack,
            ontarget = eyeop*find(~eyestatus);
        elseif joytrack,
            ontarget = joyop*find(~joystatus);
        elseif buttontrack,
            ontarget = buttonop*find(~bstatus);
        end
    else %numsigs == 2
        if eyetrack && joytrack,
            if eyefirst,
                ontarget = [eyeop*find(~eyestatus) joyop*find(~joystatus)];
            else
                ontarget = [joyop*find(~joystatus) eyeop*find(~eyestatus)];
            end
        elseif eyetrack && buttontrack,
            if eyefirst,
                ontarget = [eyeop*find(~eyestatus) buttonop*find(~bstatus)];
            else
                ontarget = [buttonop*find(~bstatus) eyeop*find(~eyestatus)];
            end
        elseif joytrack && buttontrack,
            if joyfirst,
                ontarget = [joyop*find(~joystatus) buttonop*find(~bstatus)];
            else
                ontarget = [buttonop*find(~bstatus) joyop*find(~joystatus)];
            end
        end
    end
end

set(ControlObject.EyeTargetHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
set(ControlObject.JoyTargetHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
if eyetrack && ~idle && numeyeobjects > 1,
    set(ControlObject.EyeTargetHandle(eyeobindex(2:numeyeobjects)), 'markeredgecolor', ScreenData.EyeTargetColor);
end
if joytrack && ~idle && numjoyobjects > 1,
    set(ControlObject.JoyTargetHandle(joyobindex(2:numjoyobjects)), 'markeredgecolor', ScreenData.JoyTargetColor);
end
if isnan(rt),
    ejt_totaltime = ejt_totaltime + maxtime;
else
    ejt_totaltime = ejt_totaltime + rt;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [jx, jy] = joystick_position(varargin)
persistent DAQ AI ScreenData joyx joyy jTform cxpos_last cypos_last last_jtrace_update ControlObject

t1 = trialtime;

if ~isempty(varargin) && varargin{1} == -1,
    DAQ = varargin{2};
    AI = [];
    if isempty(DAQ.AnalogInput),
        return
    end
    if isempty(DAQ.AnalogInput2),
        AI = DAQ.AnalogInput;
    else
        AI = DAQ.AnalogInput2; %use a second board for on-line sampling (much faster sample updates)
    end
    ScreenData = varargin{3};
    jTform = varargin{4};
    ControlObject.JoyTraceHandle = findobj('tag', 'trace');
    if isempty(DAQ.Joystick),
        joyx = [];
        joyy = [];
    else
        joyx = DAQ.Joystick.XChannelIndex;
        joyy = DAQ.Joystick.YChannelIndex;
    end
    cxpos_last = NaN;
    cypos_last = NaN;
    last_jtrace_update = t1;
    return
end

if isempty(AI),
    error('*** No analog inputs defined for joystick signal acquisition ***')
end

data = getsample(AI);
jx = data(joyx);    %SDS:  reads joystick position
jy = data(joyy);
if ~ScreenData.UseRawJoySignal,
    [jx jy] = tformfwd(jTform, jx, jy);
end

if (t1 - last_jtrace_update) > ScreenData.UpdateInterval,
    set(ControlObject.JoyTraceHandle, 'xdata', jx, 'ydata', jy);
    if ScreenData.ShowCursor,
        if ~isnan(cxpos_last),
% SDS X_MLVIDEO
%            mlvideo('blit', ScreenData.Device, ScreenData.CursorBlankBuffer, cxpos_last, cypos_last, ScreenData.CursorXsize, ScreenData.CursorYsize);
        end
        cxpos = floor((ScreenData.Xsize/2) + (ScreenData.PixelsPerDegree*xp));
        cypos = floor((ScreenData.Ysize/2) - (ScreenData.PixelsPerDegree*yp));
%        mlvideo('blit', ScreenData.Device, ScreenData.CursorBuffer, cxpos, cypos, ScreenData.CursorXsize, ScreenData.CursorYsize);
%        mlvideo('flip', ScreenData.Device);  %SDS:  displays joystick cursor
        cxpos_last = cxpos;
        cypos_last = cypos;
    end
    drawnow;
    last_jtrace_update = trialtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SDS   initialized L48 (-1)   called from: L86 [hotkey 'c'] (-2) ;  L1002 (-4); L1002 (-4); L1091 (-3)
function [ex, ey] = eye_position(varargin)
persistent DAQ AI ScreenData eyex eyey eTform exOff eyOff exTarget eyTarget last_etrace_update ControlObject

t1 = trialtime;

if ~isempty(varargin), 
    if varargin{1} == -1,                %SDS on initialization (L48): eye_position(-1, DaqInfo, ScreenInfo, EyeTransform);
        DAQ = varargin{2};
        AI = [];
        if isempty(DAQ.AnalogInput),
            return
        end
        if isempty(DAQ.AnalogInput2),
            AI = DAQ.AnalogInput;
        else
            AI = DAQ.AnalogInput2;
        end
        ScreenData = varargin{3};
        eTform = varargin{4};
        exOff = 0;
        eyOff = 0;
        exTarget = 0;
        eyTarget = 0;
        ControlObject.EyeTraceHandle = findobj('tag', 'eyetrace');
        if isempty(DAQ.EyeSignal),
            eyex = [];
            eyey = [];
        else
            eyex = DAQ.EyeSignal.XChannelIndex;
            eyey = DAQ.EyeSignal.YChannelIndex;
        end
        last_etrace_update = t1;
        return
    elseif varargin{1} == -2,       %SDS  called by hotkey 'c'  (L86)  
        if isnan(exTarget) || isnan(eyTarget),
            return
        end
        [ex ey] = eye_position;     % SDS  - the routine calls itself (no args) - control passes to L1483 (+15)
        exOff = exOff - ex + exTarget;  %  - adds to exOff the difference between current eye x position and exTarget
        eyOff = eyOff - ey + eyTarget;  %  - adds to eyOff the difference between current eye y position and eyTarget
        return
    elseif varargin{1} == -3,       % SDS called by L995 in  'eyejoytrack'
        ex = exOff;
        ey = eyOff;
        return
    elseif varargin{1} == -4,       %SDS: stores coordinates of target items (degrees, origin = screen centre)
        exTarget = varargin{2};     %SDS 'exTarget' is only used by mode -2, a special 'hotkey' function
        eyTarget = varargin{3};     %SDS 'eyTarget' ditto...
        return
    end
end
              %SDS - this section of code only activated by L1327 above
if isempty(AI),
    error('*** No analog inputs defined for eye-signal acquisition ***')
end
%SDS:  EYELINK/DAQ
% data = getsample(AI);
% ex = data(eyex);    %SDS samples eye x position
% ey = data(eyey);    %SDS samples eye y position      
[x,y,pupilsize] = EyeLinkCoordonees(1);                     % samples eye coordinates: data in pixels, i.e. PsychToolBox screen coords
x_eye = x.c;                                                   %SDS  eye x position  - data in pixels, i.e. PsychToolBox screen coords
y_eye = y.c;                                                   %SDS  eye y position  - data in pixels, i.e. PsychToolBox screen coords
xp_eye = (x_eye - ScreenData.Xsize/2)/ScreenData.PixelsPerDegree;      %SDS:  'xp_eye' data in degrees, origin at screen centre    
yp_eye = (ScreenData.Ysize/2 - y_eye)/ScreenData.PixelsPerDegree;      %SDS:  'yp_eye' data in degrees, origin at screen centre  
%SDS:  EYELINK/DAQ_end
% if ~ScreenData.UseRawEyeSignal,
%     [ex ey] = tformfwd(eTform, ex, ey);
%     ex = ex + exOff;
%     ey = ey + eyOff;
% end

if (t1 - last_etrace_update) > ScreenData.UpdateInterval,
    set(ControlObject.EyeTraceHandle, 'xdata', ex, 'ydata', ey);
    drawnow;
    last_etrace_update = trialtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [adata, frq] = get_analog_data(sig, varargin)
persistent DAQ eTform jTform aipresent

if sig == -1,
    DAQ = varargin{1};
    if isempty(DAQ.AnalogInput),
        aipresent = 0;
    else
        aipresent = 1;
    end
    eTform = varargin{2};
    jTform = varargin{3};
    adata = [];
    frq = [];
    return
end

if ~aipresent,
    adata = [];
    frq = 0;
    disp('Warning: No analog inputs present for call to "get_analog_data"');
    return
end

try
    isch = ischannel(DAQ.AnalogInput.(sig));
catch ME
    isch = 0;
end
if ~isch,
    fprintf(getReport(ME));
    error('Signal "%s" not found during call to "get_analog_data"', sig);
end

if isempty(varargin),
    numsamples = 1;
else
    numsamples = varargin{1};
end
aisample = peekdata(DAQ.AnalogInput, numsamples);

if strcmpi(sig(1:3), 'eye'),
    x = aisample(:, DAQ.EyeSignal.XChannelIndex);
    y = aisample(:, DAQ.EyeSignal.YChannelIndex);
    [x y] = tformfwd(eTform, x, y);
    adata = [x y];
elseif strcmpi(sig(1:3), 'joy'),
    x = aisample(:, DAQ.Joystick.XChannelIndex);
    y = aisample(:, DAQ.Joystick.YChannelIndex);
    [x y] = tformfwd(jTform, x, y);
    adata = [x y];
else
    chindex = DAQ.AnalogInput.(sig).Index;
    adata = aisample(:, chindex);
end
frq = DAQ.AnalogInput.SampleRate;

function val = simulation_positions(action, varargin)
persistent sim_vals %joyx joyy eyex eyey bval

if action == -1,
    sim_vals = zeros(1,5);
    sim_vals(5) = -Inf;
    val = 1;
    return
end

if action == 0,
    val = sim_vals;
    return
end

if action == 1,
    which_val = varargin{1};
    delta_val = varargin{2};
    sim_vals(which_val) = sim_vals(which_val) + delta_val;
    val = sim_vals;
    return
end

if action == 2,
    which_val = varargin{1};
    setto_val = varargin{2};
    sim_vals(which_val) = setto_val;
    val = sim_vals;
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function idle(duration, varargin)
persistent ScreenData

if duration == -1,
    ScreenData = varargin{1};
    return
end

colorflag = 0;
if ~isempty(varargin),
    colorflag = 1;
    color = varargin{1};
    if length(color) ~= 3,
        error('*** Unable to parse passed color values in trial subfunction: "idle" ***')
    end
    if max(color) > 1,
        color = color / max(color);
    end
% SDS X_MLVIDEO
%     mlvideo('clear', ScreenData.Device, color);
%     mlvideo('flip', ScreenData.Device);
%     cgpencol(color(1), color(2), color(3))
%     cgrect
%     cgflip
Screen('Flip', ScreenData.Ptr)
% SDS X_MLVIDEO_end
end

eyejoytrack('idle', duration);

if colorflag == 1,
% SDS X_MLVIDEO
%     mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);
%     mlvideo('flip', ScreenData.Device);
%     BC = ScreenData.BackgroundColor;
%     cgpencol(BC(1), BC(2), BC(3))
%     cgrect
%     cgflip
Screen('Flip', ScreenData.Ptr)
% SDS X_MLVIDEO_end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [scancode, rt] = getkeypress(maxtime, varargin)
persistent ScreenData

if maxtime == -1,
    ScreenData = varargin{1};
    return
end

t1 = trialtime;
t2 = 0;

rt = NaN;
scancode = [];

if ScreenData.Priority > 1,
    prtnormal;
end
while t2 < maxtime,
    scancode = mlkbd('getkey');
    t2 = trialtime - t1;
    if ~isempty(scancode),
        rt = t2;
        t2 = maxtime;
    end
end
if ScreenData.Priority == 2,
    prthigh;
elseif ScreenData.Priority == 3,
    prtrealtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = goodmonkey(duration, varargin)
persistent DAQ rewardtype reward_on reward_off noreward rewardsgiven rewardstart rewardend reward_dur rewardpolarity rewardindex

if duration == -1,
    DAQ = varargin{1};
    noreward = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
    loadbutton = findobj('tag', 'loadbutton');
    VV = get(loadbutton, 'userdata');
    reward_dur = VV.reward_dur;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(DAQ.Reward),
        noreward = 1;
    elseif strcmpi(DAQ.Reward.Subsystem, 'analog'),
        rewardtype = 1;
        ao_channels = DAQ.AnalogOutput.Channel.Index;
        reward_off = zeros(size(ao_channels))';
        rewardindex = DAQ.Reward.ChannelIndex;
        reward_on = reward_off;
        rewardpolarity = DAQ.Reward.Polarity > 0;
        reward_on(rewardindex) = DAQ.Reward.TriggerValue*rewardpolarity;
        reward_off(rewardindex) = DAQ.Reward.TriggerValue*(~rewardpolarity);
    else %digital
        rewardtype = 2;
        reward_on = DAQ.Reward.Polarity;
        reward_off = ~DAQ.Reward.Polarity;
    end
    rewardsgiven = 0;
    rewardstart = [];
    rewardend = [];
    return
elseif duration == -2, %init
    if noreward,
        return %this way no warning message given
    end
    duration = 1;
elseif duration == -3, %retrieve data at end-of-trial
    if ~rewardsgiven,
        RewardRecord = [];
    else
        RewardRecord.StartTimes = round(rewardstart);
        RewardRecord.EndTimes = round(rewardend);
    end
    varargout = {RewardRecord};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
    loadbutton = findobj('tag', 'loadbutton');
    VV = get(loadbutton, 'userdata');
    VV.reward_dur = reward_dur;
    set(findobj('tag', 'loadbutton'), 'userdata', VV);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
elseif duration == -4,
    diff = varargin{1};
    reward_dur = reward_dur + diff;
    return
elseif ischar(duration),
    if strcmpi(duration,'user'),
        duration = reward_dur;
    else
        dnum = str2double(duration);
        if isempty(dnum),
            error('Unable to parse string "%s" as argument to goodmonkey.  Acceptable values are positive numbers or "user".',duration);
        else
            duration = dnum;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if noreward,
    disp('WARNING: *** No reward output defined ***')
    return
end

if isempty(varargin),
    numreward = 1;
    pausetime = 0;
else
    numreward = 1;
    pausetime = 0;
    for i = 1:2:length(varargin)
        switch(varargin{i})
            case 'num_reward'
                numreward = varargin{i+1};
                pausetime = 40;
            case 'pause_time'
                pausetime = varargin{i+1};
            case 'trigger_val'
                triggerval = varargin{i+1};
            otherwise
                error('Unrecognized parameter passed to goodmonkey: valid parameters are ''num_reward'', ''pause_time'' and ''trigger_val''');
        end
    end
    reward_on(rewardindex) = triggerval*rewardpolarity;
    reward_off(rewardindex) = triggerval*~rewardpolarity;
end

for i = 1:numreward,
    rewardsgiven = rewardsgiven + 1;
    t1 = trialtime;
    t2 = 0;
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_on);
    else
        putvalue(DAQ.Reward.DIO, reward_on);
    end
    while t2 < duration,
        t2 = trialtime - t1;
    end
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_off); 
    else
        putvalue(DAQ.Reward.DIO, reward_off); 
    end
    rewardend(rewardsgiven) = trialtime;
    rewardstart(rewardsgiven) = t1;
    if i < numreward, %add gaps only between rewards
        t1 = trialtime;
        t2 = 0;
        while t2 < pausetime
            t2 = trialtime - t1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function success = set_frame_order(stimnum, frameorder, varargin)
persistent TrialObject

if stimnum == -1,
    TrialObject = frameorder;
    success = [];
    return
end

if TrialObject(stimnum).Modality ~= 2,
    error('set_frame_order can only be used with ''Movie'' objects');
elseif ~isnumeric(frameorder),
    error('Frame order arguments to set_frame_order must be numeric');
elseif min(size(frameorder)) > 1 || ndims(frameorder) > 2,
    error('Frame order arguments for set_frame_order must be vectors');
end

TO = TrialObject(stimnum);

if ~isempty(varargin),
    if length(varargin) ~= 2,
        error('set_frame_order accepts only 2 or 4 arguments');
    end
    frame_list = varargin{1};
    em_list = varargin{2};
    if length(frame_list) ~= length(em_list),
        error('Frame-triggered event marker arguments must be of equal length');
    elseif ~isnumeric(frame_list) || ~isnumeric(em_list),
        error('Frame-triggered event marker arguments must be numeric');
    elseif min(size(frame_list)) > 1 || ndims(frame_list) > 2 || min(size(em_list)) > 1 || ndims(em_list) > 2,
        error('Frame-triggered event marker arguments must be vectors');
    end
    TO.FrameEvents = cat(1,frame_list,em_list);
end

TO.FrameOrder = frameorder;

toggleobject(-3, stimnum, TO, 0);
eyejoytrack(-3, stimnum, TO);
TrialObject(stimnum) = TO;
success = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function translate_success = set_object_path(stimnum, xpath, ypath)
persistent ScreenData TrialObject

if stimnum == -1,
    TrialObject = xpath;
    ScreenData = ypath;
    translate_success = [];
    return
end

if ~isnumeric(xpath) || ~isnumeric(ypath),
    error('path arguments to set_object_path must be numeric vectors');
elseif min(size(xpath)) > 1 || ndims(ypath) > 2,
    error('x- and y- path arguments for set_object_path must be vectors');
elseif length(xpath) ~= length(ypath),
    error('x- and y- path vectors for set_object_path must be equal in size');
elseif isempty(TrialObject(stimnum).XPos),
    user_warning('Cannot set_object_path for object #%i.', stimnum)
    translate_success = 0;
    return
end

TO = TrialObject(stimnum);

xpos_bak = TO.XPos;
ypos_bak = TO.YPos;
xspos_bak = TO.XsPos;
yspos_bak = TO.YsPos;

TO.XPos = xpath;
TO.YPos = ypath;
hxs = round(ScreenData.Xsize/2);
hys = round(ScreenData.Ysize/2);
xoffset = round(TO.Xsize)/2;
yoffset = round(TO.Ysize)/2;
TO.XsPos = hxs + round(ScreenData.PixelsPerDegree * xpath) - xoffset;
TO.YsPos = hys - round(ScreenData.PixelsPerDegree * ypath) - yoffset; %invert so that positive y is above the horizon

if TO.XsPos + TO.Xsize > ScreenData.Xsize || TO.YsPos + TO.Ysize > ScreenData.Ysize || TO.XsPos < 1 || TO.YsPos < 1,
    TO.XPos = xpos_bak;
    TO.YPos = ypos_bak;
    TO.XsPos = xspos_bak;
    TO.YsPos = yspos_bak;
    translate_success = 0;
    user_warning('Attempt set path for object #%i failed. Target outside screen boundary.', stimnum);
else
    TO.StartPosition = 1;
    TO.CurrentPosition = 1;
    TO.NumPositions = length(xpath);
    if TO.Modality == 1,                %SDS ALARM:     whatever this does to old modality 1 (static visual objects) - is no longer appropriate !
        TO.Class = 'Movie';
        TO.Modality = 2; % set to "movie"
        TO.StartFrame = 1;
        TO.NumFrames = 1;
    end
    toggleobject(-3, stimnum, TO, 0);
    eyejoytrack(-3, stimnum, TO);
    TrialObject(stimnum) = TO;
    translate_success = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function repos_success = reposition_object(stimnum, xnew, ynew)
persistent ScreenData TrialObject

if stimnum == -1,
    TrialObject = xnew;
    ScreenData = ynew;
    repos_success = [];
    return
end

if length(stimnum) > 1,
    error('The function "reposition_object" is not vectorized (accepts only scalar inputs)');
end

TO = TrialObject(stimnum);
if ~isempty(TrialObject(stimnum).XPos),
    
    xpos_bak = TO.XPos;
    ypos_bak = TO.YPos;
    xspos_bak = TO.XsPos;
    yspos_bak = TO.YsPos;
    
    TO.XPos = xnew;
    TO.YPos = ynew;
    hxs = round(ScreenData.Xsize/2);
    hys = round(ScreenData.Ysize/2);
    xoffset = round(TO.Xsize)/2;
    yoffset = round(TO.Ysize)/2;
    TO.XsPos = hxs + round(ScreenData.PixelsPerDegree * xnew) - xoffset;
    TO.YsPos = hys - round(ScreenData.PixelsPerDegree * ynew) - yoffset; %invert so that positive y is above the horizon

    if TO.XsPos + TO.Xsize > ScreenData.Xsize || TO.YsPos + TO.Ysize > ScreenData.Ysize || TO.XsPos < 1 || TO.YsPos < 1,
        TO.XPos = xpos_bak;
        TO.YPos = ypos_bak;
        TO.XsPos = xspos_bak;
        TO.YsPos = yspos_bak;
        repos_success = 0;
        user_warning('Attempt reposition object #%i failed. Target outside screen boundary.', stimnum);
    else
        toggleobject(-3, stimnum, TO, 1);
        eyejoytrack(-3, stimnum, TO);
        TrialObject(stimnum) = TO;
        repos_success = 1;
    end

else
    user_warning('Cannot reposition object #%i.', stimnum);
    repos_success = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [t, f] = trialtime(varargin)
persistent k abs_tstart frame_length frame_offset

% SDS:  not sure why the strategy is to start tic at an indeterminate time
% before screen retrace, measure this time as 'frame_offset', and take
% account of it in calculating current frame number (i.e. deliverable 'f').
% Why not just start tic directly after flip command...?
% Have left it as it is for now.

if ~isempty(varargin),
    var = varargin{1};
    if var == -1,
        tic;
        abs_tstart = clock; %absolute time of trial start for fMRI tasks
        k = 1000;
        ScreenData = varargin{2};
% SDS X_MLVIDEO 
%         while mlvideo('verticalblank', ScreenData.Device), end
%         while ~mlvideo('verticalblank', ScreenData.Device), end
%         cgflip('v')  % SDS - Cogent command: is this exactly equivalent...?
        win = ScreenData.Ptr;
        vbl = Screen('Flip', win, [],[],[],[]);
%  VBLTimestamp = Screen('Flip', windowPtr [, when] [, dontclear] [, dontsync] [, multiflip]);
% [when] specifies when to flip: If set to zero (default), it will flip on the next possible retrace;
% [dontclear] default is zero, which will clear the framebuffer to background color after each flip;
% [dontsync] if set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs executionuntil the Flip has happened;
% [multiflip] defaults to zero; if set to a value greater than zero, Flip will flip *all* onscreen windows instead of just the specified one.
% SDS X_MLVIDEO_end   
        frame_offset = k*toc; %SDS: partial frame time elapsed since tic; milliseconds
%WA: t = 0 should be nearly aligned with DAQ "isrunning" upon entry to this initialization
%WA: t = frame_offset should align with the start of the vertical blank
        frame_length = ScreenData.FrameLength;
        fprintf('\n frame_offset = %6.4g  frame_length = %6.4g \n', frame_offset, frame_length)   % SDS temp
        return
    elseif var == -2,
        t = abs_tstart;
        return
    end
end

t = k*toc;
f = floor((t-frame_offset)/frame_length);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iti = set_iti(t)
persistent time

if t==-1,
    time = -1;
    iti = -1;
elseif t==-2,
    iti = time;
else
    time = t;
    iti = -1;
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showcursor(cflag, varargin)
% syntax: showcursor('on')  OR showcursor(1)
% syntax: showcursor('off') OR showcursor(0)

persistent ScreenData       %SDS: - why store all of screendata when only one value - buffer pages - is needed here..?

if cflag == -1,
    ScreenData = varargin{1};
    return
end

if ischar(cflag),
    cflag = strcmpi(cflag, 'on');
else
    cflag = cflag > 0;
end

for i = 1:ScreenData.BufferPages-1,      %SDS: buffer pages normally ==2; curious that more than one call to toggleobject could be required..
    toggleobject(0, 'drawmode', 'fast'); %WA: redraws existing stimuli to avoid re-activating extinguished ones
end                                      %      ...SDS: sets 'fastdraw' flag in toggle object ==1; this makes toggleobject draw to subject screen but not control screen;

eyejoytrack(-2, cflag);                  %SDS: puts value of cflag into ScreenData.Showcursor persisting within 'eyejoytrack' subroutine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setmouse(mflag, varargin)   %SDS amend  mouse for joystick [added]
% syntax: setmouse('on')   OR setmouse(1)
% syntax: setmouse('off')  OR setmouse(0)

% NB Ignore MATLAB warning "the function 'setmouse' may be unused"
% ...this is a consequence of trialholder not being the full program;
% ... the call to setmouse is provided by the inserted timing file code.

if ischar(mflag),
    mflag = strcmpi(mflag, 'on');   %SDS: sets cflag ==1  (or ==0, if 'off')
else
    mflag = mflag > 0;              %SDS: sets cflag ==1  (or ==0, if 0)
end

if mflag %  mouse on
    thisfig = get(0,'CurrentFigure');                  %SDS:  this set of commands renders the mouse cursor invisible..
    if ~isempty(thisfig)                             %        
%         set(thisfig,'PointerShapeCData',nan(16));    %        ...but not working as expected               
%         set(thisfig,'Pointer','custom');             %        ...but not working as expected
%        HideCursor                                     % PTB command; hide standard cursor here, and issue draw command for custom cursor in 'toggleobject' 
    end                                              %        
    
    dirs = getpref('MonkeyLogic', 'Directories');                                 
    system(sprintf('%smlhelper --cursor-enable',dirs.BaseDirectory));         
else    % mouse off
    dirs = getpref('MonkeyLogic', 'Directories');                             
    system(sprintf('%smlhelper --cursor-disable',dirs.BaseDirectory));       
end

eyejoytrack(-7, mflag); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hotkey(keyval, varargin)
persistent scanletters scancodes keynumbers keycallbacks

if isnumeric(keyval), %init or call from eyejoytrack
    if keyval == -1, %init
        scanletters = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./';
        scancodes = [41 2:13 16:27 43 30:40 44:53];
        keynumbers = [];
        keycallbacks = {};
        return
    else %call from eyejoytrack
        k = (keynumbers == keyval);
        if any(k),
            eval(keycallbacks{k});
        end
        return
    end
end

keynum = [];
if length(keyval) > 1,
    if strcmpi(keyval, 'esc'),
        keynum = 1;
    elseif strcmpi(keyval, 'rarr'),
        keynum = 205;
    elseif strcmpi(keyval, 'larr'),
        keynum = 203;
    elseif strcmpi(keyval, 'uarr'),
        keynum = 200;
    elseif strcmpi(keyval, 'darr'),
        keynum = 208;
    elseif strcmpi(keyval, 'numrarr'),
        keynum = 77;
    elseif strcmpi(keyval, 'numlarr'),
        keynum = 75;
    elseif strcmpi(keyval, 'numuarr'),
        keynum = 72;
    elseif strcmpi(keyval, 'numdarr'),
        keynum = 80;
    elseif strcmpi(keyval, 'space'),
        keynum = 57;
    elseif strcmpi(keyval, 'bksp'),
        keynum = 14;
    elseif strcmpi(keyval(1), 'f'),
        fval = str2double(keyval(2:end));
        if ~isnan(fval) && fval > 0 && fval < 11,
            keynum = 58 + fval;
        elseif fval == 11,
            keynum = 87;
        elseif fval == 12,
            keynum = 88;
        end
    end
    if isempty(keynum),
        error('Must specify only one letter, number, or symbol on each call to "hotkey" unless specifying a function key such as "F3"');
    end
else
    keynum = scancodes(scanletters == lower(keyval));
end
if isempty(varargin) || isempty(varargin{1}),
    disp('Warning: No function declared for HotKey "%s"', keyval);
    return
end
keyfxn = varargin{1};
n = length(keynumbers) + 1;
keynumbers(n) = keynum;
keycallbacks{n} = keyfxn;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = bhv_variable(varname, varargin)
persistent vars

if varname == -1,
    vars = struct;
    val = 0;
    return
end

if varname == -2,
    val = vars;
    return
end

if ~ischar(varname),
    error('Variable names for bhv_variable must be strings.');
end

if length(varname) > 32,
    error('Variable names must be 32 characters or fewer.');
end

if isempty(varargin),
    val = vars.(varname);
    return
end

varval = varargin{1};

if isempty(varval),
    vars.(varname) = [];
end

if ~isvector(varval),
    error('Variables must be vectors or scalars.');
end

if length(varval) > 128,
    error('Variables must be vectors of length 128 or less.');
end

if isnumeric(varval),
    vars.(varname) = double(varval);
elseif ischar(varval)
    vars.(varname) = char(varval);
else
    error('Variables must be either numeric or chars.');
end

val = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trialerror(e) %#ok<DEFNU>

if ischar(e),
    str = {'correct' 'no response' 'late response' 'break fixation' 'no fixation' 'early response' 'incorrect' 'lever break', 'ignored'};
    f = strmatch(lower(e), str);
    if length(f) > 1,
        error('*** Ambiguous argument passed to TrialError ***');
    elseif isempty(f),
        error('*** Unrecognized string passed to TrialError ***');
    end
    e = f;
elseif isnumeric(e) && (e < 0 || e > 8),
    error('*** TrialErrors can range from 0 to 8 ***');
elseif ~isnumeric(e) && ~ischar(e),
    error('*** Unexpected argument type passed to TrialError (must be either numeric or string) ***');
end
end_trial(-2, e);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function user_text(text, varargin)
persistent ScreenInfo

if text == -1,
    ScreenInfo = varargin{1};
    return
end

if ~ischar(text),
    error('User text must be passed as a char array.');
end

text = sprintf(text,varargin{:});
initcontrolscreen(6, ScreenInfo, text);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function user_warning(text, varargin)
persistent ScreenInfo on

if text == -1,
    ScreenInfo = varargin{1};
    on = true;
    return
end

if text == -2,
    initcontrolscreen(7, ScreenInfo);
    return
end

if ~ischar(text),
    error('User warnings must be passed as a char array.');
end

if strcmpi(text,'off');
    on = false;
    return
end

if strcmpi(text,'on');
    on = true;
    return
end

if ~on,
    return
end

text = sprintf(text,varargin{:});
initcontrolscreen(7, ScreenInfo, text);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function abort_trial
error('ML:TrialAborted','Trial aborted.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function escape_screen %#ok<DEFNU>
end_trial(-3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data_missed(obj, event) %#ok<INUSD,DEFNU>
user_warning('Analog input data missed event!');
abort_trial;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TrialData = end_trial(varargin)
%WA: global        %SDS - but no global variables declared
persistent DAQ ScreenData eTform jTform trialtype trialerror escape

if ~isempty(varargin),
    v = varargin{1};
    if v == -1,
        DAQ = varargin{2};
        ScreenData = varargin{3};
        eTform = varargin{4};
        jTform = varargin{5};
        trialtype = varargin{6};
        trialerror = 9;
        escape = 0;
        return
    elseif v == -2,
        trialerror = varargin{2};
        return
    elseif v == -3
        escape = 1;
        return
    end
end

t1 = trialtime;
if trialtype > 0,
    if isfield(DAQ, 'AnalogInput'),
        if ~isempty(DAQ.AnalogInput),
            stop(DAQ.AnalogInput);
            getdata(DAQ.AnalogInput, DAQ.AnalogInput.SamplesAvailable); %remove & discard any AI samples
        end
    end
    TrialData.BehavioralCodes = [];
    TrialData.AnalogData = [];
    return
end

eventmarker(18);
eventmarker(18);
eventmarker(18);

[exOff eyOff] = eye_position(-3);
[eyetargets cyclerate] = eyejoytrack(-4);
if ~isempty(eyetargets),
    etX = cat(1, eyetargets{:, 1});
    etY = cat(1, eyetargets{:, 2});
    etXY = cat(2, etX, etY);
    [X, I] = unique(etXY, 'rows', 'first');
    AIdata.EyeTargetList = etXY(sort(I),:);
else
    AIdata.EyeTargetList = [];
end
AIdata.EyeSignal = [];
AIdata.Joystick = [];
AIdata.PhotoDiode = [];
for i = 1:9,
    gname = sprintf('Gen%i', i);
    AIdata.General.(gname) = [];
end
if ~isempty(DAQ.AnalogInput),
    stop(DAQ.AnalogInput);
    data = getdata(DAQ.AnalogInput, DAQ.AnalogInput.SamplesAvailable);
    axes(findobj('tag', 'replica'));
    if ~isempty(DAQ.Joystick) && ~SIMULATION_MODE,
        joyx = DAQ.Joystick.XChannelIndex;
        joyy = DAQ.Joystick.YChannelIndex;
        jx = data(:, joyx);
        jy = data(:, joyy);
        if ~ScreenData.UseRawJoySignal,
            [jx jy] = tformfwd(jTform, jx, jy);
        end
        h1 = plot(jx, jy);
        set(h1, 'color', ScreenData.JoyTraceColor/2);
        h2 = plot(jx, jy, '.');
        set(h2, 'markeredgecolor', ScreenData.JoyTraceColor, 'markersize', 3);
        AIdata.Joystick = [jx jy];
    end
    if ~isempty(DAQ.EyeSignal) && ~SIMULATION_MODE,
        eyex = DAQ.EyeSignal.XChannelIndex;
        eyey = DAQ.EyeSignal.YChannelIndex;
        ex = data(:, eyex);
        ey = data(:, eyey);
        if ~ScreenData.UseRawEyeSignal,
            [ex ey] = tformfwd(eTform, ex, ey);
            ex = ex + exOff;
            ey = ey + eyOff;
        end
        h1 = plot(ex, ey);
        set(h1, 'color', ScreenData.EyeTraceColor/2);
        h2 = plot(ex, ey, '.');
        set(h2, 'markeredgecolor', ScreenData.EyeTraceColor, 'markersize', 3);
        AIdata.EyeSignal = [ex ey];
    end
    if ~isempty(DAQ.General),
        generalpresent = DAQ.General.GeneralPresent;
        if generalpresent,
            for i = 1:length(generalpresent),
                generalnumber = generalpresent(i);
                gname = sprintf('Gen%i', generalnumber);
                chindex = DAQ.General.(gname).ChannelIndex;
                gendata = data(:, chindex);
                AIdata.General.(gname) = gendata;
            end
        end
    end
    if ~isempty(DAQ.PhotoDiode),
        pdindx = DAQ.PhotoDiode.ChannelIndex;
        pd = data(:, pdindx);
        AIdata.PhotoDiode = pd;
    end
end

newtform = [];
if ~isempty(eTform)
    tri = [0 0; 1 0; 0 1];
    trans = maketform('affine', tri, tri+repmat([exOff eyOff],3,1));
    comp = maketform('composite',trans,eTform);
    cpi = [0 0; 1 0; 0 1; 1 1];
    cpo = tformfwd(comp,cpi);
    newtform = cp2tform(cpi,cpo,'projective');
end

TrialData.UserVars = bhv_variable(-2);
TrialData.Escape = escape;
TrialData.NewTransform = newtform;
TrialData.NewITI = set_iti(-2);
TrialData.AnalogData = AIdata;
TrialData.AbsoluteTrialStartTime = trialtime(-2);
TrialData.BehavioralCodes = eventmarker(-2);
TrialData.ObjectStatusRecord = toggleobject(-2);
TrialData.RewardRecord = goodmonkey(-3);
TrialData.TrialError = trialerror;
TrialData.CycleRate = cyclerate;
TrialData.TrialExitTime = round(trialtime - t1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SDS ADDED EXTRAS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function TaskObject_out = psytboxrouter(TaskObject_in, win, PixelsPerDegree)

ltb = length(TaskObject_in);
for i = 1:ltb
    ob = TaskObject_in(i);
%   if  strcmpi(ob.Class, 'Cogent')  % will alter to Psytbx
    if ob.Modality == 1 % specifies any PsychToolBox device
        PtboxProgName = ob.Name;  % (could alternatively use ob.Type (lowercase)
        fprintf('initialising PsychToolBox Function %s\n', ob.Name)
        [item_positions item_sizes] = feval(PtboxProgName, -1, win, i, ob);      % -1 is initializing 'mode'; win, i & ob are varargin {1} {2} & {3} % NB item_positions arrives in column vector format;
        TaskObject_in(i).XPos = item_positions(:,1)/PixelsPerDegree;  % item_positions in in pixels (screen centre origin): convert to degrees for XPos
        TaskObject_in(i).YPos = item_positions(:,2)/PixelsPerDegree;  % item_positions in in pixels (screen centre origin): convert to degrees for YPos
        TaskObject_in(i).Xsize = item_sizes(:);                       % item_sizes in in pixels: NB *not* degrees for Xsize
        TaskObject_in(i).Ysize = item_sizes(:);                       % item_sizes in in pixels: NB *not* degrees for Ysize
    end
end
TaskObject_out = TaskObject_in;
