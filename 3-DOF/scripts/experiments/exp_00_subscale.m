%% exp_00_subscale_grid.m
% QUESTION: What does the subscale rocket trajectory look like?
% MODE:     grid
% SIZE:     
PILOT = true;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp_00_subscale_grid';

% ---- Files (read by load_data) ----
cfg.files.thrust = 'J270W-14_ThrustCurve.csv'; % Name of thrust curve to reference

% ---- Parameters (INPUTS only; derived values live in derive_params) ----
% Rocket's beginning and end mass parameters
cfg.params.mass.apogeeCutoff   = 282;       % arbitrary index value from cleaned loaded thrust curve; at index, apogee is hit.
cfg.params.mass.thrustCutoff   = 106;       % arbitrary index value from cleaned loaded thrust curve; at index, burnout is hit.

cfg.params.mass.mass_start_lbm = 12.23;      % lbm, on pad
cfg.params.mass.mass_end_lbm   = 11.39;     % lbm, after burn
cfg.params.mass.burn_time      = 2.558;       % seconds
cfg.params.mass.CG_start_ft    = 4.64;      % ft from nose, on pad
cfg.params.mass.CG_end_ft      = 4.43;    % ft from nose, after burn
cfg.params.MOI_start_kgm2 = 2.26;     % kg*m^2, on pad
cfg.params.MOI_end_kgm2   = 1.96;     % kg*m^2, after burn

% Environmental parameters
 cfg.params.T_ground       = 62+459.67;  % degR (first number is deg F)
 cfg.params.P_ground       = 2116.22;    % psf
% cfg.params.envP.wind_mph  = 12;         % mph
 cfg.params.envP.h_ref     = 1043;       % ft (Cedarville)
% cfg.params.envP.gust_frac = 0.6;        % gust sigma = gust_frac * mean wind
% cfg.params.envP.gust_tau  = 1.5;        % s
% cfg.params.envP.gust_seed = 1;          

% Launch rod parameters
cfg.params.launch.cant_deg  = 5;        % cant angle (degrees) from 90 deg vertical
cfg.params.launch.cant_sign = +1;       % +1 = tilt into the wind; -1 = with wind

% Rocket geometry parameters
 cfg.params.r.d_in = 4.125;        % diameter of the rocket
 cfg.params.r.L_in = 96;         % length of the rocket
 cfg.params.r.Ln_in = 16;         % 4:1 Ogive Nosecone Length
 cfg.params.r.Cr_in = 10;         % Root chord length
 cfg.params.r.Ct_in = 4.6;          % Tip chord length
 cfg.params.r.sp_in = 3.16;       % Semi-span distance
 cfg.params.r.Xr_in = 2.7;          % Leading edge sweep distance
 cfg.params.r.t_fin_in = 0.187;   % Fin thickness
 cfg.params.r.xfinLE_in = 86;    % Inches from nose tip to root leading edge
% cfg.params.r.k_cd = 1.25;        % Multiplicative Gain on all drag
% cfg.params.r.Cd_extra = 0.02;    % Added drag for small unaccounted geometry
% cfg.params.r.Vmin = 10;          % ft/s (fail-safe for low speeds affecting AOA)

cfg.params.r.x_attach = cfg.params.mass.CG_end_ft;    

% Parachute parameters
cfg.params.chute.d_drogue_in = 24;    cfg.params.chute.Cd_drogue = 0.97;
cfg.params.chute.d_main_in = 72.83;   cfg.params.chute.Cd_main = 0.97;
% cfg.params.chute.tau_infl = 0.4; % time constant for inflation
cfg.params.chute.main_alt = 950; % ft. 

% Failure/Delay Modes
%p.chute.DrogueFail = false; % TRUE: No drogue deployment; FALSE: Drogue will deploy
%p.chute.MainFail = false; % TRUE: No main deployment; FALSE: Main will deploy
%p.chute.DrogueDelay = 0; % DEFAULT: 0, drogue right at apogee;  DELAY MODE: 2, deploys on secondary charge (2 seconds after).
%p.chute.MainDelay = 2; % DEFAULT: 2, main deploys 2 seconds after main_alt;

cfg.sweep = [
    sweepVar('envP.wind_mph',  'levels', [4 8 12 16 20], 'name','wind_mph')
    sweepVar('envP.gust_frac', 'levels', [0.2 0.3 0.4 0.5 0.6], 'name', 'gust_frac')
    sweepVar('launch.cant_deg','levels',  [5 6 7 8 9 10],'name','cant_deg')
    ];

cfg.mc.mode      = 'grid';
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)