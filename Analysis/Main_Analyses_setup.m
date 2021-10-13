%% Main_Analyses_set-up

% profile on
warning('off','all');
%warning;

%% CLEAN-UP
clear all
close all

%% PC
% current pc/laptop/external disk
curpc = 'CURRENT_DEVICE';

if strcmp(curpc,'CURRENT_DEVICE')
    curexperiment.dirroot = 'START_OF_PATH_THAT_DIFFERS_PER_DEVICE';
end

%% LOCATE FIELDTRIP FOLDER
cd(strcat(curexperiment.dirroot, 'Fieldtrip'))

%% SET CURRENT EXPERIMENT
% current experiment
sprintf('\nSET CURRENT EXPERIMENT');
% determine the current experiment
curexperiment.name   = 'DSEEG';

% determine if artifact rejection and ICA need to be done checked
% prompt                      = '\nDo you want to check the artifacts before deleting them and do you want to check the ICA-ed data?\n both=1, only artifacts=2, only ICA=3, none=4\n';
% curexperiment.manualcheck   = str2double(input(prompt,'s'));
curexperiment.manualcheck   = 1;

%% FILE LOCATIONS
% DSEEG
curexperiment.scriptdir = strcat(curexperiment.dirroot,'DSEEG_EEGdata/DSEEGFieldtripAnalyses/');
% add script directory to path
addpath(genpath(fullfile(curexperiment.scriptdir)))

% current experiment variables
eval([curexperiment.name '_Variables'])

%% LOCATIONS
% add the Fieldtripfolder to the path
addpath('Fieldtrip/fieldtrip-20160401')
ft_defaults % sets the defaults and configuresup the minimal required path settings

% locate the raw EEG files on the disk
df=[];
for i=1:length(curexperiment.extension)
    df = [df;dir(fullfile(curexperiment.datafolder_input, curexperiment.extension{i}))];
end
files = sort({df.name});
outputfile = fullfile(curexperiment.datafolder_output, sprintf('_%s_Stats.mat',curexperiment.name));
outputfile_stats = fullfile(curexperiment.datafolder_output, sprintf('_%s_Stats.mat',curexperiment.name));

try
    % EEG template
    if isfield(curexperiment,'elec')
        curexperiment.elecs          = ft_read_sens(curexperiment.elec.lay);
    end
catch
    fprintf('\nNo EEG template created\n')
end

try
    % Channel neighbours
    % E266 and E127 do not have neighbours with the distance method
    cfg               = [];
    cfg.method        = 'triangulation'; %distance
    %cfg.neighbourdist = 3;
    cfg.feedback      = 'no';
    curexperiment.neighbours        = ft_prepare_neighbours(cfg,curexperiment.elecs);
catch
    fprintf('\nno channel neighbours determined\n')
end

clear df

% Warning messages are only printed once per timeout period using
ft_warning timeout 60
ft_warning once
