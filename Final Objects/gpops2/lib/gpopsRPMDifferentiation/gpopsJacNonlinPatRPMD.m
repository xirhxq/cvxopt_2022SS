function [jacnonlin, probinfo] = gpopsJacNonlinPatRPMD(probinfo)

% gpopsJacNonlinPatRPMD
% this function finds the sparsity pattern of the non linear part of the
% Jacobian

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

% get parametermap
if numparameter ~= 0;
    parametermap = probinfo.nlpparametermap;
end

% get number of nodes
numnodes = probinfo.numnodes;

% get contnc
contnvc = probinfo.derivativemap.contnvc1;

% preallocate jacnonlin
jacnonlin = zeros(1,2);

% find nonlinear jacbian nonzeros
jacmarkere = 0;
for phasecount = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecount);
    numcontrolp = numcontrol(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    numnodesp = numnodes(phasecount);
    
    % get NLP map and derivaitve map for phase
    nlpcontmap = probinfo.nlpcontmap(phasecount);
    contdermap = probinfo.derivativemap.contmap1(phasecount);
    
    % phasetimeflag
    % this is initiated as false
    % if the optimal control problem has derivatives respect to time
    % the value is changed to true
    phasetimeflag = false;
    
    % find nonzero locations for each OCP variable
    for contnvccount = 1:contnvc(phasecount);
        varnum = contdermap.contvarmap1(contnvccount);
        if varnum <= numstatep;
            % derivative respect to state
            % get NLP variable location
            stateref = varnum;
            cols = nlpcontmap.statemap(1,stateref):(nlpcontmap.statemap(2,stateref)-1);
            % derivatives of defect constraint
            for statecount = 1:numstatep;
                if contdermap.dynamicsmap1(statecount,contnvccount) ~= 0;
                    % get NLP constraint location
                    rows = nlpcontmap.defectmap(1,statecount):nlpcontmap.defectmap(2,statecount);
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    
                    % assign values
                    jacnonlin(jacindex,1) = rows;
                    jacnonlin(jacindex,2) = cols;
                end
            end
            % derivatives of path constraints
            if numpathp ~= 0;
                for pathcount = 1:numpathp;
                    if contdermap.pathmap1(pathcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.pathmap(1,pathcount):nlpcontmap.pathmap(2,pathcount);
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        jacnonlin(jacindex,1) = rows;
                        jacnonlin(jacindex,2) = cols;
                    end
                end
            end
            % derivatives of integral constraint
            if numintegralp ~= 0;
                for integralcount = 1:numintegralp;
                    if contdermap.integrandmap1(integralcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.integrandmap(integralcount);
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        jacnonlin(jacindex,1) = rows;
                        jacnonlin(jacindex,2) = cols;
                    end
                end
            end
        elseif varnum <= numstatep+numcontrolp;
            % derivative respect to control
            % get NLP variable location
            controlref = varnum-numstatep;
            cols = nlpcontmap.controlmap(1,controlref):nlpcontmap.controlmap(2,controlref);
            % derivatives of defect constraint
            for statecount = 1:numstatep;
                if contdermap.dynamicsmap1(statecount,contnvccount) ~= 0;
                    % get NLP constraint location
                    rows = nlpcontmap.defectmap(1,statecount):nlpcontmap.defectmap(2,statecount);
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    
                    % assign values
                    jacnonlin(jacindex,1) = rows;
                    jacnonlin(jacindex,2) = cols;
                end
            end
            % derivatives of path constraints
            if numpathp ~= 0;
                for pathcount = 1:numpathp;
                    if contdermap.pathmap1(pathcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.pathmap(1,pathcount):nlpcontmap.pathmap(2,pathcount);
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        jacnonlin(jacindex,1) = rows;
                        jacnonlin(jacindex,2) = cols;
                    end
                end
            end
            % derivatives of integral constraint
            if numintegralp ~= 0;
                for integralcount = 1:numintegralp;
                    if contdermap.integrandmap1(integralcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.integrandmap(integralcount);
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        
                        % assign values
                        jacnonlin(jacindex,1) = rows;
                        jacnonlin(jacindex,2) = cols;
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
            % get NLP variable location
            parameterref = varnum-numstatep-numcontrolp-1;
            parametercol = parametermap(parameterref);
            % derivatives of defect constraint
            for statecount = 1:numstatep;
                if contdermap.dynamicsmap1(statecount,contnvccount) ~= 0;
                    % get NLP constraint location
                    rows = nlpcontmap.defectmap(1,statecount):nlpcontmap.defectmap(2,statecount);
                    % derivative respect to parameter
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    % assign values
                    jacnonlin(jacindex,1) = rows;
                    jacnonlin(jacindex,2) = parametercol;
                end
            end
            % derivatives of path constraints
            if numpathp ~= 0;
                for pathcount = 1:numpathp;
                    if contdermap.pathmap1(pathcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.pathmap(1,pathcount):nlpcontmap.pathmap(2,pathcount);
                        % derivative respect to parameter
                        jacmarkers = jacmarkere + 1;
                        jacmarkere = jacmarkere + numnodesp;
                        jacindex = jacmarkers:jacmarkere;
                        % assign values
                        jacnonlin(jacindex,1) = rows;
                        jacnonlin(jacindex,2) = parametercol;
                    end
                end
            end
            % derivatives of integral constraint
            if numintegralp ~= 0;
                for integralcount = 1:numintegralp;
                    if contdermap.integrandmap1(integralcount,contnvccount) ~= 0;
                        % get NLP constraint location
                        rows = nlpcontmap.integrandmap(integralcount);
                        % derivative respect to parameter
                        jacmarkere = jacmarkere + 1;
                        % assign values
                        jacnonlin(jacmarkere,1) = rows;
                        jacnonlin(jacmarkere,2) = parametercol;
                    end
                end
            end
        end
    end
    
    % derivatives with respect to time
    if phasetimeflag;
        % get NLP variable location
        t0col = nlpcontmap.timemap(1);
        tfcol = nlpcontmap.timemap(2);
        % derivatives of defect constraint
        for statecount = 1:numstatep;
            % get NLP constraint location
            rows = nlpcontmap.defectmap(1,statecount):nlpcontmap.defectmap(2,statecount);
            % derivative respect to t0
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            jacnonlin(jacindex,1) = rows;
            jacnonlin(jacindex,2) = t0col;
            % derivative respect to tf
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            jacnonlin(jacindex,1) = rows;
            jacnonlin(jacindex,2) = tfcol;
        end
        % derivatives of path constraints
        if numpathp ~= 0;
            for pathcount = 1:numpathp;
                if contdermap.pathmap1(pathcount,timenvc) ~= 0;
                    % get NLP constraint location
                    rows = nlpcontmap.pathmap(1,pathcount):nlpcontmap.pathmap(2,pathcount);
                    % derivative respect to t0
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    % assign values
                    jacnonlin(jacindex,1) = rows;
                    jacnonlin(jacindex,2) = t0col;
                    % derivative respect to tf
                    jacmarkers = jacmarkere + 1;
                    jacmarkere = jacmarkere + numnodesp;
                    jacindex = jacmarkers:jacmarkere;
                    % assign values
                    jacnonlin(jacindex,1) = rows;
                    jacnonlin(jacindex,2) = tfcol;
                end
            end
        end
        % derivatives of integral constraint
        if numintegralp ~= 0;
            for integralcount = 1:numintegralp;
                % get NLP constraint location
                rows = nlpcontmap.integrandmap(integralcount);
                % derivative respect to t0
                jacmarkere = jacmarkere + 1;
                % assign values
                jacnonlin(jacmarkere,1) = rows;
                jacnonlin(jacmarkere,2) = t0col;
                % derivative respect to tf
                jacmarkere = jacmarkere + 1;
                % assign values
                jacnonlin(jacmarkere,1) = rows;
                jacnonlin(jacmarkere,2) = tfcol;
            end
        end
    else
        % get NLP variable location
        t0col = nlpcontmap.timemap(1);
        tfcol = nlpcontmap.timemap(2);
        % derivatives of defect constraint
        for statecount = 1:numstatep;
            % get NLP constraint location
            rows = nlpcontmap.defectmap(1,statecount):nlpcontmap.defectmap(2,statecount);
            % derivative respect to t0
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            jacnonlin(jacindex,1) = rows;
            jacnonlin(jacindex,2) = t0col;
            % derivative respect to tf
            jacmarkers = jacmarkere + 1;
            jacmarkere = jacmarkere + numnodesp;
            jacindex = jacmarkers:jacmarkere;
            % assign values
            jacnonlin(jacindex,1) = rows;
            jacnonlin(jacindex,2) = tfcol;
        end
        % derivatives of integral constraint
        if numintegralp ~= 0;
            for integralcount = 1:numintegralp;
                % get NLP constraint location
                rows = nlpcontmap.integrandmap(integralcount);
                % derivative respect to t0
                jacmarkere = jacmarkere + 1;
                % assign values
                jacnonlin(jacmarkere,1) = rows;
                jacnonlin(jacmarkere,2) = t0col;
                % derivative respect to tf
                jacmarkere = jacmarkere + 1;
                % assign values
                jacnonlin(jacmarkere,1) = rows;
                jacnonlin(jacmarkere,2) = tfcol;
            end
        end
    end
end

% check if problem has events
if numeventgroup ~= 0;
    % get event variable map
    eventvarmap = probinfo.derivativemap.eventvarmap1;
    % get event NLP map
    nlpeventmap = probinfo.nlpeventmap;
    % get endpoint variable NLP map
    nlpendpvarmap = probinfo.nlpendpvarmap;
    % get event nvc
    eventnvc = probinfo.derivativemap.eventnvc1;
    for eventgroupcount = 1:numeventgroup;
        % get event function map
        eventfunmap = probinfo.derivativemap.eventfunmap1(eventgroupcount).first;
        for eventnvccount = 1:eventnvc;
            col = nlpendpvarmap(eventvarmap(eventnvccount));
            for eventcount = 1:numevent(eventgroupcount);
                if eventfunmap(eventcount,eventnvccount) ~= 0;
                    % event derivatives
                    row = nlpeventmap(1,eventgroupcount) + eventcount-1;
                    jacmarkere = jacmarkere + 1;
                    % assign values
                    jacnonlin(jacmarkere,1) = row;
                    jacnonlin(jacmarkere,2) = col;
                end
            end
        end
    end
end

% number of nonlinear nonzeros in jacobian
probinfo.jacnonlinnnz = size(jacnonlin,1);