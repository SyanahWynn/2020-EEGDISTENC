%% DSEEG_Filtering

% loop over the datasets
for d=1:length(curexperiment.datasets)
    % resample if neccesary
    if curexperiment.datasets(d).fsample ~=1024
        cfg.resamplefs = 1024;
        data_resample = ft_resampledata(cfg, curexperiment.datasets(d));
        cfg = [];
        evalc(sprintf('clear %s', curexperiment.datasets_names{d}));
        eval(sprintf('%s = ft_preprocessing(cfg,data_resample);',curexperiment.datasets_names{d}));
        % update the datasets
        evalc(curexperiment.define_datasets);
    end
    cfg             = [];
    cfg.bpfilter    = 'yes';
    cfg.bpfreq      = [curexperiment.bp_lowfreq curexperiment.bp_highfreq];
    % filter the data
    data_filter     = ft_preprocessing(cfg, curexperiment.datasets(d));
    cfg             = [];
    evalc(sprintf('cfg.toilim = [-curexperiment.prestim%d+.5 curexperiment.poststim%d-.5];', d,d));
    data_filter     = ft_redefinetrial(cfg,data_filter);
        
    % save the filtered data
    evalc(sprintf('%s = data_filter;', curexperiment.datasets_names{d}));
    evalc(sprintf('cur_hdr = any(strcmp(''hdr'',fieldnames(%s)));',curexperiment.datasets_names{d}));
    if cur_hdr
        evalc(sprintf('%s = rmfield(%s,''hdr'');', curexperiment.datasets_names{d},curexperiment.datasets_names{d}));
    end
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_Filtered.mat'], curexperiment.datasets_names{d});
    clear data_filter
end

% update the datasets
evalc(curexperiment.define_datasets);