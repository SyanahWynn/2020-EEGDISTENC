%% DSEEG_CreateAnalysesFolder

% determine age_group
if exist(outputfile,'file')
   load(outputfile)
   if f <= length(Data.BehavRes.group)
       age_group = Data.BehavRes.group(f,:); 
   else
       age_group = 'Unknown';
   end
else
    age_group = 'Unknown';
end

% determine appropriate folder
curexperiment.analysis_loc = fullfile(curexperiment.datafolder_output, sprintf('%s', curexperiment.name,'_',age_group));
if ~exist(curexperiment.analysis_loc, 'dir')
    mkdir(curexperiment.analysis_loc);
end