function writeSnapshot(cfg, outdir)
% WRITESNAPSHOT  Saves the exact configuration next to the results.
% Refuses to mix two configurations into one folder.
if ~exist(outdir,'dir')
    mkdir(outdir); 
end
snap = cfg;
if ~isempty(snap.mc.single_rep_if)
    snap.mc.single_rep_if = func2str(snap.mc.single_rep_if); 
end
snap.derived = derive_params(cfg.params);
js = jsonencode(snap, 'PrettyPrint', true);
f = fullfile(outdir, 'config_snapshot.json');
if isfile(f) && ~strcmp(fileread(f), js)
    error('A different config already exists in %s. Change cfg.name or delete that folder.', outdir);
end
fid = fopen(f,'w');  fwrite(fid, js);  fclose(fid);
[~, h] = system('git rev-parse --short HEAD');
fid = fopen(fullfile(outdir,'run_info.txt'),'w');
fprintf(fid, 'date: %s\nmatlab: %s\ngit: %s\n', char(datetime('now')), version('-release'), strtrim(h));
fclose(fid);
save(fullfile(outdir,'config.mat'), 'cfg');   % exact copy for reruns
end