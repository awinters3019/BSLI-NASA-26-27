%% Benjamin Brobst -- BSLI SSTR -- 3DOF Helper -- 9/8/26
% Runs at the start of each Simulink run.
% Defines the folder layout in the code itself
% Initializes:
%   Tunable Environmental Parameters
%   Tunable Wind & Gust Parameters

% Define Paths
model_path = fileparts(get_param(bdroot, 'FileName'));    % .../3-DOF/model
parent_path = fileparts(model_path);                      % .../3-DOF
data_dir = fullfile(parent_path, 'data');                 % .../3-DOF/data
scripts_dir = fullfile(parent_path,'scripts');            % .../3-DOF/scripts
addpath(data_dir, scripts_dir); % allows our code to sense other scripts.

% Run initializing scripts
define_buses();
[envP, r, data, chute, launch] = initialize_vars(data_dir);

%fprintf('InitFcn: MC_OVERRIDE exists = %d, envP.T_ground = %.2f\n', ...
    %exist('MC_OVERRIDE','var'), envP.T_ground);

Simulink.Bus.createObject(r);     %simInBus1
Simulink.Bus.createObject(envP);  %simInBus2
Simulink.Bus.createObject(chute); %simInBus3