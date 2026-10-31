%% Benjamin Brobst -- BSLI SSTR -- 3DOF Initializing Function
% Runs at the start of each Simulink run.
% Makes sure MATLAB knows where folders are
% Initializes Buses; Builds parameters from config file.

% Define Paths
model_path = fileparts(get_param(bdroot, 'FileName'));  % .../3-DOF/model
parent_path = fileparts(model_path);                    % .../3-DOF
data_dir = fullfile(parent_path, 'data');               % .../3-DOF/data
scripts_dir = fullfile(parent_path,'scripts');          % .../3-DOF/scripts
addpath(model_path, data_dir, scripts_dir, fullfile(scripts_dir, 'functions'));
% Run initializing scripts
define_buses();
p = build_params(config(), data_dir);
envP = p.envP; r = p.r; data = p.data; chute = p.chute; launch = p.launch;

Simulink.Bus.createObject(r);     %simInBus1
Simulink.Bus.createObject(envP);  %simInBus2
Simulink.Bus.createObject(chute); %simInBus3