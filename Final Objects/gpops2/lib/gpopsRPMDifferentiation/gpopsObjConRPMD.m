function F = gpopsObjConRPMD(Z, probinfo)

% gpopsObjConRPMD
% this function computes the combined NLP objective and constraint function
% where the objective value is the first element in the output Fout
% only the nonlinear parts of the constraints are computed

% NLP constraint order
% [objective; stack all phases(1;...;numphase); stack all events(1;...;numeventgroup]
% [defects; paths; integral; duration] for each phase
% 1 is added to all assignment indices to account for objective

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numpath = probinfo.numpath;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% get OCP variables
[continput, endpinput, tp0, tpf] = gpopsContEndpInputRPMD(Z, probinfo);

% evaluate OCP continuous function
contfun = feval(probinfo.contfunction, continput);

% evaluate OCP endpoint function
endpoutput = feval(probinfo.endpfunction, endpinput);

% preallocate Fout (autodiff friendly)
F = zeros(probinfo.nlpnumcon+1,1)*Z(1,1);

% objective
F(1) = endpoutput.objective;

% find NLP constraint values for each phase
for phasecount = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    
    % get contfun for phase
    contfunp = contfun(phasecount);
    
    % scale dynamics by segement fractionages
    contfunp.dynamics = full(probinfo.collocation(phasecount).fractionMat*contfunp.dynamics);
    
    % get nlp map for phase
    phasenlpmap = probinfo.nlpcontmap(phasecount);
    
    % time difference / 2
    tdiff = (tpf(phasecount) - tp0(phasecount))/2;
    
    % non linear part defect constraint 0 = - (tf-t0/2)*f(x,u,t,P)
    Findex = phasenlpmap.defectmap(1,1):phasenlpmap.defectmap(2,numstatep);
    F(Findex+1) = -tdiff*contfunp.dynamics(:);
    
    % path constraint c(x,u,t,P)
    if numpathp ~= 0;
        Findex = phasenlpmap.pathmap(1,1):phasenlpmap.pathmap(2,numpathp);
        F(Findex+1) = contfunp.path(:);
    end
    
    % non linear part integral constraint 0 = - (tf-t0/2)*w'*(g(x,u,t,P),to,tf)
    if numintegralp ~= 0;
        Findex = phasenlpmap.integrandmap;
        F(Findex+1) = -tdiff*probinfo.collocation(phasecount).w(:,1)'*contfunp.integrand;
    end
    
    % duration constraint applied as linear constraint (leave as zero) 
end

% event constraints
if numeventgroup ~= 0;
    nlpeventmap = probinfo.nlpeventmap;
    for eventgroupcount = 1:numeventgroup;
        if numevent(eventgroupcount) ~= 0;
            Findex = nlpeventmap(1,eventgroupcount):nlpeventmap(2,eventgroupcount);
            F(Findex+1) = endpoutput.eventgroup(eventgroupcount).event;
        end
    end
end