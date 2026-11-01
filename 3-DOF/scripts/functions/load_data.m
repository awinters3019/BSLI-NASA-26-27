function data = load_data(cfg, data_dir)
% LOAD_DATA  Create cache of thrust curve and time data.
% Reads Thrust curve from where config.m says the file should be
% stored; then, creates vectors from it that it returns in the data struct.
% Data is cached so this process runs minimally.
    persistent cache % each worker reads the CSVs once 
    % (clear functions to reset cache)
    if ~isempty(cache), data = cache; return; end
    apogeeCutoff = 920; 
    % thrustCutoff = 190;
    warning('off','all');
    raw = readtable(fullfile(data_dir,cfg.files.thrust),...
        MissingRule="omitrow");
    data = struct();
    data.time_vec   = raw.x_Time_s_(1:apogeeCutoff);
    data.thrust_vec = raw.Thrust_N_(1:apogeeCutoff)*0.2248089;
    warning('on','all');
    cache = data;
end