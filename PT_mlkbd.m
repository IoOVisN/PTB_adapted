function result = PT_mlkbd(fxn, varargin)
%SYNTAX LIST:
%  mlkbd('mlinit');
%  mlkbd('init');
%  mlkbd('flush');
%  mlkbd('getkey');
%  mlkbd('release');

result = [];
fxn = lower(fxn);
switch fxn
    case 'mlinit',
        
        %nothing (for now)

    case 'init',
        
        %kbdinit;
		ListenChar(1);
        
    case 'flush',
        
        %kbdflush;
		FlushEvents;
        
    case 'getkey',
        
        %result = kbdgetkey;
		%result = GetChar(0,1);
        [~,~,result] = KbCheck;
		result = find(result);
		
    case 'release',
        
		ListenChar(0);
       %kbdrelease;
end
