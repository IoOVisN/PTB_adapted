function [x,y,pupilsize]=EyeLinkCoordonees(mode)

%   SDS.. reads latest eye coordinates from EYELINK
%         - checks that recording is operational;
%         -  starts indefinite loop that only breaks when a new eye
%            position has been registered

persistent  eye_used stopkey  % el 

if mode == -1
    stopkey = KbName('space');        %SDS: PsychToolBox/PsychBasic/KbName
    eye_used = -1;
    return
elseif mode || mode == []
    x.c=0;
    y.c=0;
    while 1
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
        [keyIsDown,secs,keyCode] = KbCheck;  %SDS: PsychToolBox/PsychBasic/KbCheck
        if keyCode(stopkey)
            break;
        end
        if Eyelink( 'NewFloatSampleAvailable') > 0
            switch eye_used
                %SDS..  eye_used is set to -1 by EyeLinkInitialisation
                %        so this induces use of Eyelink('EyeAvailable') command
                case 0      % LEFT eye
                    evt = Eyelink( 'NewestFloatSample');
                    x.c = evt.gx(1);        % left  eye x coord
                    y.c = evt.gy(1);        % left  eye y coord
                    pupilsize.l = evt.pa(1);
                    pupilsize.r = 0;
    %                 t = evt.time;
    %                 c = clock;
                    x.l = [];
                    y.l = [];
                    x.r = [];
                    y.r = [];
                case 1      % RIGHT eye
                    evt = Eyelink( 'NewestFloatSample');
                    x.c = evt.gx(2);        % right eye x coord
                    y.c = evt.gy(2);        % right eye y coord
                    pupilsize.l = 0;
                    pupilsize.r = evt.pa(2);
                    x.l = [];
                    y.l = [];
                    x.r = [];
                    y.r = [];
                case 2      % BINOCULAR
                    evt = Eyelink( 'NewestFloatSample');
                    x.l = evt.gx(1);        % left  eye x coord
                    y.l = evt.gy(1);        % left  eye y coord
                    x.r = evt.gx(2);        % right eye x coord
                    y.r = evt.gy(2);        % right eye y coord
                    pupilsize.l = evt.pa(1);
                    pupilsize.r = evt.pa(2);
    %                 t = evt.time;
    %                 c = clock;
                    x.c =(x.l+x.r)/2;
                    y.c =(y.l+y.r)/2;
    %                 c(4:6)
                case -1
                    eye_used = Eyelink('EyeAvailable');  % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR)        
            end
        end
        if (x.c~=0) || (y.c~=0)
            break;
        end
    end
end
return