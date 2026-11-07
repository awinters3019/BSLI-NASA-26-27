%% Benjamin Brobst -- BSLI SSTR -- 6DOF Initializing Function
% Runs at the start of each Simulink run.
% Makes sure MATLAB knows where folders are
% Initializes Buses; Builds parameters from config file.

% Define Paths
model_path = fileparts(get_param(bdroot, 'FileName'));  % .../6-DOF/model
parent_path = fileparts(model_path);                    % .../6-DOF
data_dir = fullfile(parent_path, 'data');               % .../6-DOF/data
scripts_dir = fullfile(parent_path,'scripts');          % .../6-DOF/scripts

% Define buses...