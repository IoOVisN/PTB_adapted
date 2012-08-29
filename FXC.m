function [item_position, item_size] = FXC(mode, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   feval(PtboxProgName, -1, win, N, ob)  :   call from PTB_trialholder>psytboxrouter: ProgName, mode, win, trial object number, trial object info
%   feval(PboxProgName, 2, N)             :   call from PTB_trialholder>toggleobject : ProgName, mode, trial object number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


persistent win Fp Idx

switch mode
    case -1
        win = varargin{1};      % window pointer 'win' will be overwritten if multiple initialising calls to FXP..
                                % ..assume that all display graphics are using the same screen!!!
        Ni = varargin{2};           % Ni is the TaskObject number
        Idx(Ni) = 1;                % Idx is a stored(persistent) row vector with 1 at positions set by Ni
%       Li = length(Idx(1:Ni)>0);                         
        Li = length(find(Idx(1:Ni)==1)); % Li recodes Ni to a counting sequence: e.g. a series of Ni values 1, 3, 4, 7  gives Li values 1, 2, 3, 4. 
        ob = varargin{3};
        radius = ob.Radius;               % Fixtn cross  position : radius ==  % of half height                                           
        angle =  ob.Angle;                % Fixtn cross  position : angle  == degrees clockwise from 12                                                       
        size = ob.FP1;                    % Fixtn cross dimension 1 : ratio screen height to cross size (e.g. 25)
        thckn = ob.FP2;                   % Fixtn cross dimension 2 : ratio cross size to thickness (e.g. 5)
        Fp(Li).color = ob.Color;          % Fixtn cross colour       (0 to 255)        
            

%       [x1, y1, x2, y2, mx, my] = centrecross(win, 30);
        [X, Y, size, x1, y1, x2, y2, mx, my, tk] = scale_centrecross(win, radius, angle, size, thckn);
        item_position = [X Y];
        item_size = size;
        
        Fp(Li).x1 = x1;
        Fp(Li).y1 = y1;
        Fp(Li).x2 = x2;
        Fp(Li).y2 = y2;
        Fp(Li).mx = mx;
        Fp(Li).my = my;
        Fp(Li).tk = tk;
        
    case 1  % White cross          % Alternative mode of function, not yet implemented
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        Li = length(find(Idx(1:Ni)==1));
        Screen('BlendFunction', win, GL_ONE, GL_ZERO);
        Screen('drawline',win,[],Fp(Li).x1, Fp(Li).my, Fp(Li).x2, Fp(Li).my, Fp(Li).tk);
        Screen('drawline',win,[],Fp(Li).mx, Fp(Li).y1, Fp(Li).mx, Fp(Li).y2, Fp(Li).tk);
        Screen('BlendFunction', win, GL_ONE, GL_ONE);  % restore blending function for Gabors
        
    case 2  % colour coded cross   %  At present mode == 2 is the obligatory setting, called from 'trialholder'
        Ni = varargin{1};          %  NB curly brackets for varargin..!
        Li = length(find(Idx(1:Ni)==1));        
        Screen('BlendFunction', win, GL_ONE, GL_ZERO);
        Screen('drawline',win, Fp(Li).color,Fp(Li).x1, Fp(Li).my, Fp(Li).x2, Fp(Li).my, Fp(Li).tk);
        Screen('drawline',win, Fp(Li).color,Fp(Li).mx, Fp(Li).y1, Fp(Li).mx, Fp(Li).y2, Fp(Li).tk);
        Screen('BlendFunction', win, GL_ONE, GL_ONE);  % restore blending function for Gabors
end

end

function [X, Y, size, x1, y1, x2, y2, mx, my, tk] = scale_centrecross(win, radius, angle, size, thckn)

% effect default values...
if radius == []
    radius = 0;
end 
if angle == []
    angle = 0;
end 
if size == []
    size = 25;
end 
if thckn == []
    thckn = 5;
end

[w, h] = Screen('WindowSize', win);

% Convert parameters to pixels...         Conditions file conventions:- 
radius = radius*h/200;              % 'radius' is distance from screen centre as a percentage of half screen height    
size = floor(h/size);               % 'size' is the ratio of screen height to cross size (cross length = cross width) : size = bar length
tk = ceil(size/thckn);              % 'thckn' is the ratio of cross size to cross thickness                           : tk = bar thickness 
if tk > 10
	tk = 10;
end

% Convert to PsychToolBox coordinates...  NB. origin is top left, all coords positive; 
x1 = floor((w - size)/2);     % left limit of cross
y1 = floor((h - size)/2);     % top limit of cross  
x2 = ceil((w + size)/2);     % right lmit of cross
y2 = ceil((h + size)/2);     % lower limit of cross
mx = w/2;
my = h/2;

% if radius == 0                          % Fixation cross at screen centre
%     return
% else                                    % Displaced fixation cross
    L = radius; 
    C = angle*pi/180;
    X = L*sin(C);                       %  X & Y are pixel coords of fixation cross if screen centre were origin (0,0) 
    Y = L*cos(C);
                                        % But PsychToolBox origin is top left, all coords positive;                      
    x1 = x1 + X;                        % ..hence add X,  but subtract Y;   
    x2 = x2 + X;
    mx = mx + X;
    y1 = y1 - Y;
    y2 = y2 - Y;   
    my = my - Y; 
% end
    
end



function [x1, y1, x2, y2, mx, my] = centrecross(win, len)

[w, h] = Screen('WindowSize', win);
x1 = (w - len)/2;
y1 = (h - len)/2;
x2 = (w + len)/2;
y2 = (h + len)/2;
mx = w/2;
my = h/2;

end
