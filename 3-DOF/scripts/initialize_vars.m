function [envP,r,data,chute,launch] = initialize_vars(data_dir)
% initialize_vars_and_data
% Input values for relevant environmental properties, rocket geometry, and
% spreadsheets.

in2ft = 1/12;
lbm2slug = 0.03108096;
kgm2_to_slugft2 = 0.7375621419;
N2lbf = 0.2248089;
mph2fps = 1.466667;

envP.T_ground   = 59 + 459.67;     % degR   (convert degF -> degR by adding 459.67)
envP.P_ground   = 2116.22;         % psf    (psi * 144; 14.696 psi = 2116.22 psf)
envP.wind_speed = 4*mph2fps;      % fps
envP.wind_dir   = 0;               % rad, 0 = blowing downrange
envP.h_ref      = 33;              % ft, wind reference height (~10 m)
% Gusts for wind (TO TURN OFF: set envP.gust_sigma = 0)
envP.gust_sigma = 0.2*envP.wind_speed;  % ft/s, desired RMS gust strength. Proportional to wind
envP.gust_tau   = 1.5;                  % s, gust correlation time (~ turbulence length / airspeed)
envP.gust_Ts    = envP.gust_tau/10;     % s, keep <= tau/10 so the filtered noise is smooth
envP.gust_seed  = 1;                    % positive integer, changed per Monte Carlo run

% Unit-variance output after filtering requires a gain of sqrt(2*tau),
% so multiplying by sigma gives an RMS of gust_sigma.
envP.gust_gain  = envP.gust_sigma * sqrt(2*envP.gust_tau);

% Create data for Thrust Curve, Mass Curve, and Moment of Inertia Curve
warning('off','all');
Tier1 = readtable(fullfile(data_dir,"Tier1_sims.csv"),MissingRule="omitrow");
Tier2 = readtable(fullfile(data_dir,"Tier2_sims.csv"),MissingRule="omitrow");
ThrustData = readtable(fullfile(data_dir,"ThrustData.csv"),MissingRule="omitrow");
warning('on','all');

% Cut off the data at apogee (everything is constant after this point.)
cutoff = 920; 
% Read Time, Total Mass, Wet Mass, and MOI from Tier1 file
data.time_vec      = Tier1.x_Time_s_(1:cutoff);  % s
data.tot_mass_vec  = Tier1.Mass_lb_(1:cutoff) * lbm2slug; % slug
data.prop_mass_vec = (Tier1.MotorMass_lb_(1:cutoff) - 4.927) * lbm2slug;  % slug
data.I_vec         = Tier1.LongitudinalMomentOfInertia_kg_m__(1:cutoff) * kgm2_to_slugft2; % slug * ft^2
data.dI_dt_vec     = diff(data.I_vec)./diff(data.time_vec); % slug * ft^2 / s
data.thrust_vec    = ThrustData.Thrust_N_(1:cutoff) * N2lbf; % lbf
r.x_cg             = mean(in2ft*Tier2.CGLocation_in_(1:cutoff)); % ft
data.CG_vec        = r.x_cg*ones(920,1); % ft
% Just makes CG an averaged constant for now (7.2294 ft from forward end).


% r stands for the struct "rocket".
% --- Body (from Neil) ---
r.d   = 6.12*in2ft;                 % ft, body diameter
r.S   = pi*r.d^2/4;                 % ft^2
r.L   = 148*in2ft;                  % ft, total length
R_    = r.d/2;
Ln    = 24*in2ft;                   % ft, 4:1 ogive nose length

% --- Fins (from Neil) ---
Nf   = 3;                           % ASSUMED, confirm with lead
Cr   = 15*in2ft;   Ct = 7*in2ft;    % ft, root and tip chord
sp   = 4.75*in2ft;                  % ft, semispan (height)
Xr   = 4*in2ft;                     % ft, LE sweep distance
r.t_fin  = 0.125*in2ft;             % ft, fin thickness
x_fin_LE = 133*in2ft;               % ft from nose tip to root LE

% --- Barrowman potential-flow terms ---
Lf       = sqrt(sp^2 + (Xr + (Ct-Cr)/2)^2);
CNa_nose = 2;   
x_nose   = 0.466*Ln;  % tangent ogive
CNa_fin  = (1+R_/(sp+R_))*4*Nf*(sp/r.d)^2/(1+sqrt(1+(2*Lf/(Cr+Ct))^2));
x_fin    = x_fin_LE + Xr*(Cr+2*Ct)/(3*(Cr+Ct)) + (1/6)*((Cr+Ct) - Cr*Ct/(Cr+Ct));

r.CNa_pot  = CNa_nose + CNa_fin;
r.x_cp_pot = (CNa_nose*x_nose + CNa_fin*x_fin)/r.CNa_pot;   % ft from nose

% --- Crossflow and drag geometry ---
r.Aplan = r.d*r.L;   r.x_cf = 0.5*r.L;   r.Cdc = 1.2;
r.Swet_body = pi*r.d*r.L;
r.Swet_fins = 2*Nf*0.5*(Cr+Ct)*sp;   r.c_fin = (Cr+Ct)/2;
r.fb = 1 + 60/(r.L/r.d)^3 + 0.0025*(r.L/r.d);
r.Abase_ratio = 1;  
% Drag Tuning
r.k_cd = 1.1;         % Gain on all drag 
r.Cdw_pk = 0.05;    % Wave drag peak (zero below Mach 0.8)
r.Cd_extra = 0.02;  % Additional bit of drag for small rocket geometry
r.Cmq  = -10;
r.Vmin = 10;                        % ft/s

% --- Recovery ---
d_drogue  = 24*in2ft;
d_main    = 100*in2ft;
Cd_drogue = 1.16;
Cd_main   = 2.59; % measured; manufacturer value is 2.92
chute.CdS_drogue = Cd_drogue * pi*d_drogue^2/4;      % ~3.6 ft^2
chute.CdS_main   = Cd_main   * pi*d_main^2/4;        % ~141 ft^2
r.x_attach = r.x_cg;    % Consider also mid-body(74-in) attachment
chute.main_alt = 2000;  % alt where main chute should begin deploying (ft)
chute.tau_infl = 0.4; % s, inflation time constant

% Cant Angle / Launch Rod Angle (deg)
launch.theta0 = deg2rad(85);
end