function ocpmult = gpopsMultipliersRPMI(lam, probinfo)

% gpopsMultipliersRPMI
% this function organizes the multipliers of the nonlinear program to
% correspond to the continuous functions and the event constraints from the
% optimal control problem

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numpath = probinfo.numpath;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;

% get number of nodes
numnodes = probinfo.numnodes;

% preallocate contmult
contmult(numphase).defectmult = [];
if sum(numpath,2) ~= 0;
    contmult(numphase).pathmult = [];
end
if sum(numintegral,2) ~= 0;
    contmult(numphase).integralmult = [];
end

% get multipliers for phases
for phasecount = 1:numphase;
    % get OCP info for each phase
    numstatep = numstate(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    numnodesp = numnodes(phasecount);
    
    % get nlp map for phase
    phasenlpmap = probinfo.nlpcontmap(phasecount);
    
    % get multiplers for defect constraints
    defectmult = lam(phasenlpmap.defectmap(1,1):phasenlpmap.defectmap(2,numstatep));
    contmult(phasecount).defectmult = reshape(defectmult,numnodesp,numstatep);
    
    % get multipliers for path constraints
    if numpathp ~= 0;
        pathmult = lam(phasenlpmap.pathmap(1,1):phasenlpmap.pathmap(2,numpathp));
        contmult(phasecount).pathmult = reshape(pathmult,numnodesp,numpathp);
    end
    
    % get multipliers for integral constraints
    if numintegralp ~= 0;
        contmult(phasecount).integralmult = lam(phasenlpmap.integrandmap)';
    end
end

% put contmult in ocpmult structure
ocpmult.contmult = contmult;

% get multipliers for events
if numeventgroup ~= 0;
    eventmultgroup(numeventgroup).eventmult = [];
    nlpeventmap = probinfo.nlpeventmap;
    for eventgroupcount = 1:numeventgroup;
        eventref = nlpeventmap(1,eventgroupcount):nlpeventmap(2,eventgroupcount);
        eventmultgroup(eventgroupcount).eventmult = lam(eventref)';
    end
    % put eventmultgroup in ocpmult structure
    ocpmult.eventmultgroup = eventmultgroup;
end