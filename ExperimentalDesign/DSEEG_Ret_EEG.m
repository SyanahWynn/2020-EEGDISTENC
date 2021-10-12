%% SET-UP %%
% Change current directory
cd(fileparts(which('DSMEG_Ret_EEG.m')))

% Clear the workspace and the screen
close all;
clear all;
sca

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace values for white
grey = white / 2;

% Open an on screen window using PsychImaging and color it grey.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get participant info
ppn=Ask(window,'Participant number:',[],[grey],'GetChar', 'center');
gender=Ask(window,'Participant gender:',[],[grey],'GetChar', 'center');
age=Ask(window,'Participant age:',[],[grey],'GetChar', 'center');
edu=Ask(window,'Participant education:',[],[grey],'GetChar', 'center');

%% VARIABLES %%
heightScalers = .2;
theImageLoc = 'Pics';
SubFileLoc = 'SubjectFiles';
SubFileName = 'retrievalList.xlsx';
%jitter = [0.9 0.95 1 1.05 1.1];
%j = randi(5,1,1);
%jitter(j);
FixDur = 1;
StimDur = 1.5;
numImages = 1;
ConfDur = 1.5;
dataLoc = 'data'; 
RestrictKeysForKbCheck([37, 39, 40, 27, 74, 78]); %left arrow, right arrow, down arrow, escape, j, n
PracTrials = 15;
RetTrials = 990;
Blocks = 6;
BlockTrials = RetTrials/Blocks;
EEG = 0; % 1 in case of EEG measurement, 0 in case of behavioral measurement

%% BUTTON BOX %%
% initialisatie buttonbox, verbinden met seriele poort
if EEG == 1
    handle = buttonbox('open');
elseif EEG == 0
    buttonbox = zeros(100);
end

%% IMPORT %%
% Get the subject file for the participant and if it is not found abort
SF = dir(SubFileLoc);
SubFiles = {SF.name};
a= cell2mat(strfind(SubFiles,ppn));
if (a==1)
else
    % Clear the screen.
    sca;
end
[num,txt,raw] = xlsread(fullfile(SubFileLoc,ppn,'\',SubFileName));

%% EXPORT %%
% set data folder and Create path and name for the results file
dataFolder = fullfile(dataLoc, '\');
Outputfile = [dataFolder 'Ret_' ppn '.mat'];
Outputfile2 = [dataFolder 'Ret_' ppn '.xlsx'];

%% INTRO %%
Screen('TextSize', window, 30);
Screen('TextFont', window, 'Calibri');
DrawFormattedText(window,...
    'Ter herhaling, Tijdens de presentatie van de foto geeft u aan\n\n of u denkt dat de foto oud of nieuw is.\n\n1. oud [pijltje links]\n\n2. nieuw [pijltje rechts]\n\n\nVervolgens krijgt u een nieuw scherm waarop u aangeeft hoe zeker u bent van uw oud/nieuw keuze.\n\n1. niet zeker [pijltje links]\n\n2. beetje zeker [pijltje beneden]\n\n3. heel zeker [pijltje rechts]\n\n\nEr volgt weer eerst een oefensessie.\n\n\nDruk op een toets om te beginnen',...
    'center', 'center', black);
% Flip to the screen
Screen('Flip', window);
WaitSecs(5);
KbStrokeWait;

%% LOOP %%
%Loop through all the rows from the file
r=2;
while r < length(raw(:,1))+1   
    r
    % Send markers
    if r == 2
        marker = 99; % start practice
        buttonbox(marker);
    elseif r == PracTrials + 2
        marker = 50; % start encoding
        buttonbox(marker);
    end
    
    %% FIXATION %%   
    % Draw fixation in the middle of the screen in Calibri in white
    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Calibri');
    DrawFormattedText(window, '+', 'center', 'center', black);
    
    % Flip to the screen
    Screen('Flip', window);
    
    % Send markers
    marker = 80; % fixation onset
    buttonbox(marker);
    
    % Wait for duration of fixation time
    WaitSecs(FixDur);
       
    %% IMGAGE %%
    
    % Here we load in the images from file from the current row. 
    currPicL = raw(r,1);
    currPicLoc = cellstr(fullfile(theImageLoc,'\',currPicL));
    theImageL = imread(currPicLoc{1});
    currPicR = raw(r,2);
    currPicLoc = cellstr(fullfile(theImageLoc,'\',currPicR));
    theImageR = imread(currPicLoc{1});

    % Make the image into a texture
    imageTextureL = Screen('MakeTexture', window, theImageL);
    imageTextureR = Screen('MakeTexture', window, theImageR);
    
    % Get the size of the image assumes that both images are equally sized
    [s1, s2, s3] = size(theImageL);
    
    % Get the aspect ratio of the image. We need this to maintain the aspect
    % ratio of the image when we draw it different sizes. Otherwise, if we
    % don't match the aspect ratio the image will appear warped / stretched
    aspectRatio = s2 / s1;
  
    % We will set the height of each drawn image to a fraction of the screens
    % height
    imageHeights = screenYpixels .* heightScalers;
    imageWidths = imageHeights .* aspectRatio;

    % Make the destination rectangles for our images.
    theRect = [0 0 imageWidths imageHeights];
    
    allRects = nan(4, numImages);
    for i = 1:numImages
    allRects(:, i) = CenterRectOnPointd(theRect, xCenter, yCenter);
    end
    
    % Draw the image to the screen, unless otherwise specified PTB will draw
    % the texture full size in the center of the screen. 
    % Check whether one or two pictures need to be presented and act
    % accordingly
    if cell2mat(raw(r,3)) == 1
        Screen('DrawTexture', window, imageTextureL, [], allRects(:,1));
        marker = 51; % Stimulus Onset Baseline Left 
    elseif cell2mat(raw(r,3)) == 2
        Screen('DrawTexture', window, imageTextureR, [], allRects(:,1));
        marker = 52; % Stimulus Onset Baseline Right
    elseif cell2mat(raw(r,3)) == 3
        Screen('DrawTexture', window, imageTextureL, [], allRects(:,1));
        marker = 53; % Stimulus Onset Distraction Left Target 
    elseif cell2mat(raw(r,3)) == 4
        Screen('DrawTexture', window, imageTextureR, [], allRects(:,1));
        marker = 54; % Stimulus Onset Distraction Right Target
    elseif cell2mat(raw(r,3)) == 30
        Screen('DrawTexture', window, imageTextureR, [], allRects(:,1));
        marker = 55; % Stimulus Onset Distraction Right Distractor 
    elseif cell2mat(raw(r,3)) == 40
        Screen('DrawTexture', window, imageTextureL, [], allRects(:,1));
        marker = 56; % Stimulus Onset Distraction Left Distractor 
    elseif cell2mat(raw(r,3)) == 91
        marker = 57; % Stimulus Onset New 
        Screen('DrawTexture', window, imageTextureL, [], allRects(:,1));
    elseif cell2mat(raw(r,3)) == 92
        Screen('DrawTexture', window, imageTextureR, [], allRects(:,1));
        marker = 57; % Stimulus Onset New
    end
    
    % Flip to the screen
    Screen('Flip', window); %fix this, frame rate stuff!
    
    % Send marker
    buttonbox(marker);
    
    % set time 0 (for reaction time)
    secs0=GetSecs;
      
    % Collect keyboard response

    % Wait for and checkwhich key was pressed
    secs1 = GetSecs;
    %responsenumber = [];
    ON_RT = 0;
    
    while (secs1 - secs0) < StimDur
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;

        response=KbName(keyCode);

        ONresponse=KbName(response);

        ON_RT=secs-secs0; % Get reaction time

        % 37 = left arrow, 39 = right arrow
        if ONresponse == 37
            % Send marker
            marker = 63; % Response Old
            buttonbox(marker);
        elseif ONresponse == 39
            % Send marker
            marker = 65; % Response New
            buttonbox(marker);
        end
        
        % Wait for duration of stimulus presentation or abort
        if keyIsDown == 1
            WaitSecs(StimDur - ON_RT); 
        end
        if ONresponse == 27 % escape
            sca;
        end
        
        % 37 = left arrow, 39 = right arrow
        if ONresponse == 37
            break
        elseif ONresponse == 39
            break
        end
        
        if ON_RT >= StimDur
            ON_RT = 0;
            ONresponse = 99;
            % Send marker
            marker = 68; % Response None
            buttonbox(marker); 
            ConfRT = 0;
            ConfResponse = 99;
        end
        
        secs1 = secs;
    end
    
    if ON_RT > 0
        %% CONFIDENCE JUDGEMENT %%
        % Draw 'hoe zeker' in the middle of the screen in Calibri in white
        Screen('TextSize', window, 30);
        Screen('TextFont', window, 'Calibri');
        DrawFormattedText(window, 'Hoe zeker?', 'center', 'center', black);

        % Flip to the screen
        Screen('Flip', window);

        % Send marker
        marker = 70; % Confidence Onset 
        buttonbox(marker); 

        % set time 0 (for reaction time)
        secs0=GetSecs;

        % Collect keyboard response

        % Wait for and checkwhich key was pressed
        secs1 = GetSecs;
        %responsenumber = [];
        ConfRT = 0;

        while (secs1 - secs0) < StimDur
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;

            response=KbName(keyCode);

            ConfResponse=KbName(response);

            ConfRT=secs-secs0; % Get reaction time

            % 37 = left arrow, 40 = down arrow, 39 = right arrow
            if ConfResponse == 37
                % Send marker
                marker = 73; % Response Confidence 1 
                buttonbox(marker);
            elseif ConfResponse == 40
                % Send marker
                marker = 75; % Response Confidence 2
                buttonbox(marker);
            elseif ConfResponse == 39
                % Send marker
                marker = 77; % Response Confidence 3
                buttonbox(marker);
            end

            % Wait for duration of stimulus presentation or abort
            if keyIsDown == 1
                WaitSecs(ConfDur - ConfRT); 
            end
            if ConfResponse == 27 % escape
                sca;
            end

            % 37 = left arrow, 40 = down arrow, 39 = right arrow
            if ConfResponse == 37
                break
            elseif ConfResponse == 40
                break
            elseif ConfResponse == 39
                break
            end

            if ConfRT >= ConfDur
                ConfRT = 0;
                ConfResponse = 99;
                % Send marker
                marker = 78; % Response Confidence No Response
                buttonbox(marker);
            end

            secs1 = secs;
        end
    end
    
    %% DATA %%
    % print results
    raw(r,1) 
    raw(r,2) 
    raw(r,3) 
    ONresponse 
    ON_RT 
    ConfResponse 
    ConfRT
    % Create results file
    Data.data(r,:)=[str2num(ppn) gender str2num(age) str2num(edu) r raw(r,1) raw(r,2) raw(r,3) ONresponse ON_RT ConfResponse ConfRT];
    Data.headers=['ppn' 'gender' 'age' 'edu' 'trial' 'pic_left' 'pic_right' 'opa' 'ONresponse' 'ON_RT' 'ConfResponse' 'ConfRT'];
    
    %% PRACTICE %%    
    if r == PracTrials + 1
        Screen('TextSize', window, 30);
        Screen('TextFont', window, 'Calibri');
        DrawFormattedText(window, 'Dit is het einde van het oefenblok Wil je nog een keer oefenen? (J/N)?', 'center', 'center', black);

        % Flip to the screen
        Screen('Flip', window);
        WaitSecs(5);
        KbWait([],2);
        
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;

        response=KbName(keyCode)

        responsenumber=KbName(response)

        if responsenumber == 74 %j
            r = 2;
        elseif responsenumber == 78 %n
        end
    elseif r == PracTrials + BlockTrials + 1 || r == PracTrials + BlockTrials*2 + 1 || r == PracTrials + BlockTrials*3 + 1 || r == PracTrials + BlockTrials*4 + 1 || r == PracTrials + BlockTrials*5 + 1
        Screen('TextSize', window, 30);
        Screen('TextFont', window, 'Calibri');
        DrawFormattedText(window, 'Pauze! Klik op een toets om verder te gaan', 'center', 'center', black);

        % Flip to the screen
        Screen('Flip', window);
        
        % Send marker
        marker = 90; % Rest onset 
        buttonbox(marker);  
        
        % wait 5 secs to avoid accidental buttonpresses and then wait for a keypress
        WaitSecs(5);
        KbStrokeWait;
        
        % Send marker
        marker = 91; % Rest offset 
        buttonbox(marker); 
    end
    r=r+1;    
    
    %% CLEAN-UP %%
    % save the data
    save(Outputfile,'Data')
    xlswrite(Outputfile2, Data.data)
    %clear the screen
    Screen('Close')
end
%% END %%
% Send markers
marker = 93; % end retrieval
buttonbox(marker);

% Show end text
Screen('TextSize', window, 30);
Screen('TextFont', window, 'Calibri');
DrawFormattedText(window,...
    'Dit is het einde van het tweede deel',...
    'center', 'center', black);
% Flip to the screen
Screen('Flip', window);
WaitSecs(5);    

%% BUTTON BOX %%
% initialisatie buttonbox, verbinden met seriele poort
if EEG == 1
    buttonbox('close');
end

%% CLEAN-UP %%
% save the data
save(Outputfile,'Data')
xlswrite(Outputfile2, Data.data)

% Clear the screen.
sca;