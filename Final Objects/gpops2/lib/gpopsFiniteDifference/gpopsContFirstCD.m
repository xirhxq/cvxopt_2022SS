function contfirstder = gpopsContFirstCD(input, probinfo)

% gpopsContFirstCD
% this function estimates the first derivatives of the OCP continuous
% function using central difference
% only the derivatives indicated in the derivativemap are found
% uses value based step sizes

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numcontrol = probinfo.numcontrol;
numintegral = probinfo.numintegral;
numpath = probinfo.numpath;
pathsum = sum(numpath,2);
integrandsum = sum(numintegral,2);
numparameters = probinfo.numparameter;

% get continuous function derivative map
contmap1 = probinfo.derivativemap.contmap1;

% get nvc for first derivatives
contnvc = probinfo.derivativemap.contnvc1;
maxnvc = max(contnvc);

% preallocate derivative output
% only nonzero derivatives of the optimal control problem are stored
dynamicsnnz = probinfo.derivativemap.dynamicsnnz1;
contfirstder(numphase).dynamicsgrd = [];
if pathsum ~= 0;
    pathnnz = probinfo.derivativemap.pathnnz1;
    contfirstder(numphase).pathgrd = [];
else
    pathnnz = zeros(1,numphase);
end
if integrandsum ~= 0;
    integrandnnz = probinfo.derivativemap.integrandnnz1;
    contfirstder(numphase).integrandgrd = [];
else
    integrandnnz = zeros(1,numphase);
end
for phasecount = 1:numphase;
    NN = size(input.phase(phasecount).time,1);
    if dynamicsnnz(phasecount) ~= 0;
        contfirstder(phasecount).dynamicsgrd = zeros(NN,dynamicsnnz(phasecount));
    end
    if pathnnz(phasecount) ~= 0;
        contfirstder(phasecount).pathgrd = zeros(NN,pathnnz(phasecount));
    end
    if integrandnnz(phasecount) ~= 0;
        contfirstder(phasecount).integrandgrd = zeros(NN,integrandnnz(phasecount));
    end
end

% get base stepsize
ustep = probinfo.stepsize;

% preallocate hstep
hstep(numphase).h1 = [];

% find derivatives of all phases simultaneously
for nvccount = 1:maxnvc;
    % initiate pertinput as the unperturbed input
    pertinput1 = input;
    pertinput2 = input;
    for phasecount = 1:numphase;
        numstatep = numstate(phasecount);
        numcontrolp = numcontrol(phasecount);
        % test if the perturbed variable count is less then the number of
        % perturbed variables in the phase
        if nvccount <= contnvc(phasecount);
            varnum = contmap1(phasecount).contvarmap1(nvccount);
            if varnum <= numstatep;
                % perturb state
                refmark = varnum;
                h = ustep.*(abs(input.phase(phasecount).state(:,refmark))+1);
                hstep(phasecount).h1 = h;
                pertinput1.phase(phasecount).state(:,refmark) = input.phase(phasecount).state(:,refmark) + h./2;
                pertinput2.phase(phasecount).state(:,refmark) = input.phase(phasecount).state(:,refmark) - h./2;
            elseif varnum <= numstatep+numcontrolp;
                % perturb control
                refmark = varnum-numstatep;
                h = ustep.*(abs(input.phase(phasecount).control(:,refmark))+1);
                hstep(phasecount).h1 = h;
                pertinput1.phase(phasecount).control(:,refmark) = input.phase(phasecount).control(:,refmark) + h./2;
                pertinput2.phase(phasecount).control(:,refmark) = input.phase(phasecount).control(:,refmark) - h./2;
            elseif varnum == numstatep+numcontrolp+1;
                % perturb time
                h = ustep.*(abs(input.phase(phasecount).time)+1);
                hstep(phasecount).h1 = h;
                pertinput1.phase(phasecount).time = input.phase(phasecount).time + h./2;
                pertinput2.phase(phasecount).time = input.phase(phasecount).time - h./2;
            elseif varnum <= numstatep+numcontrolp+1+numparameters;
                % perturb parameter
                refmark = varnum-numstatep-numcontrolp-1;
                h = ustep.*(abs(input.phase(phasecount).parameter(:,refmark))+1);
                hstep(phasecount).h1 = h;
                pertinput1.phase(phasecount).parameter(:,refmark) = input.phase(phasecount).parameter(:,refmark) + h./2;
                pertinput2.phase(phasecount).parameter(:,refmark) = input.phase(phasecount).parameter(:,refmark) - h./2;
            end
        end
    end
    
    % evaluate function on perturbed input
    pertoutput1 = feval(probinfo.contfunction, pertinput1);
    pertoutput2 = feval(probinfo.contfunction, pertinput2);
    
    % calculate the derivative value in each phase
    for phasecount = 1:numphase;
        numstatep = numstate(phasecount);
        numpathp = numpath(phasecount);
        numintegralp = numintegral(phasecount);
        % test if the perturbed variable count is less then the number of
        % perturbed variables in the phase
        if nvccount <= contnvc(phasecount);
            % calculate nonzero derivatives of dynamic constraints
            for dynamicscount = 1:numstatep;
                refmark = contmap1(phasecount).dynamicsmap1(dynamicscount,nvccount);
                if refmark ~= 0;
                    contfirstder(phasecount).dynamicsgrd(:,refmark) = (pertoutput1(phasecount).dynamics(:,dynamicscount) - pertoutput2(phasecount).dynamics(:,dynamicscount))./hstep(phasecount).h1;
                end
            end
            % calculate nonzero derivatives of path constraints
            for pathcount = 1:numpathp;
                refmark = contmap1(phasecount).pathmap1(pathcount,nvccount);
                if refmark ~= 0;
                    contfirstder(phasecount).pathgrd(:,refmark) = (pertoutput1(phasecount).path(:,pathcount) - pertoutput2(phasecount).path(:,pathcount))./hstep(phasecount).h1;
                end
            end
            % calculate nonzero derivatives of intergrand constraints
            for intergralcount = 1:numintegralp;
                refmark = contmap1(phasecount).integrandmap1(intergralcount,nvccount);
                if refmark ~= 0;
                    contfirstder(phasecount).integrandgrd(:,refmark) = (pertoutput1(phasecount).integrand(:,intergralcount) - pertoutput2(phasecount).integrand(:,intergralcount))./hstep(phasecount).h1;
                end
            end
        end
    end
end