%% DSEEG_GrandAverage_TF_Analyses_Enc_AlphaLat

% Load in the data per subject group
for g=1:curexperiment.subject_groups
    if g==1
        age_group = 'OA'; % older adult
    elseif g==2
        age_group = 'YA'; % younger adult
    end 
    curexperiment.analysis_loc = fullfile(curexperiment.datafolder_output, sprintf('%s', curexperiment.name,'_',age_group));
    % find the files in the analyses folder
    TFdir      = fullfile(curexperiment.analysis_loc, sprintf('*TF*'));
    TFdf       = dir(TFdir);
    TFfiles    = {TFdf.name};
    clear TFdir
    clear TFdf
    
    % loop over the datasets
    for d=1:length(curexperiment.datasets_names)
        % find the files from the current dataset
        TFfiles_dat    = TFfiles(find(~cellfun('isempty',strfind(TFfiles,curexperiment.dataset_name{d}))));
        TFfiles_dat    = TFfiles_dat(find(cellfun('isempty',strfind(TFfiles_dat,'GrandAverage'))));        
        for l=1:curexperiment.levels
            % locate current level files
            evalc(sprintf('curlevnames = curexperiment.data%dl%d_name',d,l));
            display(sprintf('\n%s\n',curexperiment.level_name{l}(2:end)))
            TFfiles_lev =[];
            for i=1:length(curlevnames)
                TFfiles_lev = [TFfiles_lev TFfiles_dat(find(~cellfun('isempty',strfind(TFfiles_dat,strcat(curlevnames{i},'_')))))];
            end      
            for po=1:length(curexperiment.curpow)
                TFfiles_pow = TFfiles_lev(find(~cellfun('isempty',strfind(TFfiles_lev,curexperiment.curpow{po}))));
                if ~isempty(TFfiles_pow)
                    %% DEFINE CURRENT TRIALS
                    evalc(sprintf('curdat = curexperiment.data%d.l%d',d,l));
                    % loop over conditions
                    for c=1:length(fieldnames(curdat)) 
                        % create an array to hold the inputfiles for the different conditions
                        evalc(sprintf('curTFfiles = TFfiles_pow(find(~cellfun(''isempty'',strfind(TFfiles_pow,strcat(curexperiment.data%dl%d_name{c},''_'')))));',d,l));
                        for cf=1:length(curTFfiles)
                            inputfiles(c,cf) = fullfile(curexperiment.analysis_loc, curTFfiles(cf));
                        end
                    end
                    clear c
                    clear curdat
                    clear curTFfiles
                    clear TF_files_freq
                    clear cf

                    %% GRAND AVERAGE CALCULATION
                    evalc(sprintf('curconname = curexperiment.data%dl%d_name',d,l));
                    curconname = strrep(curconname,'_','');
                    cfg = [];
                    cfg.keepindividual = 'yes';
                    for i=1:size(inputfiles,1) 
                        cfg.inputfile = inputfiles(i, ~cellfun('isempty',inputfiles(i,:)));
                        display(sprintf('\n%s: Frequency analysis %s\n',age_group,curconname{i}));
                        GrandAverage_TF(i) = ft_freqgrandaverage(cfg);
                    end
                    clear inputfiles
                    clear i

                    %% SAVE DATA
                    curfolder = fullfile(curexperiment.datafolder_output, 'DSEEG_GroupAnalyses');
                    for i=1:length(GrandAverage_TF)
                        if not(isempty(GrandAverage_TF(i).powspctrm))
                            data_cond = GrandAverage_TF(i);
                            data_cond.cfg.previous = [];
                            display(sprintf('\nSaving %s\n',curconname{i}));
                            %evalc(sprintf('save([curfolder filesep age_group curexperiment.dataset_name{d} curexperiment.data%dl%d_name{i} curexperiment.curpow{po} ''_TF_GrandAverage''],''data_cond'',''-v7.3'')',d,l));
                            evalc(sprintf('save([curfolder filesep age_group curexperiment.dataset_name{d} curexperiment.data%dl%d_name{i} curexperiment.curpow{po} ''_TF_GrandAverage''],''data_cond'')',d,l));
                        end
                    end
                    clear data_cond
                    clear i
                    clear curconname
                    clear GrandAverage_TF*
                end
            end
        
        end

    end
end
clear g
clear d
clear matfiles
clear matdf