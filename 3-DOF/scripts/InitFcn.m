%% Benjamin Brobst -- BSLI SSTR -- 3DOF Helper -- 9/8/26

clearvars;
r = 3.06/12; % radius of rocket in ft
S = pi * r^2; % fixed reference area, as needed
L = 158/12; % length of rocket in ft

model_path = fileparts(get_param(bdroot, 'FileName'));   % .../3-DOF/model
parent_path = fileparts(model_path);                      % .../3-DOF
data_dir = fullfile(parent_path, 'data');                  % .../3-DOF/data

% Read from CSVs from OpenRocket
warning('off','all')
Tier1 = readtable(fullfile(data_dir,"Tier1_sims.csv"),MissingRule="omitrow");
Tier2 = readtable(fullfile(data_dir,"Tier2_sims.csv"),MissingRule="omitrow");
ThrustData = readtable(fullfile(data_dir,"ThrustData.csv"),MissingRule="omitrow");
Mach_vs_CdCN_data = readtable(fullfile(data_dir,"Mach_vs_CdCN.csv"),MissingRule="omitrow");
Cn_alpha_data = readtable(fullfile(data_dir,"Cn_alpha.csv"),MissingRule="omitrow");
% Cp_vs_Mach_data = readtable("CP_vs_Mach_obsolete.csv",MissingRule="omitrow");
warning('on','all');

% Time before apogee makes things get funky in OpenRocket; this index cuts 
% things off earlier (~17 seconds in)
cutoff = 920; 

% Read Time, Total Mass, Wet Mass, and MOI from Tier1 file
time_vec = Tier1.x_Time_s_(1:cutoff);  % s
tot_mass_vec = Tier1.Mass_lb_(1:cutoff) * 0.031081; % slug
prop_mass_vec = (Tier1.MotorMass_lb_(1:cutoff) - 4.927) * 0.031081;  % slug
I_vec = Tier1.LongitudinalMomentOfInertia_kg_m__(1:cutoff) * 0.73756; % slug * ft^2
dI_dt_vec = 0.73756 * (diff(I_vec)./diff(time_vec)); % slug * ft^2 / s
thrust_vec = ThrustData.Thrust_N_(1:cutoff) * 0.2248; % lbf

% Read CG(t)
CG_vec = (1/12)*Tier2.CGLocation_in_(1:cutoff); % ft

% Read Mach vs. Cd and Cn
Mach_vec = Mach_vs_CdCN_data.MachNumber___(1:cutoff);
cd_vec = Mach_vs_CdCN_data.x_DragCoefficient___(1:cutoff);
% Bin Mach to unique values and interpolate between for clean 1-D lookup
[Mach_unique1, ~, idx] = unique(round(Mach_vec, 2)); % bin Mach
cd_avg = accumarray(idx, cd_vec, [], @mean);

% Fetch Cn and alpha; not monotonic
cn_vec = Cn_alpha_data.NormalForceCoefficient___(54:956);
alpha_vec = Cn_alpha_data.x_AngleOfAttack___(54:956);
alpha_vec = deg2rad(alpha_vec);
% Bin alpha; similar to Mach
[alpha_unique, ~, idx] = unique(round(alpha_vec, 3));
alpha_unique = rmmissing(alpha_unique); % has NaNs at the end
cn_avg = rmmissing(accumarray(idx, cn_vec, [], @mean));

% Give Normal Force coeff reflected behavior for negative alpha
alpha_neg = -flip(alpha_unique(alpha_unique > 0));
cn_neg = -flip(cn_avg(alpha_unique > 0));
alpha_unique = [alpha_neg; alpha_unique];
cn_avg = [cn_neg; cn_avg];

% This block is commented out: CP now set as a median const value (8.9) for
% simplification

% % Read for relation between CP and Mach
% Mach_cp_specific_vec = Cp_vs_Mach_data.MachNumber___;
% Cp_vec = (1/12)*Cp_vs_Mach_data.x_CPLocation_in_; % ft
% % Remove rows where CP is missing, from both vectors together
% valid = ~ismissing(Cp_vec);
% Mach_cp_specific_vec = Mach_cp_specific_vec(valid);
% Cp_vec = Cp_vec(valid);
% % Now bin/average, with matching lengths
% [Mach_unique2, ~, idx] = unique(round(Mach_cp_specific_vec, 2));
% cp_avg = accumarray(idx, Cp_vec, [], @mean);