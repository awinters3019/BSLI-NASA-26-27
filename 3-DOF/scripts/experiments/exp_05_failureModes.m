%% exp_05_failureModes.m
% QUESTION: How do different failure modes affect trajectory?
% MODE:     grid
% SIZE:     8 samples
PILOT = false;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp05_failureModes_grid';

cfg.sweep = [
sweepVar('chute.DrogueFail',  'levels', [false true], 'name','drogue_fail')
sweepVar('chute.MainFail',    'levels', [false true], 'name','main_fail')
sweepVar('chute.DrogueDelay', 'levels', [0 2],        'name','drogue_delay')
];

cfg.mc.mode      = 'grid';
cfg.mc.n_reps    = 1; % Gust seed doesn't vary
cfg.mc.single_rep_if = [];   % [] = off
cfg.mc.n_samples = 100;   % grid doesn't care
cfg.mc.rng_seed  = 67;    % change for an independent draw
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)