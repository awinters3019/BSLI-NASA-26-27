function d = mass_vectors(m)
% From inputted mass start and end parameters, convert to vectors. 
    lbm2slug = 1/32.174;  
    kgm2_to_slugft2 = 0.737562;
    burn_time = 2.4;      % s, fixed
    thrustCutoff = 190; apogeeCutoff = 920; % index cutoffs from OpenRocket
    
    mass_start = m.mass_start_lbm*lbm2slug;   
    mass_end   = m.mass_end_lbm*lbm2slug;
    CG_start   = m.CG_start_ft;               
    CG_end     = m.CG_end_ft;
    MOI_start  = m.MOI_start_kgm2*kgm2_to_slugft2;
    MOI_end    = m.MOI_end_kgm2*kgm2_to_slugft2;
    
    d.tot_mass_vec = [linspace(mass_start,mass_end,thrustCutoff) mass_end*ones(1,apogeeCutoff-thrustCutoff)]';
    d.CG_vec       = [linspace(CG_start,CG_end,thrustCutoff)     CG_end*ones(1,apogeeCutoff-thrustCutoff)]';
    d.I_vec        = [linspace(MOI_start,MOI_end,thrustCutoff)   MOI_end*ones(1,apogeeCutoff-thrustCutoff)]';

    I_dot = (MOI_end-MOI_start)/burn_time;
    d.dI_dt_vec    = [I_dot*ones(1,thrustCutoff) zeros(1,apogeeCutoff-thrustCutoff-1)]';
end