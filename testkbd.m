try
	
	ListenChar(2);
	result = 0;
	FlushEvents;
	tic
	while result ~= 81
		%result = GetChar(0,1);
		[~,~,result] = KbCheck;
		result = find(result);
		if ~isempty(result)
			fprintf('Char is: %g\n',result);
		elseif result == 81
			fprintf('\nWe HAD A HIT\n');
		else
			
		end
		FlushEvents;
		if isempty(result)
			result = 0;
		end
	end
	toc
    
catch ME
	
	ListenChar(0);
	rethrow(ME)
	
end

ListenChar(0);

% try
% 	disp('Test SVI...')
% 	kbdinit;
% 	result = -1;
% 	while result ~= 19
% 		kbdflush;
% 		fprintf('.');
% 		result = mlkbd('getkey');
% 		if ~isempty(result)
% 			fprintf('Char is: %g\n',result);
% 		end
% 	end
% 	
% catch ME
% 	
% 	kbdrelease;
% 	rethrow(ME);
% 	
% end

kbdrelease;
