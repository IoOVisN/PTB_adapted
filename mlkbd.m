function result = mlkbd(fxn, varargin)
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
		ListenChar(2);
        
    case 'flush',
        
        %kbdflush;
		FlushEvents;
        
    case 'getkey',
        
        %result = kbdgetkey;
		%result = GetChar(0,1);
        [~,~,result] = KbCheck;
		result = find(result);
		
    case 'release',
        
        kbdrelease;
        ListenChar(0);
end
