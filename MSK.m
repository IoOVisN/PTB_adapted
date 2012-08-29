function MSK(mode, varargin)

% cogent gabor generating system adapted to produce PsychToolBox compatible gabor images:
%  using PsychToolBox 'make texture' and 'draw textures' commands

% Modified to use structure ('Larder')to store persistent display data
% .. This enables multiple calls to PGR (or equivalent) by one condition (i.e. within one trial);
% .. although it is necessary to add the task object number to the argunents in the feval call to
% .. PGR in PTB_trialholder;
% .. Hence archive version PGR_1 will not run properly...

% MSK (mask) is modified to use four component gabors to give a counterhasing grid 

% persistent  Options Sprites Datas Ptfc tar dec dis    % tar = target; dec = decoys(distractors); dis = full display;
% persistent win mypars mypars2 gabortex dstRects rotAngles Options Datas


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   feval(PtboxProgName, -1, win, N, ob)  :   call from PTB_trialholder>psytboxrouter: ProgName, mode, win, trial object number, trial object info
%   feval(PboxProgName, 2, N)             :   call from PTB_trialholder>toggleobject : ProgName, mode, trial object number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

persistent win Larder
switch mode
    case -1     % Initialize  - on a 'per trial' basis
        
        Options.NbElements = 8;
        Options.Changes.AngleDNext=1;   % 1 for parallel axes;      3 for radial axes
        Options.DynamicBackground = 1;  % 1 for dynamic;            0 for static
        Options.Direction = 0;          % 0 for uniform direction;  1 for target in opposite direction 
        
%         Angles = [10 20 30 40 50 60 70 80];     % 8 separate levels of difficulty
%         Colors = [1 1 0.5;1 0.5 1;0.5 1 1;0.7 0.7 1; 0.7 1 0.7;1 0.7 0.7;1 0 0;0 1 0];
%         Spfrqs = [1 2 3 4 6 7 8 9];
%         Dircts = [60 65 70 75 80 85 90 95];
%         Sizes  = [110 112 114 116 124 126 128 130];
        FramesPerCycle = 60;
        
%       Datas.ColorRGBT = [1 1 1];        % COLOUR parameter
        Datas.ColorRGBD = [1 1 1];        % COLOUR parameter
        Datas.ColorRGBB = [1 1 1]*0.5;    % COLOUR parameter
%       Datas.SizeT = 240;          % SIZE parameter
        Datas.SizeD = 240;          % SIZE parameter
%       Datas.AngleT = 0;           % ORIENTATION parameter
        Datas.AngleD = 0;           % ORIENTATION parameter
%       Datas.SpaceFreqT = 4;       % SPATIAL FREQ parameter
        Datas.SpaceFreqD = 4;       % SPATIAL FREQ parameter
%       Datas.IntensityT = 100;      % DIRECTION parameter (intensity of secondary gabor)
        Datas.IntensityD = 100;      % DIRECTION parameter (intensity of secondary gabor)
        
        Datas.Binary = 2*floor(rand(1)+0.5)-1; % random selection of +1 & -1
%       Datas.SpeedT = 1;
        Datas.SpeedD = 1;
%       Datas.ShapeT = 1;           % 1 = circle
        Datas.ShapeD = 1;           % 1 = circle

        ob = varargin{3};                   %  NB curly brackets for varargin..!

        Datas.RFradius = ob.Radius;       % radius of target (screen coordinates (1024 768))  % constant across trials
        Datas.RFangle =  ob.Angle;       % angle of target (degrees CW from 12 o'clock)      % constant across trials
%       Datas.Target = ob.FP1;        % position (1-8) of target                              varies across trials
%       Datas.level = ob.FP2;         % allowed difficulty level values (e.g. 1 to 8 )        varies across trials

%         if strcmpi(ob.Class, 'ori')
%             Datas.AngleT = Angles(Datas.level);       % ORIENTATION parameter
%         elseif strcmpi(ob.Class, 'col')
%             Datas.ColorRGBT = Colors(Datas.level,1:3);% COLOUR parameter
%         elseif strcmpi(ob.Class, 'spf')
%             Datas.SpaceFreqT = Spfrqs(Datas.level);   % SPATIAL FREQ parameter
%         elseif strcmpi(ob.Class, 'int')
%             Datas.IntensityT = Dircts(Datas.level);   % graded DIRECTION parameter (intensity of secondary gabor)
%             Datas.IntensityD = Dircts(Datas.level);   % graded DIRECTION parameter (... same for distractors)
%         elseif strcmpi(ob.Class, 'din')
%             Options.Direction = 1;                    % reverse DIRECTION flag
%         elseif strcmpi(ob.Class, 'siz')
%             Datas.SizeT = Sizes(Datas.level);         % SIZE parameter
%         end
        
        L=Datas.RFradius;
        C=Datas.RFangle*pi/180 + (0:1:Options.NbElements -1)*2*pi/Options.NbElements; 
        X=L*sin(C);
        Y=L*cos(C);
        Datas.Positions=[X' Y'];
                    
        if Options.DynamicBackground == 1
            Datas.NbFrames = FramesPerCycle;    % >72 elicits: 'WRN gprim:gAddRAS System rather than video memory used'
        else
            Datas.NbFrames = 1;
        end
   
        
% Define prototypical gabor patch of 65 x 65 pixels default size: 
% 'si' is half the wanted size. 
%       si = 32;
        si = Datas.SizeD *0.5;
        tw = 2*si+1;    % Size of support in pixels, derived from si:
        th = 2*si+1;

% parameters of distractor/target  gabors:
        phase = 0;                      % Phase of underlying sine grating in degrees:
        sc = 40.0;                      % Spatial constant of the exponential "hull"
        freqD = Datas.SpaceFreqD *0.01;  % Frequency of sine grating:
%       freqT = Datas.SpaceFreqT *0.01;  % Frequency of sine grating:
        contrast = 40.0;                % Contrast of grating:
        aspectratio = 1.0;              % Aspect ratio width vs. height:
        
        paramD = [phase+180, freqD, sc, contrast, aspectratio, 0, 0, 0];
%       paramT = [phase+180, freqT, sc, contrast, aspectratio, 0, 0, 0];
        ngabors = Options.NbElements;   % number of gabor elements
        
% Initialize matrix with spec for all identical distractor Gabors:
        mypars = repmat(paramD', 1, ngabors);  %SDS: NB- inverted paramD is a column vector
%       mypars(:,Datas.Target) = paramT';      %SDS: overwrite target parameters (invert paramT)
        mypars2 = mypars;
%        mypars2(4,:) = mypars(4,:)*0.2;  % SDS: control relative contrast of counter drifting Gabor
        win = varargin{1}; 
        rect = Screen('Rect', win);
        [w, h] = RectSize(rect);

% Build a procedural gabor texture for a gabor with a support of tw x th pixels;
% the 'nonsymetric' flag set == 1 allows runtime change of aspect-ratio:
% the 'nonsymetric' flag set == 0 enables more efficient computation
%       gabortex = CreateProceduralGabor(win, tw, th, 1);
        msgid = 'MATLAB:fileparts:VersionToBeRemoved'; % (SDS: see note below...)
        warning('off',msgid)
        gabortex = CreateProceduralGabor(win, tw, th, 0);  %SDS:  see PTB notes on 'CreateProceduralGabor' below:-

% Draw the gabor once, just to make sure the gfx-hardware is ready for the
% benchmark run below and doesn't do one time setup work inside the benchmark loop.
% The flag 'kPsychDontDoRotation' tells 'DrawTexture' not
% to apply its built-in texture rotation code for rotation, but just pass
% the rotation angle to the 'gabortex' shader -- it will implement its own
% rotation code, optimized for its purpose. Additional stimulus parameters
% like phase, sc, etc. are passed as 'auxParameters' vector to
% 'DrawTexture', this vector is just passed along to the shader. For
% technical reasons this vector must always contain a multiple of 4
% elements, so we pad with three zero elements at the end to get 8 elements.
% SDS: But, this step is not strictly necessary...
%       Screen('DrawTexture', win, gabortex, [], [], [], [], [], [], [], kPsychDontDoRotation, [phase, freq, sc, contrast, aspectratio, 0, 0, 0]);

% Preallocate array with destination rectangles:
% This also defines initial gabor patch orientations, scales and location for the very first drawn stimulus frame:
        texrect = Screen('Rect', gabortex);       %SDS: gabortex is just a 'handle'(or index), not the texture matrix itself...
%       inrect = repmat(texrect', 1, ngabors);    %SDS: this is only used to prevent drifting Gabors going off screen limits
         
        dstRects = zeros(4, ngabors);
        for i=1:ngabors
        %   scale(i) = 1*(0.1 + 0.9 * randn);                   %SDS: do not require randomly varying sizes... 
        %   dstRects(:, i) = CenterRectOnPoint(texrect * scale(i), rand * w, rand * h)';
        %   SDS: substitute circular array positions and modify to Screen coordinates (origin at top left, all positive)   
            dstRects(:, i) = CenterRectOnPoint(texrect, Datas.Positions(i,1)+ 0.5*w, Datas.Positions(i,2)+ 0.5*h)';
        end

% Preallocate array with rotation angles:  
%       rotAngles = rand(1, ngabors) * 360;     SDS: do not require random rotations...
        rotAngles(1, 1:ngabors) = Datas.AngleD;
%       rotAngles(1,Datas.Target) = Datas.AngleT;
        
% Store all display parameter data in the structure 'Larder':    Are multiple calls to MSK likely..?  If not, Larder strategy is not required
        Ni = varargin{2};          %  NB curly brackets for varargin..!
        Larder(Ni).Options = Options;
        Larder(Ni).Datas = Datas;
        Larder(Ni).mypars = mypars;
        Larder(Ni).mypars2 = mypars2;
        Larder(Ni).gabortex = gabortex;
        Larder(Ni).dstRects = dstRects;
        Larder(Ni).rotAngles = rotAngles;
  
    case 1      % mode 1: a single central gabor
%         Ni = varargin{1};          %  NB curly brackets for varargin..!
%         Screen('DrawTexture', win, Larder(Ni).gabortex, [], [], [], [], [], [0 255 0], [], kPsychDontDoRotation, Larder(Ni).mypars(:,1));
%         Screen('DrawingFinished', win);
%         shift = 360/Larder(Ni).Datas.NbFrames;
%         Larder(Ni).mypars(1,:) = Larder(Ni).mypars(1,:) + shift;
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        
        rect = Screen('Rect', win);
        [w, h] = RectSize(rect);
        gabortex = Larder(Ni).gabortex;         
        texrect = Screen('Rect', gabortex);                  % wierdly, 'DrawTextures' does not allow default specification of 'dstRects' if 'rotAngles' is not default
        dstRect = CenterRectOnPoint(texrect, w/2, h/2)';     % ..hence need to define dstRects de novo 
        dstRects = [dstRect dstRect dstRect dstRect];
        rotAngles = Larder(Ni).rotAngles;                    % rotAngles 
        rotAngles2  = rotAngles + 90;
        mypars = Larder(Ni).mypars;          % not necessary to rename Larder contents
        mypars2 = Larder(Ni).mypars2;        % ..but it helps to make code less cumbersome to the eye! 
        NbFrames = Larder(Ni).Datas.NbFrames;
        Binary = Larder(Ni).Datas.Binary;
        % drifting grid:
%        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects], [rotAngles rotAngles2], [], [], [], [], kPsychDontDoRotation, [mypars mypars]);
        % counterphasing grid
        Screen('DrawTextures', win, gabortex, [], [dstRects], [rotAngles(1) rotAngles2(1) rotAngles(1) rotAngles2(1)], [], [], [], [], kPsychDontDoRotation, [mypars(:,1) mypars(:,1) mypars2(:,1) mypars2(:,1)]);
%        Screen('DrawTextures', win, gabortex, [], [dstRects], [0 90 0 90], [], [], [], [], kPsychDontDoRotation, [mypars(:,1) mypars(:,1) mypars2(:,1) mypars2(:,1)]);
        Screen('DrawingFinished', win);
        shift = 360/NbFrames;
        Larder(Ni).mypars(1,:) = mypars(1,:) + shift*Binary;
        Larder(Ni).mypars2(1,:) = mypars2(1,:) - shift*Binary;

    case 2      % mode 2: the array of gabors
           % superimposed: gabors with opposite phase, yielding a counterphasing static 'node' gabor (eggbox)
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        gabortex = Larder(Ni).gabortex;         % not necessary to rename Larder contents
        dstRects = Larder(Ni).dstRects;         % ..but it helps to make code less cumbersome to the eye! 
        rotAngles = Larder(Ni).rotAngles;
        rotAngles2  = rotAngles + 90;
        mypars = Larder(Ni).mypars;
        mypars2 = Larder(Ni).mypars2;
        NbFrames = Larder(Ni).Datas.NbFrames;
        Binary = Larder(Ni).Datas.Binary;
        % drifting grid:
%        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects], [rotAngles rotAngles2], [], [], [], [], kPsychDontDoRotation, [mypars mypars]);
        % counterphasing grid
        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects dstRects dstRects], [rotAngles rotAngles2 rotAngles rotAngles2], [], [], [], [], kPsychDontDoRotation, [mypars mypars mypars2 mypars2]);
%        Screen('DrawingFinished', win);     % the 'DrawingFinished' command prevents anything else being drawn on top of the mask
        shift = 360/NbFrames;
        Larder(Ni).mypars(1,:) = mypars(1,:) + shift*Binary;
        Larder(Ni).mypars2(1,:) = mypars2(1,:) - shift*Binary;

    case 3  %  testing mode, for use with test_PGR
        % superimposed: gabors with opposite phase, yielding a counterphasing static gabor
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        gabortex = Larder(Ni).gabortex;         % not necessary to rename Larder contents
        dstRects = Larder(Ni).dstRects;         % ..but it helps to make code less cumbersome to the eye! 
        rotAngles = Larder(Ni).rotAngles;
        mypars = Larder(Ni).mypars;
        mypars2 = Larder(Ni).mypars2;
        NbFrames = Larder(Ni).Datas.NbFrames;
        Binary = Larder(Ni).Datas.Binary;
        
        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects], [rotAngles rotAngles], [], [], [], [], kPsychDontDoRotation, [mypars mypars2]);
        Screen('DrawingFinished', win);
        shift = 360/NbFrames;
        Larder(Ni).mypars(1,:) = mypars(1,:) + shift*Binary;
        Larder(Ni).mypars2(1,:) = mypars2(1,:) - shift*Binary;
        
    case 4  %  testing mode, for use with test_PGR: superimposed: gratings with opposite phase, & different colours
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        gabortex = Larder(Ni).gabortex;
        dstRects = Larder(Ni).dstRects;
        rotAngles = Larder(Ni).rotAngles;
        mypars = Larder(Ni).mypars;
        mypars2 = Larder(Ni).mypars2;
        NbFrames = Larder(Ni).Datas.NbFrames;
        Binary = Larder(Ni).Datas.Binary;
        
        Screen('DrawTextures', win, gabortex, [], [dstRects], [rotAngles], [], [], [0 255 0], [], kPsychDontDoRotation, [mypars]);
        Screen('DrawTextures', win, gabortex, [], [dstRects], [rotAngles], [], [], [255 0 255], [], kPsychDontDoRotation, [mypars2]);
        Screen('DrawingFinished', win);
        shift = 360/NbFrames;
        Larder(Ni). mypars(1,:) = mypars(1,:) + shift*Binary;
        Larder(Ni).mypars2(1,:) = mypars2(1,:) - shift*Binary;
        
    case 5  %  testing mode, for use with test_PGR: superimposed: gabors with opposite phase, yielding a counterphasing static gabor *** same as mode #2 ***
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        gabortex = Larder(Ni).gabortex;         % not necessary to rename Larder contents
        dstRects = Larder(Ni).dstRects;         % ..but it helps to make code less cumbersome to the eye! 
        rotAngles = Larder(Ni).rotAngles;
        rotAngles2  = rotAngles + 90;
        mypars = Larder(Ni).mypars;
        mypars2 = Larder(Ni).mypars2;
        NbFrames = Larder(Ni).Datas.NbFrames;
        Binary = Larder(Ni).Datas.Binary;
        % drifting grid:
%        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects], [rotAngles rotAngles2], [], [], [], [], kPsychDontDoRotation, [mypars mypars]);
        % counterphasing grid
        Screen('DrawTextures', win, gabortex, [], [dstRects dstRects dstRects dstRects], [rotAngles rotAngles2 rotAngles rotAngles2], [], [], [], [], kPsychDontDoRotation, [mypars mypars mypars2 mypars2]);
        Screen('DrawingFinished', win);
        shift = 360/NbFrames;
        Larder(Ni).mypars(1,:) = mypars(1,:) + shift*Binary;
        Larder(Ni).mypars2(1,:) = mypars2(1,:) - shift*Binary;
end

end


% [gaborid, gaborrect] = CreateProceduralGabor(windowPtr, width, height [, nonSymmetric=0][, backgroundColorOffset =(0,0,0,0)][, disableNorm=0][, contrastPreMultiplicator=1])
%
% Creates a procedural texture that allows to draw Gabor stimulus patches
% in a very fast and efficient manner on modern graphics hardware.
%
% This works on GPU's with support for the OpenGL shading language and
% vertex- and fragment shaders. See ProceduralGaborDemo and
% ProceduralGarboriumDemo for examples on how to use this function.
% ProceduralGaborDemo shows drawing of a single gabor and also allows to
% perform a speed benchmark and a correctness test to verify correct
% working and accuracy of this approach. ProceduralGarboriumDemo shows how
% to draw large numbers of gabor patches with different paramters in a very
% fast and efficient way.
%
% Parameters and their meaning:
%
% 'windowPtr' A handle to the onscreen window.
% 'width' x 'height' The maximum size (in pixels) of the gabor. More
% precise, the size of the mathematical support of the gabor. Providing too
% small values here would 'cut off' peripheral parts or your gabor. Too big
% values don't hurt wrt. correctness or accuracy, they just hurt
% performance, ie. drawing speed. Use a reasonable size for your purpose.
%
% 'nonSymmetric' Optional, defaults to zero. A non-zero value means that
% you intend to draw gabors whose gaussian hull is not perfectly circular
% symmetric, but a more general ellipsoid. The generated procedural texture
% will honor an additional 'spatial aspect ratio' parameter, at the expense
% of a higher computational effort and therefore slower drawing speed.
%
% 'backgroundColorOffset' Optional, defaults to [0 0 0 0]. A RGBA offset
% color to add to the final RGBA colors of the drawn gabor, prior to
% drawing it.
%
% 'disableNorm' Optional, defaults to 0. If set to a value of 1, the
% special multiplicative normalization term normf = 1/(sqrt(2*pi) * sc)
% will not be applied to the computed gabor. By default (setting 0), it
% will be applied. This term seems to be a reasonable normalization of the
% total amplitude of the gabor, but it is not part of the standard
% definition of a gabor. Therefore we allow to disable this normalization.
%
% 'contrastPreMultiplicator' Optional, defaults to 1. This value is
% multiplied as a scaling factor to the requested contrast value. If you
% set the 'disableNorm' parameter to 1 to disable the builtin normf
% normalization and then specify contrastPreMultiplicator = 0.5 then the
% per gabor 'contrast' value will correspond to what practitioners of the
% field usually understand to be the contrast value of a gabor.
%
%
% The function returns a procedural texture handle 'gaborid' that you can
% pass to the Screen('DrawTexture(s)', windowPtr, gaborid, ...) functions
% like any other texture handle. The 'gaborrect' is a rectangle which
% describes the size of the gabor support.
%
% A typical invocation to draw a single gabor patch may look like this:
%
% Screen('DrawTexture', windowPtr, gaborid, [], dstRect, Angle, [], [],
% modulateColor, [], kPsychDontDoRotation, [phase+180, freq, sc,
% contrast, aspectratio, 0, 0, 0]);
%
% Draws the gabor 'gaborid' into window 'windowPtr', at position 'dstRect',
% or in the center if 'dstRect' is set to []. Make sure 'dstRect' has the
% size of 'gaborrect' to avoid spatial distortions! You could do, e.g.,
% dstRect = OffsetRect(gaborrect, xc, yc) to place the gabor centered at
% screen position (xc,yc).
%
% The definition of the gabor mostly follows the definition of Wikipedia,
% but you can check the source code of ProceduralGaborDemo for a reference
% Matlab implementation which is exactly equivalent to what this routine
% does.
%
% Wikipedia's definition (better readable): http://en.wikipedia.org/wiki/Gabor_filter
% See http://tech.groups.yahoo.com/group/psychtoolbox/message/9174 for
% Psychtoolbox forum message 9174 with an in-dephs discussion of this
% function.
%
%
% 'Angle' is the optional orientation angle in degrees (0-360), default is zero degrees.
%
% 'modulateColor' is the base color of the gabor patch - it defaults to
% white, ie. the gabor has only luminance, but no color. If you'd set it to
% [255 0 0] you'd get a reddish gabor.
%
% 'phase' is the phase of the gabors sine grating in degrees.
%
% 'freq' is its spatial frequency in cycles per pixel.
%
% 'sc' is the spatial constant of the gaussian hull function of the gabor, ie.
% the "sigma" value in the exponential function.
%
% 'contrast' is the amplitude of your gabor in intensity units - A factor
% that is multiplied to the evaluated gabor equation before converting the
% value into a color value. 'contrast' may be a bit of a misleading term
% here...
%
% 'aspectratio' Defines the aspect ratio of the hull of the gabor. This
% parameter is ignored if the 'nonSymmetric' flag hasn't been set to 1 when
% calling the CreateProceduralGabor() function.
%
% Make sure to use the Screen('DrawTextures', ...); function properly,
% instead of the Screen('DrawTexture', ...); function, if you want to draw
% many different gabors simultaneously - this is much faster!
%


%SDS: CreateProceduralGabor generates this tedious error message
%SDS: warning is suppressed by warning('off', message identifier)
% Warning: The fourth output, VERSN, of FILEPARTS will be removed in a future release. 
% > In fileparts at 35
%   In LoadGLSLProgramFromFiles at 112
%   In CreateProceduralGabor at 151



%SDS:  function handle = LoadShaderFromFile(filename, shadertype, debug)
%SDS: called (indirectly) by CreateProceduralGabor generates 2 tedious bulletins (from L55 & L58 & L68):-
% Building a fragment shader:Reading shader from file C:\NewBox\Psychtoolbox\PsychOpenGL\PsychGLSLShaders\BasicGaborShader.frag.txt ...
% Building a vertex shader:Reading shader from file C:\NewBox\Psychtoolbox\PsychOpenGL\PsychGLSLShaders\BasicGaborShader.vert.txt ...
% SDS: ... which have been commented.