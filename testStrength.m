function strengthAll = testStrength()

    clear all;
   pathNames2013();
%     pathNames2();
    nbHands = input('1 or 2 hands: ');

%------------------------------                                                                --------------------------------------------
%% GRAPHICS

        % First blank screen 
        blankScreen = dotsDrawableText();
        blankScreen.isVisible = true;

        % Ready prompts: RH
        readypromptRH = dotsDrawableText();
        readypromptRH.string = 'With your dominant hand, squeeze the device as strong as possible';
        readypromptRH.color = [40 40 40];
        
        % Ready prompts: LH
        readypromptLH = dotsDrawableText();
        readypromptLH.string = 'With your non-dominant hand, squeeze the device as strong as possible';
        readypromptLH.color = [40 40 40];
        readypromptLH.fontSize = 42;
        readypromptLH.typefaceName = 'Calibri';
        readypromptLH.isVisible = true;
        
        % Stop prompts
        stopprompt = dotsDrawableText();
        stopprompt.string = 'STOP';
        stopprompt.color = [40 40 40];
        stopprompt.fontSize = 42;
        stopprompt.typefaceName = 'Calibri';
        stopprompt.isVisible = true; 

        % get a drawing window
        sc=dotsTheScreen.theObject;
        sc.reset('displayIndex', 2);
        %dotsTheScreen.reset();
        dotsTheScreen.openWindow();

        % Display firt screen
        dotsDrawable.drawFrame({blankScreen});

                
%--------------------------------------------------------------------------
%% DYNAMOMETER
if nbHands ==2
    strengthAll = zeros(2,2);
else
    strengthAll = zeros(1,2);
end

        for h= 1: nbHands
            
        % 1 - Open dynamometer
        % create dynamometer object
        d(h) = dynamometer(h);
        % start recording
        d(h).start;
        tic
        pause(3); 

            % TWO GRIP TESTS PER HAND
            for i = 1:2      

            % 2 - Look for pressure    
                % SWITCH THE SCREEN: Instructions
                switch h
                    case 1
                    dotsDrawable.drawFrame({readypromptRH});
                    case 2
                    dotsDrawable.drawFrame({readypromptLH});
                end

                % DETECT PRESSURE
                valthreshold = 10;
                strength = 0;
                while strength <valthreshold
                    pause(0.05)
                    strength = d(h).read;
                end

            %% Change to blank screen
            % 3 - Collect data from dynamometer for 1 second

                % SWITCH THE SCREEN
                dotsDrawable.drawFrame({blankScreen});

                % READ FOR 1 SECOND
                % trial duration
                T  = 5; % arbitrary long time in s
                dt = 0.03 ; % display refresh lag

                % time loop
                timeStart =toc;
                f = zeros(50,1);
                for j=1:round(T/dt) 
                    pause(dt);
                    timeNow = toc - timeStart;
                    % update internal buffer and return last value
                    f(j) = d(h).read;
                    % make sure it doesn't go beyond 1 second
                    if timeNow>1;
                        break
                    end
                end

                % stop recording and get the buffer
          
                 strengthAll(h,i) = max(f);


                % SWITCH THE SCREEN: STOP
                dotsDrawable.drawFrame({stopprompt});
                pause(2);
            
                
            end
            
            if nbHands == 1 && h==1 || nbHands == 2 && h==2
                clear d                        
                % close the OpenGL drawing window
                dotsTheScreen.closeWindow();
            end
            
            
        end


save('strengthAll.mat','strengthAll');






end

    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   


