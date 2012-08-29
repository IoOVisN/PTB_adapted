function UniqueTaskObjects = PT_sort_taskobjects(Conditions)
%
% Created by WA, July, 2006
% Modified 12/15/06 -WA
% Last modified 8/13/08 -WA (to include movies)
% 
% Modified July 2012 SDS: to accommodate PsychToolBox



stimnum = 0;
for cond = 1:length(Conditions),
   TaskObject = Conditions(cond).TaskObject;
   %TaskObject = orderfields(TaskObject);  commented WA
   for tonum = 1:length(TaskObject),
       stimnum = stimnum + 1;
       AllTaskObjects(stimnum) = TaskObject(tonum);
   end
end

TOtypes = cellstr(strvcat(AllTaskObjects.Type)); %WA: works because "type" is always 3 chars
% WA: recognized types are: fix, pic, snd, crc, sqr, mov, stm, ttl, gen  
% SDS: fix pic crc sqr mov  are graphics; gen is not needed
% SDS: new types are gab msk fxc --- --- names of PsychToolBox routines

UGAB = [];
f = find(strcmpi(TOtypes, 'gab'));
if ~isempty(f),
    GAB = AllTaskObjects(f);
    UGAB = uniquestructs(GAB, 'Class',  'FP1', 'FP2'); % SDS FP1 is target position, FP2 is level of difficulty
end

UMSK = [];
f = find(strcmpi(TOtypes, 'msk'));
if ~isempty(f),
    MSK = AllTaskObjects(f);
    UMSK = uniquestructs(MSK, 'Class'); 
end

UFXC = [];
f = find(strcmpi(TOtypes, 'fxc'));
if ~isempty(f),
    FXC = AllTaskObjects(f);
    UFXC = uniquestructs(FXC, 'Class', 'FP1', 'FP2', 'Color'); % SDS FP1 is cross size, FP2 is cross width
end

% UFIX = [];                            %SDS amend
% f = find(strcmpi(TOtypes, 'fix'));
% if ~isempty(f),
%     UFIX = AllTaskObjects(f(1));
% end
% 
% UPIC = [];
% f = find(strcmpi(TOtypes, 'pic'));
% if ~isempty(f),
%     PIC = AllTaskObjects(f);
%     UPIC = uniquestructs(PIC, 'Name');
% end

USND = [];
f = find(strcmpi(TOtypes, 'snd'));
if ~isempty(f),
    SND = AllTaskObjects(f);
    USND = uniquestructs(SND, 'WaveForm', 'Freq');
end

USTM = [];
f = find(strcmpi(TOtypes, 'stm'));
if ~isempty(f),
    STM = AllTaskObjects(f);
    USTM = uniquestructs(STM, 'Name', 'OutputPort');
end

% UCRC = [];                            %SDS amend
% f = find(strcmpi(TOtypes, 'crc'));
% if ~isempty(f),
%     CRC = AllTaskObjects(f);
%     UCRC = uniquestructs(CRC, 'Radius', 'Color', 'FillFlag'); %SDS lists all bracketed parameters, except position info
% end
% 
% USQR = [];
% f = find(strcmpi(TOtypes, 'sqr'));
% if ~isempty(f),
%     SQR = AllTaskObjects(f);
%     USQR = uniquestructs(SQR, 'Xsize', 'Ysize', 'Color', 'FillFlag');
% end
% 
% UMOV = [];
% f = find(strcmpi(TOtypes, 'mov'));
% if ~isempty(f),
%     MOV = AllTaskObjects(f);
%     UMOV = uniquestructs(MOV, 'Name');
% end

% UGEN = [];
% f = find(strcmpi(TOtypes, 'gen'));
% if ~isempty(f),
%     GEN = AllTaskObjects(f);
%     UGEN = uniquestructs(GEN, 'FunctionName');
% end

UTTL = [];
f = find(strcmpi(TOtypes, 'ttl'));
if ~isempty(f),
    TTL = AllTaskObjects(f);
    UTTL = uniquestructs(TTL, 'OutputPort');
end

%UniqueTaskObjects = AllTaskObjects(uindx); %  commented by WA
%UniqueTaskObjects = cat(2, UFIX, UPIC, UMOV, UCOG_FXC, UCOG_GBR, UCOG_TGR, UCOG_PGR, USND, USTM, UCRC, USQR, UGEN, UTTL); 
UniqueTaskObjects = cat(2, UGAB, UMSK, UFXC, USND, USTM, UTTL);             %SDS amend

for i = 1:length(UniqueTaskObjects),
    obname = UniqueTaskObjects(i).Name; 
    obname = stripfilename(obname);        %SDS - stripfilename is a subroutine @l250
    obclass = UniqueTaskObjects(i).Class;  %SDS added extra   TaskObject.Class is a new field; it refers to a mode of operation of some PsychToolBox programs
    obclass = stripfilename(obclass);      %SDS not sure that this line is necessary...
    UOB = UniqueTaskObjects(i);
    switch UOB.Type,                      %SDS This line of text appears in the Main Menu, Stimulus list-box.
        case 'gab'                        %SDS added extra: Add a fresh case for each new PsychToolBox device...
            txt = sprintf('GAB: %s  target posn= %i level= %i', obclass, UOB.FP1, UOB.FP2);
            
        case 'msk'                        %SDS added extra
            txt = sprintf('MSK: %s' , obclass);
            
        case 'fxc'                       %SDS added extra
            txt = sprintf('FXC: %s size= %i width= %i rgb=[%1.0f %1.0f %1.0f]', obclass, UOB.FP1, UOB.FP2, UOB.Color(1), UOB.Color(2),UOB.Color(3));
            
%         case 'fix',                                       % SDS commented
%             txt = sprintf('Fix: Default');
%         case 'pic',
%             xs = UOB.Xsize;
%             ys = UOB.Ysize;
%             if xs == -1,
%                 img = imread(UOB.Name);
%                 ys = size(img, 1);
%                 xs = size(img, 2);
%             end
%             txt = sprintf('Pic: %s  [%i x %i]', obname, xs, ys);
%         case 'gen',                                       % SDS commented
%             funcname = UniqueTaskObjects(i).FunctionName;
%             [p funcname e] = fileparts(funcname);
%             txt = sprintf('Gen: %s', funcname);
%         case 'mov',                                       % SDS commented
% %             mov = aviread(UOB.Name);                                                                          % commented WA
% %             [ys xs zs] = size(mov(1).cdata); %#ok<NASGU> zs needed to get correct dimensions into xs and ys   % commented WA
% %             numframes = length(mov);                                                                          % commented WA
% %             txt = sprintf('Mov: %s [%i x %i] %i Frames', obname, xs, ys, numframes);                          % commented WA
            
%             reader = mmreader(UOB.Name);
%             txt = sprintf('Mov: %s [%i x %i] %i Frames', obname, get(reader, 'width'), get(reader, 'height'), get(reader, 'numberOfFrames'));

        case 'snd',
            dur = length(UOB.WaveForm) / UOB.Freq;
            txt = sprintf('Snd: %s (%2.1f sec)', obname, dur);
%         case 'crc',                                       % SDS commented
%             if UOB.FillFlag == 1,
%                 obname = 'Solid';
%             else
%                 obname = 'Outline';
%             end
%             txt = sprintf('Crc: %s r=%3.2f rgb=[%1.2f %1.2f %1.2f]', obname, UOB.Radius, UOB.Color(1), UOB.Color(2), UOB.Color(3));
%         case 'sqr',                                       % SDS commented
%             if UOB.FillFlag == 1,
%                 obname = 'Solid';
%             else
%                 obname = 'Outline';
%             end
%             txt = sprintf('Sqr: %s [%2.2f x %2.2f] rgb = [%1.2f %1.2f %1.2f]', obname, UOB.Xsize, UOB.Ysize, UOB.Color(1), UOB.Color(2), UOB.Color(3));
        case 'stm',
            dur = length(UOB.WaveForm) / UOB.Freq;
            txt = sprintf('%s (%2.1f sec)', obname, dur);
        case 'ttl',
            txt = sprintf('TTL: >> Port %i', UOB.OutputPort);
    end %case
    UniqueTaskObjects(i).Description = txt;
end

function [Ustruct, Uindx] = uniquestructs(S, varargin)

%SDS:  'S' is the task object descriptors for all task objects of a particular class (e.g. 'mov', 'crc', 'cog'))
%SDS:  varargin are the names of the fields specified for that class.. 

logarray = zeros(length(S), length(varargin));

for i = 1:length(varargin),  % SDS - the number of items/parameters within the brackets of the target object description in the conditions file
                                   ... NO: actually the number of named fields in the call to 'uniquestructs' subroutine - should be the same really..
    fname = varargin{i}; 
    sampleS = S(1).(fname);  
    if isnumeric(sampleS),
        if isscalar(sampleS),
            fval = cat(1, S(:).(fname));
            [b indx j] = unique(fval, 'rows');
        elseif isvector(sampleS),
            pad = 0;
            for k = 1:length(S),
                pad = max(pad,length(S(k).(fname)));
%               fprintf('pad is %i \n',pad)  %SDS temp
            end
            for k = 1:length(S),
                v = S(k).(fname);    
                v(end+1:pad) = NaN;
                S(k).(fname) = v;
            end
            fval = cat(1, S(:).(fname));
            [b indx j] = unique(fval, 'rows');
            for k = 1:length(S),
                v = S(k).(fname);
                v = v(~isnan(v));
                S(k).(fname) = v;
            end
        else
            maxsize = zeros(length(size(sampleS)));
            for k = 1:length(S),
                maxsize = max( [maxsize ; size(S(k).(fname))] );
            end
            shapes = cell(1,length(S));
            for k = 1:length(S),
                v = S(k).(fname);
                shapes{k} = size(v);
                v = padarray(v,maxsize-size(v),NaN,'post');
                S(k).(fname) = v;
            end
            d = length(maxsize)+1;
            fval = cat(d, S(:).(fname));
            [b indx j] = unique_dim(fval, d);
            for k = 1:length(S),
                v = S(k).(fname);
                v = v(~isnan(v));
                v = reshape(v,shapes{k});
                S(k).(fname) = v;
            end
%         else                                                                                          % commented WA
%             error('uniquestructs unable to handle non-scalar, non-vector, numeric fields.');          % commented WA
         end
    else    % SDS - now dealing with nonnumeric 'sampleS' i.e. text values/parameters/descriptors  ?   
        fval = cat(1, {S(:).(fname)});
        [b indx j] = unique(fval);
    end
    logarray(:, i) = j';
end

[b Uindx j] = unique(logarray, 'rows');
Ustruct = S(Uindx);

indxarray = j(Uindx);
for i = 1:size(b, 1),
    xp = cat(1, S(j == i).Xpos);
    yp = cat(1, S(j == i).Ypos);
    Ustruct(indxarray == i).Xpos = xp;
    Ustruct(indxarray == i).Ypos = yp;
end

function fnameresult = stripfilename(fname)

f = find(fname == filesep);
if ~isempty(f),
    fname = fname(max(f)+1:length(fname));
end
dot = find(fname == '.');
if ~isempty(dot),
    fname = fname(1:dot-1);
end
fnameresult = fname;

function [B, I, J] = unique_dim(A, d)

s = size(A);
sd = size(A,d);
n = length(s);

Ad = shiftdim(A,n-d);
l = prod(s(1:length(s)~=d));
shape = size(Ad);
shape = shape(1:end-1);

U = cell(1,sd);
I = [];
J = [];
for i=1:sd,
    ia = 1 + (i-1)*l;
    ib = i*l;
    Ai = Ad(ia:ib);
    for j=1:length(U)
        if isempty(U{j}),
            U{j} = Ai;
            I(end+1)=i; %#ok<AGROW>
            J(end+1)=j; %#ok<AGROW>
            break;
        end
        eq = (U{j} == Ai);
        while ~isscalar(eq),
            eq = all(eq);
        end
        if eq,
            J(end+1)=j; %#ok<AGROW>
            break;
        end
    end
end
B = [];
for i=1:length(I),
    u = reshape(U{i},shape);
    B = cat(n,B,u);
end
B = shiftdim(B,d);