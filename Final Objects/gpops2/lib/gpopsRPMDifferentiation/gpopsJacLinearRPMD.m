function [jaclindiag, jaclinoffdiag] = gpopsJacLinearRPMD(probinfo)

% gpopsJacLinearRPMD
% this function finds the linear part of the NLP Jacobian
% the linear part is stored in two parts
% jaclindiag contains the diagnal part of the differentiation matrices
% jaclinoffdiag contains the off diagnal of the differentiation matrices
% along with the duration constraint derivatives respect to t0 and tf and
% the integral constraint respect to the integral variable

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numintegral = probinfo.numintegral;

% get number of nonzeros in differentiation matrix for each phase
Ddiagnnz = zeros(1,numphase);
Doffdiagnnz = zeros(1,numphase);
for phasecout = 1:numphase;
    Ddiagnnz(phasecout) = size(probinfo.collocation(phasecout).Ddiag,1);
    Doffdiagnnz(phasecout) = size(probinfo.collocation(phasecout).Doffdiag,1);
end
% number of nonzeros of linear jacbian components
jldiagnnz = numstate*Ddiagnnz';
jloffdnnz = numstate*Doffdiagnnz' + 2*numphase + sum(numintegral,2);

% preallocate jaclindiag and jaclinoffdiag
jaclindiag = zeros(jldiagnnz,3);
jaclinoffdiag = zeros(jloffdnnz,3);

% find linear jacbian nonzeros
jldiagmarkere = 0;
jloffdmarkere = 0;
for phasecout = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecout);
    numintegralp = numintegral(phasecout);
    
    % get nlpcontmap and collocation
    nlpcontmap = probinfo.nlpcontmap(phasecout);
    phasemesh = probinfo.collocation(phasecout);
    
    for statecount = 1:numstatep;
        % get assignment markers
        jldiagmarkers = jldiagmarkere + 1;
        jldiagmarkere = jldiagmarkere + Ddiagnnz(phasecout);
        jloffdmarkers = jloffdmarkere + 1;
        jloffdmarkere = jloffdmarkere + Doffdiagnnz(phasecout);
        
        % get assignment index
        jldiagindex = jldiagmarkers:jldiagmarkere;
        jloffdindex = jloffdmarkers:jloffdmarkere;
        
        % assign linear locations and values
        rowoffset = nlpcontmap.defectmap(1,statecount)-1;
        coloffset = nlpcontmap.statemap(1,statecount)-1;
        
        % 3rd column is differentiation matrix values when s is [-1, 1) on
        % entire phase
        % 4th column is differentiation matrix values when s is [-1, 1) in
        % each segment
        jaclindiag(jldiagindex,:) = [phasemesh.Ddiag(:,1)+rowoffset, phasemesh.Ddiag(:,2)+coloffset, phasemesh.Ddiag(:,4)];
        jaclinoffdiag(jloffdindex,:) = [phasemesh.Doffdiag(:,1)+rowoffset, phasemesh.Doffdiag(:,2)+coloffset, phasemesh.Doffdiag(:,4)];
    end
    
    % get assignment markers
    jloffdmarkers = jloffdmarkere + 1;
    jloffdmarkere = jloffdmarkere + 2;
    
    % duration constraint derivatives respect to t0 and tf
    jaclinoffdiag(jloffdmarkers,:) = [nlpcontmap.durationmap, nlpcontmap.timemap(1), -1];
    jaclinoffdiag(jloffdmarkere,:) = [nlpcontmap.durationmap, nlpcontmap.timemap(2), 1];
    
    if numintegralp ~= 0;
        for integralcount = 1:numintegralp;
            % get assignment markers
            jloffdmarkere = jloffdmarkere + 1;
            
            % integral constraint respect to the integral variable
            jaclinoffdiag(jloffdmarkere,:) = [nlpcontmap.integrandmap(integralcount), nlpcontmap.integralvarmap(integralcount), 1];
        end
    end
end