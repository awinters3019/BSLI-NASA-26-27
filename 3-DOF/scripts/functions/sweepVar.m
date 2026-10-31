function s = sweepVar(path, kind, val, varargin)
% PURPOSE: Allows you to put in another kind of variable which you wish to
% vary, over a specific range (we are not restricted to just the variables
% we used in PDR.)
% Input Ex: sweepVar('envP.wind_mph','levels',[0 5 10]) or sweepVar('r.k_cd','range',[.9 1.1],'n',3)
    ip = inputParser; ip.addParameter('n',[]); ip.addParameter('name',strrep(path,'.','_'));
    ip.parse(varargin{:});
    s.path = path;  s.name = ip.Results.name;  s.n = ip.Results.n;
    s.levels = [];  s.range = [];
    switch kind
        case 'levels', s.levels = val;
        case 'range',  s.range  = val;
        otherwise, error('kind must be ''levels'' or ''range''');
    end
end