function solution = gpopsSolutionRPMI(Zsol, Fmul, probinfo)

% gpopsSolutionRPMI
% this function outputs the solution of the optimal control problem from
% the solution of the NLP

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numcontrol = probinfo.numcontrol;
numintegral = probinfo.numintegral;
numparameter = probinfo.numparameter;

% get number of nodes
numnodes = probinfo.numnodes;

% preallocate phase and endpphase
phase(numphase).time = [];
phase(numphase).state = [];
if sum(numcontrol,2) ~= 0;
    phase(numphase).control = [];
end
if sum(numintegral,2) ~= 0;
    phase(numphase).integral = [];
end
phase(numphase).costate = [];
phase(numphase).timeRadau = [];
if sum(numcontrol,2) ~= 0;
    phase(numphase).controlRadau = [];
end

% get parameters
if numparameter ~= 0;
    parameter = Zsol(probinfo.nlpparametermap)';
end

% get variables for phases
for phasecount = 1:numphase;
    % get OCP info for each phase
    numstatep = numstate(phasecount);
    numcontrolp = numcontrol(phasecount);
    numintegralp = numintegral(phasecount);
    numnodesp = numnodes(phasecount);
    
    % get nlp map and collocation for phase
    phasenlpmap = probinfo.nlpcontmap(phasecount);
    meshp = probinfo.collocation(phasecount);
    
    % get OCP time for phase
    s = probinfo.collocation(phasecount).s(:,1);
    w = probinfo.collocation(phasecount).w(:,2);
    Emat = probinfo.collocation(phasecount).Emat;
    sp1 = [s; 1];
    t0 = Zsol(phasenlpmap.timemap(1));
    tf = Zsol(phasenlpmap.timemap(2));
    time = (sp1 + 1).*(tf - t0)./2 + t0;
    phase(phasecount).time = time;
    phase(phasecount).timeRadau = time(1:end-1);
    
    % get OCP state for phase
    state = Zsol(phasenlpmap.statemap(1,1):phasenlpmap.statemap(2,numstatep));
    phase(phasecount).state = reshape(state,numnodesp+1,numstatep);
    
    % get OCP control for phase
    if numcontrolp ~= 0;
        controlRadau = Zsol(phasenlpmap.controlmap(1,1):phasenlpmap.controlmap(2,numcontrolp));
        controlRadau = reshape(controlRadau,numnodesp,numcontrolp);
        controlextrap = interp1(s,controlRadau,1,'pchip','extrap');
        phase(phasecount).control = [controlRadau; controlextrap];
        phase(phasecount).controlRadau = controlRadau;
    end

    % get OCP integral for phase
    if numintegralp ~= 0;
        phase(phasecount).integral = Zsol(phasenlpmap.integralvarmap)';
    end
    
    % get OCP costate for phase
    defectmult = Fmul(phasenlpmap.defectmap(1,1):phasenlpmap.defectmap(2,numstatep));
    defectmult = Emat'*reshape(defectmult,numnodesp,numstatep);
    costate = zeros(numnodesp+1,numstatep);
    for statecount = 1:numstatep;
        costate(1:numnodesp,statecount) = defectmult(:,statecount)./w; 
        costate(numnodesp+1,statecount) = interp1(s, costate(1:numnodesp,statecount), 1, 'pchip', 'extrap');
        %D = inv(Emat');
        %costate(numnodesp+1,statecount) = D(:,end)'*defectmult(:,statecount);
        %costate(numnodesp+1,statecount) = Emat\costate(1:numnodesp,statecount);
    end
    phase(phasecount).costate = costate;
end

% add variables for all phases to solution
solution.phase = phase;

% get endpinput for parameter guess
if numparameter ~= 0;
    solution.parameter = parameter;
end
