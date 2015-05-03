%
% nets_stats - calculate various timeseries stats
% Steve Smith, 2013-2014
%
% [ts_stats] = nets_stats(ts);
%
% estimates mean and stddev (across subjects) for temporal stats:   stddev skewness kurtosis
%

function [ts_stats] = nets_stats(ts);

all_stats.std=[]; all_stats.skewness=[]; all_stats.kurtosis=[]; 
for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);
  all_stats.std      = [all_stats.std; std(grot)];
  all_stats.skewness = [all_stats.skewness; skewness(grot)];
  all_stats.kurtosis = [all_stats.kurtosis; kurtosis(grot)];
end

ts_stats.std.mean        = mean(all_stats.std);
ts_stats.std.std         = std(all_stats.std);
ts_stats.skewness.mean   = mean(all_stats.skewness);
ts_stats.skewness.std    = std(all_stats.skewness);
ts_stats.kurtosis.mean   = mean(all_stats.kurtosis);
ts_stats.kurtosis.std    = std(all_stats.kurtosis);

