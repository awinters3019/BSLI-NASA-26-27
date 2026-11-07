%% exp_06_silly.m
% QUESTION: What happens when we put the rocket under absurd conditions?
% MODE:     grid
% SIZE:     samples
PILOT = false;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp_06_silly';

cfg.sweep = [
    sweepVar('launch.cant_deg',  'levels', [20 30 40 50 60 70 80 90], 'name','cant_deg')
    sweepVar('launch.cant_sign',  'levels', [+1, -1],'name','cant_sign')
    sweepVar('chute.DrogueFail', 'levels', [false true], 'name','drogue_fail')
    ];

cfg.mc.mode      = 'grid';
cfg.mc.n_reps    = 1; % Gust seed doesn't vary
cfg.mc.single_rep_if = [];   % [] = off
cfg.mc.n_samples = 100;   % grid doesn't care
cfg.mc.rng_seed  = 67;    % change for an independent draw
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)