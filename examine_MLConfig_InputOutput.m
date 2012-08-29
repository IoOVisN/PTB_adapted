function examine_MLConfig_InputOutput

% Checking out what code from MLogic main directory routine 'initio' does !!!
% It produces a this error message(s):
%   Button1: Cannot create analog input object
%   Button1: Cannot create analog input object
%   ??? Error using ==> PT_monkeylogic at 398
%   *** DAQ initialization error ***


load('ptori_GAB_FXC_a_cfg.mat')
IO = MLConfig.InputOutput;
fnames = fieldnames(IO);   %SDS: This is the scrollable list of items in the Input/Output section of the main menu 
numfields = length(fnames);


%for manual editing:
configIO.AI.BufferingConfig =  [16 1024]; %[1 2000];
configIO.AI.InputRange = [-10 10];
configIO.Reward.TriggerValue = 5; %if analog, number of volts to trigger or hold at (will be "1" if digital).

%from menu:
configIO.AI.SampleRate = IO.Configuration.AnalogInputFrequency;
configIO.AI.InputType = IO.Configuration.AnalogInputType;
configIO.AI.AnalogInputDuplication = IO.Configuration.AnalogInputDuplication;
configIO.Reward.Polarity = IO.Configuration.RewardPolarity; %+1 for positive-edge reward trigger, -1 for negative edge


%Create DAQ objects within DAQ structure
for i = 1:length(fnames),                                   %SDS end @ L 359;  'fnames' defined L24
    signame = fnames{i}
    sigpresent = isfield(IO.(signame), 'Adaptor')
    if sigpresent,                                          %SDS end @ L 358;
        if strcmpi(IO.(signame).Subsystem, 'AnalogInput'), 
            
                        %create ai objects
%            if isempty(DAQ.AnalogInput),
                [DAQ.AnalogInput DaqError] = init_ai(IO.(signame).Constructor, configIO);  %SDS - subroutine @ L387; configIO defined @L11-19
                if ~isempty(DaqError),
                    DaqError{1} = sprintf('%s: %s', signame, DaqError{1});
                    disp(DaqError{1})
                    daqreset;
                    return
                end
%            end
        end
    end
    
end
    
function [ai DaqError] = init_ai(constructor, configIO) %SDS  called from L160: [DAQ.AnalogInput DaqError] = init_ai(IO.(signame).Constructor, configIO);
DaqError = [];
try
    ai = eval(constructor);
catch
    ai = [];
    DaqError{1} = 'Cannot create analog input object';
    return
end