function s = setByPath(s, path, val)
% SETBYPATH  Given a specific path and value to override the default with,
% assign that value in. Throws error on typos instead of silently creating 
% a new field.

% Ex. setByPath(p, 'envP.wind_mph', 10)
parts = strsplit(path, '.');
try getfield(s, parts{:});
catch, error('Config path "%s" does not exist in cfg.params. Check spelling.', path); end
s = setfield(s, parts{:}, val);
end