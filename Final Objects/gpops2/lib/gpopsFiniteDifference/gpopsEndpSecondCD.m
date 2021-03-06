function endpsecondder = gpopsEndpSecondCD(input, probinfo)

% gpopsEndpSecondCD
% this function estimates the second derivatives of the OCP endpoint
% function using central difference
% only the derivatives indicated in the derivativemap are found
% uses value based step sizes

% OCP info
numstate = probinfo.numstate;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% get endpoint derivative map
endpvarloc = probinfo.endpvarloc;
endpnvc2 = probinfo.derivativemap.endpnvc2;
objnnz2 = probinfo.derivativemap.objnnz2;
endpvarmap2 = probinfo.derivativemap.endpvarmap2;
endpobjmap2 = probinfo.derivativemap.endpobjmap2;

% preallocate derivative output
% only nonzero derivatives of the optimal control problem are stored
objectivehes = zeros(1,objnnz2);
if numeventgroup ~= 0;
    eventnnz2 = probinfo.derivativemap.eventnnz2;
    endpeventmap2 = probinfo.derivativemap.endpeventmap2;
    eventgroup(numeventgroup).eventhes = [];
    for eventgroupcount = 1:numeventgroup;
        eventgroup(eventgroupcount).eventhes = zeros(1,eventnnz2(eventgroupcount));
    end
end

% get base stepsize
ustep = probinfo.stepsize;

for nvccount = 1:endpnvc2
    % initiate pertinput as the unperturbed input
    pertinput1 = input;
    pertinput2 = input;
    pertinput3 = input;
    pertinput4 = input;
    
    % get variable phase, and variable number in phase
    varnum1 = endpvarmap2(1,nvccount);
    varnum2 = endpvarmap2(2,nvccount);
    
    varphase1 = endpvarloc(1,varnum1);
    phasevarnum1 = endpvarloc(2,varnum1);

    varphase2 = endpvarloc(1,varnum2);
    phasevarnum2 = endpvarloc(2,varnum2);
    
    if varphase1 ~= 0;
        if phasevarnum1 <= numstate(varphase1);
            % perturb initial state
            refmark = phasevarnum1;
            h1 = ustep.*(abs(input.phase(varphase1).initialstate(refmark))+1);
            pertinput1.phase(varphase1).initialstate(refmark) = pertinput1.phase(varphase1).initialstate(refmark) + h1./2;
            pertinput2.phase(varphase1).initialstate(refmark) = pertinput2.phase(varphase1).initialstate(refmark) - h1./2;
            pertinput3.phase(varphase1).initialstate(refmark) = pertinput3.phase(varphase1).initialstate(refmark) + h1./2;
            pertinput4.phase(varphase1).initialstate(refmark) = pertinput4.phase(varphase1).initialstate(refmark) - h1./2;
        elseif phasevarnum1 <= 2*numstate(varphase1);
            % perturb final state
            refmark = phasevarnum1-numstate(varphase1);
            h1 = ustep.*(abs(input.phase(varphase1).finalstate(refmark))+1);
            pertinput1.phase(varphase1).finalstate(refmark) = pertinput1.phase(varphase1).finalstate(refmark) + h1./2;
            pertinput2.phase(varphase1).finalstate(refmark) = pertinput2.phase(varphase1).finalstate(refmark) - h1./2;
            pertinput3.phase(varphase1).finalstate(refmark) = pertinput3.phase(varphase1).finalstate(refmark) + h1./2;
            pertinput4.phase(varphase1).finalstate(refmark) = pertinput4.phase(varphase1).finalstate(refmark) - h1./2;
        elseif phasevarnum1 == 2*numstate(varphase1)+1;
            % perturb initial time
            h1 = ustep.*(abs(input.phase(varphase1).initialtime)+1);
            pertinput1.phase(varphase1).initialtime = pertinput1.phase(varphase1).initialtime + h1./2;
            pertinput2.phase(varphase1).initialtime = pertinput2.phase(varphase1).initialtime - h1./2;
            pertinput3.phase(varphase1).initialtime = pertinput3.phase(varphase1).initialtime + h1./2;
            pertinput4.phase(varphase1).initialtime = pertinput4.phase(varphase1).initialtime - h1./2;
        elseif phasevarnum1 == 2*numstate(varphase1)+2;
            % perturb final time
            h1 = ustep.*(abs(input.phase(varphase1).finaltime)+1);
            pertinput1.phase(varphase1).finaltime = pertinput1.phase(varphase1).finaltime + h1./2;
            pertinput2.phase(varphase1).finaltime = pertinput2.phase(varphase1).finaltime - h1./2;
            pertinput3.phase(varphase1).finaltime = pertinput3.phase(varphase1).finaltime + h1./2;
            pertinput4.phase(varphase1).finaltime = pertinput4.phase(varphase1).finaltime - h1./2;
        elseif phasevarnum1 <= 2*numstate(varphase1)+2+numintegral(varphase1);
            % perturb integral
            refmark = phasevarnum1-2*numstate(varphase1)-2;
            h1 = ustep.*(abs(input.phase(varphase1).integral(refmark))+1);
            pertinput1.phase(varphase1).integral(refmark) = pertinput1.phase(varphase1).integral(refmark) + h1./2;
            pertinput2.phase(varphase1).integral(refmark) = pertinput2.phase(varphase1).integral(refmark) - h1./2;
            pertinput3.phase(varphase1).integral(refmark) = pertinput3.phase(varphase1).integral(refmark) + h1./2;
            pertinput4.phase(varphase1).integral(refmark) = pertinput4.phase(varphase1).integral(refmark) - h1./2;
        end
    else
        % perturb parameter
        refmark = phasevarnum1;
        h1 = ustep.*(abs(input.parameter(refmark))+1);
        pertinput1.parameter(refmark) = pertinput1.parameter(refmark) + h1./2;
        pertinput2.parameter(refmark) = pertinput2.parameter(refmark) - h1./2;
        pertinput3.parameter(refmark) = pertinput3.parameter(refmark) + h1./2;
        pertinput4.parameter(refmark) = pertinput4.parameter(refmark) - h1./2;
    end
    
    if varphase2 ~= 0;
        if phasevarnum2 <= numstate(varphase2);
            % perturb initial state
            refmark = phasevarnum2;
            h2 = ustep.*(abs(input.phase(varphase2).initialstate(refmark))+1);
            pertinput1.phase(varphase2).initialstate(refmark) = pertinput1.phase(varphase2).initialstate(refmark) + h2./2;
            pertinput2.phase(varphase2).initialstate(refmark) = pertinput2.phase(varphase2).initialstate(refmark) + h2./2;
            pertinput3.phase(varphase2).initialstate(refmark) = pertinput3.phase(varphase2).initialstate(refmark) - h2./2;
            pertinput4.phase(varphase2).initialstate(refmark) = pertinput4.phase(varphase2).initialstate(refmark) - h2./2;
        elseif phasevarnum2 <= 2*numstate(varphase2);
            % perturb final state
            refmark = phasevarnum2-numstate(varphase2);
            h2 = ustep.*(abs(input.phase(varphase2).finalstate(refmark))+1);
            pertinput1.phase(varphase2).finalstate(refmark) = pertinput1.phase(varphase2).finalstate(refmark) + h2./2;
            pertinput2.phase(varphase2).finalstate(refmark) = pertinput2.phase(varphase2).finalstate(refmark) + h2./2;
            pertinput3.phase(varphase2).finalstate(refmark) = pertinput3.phase(varphase2).finalstate(refmark) - h2./2;
            pertinput4.phase(varphase2).finalstate(refmark) = pertinput4.phase(varphase2).finalstate(refmark) - h2./2;
        elseif phasevarnum2 == 2*numstate(varphase2)+1;
            % perturb initial time
            h2 = ustep.*(abs(input.phase(varphase2).initialtime)+1);
            pertinput1.phase(varphase2).initialtime = pertinput1.phase(varphase2).initialtime + h2./2;
            pertinput2.phase(varphase2).initialtime = pertinput2.phase(varphase2).initialtime + h2./2;
            pertinput3.phase(varphase2).initialtime = pertinput3.phase(varphase2).initialtime - h2./2;
            pertinput4.phase(varphase2).initialtime = pertinput4.phase(varphase2).initialtime - h2./2;
        elseif phasevarnum2 == 2*numstate(varphase2)+2;
            % perturb final time
            h2 = ustep.*(abs(input.phase(varphase2).finaltime)+1);
            pertinput1.phase(varphase2).finaltime = pertinput1.phase(varphase2).finaltime + h2./2;
            pertinput2.phase(varphase2).finaltime = pertinput2.phase(varphase2).finaltime + h2./2;
            pertinput3.phase(varphase2).finaltime = pertinput3.phase(varphase2).finaltime - h2./2;
            pertinput4.phase(varphase2).finaltime = pertinput4.phase(varphase2).finaltime - h2./2;
        elseif phasevarnum2 <= 2*numstate(varphase2)+2+numintegral(varphase2);
            % perturb integral
            refmark = phasevarnum2-2*numstate(varphase2)-2;
            h2 = ustep.*(abs(input.phase(varphase2).integral(refmark))+1);
            pertinput1.phase(varphase2).integral(refmark) = pertinput1.phase(varphase2).integral(refmark) + h2./2;
            pertinput2.phase(varphase2).integral(refmark) = pertinput2.phase(varphase2).integral(refmark) + h2./2;
            pertinput3.phase(varphase2).integral(refmark) = pertinput3.phase(varphase2).integral(refmark) - h2./2;
            pertinput4.phase(varphase2).integral(refmark) = pertinput4.phase(varphase2).integral(refmark) - h2./2;
        end
    else
        % perturb parameter
        refmark = phasevarnum2;
        h2 = ustep.*(abs(input.parameter(refmark))+1);
        pertinput1.parameter(refmark) = pertinput1.parameter(refmark) + h2./2;
        pertinput2.parameter(refmark) = pertinput2.parameter(refmark) + h2./2;
        pertinput3.parameter(refmark) = pertinput3.parameter(refmark) - h2./2;
        pertinput4.parameter(refmark) = pertinput4.parameter(refmark) - h2./2;
    end
    
    % evaluate function on perturbed input
    pertoutput1 = feval(probinfo.endpfunction, pertinput1);
    pertoutput2 = feval(probinfo.endpfunction, pertinput2);
    pertoutput3 = feval(probinfo.endpfunction, pertinput3);
    pertoutput4 = feval(probinfo.endpfunction, pertinput4);
    
    % calculate nonzero derivatives of the objective
    refmark = endpobjmap2(nvccount);
    if refmark ~= 0;
        objectivehes(refmark) = (pertoutput1.objective - pertoutput2.objective - pertoutput3.objective + pertoutput4.objective)./(h1.*h2);
    end
    
    % calculate nonzero derivatives of event constraints
    for eventgroupcount = 1:numeventgroup;
        for eventcount = 1:numevent(eventgroupcount);
            refmark = endpeventmap2(eventgroupcount).second(eventcount,nvccount);
            if refmark ~= 0;
                eventgroup(eventgroupcount).eventhes(refmark) = (pertoutput1.eventgroup(eventgroupcount).event(eventcount) - pertoutput2.eventgroup(eventgroupcount).event(eventcount) - pertoutput3.eventgroup(eventgroupcount).event(eventcount) + pertoutput4.eventgroup(eventgroupcount).event(eventcount))./(h1.*h2);
            end
        end
    end
end

endpsecondder.objectivehes = objectivehes;
if numeventgroup ~= 0;
    endpsecondder.eventgroup = eventgroup;
end