%% DSEEG_TrialCount
% count the trialtypes

% load the data
if exist(outputfile,'file')
   load(outputfile)
end

% determine age group
if f <= length(Data.BehavRes.group)
   age_group = Data.BehavRes.group(f,:); 
else
   age_group = 'Unknown';
end

% loop through the datasets
for d=1:length(curexperiment.datasets)
    % get all possible markers
    evalc(sprintf('markers = cell2mat(table2cell(struct2table(curexperiment.data%d.l%d)));',d,curexperiment.levels));
    % count the markers
    for i=1:length(markers)
      evalc(sprintf('count(i) = sum(%s.trialinfo(:,1)==markers(i))',curexperiment.datasets_names{d}));
    end
    evalc(sprintf('fldnms = fieldnames(curexperiment.data%d.l%d);',d,curexperiment.levels));
    % linkcount to conditions
    for i=1:length(fldnms)
        evalc(sprintf('conmarkers = curexperiment.data%d.l%d.%s;',d,curexperiment.levels,fldnms{i}));
        concount(i) = sum(count(ismember(markers,conmarkers)));
    end
    % wrapping up
    evalc(sprintf('connames = char(curexperiment.data%dl%d_name);',d,curexperiment.levels));
    count_tab = array2table(concount,'VariableNames',cellstr(connames(:,2:end)),'RowNames',{subjectdata.subjectnr})
    try
        evalc(sprintf('Data.TrialCount.%s.%s = [Data.TrialCount.%s.%s; count_tab];',age_group,curexperiment.dataset_name{d}(2:end),age_group,curexperiment.dataset_name{d}(2:end)));
    catch
        evalc(sprintf('Data.TrialCount.%s.%s = count_tab;',age_group,curexperiment.dataset_name{d}(2:end)));
    end
    clear markers count fldnms conmarkers connames concount count_tab
end
clear age_group
save(outputfile,'Data')