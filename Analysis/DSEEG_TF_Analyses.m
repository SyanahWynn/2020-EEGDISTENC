%% DSEEG_TF_Analyses
% Do within subject time-frequency analyses

% determine subject frequency data
TFdir      = fullfile(curexperiment.analysis_loc, sprintf('%s*TF.mat*',subjectdata.subjectnr));
TFdf       = dir(TFdir);
TFfiles    = {TFdf.name};

% set the names of the frequency ranges of interest
freq_names = fieldnames(curexperiment.freq_interest);

% loop over the datasets
for d=1:length(curexperiment.datasets)
    % locate current dataset files
    display(sprintf('\n%s\n', curexperiment.dataset_name{d}(2:end)))
    TFfiles_dat = TFfiles(find(~cellfun('isempty',strfind(TFfiles,curexperiment.dataset_name{d}))));
    % loop over all levels of processing
    for l=1:curexperiment.levels
        % locate current level files
        evalc(sprintf('curlevnames = curexperiment.data%dl%d_name',d,l));
        display(sprintf('\n%s %s\n',subjectdata.subjectnr,curexperiment.level_name{l}(2:end)))
        TFfiles_lev =[];
        for i=1:length(curlevnames)
            TFfiles_lev = [TFfiles_lev TFfiles_dat(find(~cellfun('isempty',strfind(TFfiles_dat,strcat(curlevnames{i},'_')))))];
        end
        %% TRIAL SELECTION
        % Select trials based upon condition
        cfg = [];
        %define the current dataset
        evalc(sprintf('curdat = curexperiment.data%d.l%d',d,l));
        for t=1:length(fieldnames(curdat))
            % define the current condition
            evalc(sprintf('curcond = curexperiment.data%d.l%d.condition%d',d,l,t));
            % find the trails corresponding to the current condition
            cfg.trials = find(ismember(curexperiment.datasets(d).trialinfo(:,1),curcond)); 
            data(t) = ft_selectdata(cfg,curexperiment.datasets(d));
            if l==2 % FamRec analyses
                evalc(sprintf('post_data_%s(f,t) = length(cfg.trials);',curexperiment.datasets_names{d}(6:end)));
            end
        end
        clear curdat
        clear curcond
        clear t

        %% TOTAL POWER
        % loop over them and do freq analyses
        for fr=1:length(fieldnames(curexperiment.freq_interest))         
            % frequency analyses per condition
            cfg              = [];
            cfg.output       = 'pow';
            cfg.channel      = 'EEG';
            cfg.method       = 'mtmconvol';
            cfg.taper        = 'hanning';
            cfg.foi          = getfield(curexperiment.freq_interest, freq_names{fr}); 
            cfg.t_ftimwin    = ones(length(cfg.foi)).*getfield(curexperiment.timwin, freq_names{fr});
            evalc(sprintf('cfg.toi = -curexperiment.prestim%d:.01:curexperiment.poststim%d-1;',d,d));
            for i=1:length(data)
                display(sprintf('\nCurrent frequency analysis:'))
                display(eval(sprintf('curexperiment.data%dl%d_name{i}(2:end)\n',d,l)))
                if not(isempty(data(i).trialinfo))
                    evalc(sprintf('data_freq_%s(i) = ft_freqanalysis(cfg, data(i));',freq_names{fr}));               
                end
            end
            % check for missing data
            for i=1:length(data)
                if isempty(data(i).trialinfo)
                    for i2=1:length(data)
                        if not(isempty(data(i2).trialinfo))
                            evalc(sprintf('data_freq_%s(i) = data_freq_%s(i2);',freq_names{fr},freq_names{fr}));
                            evalc(sprintf('data_freq_%s(i).powspctrm = NaN(size(data_freq_%s(i).powspctrm));',freq_names{fr},freq_names{fr}));
                            break
                        end
                        if i2==length(data)
                            error('Missing data')
                        end
                    end
                    
                end
            end    
        end
        clear data
        clear i
        clear fr

        %% SAVE DATA TOTAL POWER
        for fr=1:length(fieldnames(curexperiment.freq_interest))
            evalc(sprintf('data_freq = data_freq_%s;',freq_names{fr}));
            for i=1:length(data_freq)
                %if not(isempty(data_freq(i).powspctrm))
                    data_cond = data_freq(i);
                    data_cond.cfg.previous = [];
                    evalc(sprintf('save([curexperiment.analysis_loc filesep subjectdata.subjectnr curexperiment.dataset_name{d} curexperiment.data%dl%d_name{i} ''_Total_TF''],''data_cond'')',d,l));
                %end
            end
        end
        clear data_cond data_freq*
        
    end   
end

clear d
clear TFfiles
clear TFdf
clear TFdir
clear fr
clear l