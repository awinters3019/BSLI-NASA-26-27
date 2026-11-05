%% exp_05_fullres_replay.m -- replay ONE Monte Carlo run at full resolution
clearvars;
exp_dir = fileparts(mfilename('fullpath'));
scripts_dir = fileparts(exp_dir);
parent  = fileparts(scripts_dir);
data_dir = fullfile(parent, 'data');
addpath(scripts_dir, fullfile(scripts_dir, 'functions'));

studyName = 'exp01_wind_cant_grid_pilot';     % results/<studyName>/
runRow    = 1;                  % which run (row of M) to replay

S   = load(fullfile(parent, 'results', studyName, 'mc_profiles.mat'), 'M', 'cfg');
cfg = S.cfg;  row = S.M(runRow, :);

% Rebuild this run's overrides exactly as buildInput did
sw = cfg.sweep;  ovr = cell(numel(sw), 2);
for k = 1:numel(sw), ovr(k,:) = {sw(k).path, row.(sw(k).name)}; end
if ~isempty(cfg.mc.seed_path), ovr(end+1,:) = {cfg.mc.seed_path, row.seed}; end

out = run_single(cfg, ovr, false);
p   = build_params(cfg, data_dir, ovr);          % for the geometry (r) and chute sizes
F   = extract_fullres(out, p, 0.02);

outdir = fullfile(parent, 'results', 'fullres');  if ~exist(outdir, 'dir'), mkdir(outdir); end
matfile = fullfile(outdir, sprintf('%s_run%04d_fullres.mat', studyName, row.run_id));
save(matfile, 'F', '-v7');
rocket_viewer_full(matfile)