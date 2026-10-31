function s = setByPath(s, path, val)
    % setByPath(p, 'envP.wind_mph', 10). Throws error on typos instead of 
    % silently creating a new field.
    parts = strsplit(path, '.');
    try getfield(s, parts{:});
    catch, error('Config path "%s" does not exist in cfg.params. Check spelling.', path); end
    s = setfield(s, parts{:}, val);
end