function [probinfo, ocpscales] = gpopsScaleRPMD(setup, probinfo)

% gpopsScaleRPMD
% this function finds the variable scales and shifts, and the constraint
% scales for the nonlinear program

if probinfo.scaleflag;
    % get scales of the OCP using the problem bounds
    if strcmpi(setup.scales.method, 'automatic-bounds');
        % get scales of the OCP using the problem bounds
        ocpscales = gpopsScalesFromBounds(setup, probinfo);
    elseif strcmpi(setup.scales.method, 'automatic-guess');
        % get scales of the OCP using the problem guess
        ocpscales = gpopsScalesFromGuess(setup, probinfo);
    elseif strcmpi(setup.scales.method, 'defined');
        %something like this
        ocpscales = setup.scales;
    end
    
    % find NLP scales from optimal control problem scales
    probinfo = ocp2nlpscales(ocpscales, probinfo);
else
    ocpscales = [];
    % is the scale method is 'none', problem is not to be scaled
    probinfo.Zscale = 1;
    probinfo.Zshift = 0;
    probinfo.Fscale = 1;
end

function probinfo = ocp2nlpscales(ocpscales, probinfo)

% opRPMocp2nlpscales
% this sub function defines the NLP variable scales and shifts, and the NLP
% constraint scales from the optimal control problem scales
% nonlinear program resulting from the Radau Pseudospectral Method

% Zscale is the NLP variable scale
% Zshift is the NLP variable shift
% Fscale is the constraint scale

% nlp variable order
% [states*(nodes+1); controls*nodes; t0; tf, Q] for each phase
% [stack all phases(1;...;numphase); parameters]

% nlp constraint order
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

% preallocate nlp bounds
Zscale = zeros(probinfo.nlpnumvar,1);
Zshift = zeros(probinfo.nlpnumvar,1);
Fscale = zeros(probinfo.nlpnumcon,1);

for phasecount = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecount);
    numcontrolp = numcontrol(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    
    % get phase scales and NLP map
    phasescales = ocpscales.phase(phasecount);
    phasenlpmap = probinfo.nlpcontmap(phasecount);
    
    % get NLP scales and shifts for state variables in each phase
    % get NLP constraint scales for defect constraints in each phase
    for statecount = 1:numstatep;
        % get assignment index for NLP variables and constraints
        Zindex = phasenlpmap.statemap(1,statecount):phasenlpmap.statemap(2,statecount);
        Findex = phasenlpmap.defectmap(1,statecount):phasenlpmap.defectmap(2,statecount);
        
        % assign NLP variable scale and shift values
        Zscale(Zindex) = phasescales.statescale(statecount);
        Zshift(Zindex) = phasescales.stateshift(statecount);
        
        % assign NLP constraint scale values
        Fscale(Findex) = phasescales.dynamicsconscale(statecount);
    end
    
    % check if phase contains control variables
    if numcontrolp ~= 0;
        % get NLP scales and shifts for control variables in each phase
        for controlcount = 1:numcontrolp;
            % get assignment index for NLP variables
            Zindex = phasenlpmap.controlmap(1,controlcount):phasenlpmap.controlmap(2,controlcount);
            
            % assign NLP variable scale and shift values
            Zscale(Zindex) = phasescales.controlscale(controlcount);
            Zshift(Zindex) = phasescales.controlshift(controlcount);
        end
    end
    
    % check if phase contains path constraints
    if numpathp ~= 0;
        % get NLP constraint scales for path constraints in each phase
        for pathcount = 1:numpathp;
            % get assignment index for NLP constraints
            Findex = phasenlpmap.pathmap(1,pathcount):phasenlpmap.pathmap(2,pathcount);
            
            % assign NLP constraint scale values
            Fscale(Findex) = phasescales.pathconscale(pathcount);
        end
    end
    
    % get assignment index for NLP variable
    Zindex = phasenlpmap.timemap(1);
    
    % get NLP scales and shifts for initial variables in each phase
    Zscale(Zindex) = phasescales.t0scale;
    Zshift(Zindex) = phasescales.t0shift;
    
    % get assignment index for NLP variable
    Zindex = phasenlpmap.timemap(2);
    
    % get NLP scales and shifts for final variables in each phase
    Zscale(Zindex) = phasescales.tfscale;
    Zshift(Zindex) = phasescales.tfshift;
    
    % check if phase contains integral constraints
    if numintegralp ~= 0;
        % get NLP scales and shifts for intergral variables in each phase
        % get NLP constraint scales for intergral constraints in each phase
        % get assignment index for NLP variables and constraints
        Zindex = phasenlpmap.integralvarmap;
        Findex = phasenlpmap.integrandmap;
        
        % assign NLP variable scale and shift values
        Zscale(Zindex) = phasescales.integralscale;
        Zshift(Zindex) = phasescales.integralshift;
        
        % assign NLP constraint scale values
        Fscale(Findex) = phasescales.integrandconscale;
    end
    
    % duration scale is 1
    Fscale(phasenlpmap.durationmap) = 1;
end

% check if problem has events
if numeventgroup ~= 0;
    % get NLP event map
    nlpeventmap = probinfo.nlpeventmap;
    
    % get event scales
    eventscales = ocpscales.eventgroup;
    
    % get NLP constraint scales for event constraints
    for eventgroupcount = 1:numeventgroup;
        % get assignment index for NLP constraints
        Findex = nlpeventmap(1,eventgroupcount):nlpeventmap(2,eventgroupcount);
        
        % assign NLP constraint scale values
        Fscale(Findex) = eventscales(eventgroupcount).eventconscale;
    end
end

% check is problem has parameters
if numparameter ~= 0;
    % get NLP scales and shifts for parameter variables in each phase
    % get assignment index for NLP variable
    Zindex = probinfo.nlpparametermap;
    
    % get NLP scales and shifts for initial variables in each phase
    Zscale(Zindex) = ocpscales.parameterscale;
    Zshift(Zindex) = ocpscales.parametershift;
end

% assign Zscale, Zshift, and Fscale to probinfo
probinfo.objscale = ocpscales.objscale;
probinfo.Zscale = Zscale;
probinfo.Zshift = Zshift;
probinfo.Fscale = Fscale;