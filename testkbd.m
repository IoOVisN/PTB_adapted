try
	
	ListenChar(2);
	result = 0;
	FlushEvents;
	tic
	while result ~= 32
		%result = GetChar(0,1);
		[~,~,result] = KbCheck; result = find(result);
		if ~isempty(result)
			fprintf('Char is: %g\n',result);
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
% 	while (result ~= 16) || (result ~= 81)
% 		result = -1;
% 		result = mlkbd('getkey');
% 		if ~isempty(result)
% 			fprintf('SVI Char is: %g\n',result);
% 		end
% 		kbdflush;
% 	end
% 	
% catch ME
% 	
% 	kbdrelease;
% 	rethrow(ME);
% 	
% end
% 
% kbdrelease;
