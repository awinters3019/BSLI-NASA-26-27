function cfg = config()
% All user-editable settings. Units: ft, slug, s, lbf, degR, psf, rad,
% except where a name carries its unit (_mph, _deg, _in).
% Please experiment, edit, and change things here.
cfg.name = 'config_testing';                % results go to results/<name>/

%% ---- Files (read by load_data) ----
cfg.files.thrust = 'ThrustData.csv'; % Name of thrust curve to reference

%% ---- Parameters (INPUTS only; derived values live in derive_params) ----
% Rocket's beginning and end mass parameters
p.mass.mass_start_lbm = 51.5;      % lbm, on pad
p.mass.mass_end_lbm   = 45.92;     % lbm, after burn
p.mass.CG_start_ft    = 7.22;      % ft from nose, on pad
p.mass.CG_end_ft      = 6.7533;    % ft from nose, after burn
p.mass.MOI_start_kgm2 = 24.24;     % kg*m^2, on pad
p.mass.MOI_end_kgm2   = 20.23;     % kg*m^2, after burn

% Environmental parameters
p.envP.T_ground  = 59 + 459.67;     % degR (first number is deg F)
p.envP.P_ground  = 2116.22;    % psf
p.envP.wind_mph  = 4;         % mph
p.envP.wind_dir  = 0;          % rad
p.envP.h_ref     = 33;         % ft
p.envP.gust_frac = 0.2;        % gust sigma = gust_frac * mean wind
p.envP.gust_tau  = 1.5;        % s
p.envP.gust_seed = 1;          

% Launch rod parameters
p.launch.cant_deg  = 5;        % cant angle (degrees) from 90 deg vertical
p.launch.cant_sign = +1;       % +1 = tilt into the wind; -1 = with wind

% Rocket geometry parameters
p.r.d_in = 6.12;           % diameter of the rocket
p.r.L_in = 148;         % length of the rocket
p.r.Ln_in = 24;         % 4:1 Ogive Nosecone Length
p.r.Nf = 3;             % Number of fins
p.r.Cr_in = 15;         % Root chord length
p.r.Ct_in = 7;          % Tip chord length
p.r.sp_in = 4.75;       % Semi-span distance
p.r.Xr_in = 4;          % Leading edge sweep distance
p.r.t_fin_in = 0.125;    % Fin thickness
p.r.xfinLE_in = 133;    % Inches from nose tip to root leading edge
p.r.k_cd = 1.25;           % Multiplicative Gain on all drag
p.r.Cd_extra = 0.02;    % Added drag for small unaccounted geometry
p.r.Cdw_pk = 0.05;      % Wave drag peak (unused for Mach < 0.8)
p.r.Cmq = -10;          %
p.r.Vmin = 10;          % ft/s (fail-safe for low speeds affecting AOA)
p.r.x_attach = p.mass.CG_end_ft;    % Location where parachutes attach (ft)

% Parachute parameters
p.chute.d_drogue_in = 24;  p.chute.Cd_drogue = 1.16;
p.chute.d_main_in = 100;   p.chute.Cd_main = 2.59;
p.chute.tau_infl = 0.4; % time constant for inflation
p.chute.main_alt = 1000; % ft
cfg.params = p;

%% --- Sweep: any input path, any number of variables, for Monte Carlo ---
% 'levels' = explicit values (numeric, logical, or string array)
% 'range'  = [lo hi]; grid uses n evenly spaced points, lhs/random sample continuously
cfg.sweep = [
    sweepVar('envP.P_ground',   'range',  [2086 2125],       'n',4, 'name','P_psf')
    sweepVar('envP.T_ground',   'range',  [510.67 529.67],   'n',4, 'name','T_R')
    sweepVar('launch.cant_deg', 'range',  [5 10],            'n',5, 'name','cant_deg')
    sweepVar('envP.wind_mph',   'levels', [0 5 10 15 20],           'name','wind_mph')
    ];

%% ---- Monte Carlo ----
cfg.mc.mode          = 'grid';            % 'grid' | 'lhs' | 'random'
cfg.mc.n_reps        = 6;                 % replicates per grid point (grid mode)
cfg.mc.n_samples     = 2000;              % total runs (lhs/random) -- don't worry about this for grid
cfg.mc.seed_path     = 'envP.gust_seed';  % each run's unique seed is written here ('' = none)
cfg.mc.seed_base     = 0;
cfg.mc.rng_seed      = 0;                 % shuffle/sampling reproducibility
cfg.mc.single_rep_if = @(T) T.wind_mph == 0;   % [] = off; one rep where gusts do nothing
cfg.mc.n_pilot       = 10;                % >0 = smoke test, 0 = full run
cfg.mc.n_workers     = 4;
cfg.mc.batch_size    = 96;                % multiple of n_workers

%% ---- Simulation and outputs ----
cfg.sim.model        = 'TDOF_simulink_v2';
cfg.sim.model_params = {'StopTime','400', 'InspectSignalLogs','off'};  % any setModelParameter pairs
cfg.out.dt           = 0.2;               % s, stored-profile resolution
cfg.out.t_max        = 250;
cfg.out.save_extras  = true;              % theta(t), q(t)
end