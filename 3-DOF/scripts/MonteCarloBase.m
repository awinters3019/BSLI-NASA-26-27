% This script can run and save data from the model from MATLAB
model_path = fileparts(get_param(bdroot, 'FileName'));
parent_path = fileparts(model_path);      % .../3-DOF
data_dir = fullfile(parent_path, 'data'); % .../3-DOF/model
model_path = fullfile(model_path,"TDOF_simulink.slx");

[~, mdl, ~] = fileparts(model_path);   % sim() wants the model NAME, not the full path

% Make sure Simulink can find it (adds its folder to path for this session)
addpath(fileparts(model_path));
load_system(model_path);

out = sim(mdl);

% --- Save outputs into the data directory ---
% .mat file:
matFile = fullfile(data_dir, 'latest_run.mat');
logsout = out.logsout;
save(matFile, 'logsout');