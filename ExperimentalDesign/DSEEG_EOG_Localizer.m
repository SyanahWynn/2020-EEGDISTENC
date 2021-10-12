% Clear the workspace and the screen
sca;
close all;
clearvars;

%% SET-UP
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer. For help see: Screen Screens?
screens = Screen('Screens');

% Draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen. When only one screen is attached to the monitor we will draw to
% this. For help see: help max
screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% luminace values are (in general) defined between 0 and 1.
% For help see: help WhiteIndex and help BlackIndex
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window and color it black
% For help see: Screen OpenWindow?
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window in pixels
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing
% For help see: Screen BlendFunction?
% Also see: Chapter 6 of the OpenGL programming guide
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%% VARIABLES
EEG = 1; % 1 in case of EEG measurement, 0 in case of behavioral measurement
% location of the dots
x = [xCenter screenXpixels*.965 screenXpixels*.035...
    screenXpixels*.035 screenXpixels*.965 screenXpixels*.500...
    screenXpixels*.333 screenXpixels*.666];
y = [yCenter screenYpixels*.965 screenYpixels*.965...
    screenYpixels*.500 screenYpixels*.500 screenYpixels*.965...
    screenYpixels*.666 screenYpixels*.666];
dotPositionMatrix = [x;y];
% Set the size of the dots
dotSize = 30;
% make an array that references to the dot positions, except the first
% (centre dot)
dotLoc = [randperm(length(dotPositionMatrix)) randperm(length(dotPositionMatrix)) randperm(length(dotPositionMatrix))];
dotLoc = dotLoc(dotLoc~=1);
% Set the color of our dots to zero
dotColors = [zeros(size(x));zeros(size(x));zeros(size(x))];
RestrictKeysForKbCheck([37, 39, 27, 74, 78]); %left arrow, right arrow, down arrow, escape, j, n
% set the presentation time of the dots
stimTime = 2;
%% BUTTON BOX %%
% initialisatie buttonbox, verbinden met seriele poort
if EEG == 1
    handle = buttonbox('open');
elseif EEG == 0
    buttonbox = zeros(100);
end

%% INTRO %%
Screen('TextSize', window, 30);
Screen('TextFont', window, 'Calibri');
DrawFormattedText(window,...
    'Welkom.\n\nU krijgt straks stippen op het scherm te zien.\n het is de bedoeling dat u naar de stip op het scherm kijk tot deze verdwijnt.\nZodra er een nieuwe stip verschijnt kijkt u daar naar totdat deze verdwijnt, enz.\n\nDe stippen zullen 2 seconden op het scherm blijven staan.\n\n\nWanneer u klaar bent voor de oefensessie, druk op een pijltje',...
    'center', 'center', white);
% Flip to the screen
Screen('Flip', window);
WaitSecs(5);
% Marker begin
marker = 30;
buttonbox(marker);
KbStrokeWait;

%% LOOP
% loop over the dot locations and make the dots appear
i=1;
for dot=1:length(dotLoc)*2+1
    % color the current dot
    if mod(dot,2) ~= 0
        dotColors(:,1)= [1 1 1];
        marker = 1; % centre
        buttonbox(marker);
    else
        dotColors(:,dotLoc(i)) = [1 1 1];
        marker = dotLoc(i); % loc other dots
        buttonbox(marker);
        i = i + 1;
    end
    
    % Draw all of our dots to the screen in a single line of code
    % For help see: Screen DrawDots
    Screen('DrawDots', window, dotPositionMatrix,...
        dotSize, dotColors, [], 2);

    % Flip to the screen. This command basically draws all of our previous
    % commands onto the screen. See later demos in the animation section on more
    % timing details. And how to demos in this section on how to draw multiple
    % rects at once.
    % For help see: Screen Flip?
    Screen('Flip', window);
    
    % Set the color of our dots to zero
    dotColors = [zeros(size(x));zeros(size(x));zeros(size(x))];
    
    % abort experiment when needed
    % set time 0 (for reaction time)
    secs0=GetSecs;
    secs1 = GetSecs;
    while (secs1 - secs0) < stimTime
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        response=KbName(keyCode);
        responsenumber=KbName(response);
        if responsenumber == 27 % escape
            break
            sca;
        end
        secs1 = secs;
    end
    % Wait for two seconds
    % WaitSecs(2);
end  
 
% Marker end
marker = 30;
buttonbox(marker);    

%% BUTTON BOX %%
% initialisatie buttonbox, verbinden met seriele poort
if EEG == 1
    buttonbox('close');
end

% Clear the screen. "sca" is short hand for "Screen CloseAll". This clears
% all features related to PTB. Note: we leave the variables in the
% workspace so you can have a look at them if you want.
% For help see: help sca
sca;