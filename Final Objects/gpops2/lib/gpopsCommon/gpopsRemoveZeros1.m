function newderivativemap = gpopsRemoveZeros1(probinfo, contdersamples1, endpdersamples1)

% gpopsRemoveZeros1
% this function removes zeros from the first derivative map
% and defines a new first derivative map
% the first derivatives of the continuous and endpoint function are used to
% determine the location of zeros

% get problem information
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numpath = probinfo.numpath;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% find nonzeros of the continuous function --------------------------------
contmap1 = probinfo.derivativemap.contmap1;
contnvc1 = probinfo.derivativemap.contnvc1;

% preallocate newcontmap1 for first derivatives
newcontmap1(numphase).contvarmap1 = [];
newcontmap1(numphase).dynamicsmap1 = [];
newcontnvc1 = zeros(1,numphase);
newdynamicsnnz1 = zeros(1,numphase);
if sum(numpath,2) ~= 0;
    newcontmap1(numphase).pathmap1 = [];
    newpathnnz1 = zeros(1,numphase);
end
if sum(numintegral,2) ~= 0;
    newcontmap1(numphase).integrandmap1 = [];
    newintegrandnnz1 = zeros(1,numphase);
end

% find first derivative nonzeros of the continuous function
for phasecount = 1:numphase;
    numstatep = numstate(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    
    % find sum of absolute values for all samples (stack)
    newdynamicsmap1 = zeros(numstatep,contnvc1(phasecount));
    dynamicsgrdstack1 = sum(abs(contdersamples1(phasecount).dynamicsgrd),1);
    if numpathp ~= 0;
        newpathmap1 = zeros(numpathp,contnvc1(phasecount));
        pathgrdstack1 = sum(abs(contdersamples1(phasecount).pathgrd),1);
    end
    if numintegralp ~= 0;
        newintegrandmap1 = zeros(numintegralp,contnvc1(phasecount));
        integrandgrdstack1 = sum(abs(contdersamples1(phasecount).integrandgrd),1);
    end
    
    % initiate counters to keep track of number of nonzeros
    dynamicsnnzcount = 0;
    pathnnzcount = 0;
    integrandnnzcount = 0;
    
    for contnvccount = 1:contnvc1(phasecount);
        for dynamicscount = 1:numstatep;
            refmark = contmap1(phasecount).dynamicsmap1(dynamicscount,contnvccount);
            if refmark ~= 0;
                if dynamicsgrdstack1(refmark) ~= 0;
                    dynamicsnnzcount = dynamicsnnzcount + 1;
                    newdynamicsmap1(dynamicscount,contnvccount) = dynamicsnnzcount;
                end
            end
        end
        % calculate nonzero derivatives of path constraints
        if numpathp ~= 0;
            for pathcount = 1:numpathp;
                refmark = contmap1(phasecount).pathmap1(pathcount,contnvccount);
                if refmark ~= 0;
                    if pathgrdstack1(refmark) ~= 0;
                        pathnnzcount = pathnnzcount + 1;
                        newpathmap1(pathcount,contnvccount) = pathnnzcount;
                    end
                end
            end
        end
        % calculate nonzero derivatives of intergrand constraints
        if numintegralp ~= 0;
            for intergralcount = 1:numintegralp;
                refmark = contmap1(phasecount).integrandmap1(intergralcount,contnvccount);
                if refmark ~= 0;
                    if integrandgrdstack1(refmark) ~= 0;
                        integrandnnzcount = integrandnnzcount + 1;
                        newintegrandmap1(intergralcount,contnvccount) = integrandnnzcount;
                    end
                end
            end
        end
    end
    
    % find variables that have nonzero first derivatives with respect to them
    % add dynamics, path, and intergrand derivative map together
    contmapstack1 = sum(newdynamicsmap1,1);
    if numpathp ~= 0;
        contmapstack1 = contmapstack1 + sum(newpathmap1,1);
    end
    if numintegralp ~= 0;
        contmapstack1 = contmapstack1 + sum(newintegrandmap1,1);
    end
    contindex1 = find(contmapstack1);
    
    % store new derivative map
    newcontnvc1(phasecount) = length(contindex1);
    newcontmap1(phasecount).contvarmap1 = contmap1(phasecount).contvarmap1(contindex1);
    newdynamicsnnz1(phasecount) = dynamicsnnzcount;
    newcontmap1(phasecount).dynamicsmap1 = newdynamicsmap1(:,contindex1);
    if numpathp ~= 0;
        newpathnnz1(phasecount) = pathnnzcount;
        newcontmap1(phasecount).pathmap1 = newpathmap1(:,contindex1);
    end
    if numintegralp ~= 0;
        newintegrandnnz1(phasecount) = integrandnnzcount;
        newcontmap1(phasecount).integrandmap1 = newintegrandmap1(:,contindex1);
    end
end
%--------------------------------------------------------------------------

% find endpoint first derivative nonzeros ---------------------------------
objgrdsamples = endpdersamples1.objectivegrd;
endpnvc1 = probinfo.derivativemap.endpnvc1;
endpvarmap1 = probinfo.derivativemap.endpvarmap1;
endpobjmap1 = probinfo.derivativemap.endpobjmap1;

% find sum of absolute values for all samples (stack)
objstack1 = sum(abs(objgrdsamples),1);
if numeventgroup ~= 0;
    eventgroupsamples = endpdersamples1.eventgroup;
    eventgroupstack(numeventgroup).eventstack1 = [];
    for eventgroupcount = 1:numeventgroup;
        eventgroupstack(eventgroupcount).eventstack1 = sum(abs(eventgroupsamples(eventgroupcount).eventgrd),1);
    end
end

% preallocate new endp, obj and event first derivative map
% endp map
newendpobjmap1 = zeros(1,endpnvc1);

% find first derivative nonzeros of objective
objnnzcount = 0;
for nvccount = 1:endpnvc1
    refmark = endpobjmap1(nvccount);
    if refmark ~= 0;
        if objstack1(refmark) ~= 0;
            objnnzcount = objnnzcount + 1;
            newendpobjmap1(nvccount) = objnnzcount;
        end
    end
end
objmapstack = newendpobjmap1;
% remove zeros
objindex1 = find(newendpobjmap1);

% new endp map
newendpnvc1 = objnnzcount;
newendpvarmap1 = endpvarmap1(objindex1);
newendpobjmap1 = newendpobjmap1(objindex1);

% new objective map
newobjnnz1 = objnnzcount;
newobjnvc1 = objnnzcount;
newobjvarmap1 = newendpvarmap1;
newobjfunmap1 = newendpobjmap1;

% find first derivative nonzeros of events
% event map
if numeventgroup ~= 0;
    % get endpeventmap1
    endpeventmap1 = probinfo.derivativemap.endpeventmap1;
    
    % preallocate newendpeventmap1, neweventnnz1 and eventmapstack
    tempendpeventmap(numeventgroup).first = [];
    neweventnnz1 = zeros(1,numeventgroup);
    eventmapstack = zeros(1,endpnvc1);
    
    for eventgroupcount = 1:numeventgroup;
        eventnnzcount = 0;
        neweventmap1 = zeros(numevent(eventgroupcount),endpnvc1);
        for nvccount = 1:endpnvc1
            for eventcount = 1:numevent(eventgroupcount);
                refmark = endpeventmap1(eventgroupcount).first(eventcount,nvccount);
                if refmark ~= 0;
                    if eventgroupstack(eventgroupcount).eventstack1(refmark) ~= 0;
                        eventnnzcount = eventnnzcount + 1;
                        neweventmap1(eventcount,nvccount) = eventnnzcount;
                    end
                end
            end
        end
        neweventnnz1(eventgroupcount) = eventnnzcount;
        tempendpeventmap(eventgroupcount).first = neweventmap1;
        eventmapstack = eventmapstack + sum(neweventmap1,1);
    end
    % find endp map by adding obj stack to event stack
    endpindex1 = find(eventmapstack + objmapstack);
    
    % new endp map (updated to include events)
    newendpnvc1 = length(endpindex1);
    newendpvarmap1 = endpvarmap1(endpindex1);
    newendpobjmap1 = objmapstack(endpindex1);
    
    % new event map
    eventindex1 = find(eventmapstack);
    neweventnvc1 = length(eventindex1);
    neweventvarmap1 = endpvarmap1(eventindex1);
    
    % get endpeventmap1 and eventfunmap1
    newendpeventmap1(numeventgroup).first = [];
    neweventfunmap1(numeventgroup).first = [];
    for eventgroupcount = 1:numeventgroup;
        newendpeventmap1(eventgroupcount).first = tempendpeventmap(eventgroupcount).first(:,endpindex1);
        neweventfunmap1(eventgroupcount).first = tempendpeventmap(eventgroupcount).first(:,eventindex1);
    end
end

% endp first derivative map
newderivativemap = probinfo.derivativemap;

% first derivative map
newderivativemap.endpnvc1 = newendpnvc1;
newderivativemap.endpvarmap1 = newendpvarmap1;
newderivativemap.endpobjmap1 = newendpobjmap1;
if numeventgroup ~= 0;
    newderivativemap.endpeventmap1 = newendpeventmap1;
end

% first derivative obj and event nnz
newderivativemap.objnnz1 = newobjnnz1;
if numeventgroup ~= 0;
    newderivativemap.eventnnz1 = neweventnnz1;
end

% first derivative obj map
newderivativemap.objnvc1 = newobjnvc1;
newderivativemap.objvarmap1 = newobjvarmap1;
newderivativemap.objfunmap1 = newobjfunmap1;

% first derivative event map
if numeventgroup ~= 0;
    newderivativemap.eventnvc1 = neweventnvc1;
    newderivativemap.eventvarmap1 = neweventvarmap1;
    newderivativemap.eventfunmap1 = neweventfunmap1;
end

% first derivative cont map
newderivativemap.contnvc1 = newcontnvc1;
newderivativemap.contmap1 = newcontmap1;

% first derivative dynamics, path, and intergrand nnz
newderivativemap.dynamicsnnz1 = newdynamicsnnz1;
if sum(numpath,2) ~= 0;
    newderivativemap.pathnnz1 = newpathnnz1;
end
if sum(numintegral,2) ~= 0;
    newderivativemap.integrandnnz1 = newintegrandnnz1;
end