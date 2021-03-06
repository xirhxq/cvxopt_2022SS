function grdjacnz = gpopsGrdJacnzRPMD(Z, probinfo)

% gpopsGrdJacnzRPMD
% this function computes the values of the Gradient and Jacbian nonzeros
% that correspond to the locations of the combined Gradient and Jacobian
% sparsity pattern

% NLP variable order
% [states*(nodes+1); controls*nodes; t0; tf, Q] for each phase
% [stack all phases(1;...;numphase); parameters]

% NLP constraint order
% [defect*nodes; path*nodes; integral; duration] for each phase
% [stack all phases(1;...;numphase); stack all events(1;...;numeventgroup]

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numcontrol = probinfo.numcontrol;
numpath = probinfo.numpath;
numintegral = probinfo.numintegral;
numparameter = probinfo.numparameter;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% get input for OCP functions
% get continput and endpinput
[continput, endpinput, tp0, tpf] = gpopsContEndpInputRPMD(Z, probinfo);

% get first derivatives of the optimal control problem
if probinfo.analyticflag;
    contgrd = feval(probinfo.contgrd, continput);
    endpgrd = feval(probinfo.endpgrd, endpinput);
else
    contgrd = feval(probinfo.contgrd, continput, probinfo);
    endpgrd = feval(probinfo.endpgrd, endpinput, probinfo);
end

% get first derivatives of objective
objgrd = endpgrd.objectivegrd;

% evaluate OCP continuous function
contfun = feval(probinfo.contfunction, continput);

% get number of nodes
numnodes = probinfo.numnodes;

% get contnc
contnvc = probinfo.derivativemap.contnvc1;

% preallocate jacnonlin
grdjacnz = zeros(probinfo.jacnnz + probinfo.grdnnz,1);

% assign gradient values
grdjacnz(1:probinfo.grdnnz) = objgrd(probinfo.derivativemap.objfunmap1)';

% find nonlinear jacbian nonzeros
jacmarkere = probinfo.grdnnz;
for phasecount = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecount);
    numcontrolp = numcontrol(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    numnodesp = numnodes(phasecount);
    
    % here multiply by fractionMat
    % get fractionMat and integration weights for phase
    fractionMat = probinfo.collocation(phasecount).fractionMat;
    w = probinfo.collocation(phasecount).w(:,1);
    
    % get time interval change derivatives
    dtdt0 = probinfo.collocation(phasecount).dtdt0;
    dtdtf = probinfo.collocation(phasecount).dtdtf;
    
    % contfun and contgrd for phase
    contgrdp = contgrd(phasecount);
    contfunp = contfun(phasecount);
    
    % scale dynamicsgrd and dynamics by segement fractionages
    contgrdp.dynamicsgrd = full(fractionMat*contgrdp.dynamicsgrd);
    contfunp.dynamics = full(fractionMat*contfunp.dynamics);
    
    % get time difference
    tdiff = (tpf(phasecount) - tp0(phasecount))/2;
    
    % get derivaitve map for phase
    contdermap = probinfo.derivativemap.contmap1(phasecount);
    
    % phasetimeflag
    % this is initiated as false
    % if the optimal control problem has derivatives respect to time
    % the value is changed to true
    phasetimeflag = false;
    
    % find Jacobian nonzero values for each OCP variable
    for contnvccount = 1:contnvc(phasecount);
        varnum = contdermap.contvarmap1(contnvccount);
        if varnum <= numstatep+numcontrolp;
            % derivative respect to state and control
            % derivatives of defect constraint
            for dynamicscount = 1:numstatep;
                dynamicsgrdref = contdermap.dynamicsmap1(dynamicscount,contnvccount);
                if dynamicsgrdref ~= 0;
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    
                    % assign values
                    grdjacnz(jacindex) = -tdiff*contgrdp.dynamicsgrd(:,dynamicsgrdref);
                end
            end
            % derivatives of path constraints
            if numpathp ~= 0;
                for pathcount = 1:numpathp;
                    pathgrdref = contdermap.pathmap1(pathcount,contnvccount);
                    if pathgrdref ~= 0;
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        grdjacnz(jacindex) = contgrdp.pathgrd(:,pathgrdref);
                    end
                end
            end
            % derivatives of integral constraint
            if numintegralp ~= 0;
                for integralcount = 1:numintegralp;
                    integrandgrdref = contdermap.integrandmap1(integralcount,contnvccount);
                    if integrandgrdref ~= 0;
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        grdjacnz(jacindex) = -tdiff*w.*contgrdp.integrandgrd(:,integrandgrdref);
                    end
                end
            end
        elseif varnum == numstatep+numcontrolp+1;
            % derivative respect to time
            % current phase has derivatives with respect to time
            % change phasetimeflag to true
            phasetimeflag = true;
            % get the variable number for time
            timenvc = contnvccount;
        elseif varnum <= numstatep+numcontrolp+1+numparameter;
            % derivative respect to parameter
            % derivatives of defect constraint
            for dynamicscount = 1:numstatep;
                dynamicsgrdref = contdermap.dynamicsmap1(dynamicscount,contnvccount);
                if dynamicsgrdref ~= 0;
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    
                    % assign values
                    grdjacnz(jacindex) = -tdiff*contgrdp.dynamicsgrd(:,dynamicsgrdref);
                end
            end
            % derivatives of path constraints
            if numpathp ~= 0;
                for pathcount = 1:numpathp;
                    pathgrdref = contdermap.pathmap1(pathcount,contnvccount);
                    if pathgrdref ~= 0;
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        grdjacnz(jacindex) = contgrdp.pathgrd(:,pathgrdref);
                    end
                end
            end
            % derivatives of integral constraint
            if numintegralp ~= 0;
                for integralcount = 1:numintegralp;
                    integrandgrdref = contdermap.integrandmap1(integralcount,contnvccount);
                    if integrandgrdref ~= 0;
                        jacmarkere = jacmarkere + 1;
                        
                        % assign values
                        grdjacnz(jacmarkere) = -tdiff*w'*contgrdp.integrandgrd(:,integrandgrdref);
                    end
                end
            end
        end
    end
    
    % derivatives with respect to time
    if phasetimeflag;
        % derivatives of defect constraint
        for dynamicscount = 1:numstatep;
            dynamicsgrdref = contdermap.dynamicsmap1(dynamicscount,timenvc);
            if dynamicsgrdref ~= 0;
                % derivative respect to t0
                jacmarkers = jacmarkere + 1;
                jacmarkere = jacmarkere + numnodesp;
                jacindex = jacmarkers:jacmarkere;
                % assign values
                grdjacnz(jacindex) = contfunp.dynamics(:,dynamicscount)/2 - tdiff*dtdt0.*contgrdp.dynamicsgrd(:,dynamicsgrdref);
                
                % derivative respect to tf
                jacmarkers = jacmarkere + 1;
                jacmarkere = jacmarkere + numnodesp;
                jacindex = jacmarkers:jacmarkere;
                % assign values
                grdjacnz(jacindex) = -contfunp.dynamics(:,dynamicscount)/2 - tdiff*dtdtf.*contgrdp.dynamicsgrd(:,dynamicsgrdref);
            else
                % derivative respect to t0
                jacmarkers = jacmarkere + 1;
                jacmarkere = jacmarkere + numnodesp;
                jacindex = jacmarkers:jacmarkere;
                % assign values
                grdjacnz(jacindex) = contfunp.dynamics(:,dynamicscount)/2;
                
                % derivative respect to tf
                jacmarkers = jacmarkere + 1;
                jacmarkere = jacmarkere + numnodesp;
                jacindex = jacmarkers:jacmarkere;
                % assign values
                grdjacnz(jacindex) = -contfunp.dynamics(:,dynamicscount)/2;
            end
        end
        % derivatives of path constraints
        if numpathp ~= 0;
            for pathcount = 1:numpathp;
                pathgrdref = contdermap.pathmap1(pathcount,timenvc);
                if pathgrdref ~= 0;
                    % derivative respect to t0
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    % assign values
                    grdjacnz(jacindex) = dtdt0.*contgrdp.pathgrd(:,pathgrdref);
                    
                    % derivative respect to tf
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    % assign values
                    grdjacnz(jacindex) = dtdtf.*contgrdp.pathgrd(:,pathgrdref);
                end
            end
        end
        % derivatives of integral constraint
        if numintegralp ~= 0;
            for integralcount = 1:numintegralp;
                integrandgrdref = contdermap.integrandmap1(integralcount,timenvc);
                if integrandgrdref ~= 0;
                    % derivative respect to t0
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    grdjacnz(jacmarkere) = w'*(contfunp.integrand(:,integralcount)/2 - tdiff*(dtdt0.*contgrdp.integrandgrd(:,integrandgrdref)));

                    % derivative respect to tf
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    grdjacnz(jacmarkere) = -w'*(contfunp.integrand(:,integralcount)/2 - tdiff*(dtdtf.*contgrdp.integrandgrd(:,integrandgrdref)));
                else
                    % derivative respect to t0
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    grdjacnz(jacmarkere) = w'*contfunp.integrand(:,integralcount)/2;

                    % derivative respect to tf
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    grdjacnz(jacmarkere) = -w'*contfunp.integrand(:,integralcount)/2;
                end
            end
        end
    else
        % derivatives of defect constraint
        for dynamicscount = 1:numstatep;
            % derivative respect to t0
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            grdjacnz(jacindex) = contfunp.dynamics(:,dynamicscount)/2;
            
            % derivative respect to tf
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            grdjacnz(jacindex) = -contfunp.dynamics(:,dynamicscount)/2;
        end
        % derivatives of integral constraint
        if numintegralp ~= 0;
            for integralcount = 1:numintegralp;
                % derivative respect to t0
                jacmarkere = jacmarkere + 1;
                % assign values
                grdjacnz(jacmarkere) = w'*contfunp.integrand(:,integralcount)/2;
                
                % derivative respect to tf
                jacmarkere = jacmarkere + 1;
                % assign values
                grdjacnz(jacmarkere) = -w'*contfunp.integrand(:,integralcount)/2;
            end
        end
    end
end

% check if problem has events
if numeventgroup ~= 0;
    % get event nvc
    eventnvc = probinfo.derivativemap.eventnvc1;
    for eventgroupcount = 1:numeventgroup;
        % get event function map
        eventfunmap = probinfo.derivativemap.eventfunmap1(eventgroupcount).first;
        eventgrd = endpgrd.eventgroup(eventgroupcount).eventgrd;
        for eventnvccount = 1:eventnvc;
            for eventcount = 1:numevent(eventgroupcount);
                eventgrdref = eventfunmap(eventcount,eventnvccount);
                if eventgrdref ~= 0;
                    % event derivatives
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    grdjacnz(jacmarkere) = eventgrd(eventgrdref);
                end
            end
        end
    end
end