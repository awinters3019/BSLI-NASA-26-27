%% rerun_failed.m -- rerun only the runs with ok == false, same inputs and seeds
scripts_dir = fileparts(mfilename('fullpath'));
parent_path = fileparts(scripts_dir);
model_dir   = fullfile(parent_path, 'model');
data_dir    = fullfile(parent_path, 'data');
addpath(model_dir, data_dir, scripts_dir);

mdl = 'TDOF_simulink_v2';                       % your current model name
load_system(fullfile(model_dir, [mdl '.slx']));
outdir = fullfile(parent_path, 'results');

L = load(fullfile(outdir,'mc_profiles.mat'));   % M, PR, tgrid, cfg
M = L.M;  PR = L.PR;  tgrid = L.tgrid;  cfg = L.cfg;

[envP0, ~, ~, ~, launch0] = initialize_vars(data_dir);
bad = find(~M.ok)';
fprintf('Rerunning %d failed runs\n', numel(bad));

for i = bad
    in  = buildInput(mdl, M(i,:), envP0, launch0, cfg);   % same inputs and gust_seed
    out = sim(in);
    [m, p] = extractRun(out, tgrid, cfg);
    for f = fieldnames(m)'
        M.(f{1})(i) = m.(f{1});
    end
    for n = fieldnames(p)'
        PR.(n{1})(i,:) = p.(n{1});
    end
    fprintf('run_id %d: ok = %d  %s\n', M.run_id(i), M.ok(i), M.err(i));
end

save(fullfile(outdir,'mc_profiles.mat'), 'M','PR','tgrid','cfg','-v7.3');
writetable(M, fullfile(outdir,'mc_summary.csv'));