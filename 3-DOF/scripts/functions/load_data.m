function data = load_data(cfg, data_dir)
    persistent cache % each worker reads the CSVs once 
    % (clear functions to reset cache)
    if ~isempty(cache), data = cache; return; end
    apogeeCutoff = 920; 
    % thrustCutoff = 190;
    warning('off','all');
    raw = readtable(fullfile(data_dir, cfg.files.thrust),MissingRule="omitrow");
    data = struct();
    data.time_vec   = raw.x_Time_s_(1:apogeeCutoff);
    data.thrust_vec = raw.Thrust_N_(1:apogeeCutoff)*0.2248089;
    cache = data;

    %ThrustData = fullfile(data_dir, cfg.files.thrust);
    %data = readtable(ThrustData,MissingRule="omitrow");
    warning('on','all');
    cache = data;
end