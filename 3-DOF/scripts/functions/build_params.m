function p = build_params(cfg, data_dir, ovr)
    % ovr: Nx2 cell {path, value; ...} applied to the raw inputs BEFORE 
    % deriving.
    p = cfg.params;
    if nargin > 2 % if ovr was received
        for k = 1:size(ovr,1)
        p = setByPath(p, ovr{k,1}, ovr{k,2}); 
        end
    end
    p = derive_params(p);
    d = load_data(cfg, data_dir);                       % thrust only (cached)
    if istable(d), d = table2struct(d, 'ToScalar', true); end   % columns become fields
    p.data = d;
    md = mass_vectors(p.mass);                          % rebuilt every run, so sweeps work
    for f = fieldnames(md)', p.data.(f{1}) = md.(f{1}); end
    p = rmfield(p,'mass'); % just doesn't need to be sent through
end