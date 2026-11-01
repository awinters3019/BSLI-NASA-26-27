function MonteCarlo(cfg)
% MONTECARLO  Batch Monte Carlo driven entirely by a config struct.
%   MonteCarlo()         uses config()
%   MonteCarlo(cfg)      uses a modified config (see scripts/experiments/)
%
% Function calls in the MonteCarlo:
%   writeSnapshot: Documents the configuration that was used.
%   buildRunTable: Creates permutation table of run inputs that will be
%     sent to Simulink.
%   buildInput: formats configured sweeps and builds parameters in a way
%     that Simulink can interpret.
%   extractRun: takes the output of a finished run and begins the process
%     of turning it into data.
%
% ** Needs MATLAB's Parallel Computing Toolbox. **

%% --------- 1. Locate project folders and load the model ---------
if nargin < 1, cfg = config(); end
scripts_dir = fileparts(mfilename('fullpath'));      % .../3-DOF/scripts
parent_path = fileparts(scripts_dir);                % .../3-DOF
model_dir   = fullfile(parent_path, 'model');
data_dir    = fullfile(parent_path, 'data');
func_dir    = fullfile(scripts_dir, 'functions');
addpath(model_dir, data_dir, scripts_dir, func_dir);

mdl = cfg.sim.model;                                 % model name, no .slx
assert(isfile(fullfile(model_dir, [mdl '.slx'])), 'Model not found in %s', model_dir);
load_system(fullfile(model_dir, [mdl '.slx']));

%% --------- 2. Output folder and config snapshot ---------
outdir = fullfile(parent_path, 'results', cfg.name);
if cfg.mc.n_pilot > 0
    outdir = [outdir '_pilot'];       % pilots never mix with the full run
end
writeSnapshot(cfg, outdir);           % documents the run, guards against mixing configs

%% --------- 3. Run table ---------
T = buildRunTable(cfg);
if cfg.mc.n_pilot > 0, T = T(1:min(cfg.mc.n_pilot, height(T)), :); end
N = height(T);
tgrid = (0:cfg.out.dt:cfg.out.t_max)';
nProf = 4 + 2*cfg.out.save_extras;
fprintf('%d runs, ~%.0f MB of profiles, output: %s\n', ...
        N, N*numel(tgrid)*nProf*4/1e6, outdir);

%% --------- 4. Parallel pool ---------
nWorkers = cfg.mc.n_workers;
pool = gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers ~= nWorkers
    delete(pool);  pool = [];
end
if isempty(pool)
    parpool('Processes', nWorkers);
end
paths = {model_dir, data_dir, scripts_dir, func_dir};   % workers don't inherit the client path

%% --------- 5. Batches ---------
bs = cfg.mc.batch_size;
nB = ceil(N/bs);
for b = 1:nB
    f = fullfile(outdir, sprintf('mc_batch_%03d.mat', b));
    if isfile(f)
        fprintf('Batch %d/%d exists, skipping\n', b, nB); 
        continue; 
    end
    idx = (b-1)*bs+1 : min(b*bs, N);
    K   = numel(idx);

    % build one SimulationInput per run
    in = repmat(Simulink.SimulationInput(mdl), 1, K);
    for k = 1:K
        in(k) = buildInput(cfg, T(idx(k),:), data_dir);
    end

    tic
    out = parsim(in,'ShowProgress','on','SetupFcn', @() addpath(paths{:}));

    % reduce each run to a summary row + downsampled profiles
    clear m prof
    for k = 1:K
        [m(k), prof(k)] = extractRun(out(k), tgrid, cfg); %#ok<AGROW>
    end
    M  = [T(idx,:), struct2table(m(:))];
    PR = struct();
    for n = fieldnames(prof)'
        PR.(n{1}) = vertcat(prof.(n{1}));
    end
    save(f, 'M', 'PR', '-v7');

    % sanity check: if inputs were swept but every apogee is identical,
    % the overrides are almost certainly not reaching the model.
    ok = M.ok;
    msg = '';
    if nnz(ok) > 1 && numel(cfg.sweep) > 0 && std(M.apogee_ft(ok)) < 1e-6
        msg = '  WARNING: identical apogees, overrides may not be reaching the model';
    end
    fprintf('Batch %d/%d: %.0f s, %d failed, %d not landed%s\n', ...
            b, nB, toc, sum(~M.ok), sum(M.ok & ~M.landed), msg);
end

%% --------- 6. Merge batches ---------
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
save(fullfile(outdir, 'mc_profiles.mat'), 'M', 'PR', 'tgrid', 'cfg', '-v7.3');
writetable(M, fullfile(outdir, 'mc_summary.csv'));
fprintf('Done: %d runs merged (%d ok, %d landed) -> %s\n', ...
        height(M), sum(M.ok), sum(M.landed), outdir);
end