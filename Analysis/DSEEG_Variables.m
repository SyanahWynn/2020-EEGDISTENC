%% DSEEG VARIABLES
% location of the EEG data
if strcmp(curpc,'CURRENT_DEVICE')
    curexperiment.datafolder_input  = 'LOCATION_OF_RAW_EEG_DATA'; 
end
% location of the behavioral data
if strcmp(curpc,'CURRENT_DEVICE')
    curexperiment.datafolder_inputbehav  = 'LOCATION_OF_RAW_BEHAVIORAL_FILES';
end
% location of outputfiles
if strcmp(curpc,'CURRENT_DEVICE')
    curexperiment.datafolder_output = 'LOCATION_OF_OUTPUTFILES';
end
% extension of the EEG files
curexperiment.extension             = '*.bdf';
% EEG template
curexperiment.elec.lay                = 'biosemi32.lay'; % will be loaded as a layout in curexperiment.elecs
% number of trials
curexperiment.Ntrials_ret           = 990;
curexperiment.Ntrials_enc           = 396;
curexperiment.Ntrials_prac          = 15;
curexperiment.ROCBlockL             = 6; % 1x for baseline, 2x for distraction
% the value you need to substract from the MATLAB markers to get the original EEG markers
curexperiment.marker_offset         = 64512;
% epoch event type
curexperiment.eventtype             = 'STATUS';
% pre- and post stimulus time
curexperiment.prestim1              = 2; % encoding % add .5 more for data padding
curexperiment.poststim1             = 2; % encoding % add .5 more for data padding
curexperiment.prestim2              = 1.5;  % retrieval % add .5 more for data padding
curexperiment.poststim2             = 2.5; % retrieval % add .5 more for data padding
curexperiment.prestim3              = 0;  % localizer
curexperiment.poststim3             = 2; % localizer
% original markers
description                         = {'Start Practice Trial', ...
                                    'Start Encoding', 'Encoding Stimulus Onset Baseline Left', 'Encoding Stimulus Onset Baseline Right', ...
                                    'Encoding Stimulus Onset Distraction Left Target', 'Encoding Stimulus Onset Distraction Right Target',...
                                    'Response Natural', 'Response Manmade', 'Response None Enc',...
                                    'Fixation Onset Enc', 'Cue Onset', 'Rest onset', 'Rest offset', 'End Encoding',...
                                    'Start Retrieval', 'Retrieval Stimulus Onset Baseline Left', 'Retrieval Stimulus Onset Baseline Right',...
                                    'Retrieval Stimulus Onset Distraction Left Target', 'Retrieval Stimulus Onset Distraction Right Target',...
                                    'Retrieval Stimulus Onset Distraction Right Distractor', 'Retrieval Stimulus Onset Distraction Left Distractor',...
                                    'Retrieval Stimulus Onset New', 'Response Old', 'Response New', 'Response None ON', ...
                                    'Confidence Onset', 'Response Confidence 1', 'Response Confidence 2', 'Response Confidence 3', 'Response Confidence None', ...
                                    'Fixation Onset Ret', 'End Retrieval',...
                                    'Begin Localizer/End Localizer', 'Centre', 'Bottom Right', 'Bottom Left',...
                                    'Middle Left', 'Middle Right', 'Bottom Middle',...
                                    '2/3 Left', '2/3 Right'};
original_marker                     = {99,...
                                    10,21,22,...
                                    23,24,...
                                    33,35,38,...
                                    40,45,90,91,13,...
                                    50,51,52,...
                                    53,54,...
                                    55,56,...
                                    57,63,65,68,...
                                    70,73,75,77,78,...
                                    80,93,...
                                    30,1,2,3,...
                                    4,5,6,...
                                    7,8}';
count_without_practice              = {2,...
                                    1,66,66,...
                                    132,132,...
                                    [],[],[],...
                                    396,396,7,7,1,...
                                    1,66,66,...
                                    132,132,...
                                    132,132,...
                                    330,[],[],[],...
                                    [],[],[],[],[],...
                                    990,1,...
                                    2,15,2,2,...
                                    2,2,2,...
                                    2,2}';
cur_count                           = zeros(length(description),1);
%curexperiment.original_markers      = struct('description', description, 'original_marker', original_marker, 'count', count_without_practice);
curexperiment.original_markers       = table(original_marker,count_without_practice,cur_count,'RowNames',description);
clear original_marker
clear count_without_practice
clear description
curexperiment.markers.enc           = [21,22,23,24]; % stimulus onset markers
curexperiment.markers.ret           = [51,52,53,54,55,56,57]; % stimulus onset markers
% levels of processing
curexperiment.levels                = 2;
curexperiment.level_name{1}         = '_MemoryGlobal';
curexperiment.level_name{2}         = '_MemorySpecific';
% conditions

%% only if you analyze enc separate for cue and stim window
curexperiment.data1.l1.condition1    = [311,313];                            curexperiment.data1l1_name{1}   = '_LowDistractionL'; % encoding, subsequent baseline left
curexperiment.data1.l1.condition2    = [321,323];                            curexperiment.data1l1_name{2}   = '_LowDistractionR'; % encoding, subsequent baseline right
curexperiment.data1.l1.condition3    = [3111,3113,3131,3133];                curexperiment.data1l1_name{3}   = '_HighDistractionL'; % encoding, subsequent baseline left
curexperiment.data1.l1.condition4    = [3211,3213,3231,3233];                curexperiment.data1l1_name{4}   = '_HighDistractionR'; % encoding, subsequent baseline right

curexperiment.data1.l2.condition1    = 311;                                  curexperiment.data1l2_name{1}   = '_HitLowDistractionL';% encoding, baseline left subsequent hit
curexperiment.data1.l2.condition2    = 321;                                  curexperiment.data1l2_name{2}   = '_HitLowDistractionR';% encoding, baseline right subsequent hit
curexperiment.data1.l2.condition3    = 313;                                  curexperiment.data1l2_name{3}   = '_MissLowDistractionL';% encoding, baseline left subsequent miss
curexperiment.data1.l2.condition4    = 323;                                  curexperiment.data1l2_name{4}   = '_MissLowDistractionR';% encoding, baseline right subsequent miss
curexperiment.data1.l2.condition5    = [3111, 3113];                         curexperiment.data1l2_name{5}   = '_HitHighDistractionL';% encoding, target left target hit distractor hit
curexperiment.data1.l2.condition6    = [3211, 3213];                         curexperiment.data1l2_name{6}   = '_HitHighDistractionR';% encoding, target right target hit distractor hit
curexperiment.data1.l2.condition7    = [3131, 3133];                         curexperiment.data1l2_name{7}   = '_MissHighDistractionL';% encoding, target left target miss distractor hit
curexperiment.data1.l2.condition8    = [3231, 3233];                         curexperiment.data1l2_name{8}   = '_MissHighDistractionR';% encoding, target right target miss distractor hit

% EOG localizer
curexperiment.data3.l1.condition1      = 1; % centre
curexperiment.data3.l1.condition2      = 2; % bottom right
curexperiment.data3.l1.condition3      = 3; % bottom left
curexperiment.data3.l1.condition4      = 4; % middle left
curexperiment.data3.l1.condition5      = 5; % middle right
curexperiment.data3.l1.condition6      = 6; % bottom middle
curexperiment.data3.l1.condition7      = 7; % 2/3 left
curexperiment.data3.l1.condition8      = 8; % 2/3 right

% online reference / implicit reference (non-recorded)
curexperiment.extelec.impref        = 'CSM';
% desired new/offline reference(s)
curexperiment.extelec.newref1       = 'EXG5'; % left mastoid
curexperiment.extelec.newref2       = 'EXG6'; % right mastoid
% EOG electrodes
curexperiment.extelec.heog_l        = 'EXG1'; %left HEOG electrode
curexperiment.extelec.heog_r        = 'EXG2'; %right HEOG electrode
curexperiment.extelec.veog_t        = 'EXG3'; %top VEOG electrode
curexperiment.extelec.veog_b        = 'EXG4'; %bottom VEOG electrode
% number of EEG electrodes
curexperiment.Nelectrodes           = 32;
% number of external electrodes
curexperiment.Nextelectrodes        = 8;
% % filtering
curexperiment.bp_lowfreq            = .5;
curexperiment.bp_highfreq           = 30;

% dataset names
curexperiment.datasets_names        = {'data_enc_cue', 'data_enc_stim'};
curexperiment.define_datasets       = 'curexperiment.datasets = [data_enc_cue, data_enc_stim]';
curexperiment.dataset_name{1}       = '_EncData_cue';
curexperiment.dataset_name{2}       = '_EncData_stim';

% list of analyses to be done
curexperiment.analyses              = {'pow','erp'};
curexperiment.Nanalyses.tp          = 29; % amount of outputfiles tf
curexperiment.Nanalyses.plt         = 0; % amount of outputfiles plotting
curexperiment.Nanalyses.erp         = 16; % amount of outputfiles ERP
curexperiment.Nanalyses.ep          = 0; % amount of outputfiles EP
% plotting
curexperiment.plotchannels          = {'O1', 'Oz', 'O2', 'PO3', 'PO4', 'P7', 'P3', 'Pz', 'P4', 'P8'};
curexperiment.plotchannels_left     = {'O1', 'PO3', 'P3', 'P7'};
curexperiment.plotchannels_right    = {'O2', 'PO4', 'P4', 'P8'};
curexperiment.plotfont              = 5;
curexperiment.plotcolors            = [.4 .6 1;.8 .8 1;0 0 0;.8 .8 .8];
curexperiment.plotgroups            = ones(36,1);
curexperiment.plotgroups(1:2)       = 2;
curexperiment.plotgroups(13:22)     = 3;
curexperiment.plotgroups(35:36)     = 4;
% power analyses
curexperiment.freq_interest.low     = 2:2:30; % (low) frequencies of interest
curexperiment.timwin.low            = 0.5; % length of timewindow for the low frequencies
curexperiment.baselinewindow        = [-1.25 -1]; % baseline window
curexperiment.baselinetype          = 'relchange'; % baseline window
curexperiment.curpow                = {'_Total'}; % set the current power type of interest
% define the subject groups
curexperiment.subject_groups        = 2; % amount of subject groups
curexperiment.subject_groups_names  = {'OA','YA'};
curexperiment.Nses                  = 1;
curexperiment.Nppn                  = 59;
curexperiment.behav.file_format     = {'%f%s%f%s%s%f%f','%f%s%f%s%f%s%f%f%s%f%f%f'}; % file format of phase input files
curexperiment.behav.vars            = [{'ppn' 'gender' 'age' 'edu' 'trialnr' 'pic_left' 'pic_right' 'enc_trialtype' 'enc_resp' 'enc_RT','',''};...
                                      {'ppn' 'gender' 'age' 'edu' 'trialnr' 'pic_left' 'pic_right' 'ret_trialtype' 'ret_resp' 'ret_RT' 'conf_resp' 'conf_RT'}];
curexperiment.behav.ext             = '.xlsx'; %extension of inputfiles
