%% exp_07_Cmq.m
% QUESTION: How does the rocket react to changes in Cmq?
% MODE:     grid
% SIZE:     11 samples
clearvars;
PILOT = false;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp_07_Cmq';

cfg.sweep = [
    sweepVar('r.Cmq', 'range',  [-10 0],            'n',11, 'name','C_mq')
];

cfg.mc.mode      = 'grid';
cfg.mc.n_reps    = 1; % Gust seed doesn't vary
cfg.mc.single_rep_if = [];   % [] = off
cfg.mc.n_samples = 100;   % grid doesn't care
cfg.mc.rng_seed  = 67;    % change for an independent draw
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)