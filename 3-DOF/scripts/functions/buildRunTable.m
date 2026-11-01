function T = buildRunTable(cfg)
% BUILDRUNTABLE  Builds the table of different run permutations that 
% MonteCarlo.m will read from, and send entries from to Simulink.
sweep = cfg.sweep;  mc = cfg.mc;  nV = numel(sweep);
names = {sweep.name};
rng(mc.rng_seed);
switch mc.mode
    case 'grid'
        lv = cell(1,nV);  ax = cell(1,nV);
        for k = 1:nV
            if ~isempty(sweep(k).levels), lv{k} = sweep(k).levels(:);
            else
                assert(~isempty(sweep(k).n), '"%s": grid mode needs ''n''.', sweep(k).path);
                lv{k} = linspace(sweep(k).range(1), sweep(k).range(2), sweep(k).n)';
            end
            ax{k} = 1:numel(lv{k});
        end
        idx = cell(1,nV);  [idx{:}] = ndgrid(ax{:});
        cols = cell(1,nV);
        for k = 1:nV, cols{k} = lv{k}(idx{k}(:)); end
        T = table(cols{:}, 'VariableNames', names);
        ii  = repelem((1:height(T))', mc.n_reps);
        rep = repmat((1:mc.n_reps)', height(T), 1);
        T = T(ii,:);  T.rep = rep;
        if ~isempty(mc.single_rep_if)
            T(T.rep > 1 & mc.single_rep_if(T), :) = [];
        end
    case {'lhs','random'}
        N = mc.n_samples;
        cont = find(arrayfun(@(s) ~isempty(s.range), sweep));
        nc = max(numel(cont), 1);
        if strcmp(mc.mode,'lhs'), U = lhsdesign(N, nc); else, U = rand(N, nc); end
        cols = cell(1,nV);
        for k = 1:nV
            if ismember(k, cont)
                cols{k} = sweep(k).range(1) + U(:, cont==k)*diff(sweep(k).range);
            else   % discrete: balanced across levels, random order
                L = sweep(k).levels(:);
                cols{k} = L(mod(randperm(N)-1, numel(L)) + 1);
            end
        end
        T = table(cols{:}, 'VariableNames', names);  T.rep = ones(N,1);
    otherwise
        error('cfg.mc.mode must be grid, lhs, or random.');
end
T.run_id = (1:height(T))';
T.seed   = mc.seed_base + T.run_id; % unique, replayable
T = T(randperm(height(T)), :);      % shuffle: stopping early is still a fair sample
end