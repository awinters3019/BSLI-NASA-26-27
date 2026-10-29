%% MonteCarlo.m  -- batch Monte Carlo for the 3-DOF rocket model
clear; clearvars; clc;
% locate project folders from this file's own location
scripts_dir = fileparts(mfilename('fullpath'));      % .../3-DOF/scripts
parent_path = fileparts(scripts_dir);                % .../3-DOF
model_dir   = fullfile(parent_path, 'model');        % .../3-DOF/model
data_dir    = fullfile(parent_path, 'data');         % .../3-DOF/data
addpath(model_dir, data_dir, scripts_dir);
mdl = 'TDOF_simulink_v2';                       % model name; no .slx
assert(isfile(fullfile(model_dir, [mdl '.slx'])), 'Model not found in %s', model_dir);
load_system(fullfile(model_dir, [mdl '.slx']));

%% ---------------- 1. Configuration ----------------
cfg.pressure_psf = linspace(2086, 2125, 4);     % 13 psf steps
cfg.temp_R       = linspace(1532/3, 1589/3, 4); % ~6.3 R steps
cfg.cant_deg     = linspace(5, 10, 5);          % 1.25 deg steps
cfg.wind_mph     = [0 5 10 15 20];
cfg.n_seeds      = 6;      % gust seeds per condition (wind > 0 only)
cfg.cant_sign    = +1;     % +1 = tilt INTO the wind, -1 = with it
cfg.gust_frac    = 0.2;    % gust_sigma = 0.2 * mean wind
cfg.dt           = 0.2;    % s, stored-profile resolution
cfg.t_max        = 250;    % s, profile grid length
cfg.sim_stop     = 400;    % s, safety stop (runs hitting this are flagged landed=false)
nWorkers = 4;              % cores dedicated to the Monte Carlo
pool = gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers ~= nWorkers
    delete(pool);  pool = [];       % wrong size, restart it
end
if isempty(pool)
    parpool('Processes', nWorkers);
end
cfg.batch_size = 16*nWorkers;       % 96, a multiple of the worker count
cfg.save_extras  = true;   % also store theta(t), q(t)
cfg.n_pilot      = 0;     % >0 = smoke test with this many runs; set 0 for the full run

[envP0, r0, data0, chute0, launch0] = initialize_vars(data_dir);

%% ---------------- 2. Build the run table ----------------
[P,T,C,W,S] = ndgrid(cfg.pressure_psf, cfg.temp_R, cfg.cant_deg, cfg.wind_mph, 1:cfg.n_seeds);
runs = table(P(:),T(:),C(:),W(:),S(:), 'VariableNames', ...
             {'P_psf','T_R','cant_deg','wind_mph','seed_idx'});
runs(runs.wind_mph==0 & runs.seed_idx>1, :) = [];   % no gusts at 0 wind -> extra seeds are duplicates
runs.run_id    = (1:height(runs))';
runs.gust_seed = runs.run_id;                       % incrementing, unique, replayable
rng(0);  runs = runs(randperm(height(runs)), :);    % shuffle: stopping early still gives a fair sample
if cfg.n_pilot > 0, runs = runs(1:cfg.n_pilot, :); end
N = height(runs);

tgrid = (0:cfg.dt:cfg.t_max)';
nProf = 4 + 2*cfg.save_extras;
fprintf('%d runs, ~%.0f MB of profiles\n', N, N*numel(tgrid)*nProf*4/1e6);

outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(outdir,'dir'), mkdir(outdir); end

%% ---------------- 3. Run in batches ----------------
nB = ceil(N/cfg.batch_size);
for b = 1:nB
    f = fullfile(outdir, sprintf('mc_batch_%03d.mat', b));
    if isfile(f), fprintf('Batch %d exists, skipping\n', b); continue; end
    idx = (b-1)*cfg.batch_size+1 : min(b*cfg.batch_size, N);

    clear in
    for k = 1:numel(idx)
        in(k) = buildInput(mdl, runs(idx(k),:), envP0, launch0, cfg); %#ok<SAGROW>
    end

    tic
    paths = {model_dir, data_dir, scripts_dir};
    out = parsim(in, 'ShowProgress','on', ... 'TransferBaseWorkspaceVariables','off', ...
             'SetupFcn', @() addpath(paths{:}));
    clear m prof
    for k = 1:numel(idx)
        [m(k), prof(k)] = extractRun(out(k), tgrid, cfg); %#ok<SAGROW>
    end
    M = [runs(idx,:), struct2table(m)];
    PR = struct();
    for n = fieldnames(prof)'
        PR.(n{1}) = vertcat(prof.(n{1}));
    end
    save(f, 'M', 'PR', '-v7');

    % Did the overrides actually reach the model? (see "Pilot check")
    dev = max(abs(M.T0_logged - M.T_R), [], 'omitnan');
    fprintf('Batch %d/%d: %.0f s, %d failed, max T-override error %.3g R\n', ...
            b, nB, toc, sum(~M.ok), dev);
    if dev > 1e-3
        warning('Overrides are NOT reaching the model - see the initialize_vars guard.');
    end
end

%% ---------------- 4. Merge ----------------
files = dir(fullfile(outdir, 'mc_batch_*.mat'));
M = table();  PR = struct();
for i = 1:numel(files)
    s = load(fullfile(outdir, files(i).name));
    M = [M; s.M]; %#ok<AGROW>
    for n = fieldnames(s.PR)'
        if ~isfield(PR, n{1}), PR.(n{1}) = []; end
        PR.(n{1}) = [PR.(n{1}); s.PR.(n{1})];
    end
end
save(fullfile(outdir,'mc_profiles.mat'), 'M','PR','tgrid','cfg','-v7.3');
writetable(M, fullfile(outdir,'mc_summary.csv'));
fprintf('Done: %d runs merged -> %s\n', height(M), outdir);