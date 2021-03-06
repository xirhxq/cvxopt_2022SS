function endpinput = gpopsEndpInputRPMI(Z, probinfo)

% gpopsEndpInputRPMI
% this function gets the input for the endpoint function only
% from the NLP variable vector

% get OCP info
numphase = probinfo.numphase;
numintegral = probinfo.numintegral;
numparameter = probinfo.numparameter;

% preallocate endpphase
endpphase(numphase).initialstate = [];
endpphase(numphase).finalstate = [];
endpphase(numphase).initialtime = [];
endpphase(numphase).finaltime = [];
if sum(numintegral,2) ~= 0;
    endpphase(numphase).integral = [];
end

% get variables for phases
for phasecount = 1:numphase;
    % get OCP info for each phase
    numintegralp = numintegral(phasecount);
    
    % get nlp map for phase
    phasenlpmap = probinfo.nlpcontmap(phasecount);
    
    % get OCP initial and final state for phase
    endpphase(phasecount).initialstate = Z(phasenlpmap.statemap(1,:))';
    endpphase(phasecount).finalstate   = Z(phasenlpmap.statemap(2,:))';
    
    % get OCP t0 and tf for phase
    endpphase(phasecount).initialtime = Z(phasenlpmap.timemap(1));
    endpphase(phasecount).finaltime   = Z(phasenlpmap.timemap(2));
    
    % get OCP integral for phase
    if numintegralp ~= 0;
        endpphase(phasecount).integral = Z(phasenlpmap.integralvarmap)';
    end
end

% add variables for all phases to enpinput
endpinput.phase = endpphase;

% get endpinput for parameter guess
if numparameter ~= 0;
    endpinput.parameter = Z(probinfo.nlpparametermap)';
end

% add auxdata to continput and endpinput
if probinfo.auxflag;
    endpinput.auxdata = probinfo.auxdata;
end