function define_buses()
% Makes easy objects for each of the main buses which carry data. 
% Think of buses as structs whose values are easily modifiable.
assignin('base','StateBus', mkbus({'theta','q','X','Z','U','W'}));
assignin('base','EnvBus',   mkbus({'rho','a','T','P','mu','wind_xe','wind_ze'}));
assignin('base','AirBus',   mkbus({'U_rel','W_rel','V','alpha','Mach','qdyn'}));
assignin('base','MassBus',  mkbus({'m','dIdt','I','CG'}));
assignin('base','PhaseBus', mkbus({'drogue_cmd','main_cmd','phase'}))
end

function bus = mkbus(names)
els = cell(1, numel(names));
    for i = 1:numel(names)
        els{i} = Simulink.BusElement;
        els{i}.Name = names{i};
        els{i}.DataType = 'double';
    end
bus = Simulink.Bus;
bus.Elements = [els{:}];
end