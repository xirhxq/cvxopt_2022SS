function eventgroup = gpopsEventFirstBD(input, probinfo)

% gpopsEventFirstBD
% this function estimates the first derivatives of the OCP events only
% function using backward difference
% only the derivatives indicated in the derivativemap are found
% uses value based step sizes

% OCP info
numstate = probinfo.numstate;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% get endpoint derivative map
endpvarloc = probinfo.endpvarloc;
eventnvc1 = probinfo.derivativemap.eventnvc1;
eventvarmap1 = probinfo.derivativemap.eventvarmap1;

% preallocate derivative output
% only nonzero derivatives of the optimal control problem are stored
eventnnz1 = probinfo.derivativemap.eventnnz1;
eventfunmap1 = probinfo.derivativemap.eventfunmap1;
eventgroup(numeventgroup).eventgrd = [];
for eventgroupcount = 1:numeventgroup;
    eventgroup(eventgroupcount).eventgrd = zeros(1,eventnnz1(eventgroupcount));
end

% get base stepsize
ustep = probinfo.stepsize;

% get non-perturbed function solution
output = feval(probinfo.endpfunction, input);

for nvccount = 1:eventnvc1
    % initiate pertinput as the unperturbed input
    pertinput = input;
    
    % get variable phase, and variable number in phase
    varnum = eventvarmap1(nvccount);
    varphase = endpvarloc(1,varnum);
    phasevarnum = endpvarloc(2,varnum);
    
    if varphase ~= 0;
        if phasevarnum <= numstate(varphase);
            % perturb initial state
            refmark = phasevarnum;
            h = ustep.*(abs(input.phase(varphase).initialstate(refmark))+1);
            pertinput.phase(varphase).initialstate(refmark) = input.phase(varphase).initialstate(refmark) - h;
        elseif phasevarnum <= 2*numstate(varphase);
            % perturb final state
            refmark = phasevarnum-numstate(varphase);
            h = ustep.*(abs(input.phase(varphase).finalstate(refmark))+1);
            pertinput.phase(varphase).finalstate(refmark) = input.phase(varphase).finalstate(refmark) - h;
        elseif phasevarnum == 2*numstate(varphase)+1;
            % perturb initial time
            h = ustep.*(abs(input.phase(varphase).initialtime)+1);
            pertinput.phase(varphase).initialtime = input.phase(varphase).initialtime - h;
        elseif phasevarnum == 2*numstate(varphase)+2;
            % perturb final time
            h = ustep.*(abs(input.phase(varphase).finaltime)+1);
            pertinput.phase(varphase).finaltime = input.phase(varphase).finaltime - h;
        elseif phasevarnum <= 2*numstate(varphase)+2+numintegral(varphase);
            % perturb integral
            refmark = phasevarnum-2*numstate(varphase)-2;
            h = ustep.*(abs(input.phase(varphase).integral(refmark))+1);
            pertinput.phase(varphase).integral(refmark) = input.phase(varphase).integral(refmark) - h;
        end
    else
        % perturb parameter
        refmark = phasevarnum;
        h = ustep.*(abs(input.parameter(refmark))+1);
        pertinput.parameter(refmark) = input.parameter(refmark) - h;
    end
    
    % evaluate function on perturbed input
    pertoutput = feval(probinfo.endpfunction, pertinput);
    
    % calculate nonzero derivatives of event constraints
    for eventgroupcount = 1:numeventgroup;
        for eventcount = 1:numevent(eventgroupcount);
            refmark = eventfunmap1(eventgroupcount).first(eventcount,nvccount);
            if refmark ~= 0;
                eventgroup(eventgroupcount).eventgrd(refmark) = (output.eventgroup(eventgroupcount).event(eventcount) - pertoutput.eventgroup(eventgroupcount).event(eventcount))./h;
            end
        end
    end
end