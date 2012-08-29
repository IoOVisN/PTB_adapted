try
	
	ListenChar(1);
	result = -1;
	FlushEvents;
	while result ~= 113
		result = GetChar(0,1);
		if ~isempty(result)
			fprintf('Char is: %g\n',result);
		end
		FlushEvents;
	end
    
catch ME
	
	ListenChar(0);
	rethrow(ME)
	
end

ListenChar(0);

try
	disp('Test SVI...')
	kbdinit;
	result = -1;
	while result ~= 19
		kbdflush;
		fprintf('.');
		result = mlkbd('getkey');
		if ~isempty(result)
			fprintf('Char is: %g\n',result);
		end
	end
	
catch ME
	
	kbdrelease;
	rethrow(ME);
	
end

kbdrelease;
