function newderivativemap = gpopsRemoveZeros2(probinfo, contdersamples2, endpdersamples2)

% gpopsRemoveZeros2
% this function removes zeros from the second derivative map
% and defines a new second derivative map
% the second derivatives of the continuous and endpoint function are used to
% determine the location of zeros

% get problem information
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numpath = probinfo.numpath;
numintegral = probinfo.numintegral;
numeventgroup = probinfo.numeventgroup;
numevent = probinfo.numevent;

% find nonzeros of the continuous function --------------------------------
contmap2 = probinfo.derivativemap.contmap2;
contnvc2 = probinfo.derivativemap.contnvc2;

% preallocate newcontmap2 for second derivatives
newcontmap2(numphase).contvarmap2 = [];
newcontmap2(numphase).dynamicsmap2 = [];
newcontnvc2 = zeros(1,numphase);
newdynamicsnnz2 = zeros(1,numphase);
if sum(numpath,2) ~= 0;
    newcontmap2(numphase).pathmap2 = [];
    newpathnnz2 = zeros(1,numphase);
end
if sum(numintegral,2) ~= 0;
    newcontmap2(numphase).integrandmap2 = [];
    newintegrandnnz2 = zeros(1,numphase);
end

% find second derivative nonzeros of the continuous function
for phasecount = 1:numphase;
    numstatep = numstate(phasecount);
    numpathp = numpath(phasecount);
    numintegralp = numintegral(phasecount);
    
    % find sum of absolute values for all samples (stack)
    newdynamicsmap2 = zeros(numstatep,contnvc2(phasecount));
    dynamicsgrdstack2 = sum(abs(contdersamples2(phasecount).dynamicshes),1);
    if numpathp ~= 0;
        newpathmap2 = zeros(numpathp,contnvc2(phasecount));
        pathgrdstack2 = sum(abs(contdersamples2(phasecount).pathhes),1);
    end
    if numintegralp ~= 0;
        newintegrandmap2 = zeros(numintegralp,contnvc2(phasecount));
        integrandgrdstack2 = sum(abs(contdersamples2(phasecount).integrandhes),1);
    end
    
    % initiate counters to keep track of number of nonzeros
    dynamicsnnzcount = 0;
    pathnnzcount = 0;
    integrandnnzcount = 0;
    
    for contnvccount = 1:contnvc2(phasecount);
        for dynamicscount = 1:numstatep;
            refmark = contmap2(phasecount).dynamicsmap2(dynamicscount,contnvccount);
            if refmark ~= 0;
                if dynamicsgrdstack2(refmark) ~= 0;
                    dynamicsnnzcount = dynamicsnnzcount + 1;
                    newdynamicsmap2(dynamicscount,contnvccount) = dynamicsnnzcount;
                end
            end
        end
        % calculate nonzero derivatives of path constraints
        if numpathp ~= 0;
            for pathcount = 1:numpathp;
                refmark = contmap2(phasecount).pathmap2(pathcount,contnvccount);
                if refmark ~= 0;
                    if pathgrdstack2(refmark) ~= 0;
                        pathnnzcount = pathnnzcount + 1;
                        newpathmap2(pathcount,contnvccount) = pathnnzcount;
                    end
                end
            end
        end
        % calculate nonzero derivatives of intergrand constraints
        if numintegralp ~= 0;
            for intergralcount = 1:numintegralp;
                refmark = contmap2(phasecount).integrandmap2(intergralcount,contnvccount);
                if refmark ~= 0;
                    if integrandgrdstack2(refmark) ~= 0;
                        integrandnnzcount = integrandnnzcount + 1;
                        newintegrandmap2(intergralcount,contnvccount) = integrandnnzcount;
                    end
                end
            end
        end
    end
    
    % find variables that have nonzero second derivatives with respect to them
    % add dynamics, path, and intergrand derivative map together
    contmapstack2 = sum(newdynamicsmap2,1);
    if numpathp ~= 0;
        contmapstack2 = contmapstack2 + sum(newpathmap2,1);
    end
    if numintegralp ~= 0;
        contmapstack2 = contmapstack2 + sum(newintegrandmap2,1);
    end
    contindex2 = find(contmapstack2);
    
    % store new derivative map
    newcontnvc2(phasecount) = length(contindex2);
    newcontmap2(phasecount).contvarmap2 = contmap2(phasecount).contvarmap2(:,contindex2);
    newdynamicsnnz2(phasecount) = dynamicsnnzcount;
    newcontmap2(phasecount).dynamicsmap2 = newdynamicsmap2(:,contindex2);
    if numpathp ~= 0;
        newpathnnz2(phasecount) = pathnnzcount;
        newcontmap2(phasecount).pathmap2 = newpathmap2(:,contindex2);
    end
    if numintegralp ~= 0;
        newintegrandnnz2(phasecount) = integrandnnzcount;
        newcontmap2(phasecount).integrandmap2 = newintegrandmap2(:,contindex2);
    end
end
%--------------------------------------------------------------------------

% find endpoint second derivative nonzeros ---------------------------------
objhessamples = endpdersamples2.objectivehes;
endpnvc2 = probinfo.derivativemap.endpnvc2;
endpvarmap2 = probinfo.derivativemap.endpvarmap2;
endpobjmap2 = probinfo.derivativemap.endpobjmap2;

% find sum of absolute values for all samples (stack)
objstack2 = sum(abs(objhessamples),1);
if numeventgroup ~= 0;
    eventgroupsamples = endpdersamples2.eventgroup;
    eventgroupstack(numeventgroup).eventstack2 = [];
    for eventgroupcount = 1:numeventgroup;
        eventgroupstack(eventgroupcount).eventstack2 = sum(abs(eventgroupsamples(eventgroupcount).eventhes),1);
    end
end

% preallocate new endp, obj and event second derivative map
% endp map
newendpobjmap2 = zeros(1,endpnvc2);

% find second derivative nonzeros of objective
objnnzcount = 0;
for nvccount = 1:endpnvc2
    refmark = endpobjmap2(nvccount);
    if refmark ~= 0;
        if objstack2(refmark) ~= 0;
            objnnzcount = objnnzcount + 1;
            newendpobjmap2(nvccount) = objnnzcount;
        end
    end
end
objmapstack = newendpobjmap2;
% remove zeros
objindex2 = find(newendpobjmap2);

% new endp map
newobjnnz2 = objnnzcount;
newendpnvc2 = objnnzcount;
newendpvarmap2 = endpvarmap2(:,objindex2);
newendpobjmap2 = newendpobjmap2(:,objindex2);

% find second derivative nonzeros of events
% event map
if numeventgroup ~= 0;
    
    % get endpeventmap2
    endpeventmap2 = probinfo.derivativemap.endpeventmap2;
    
    % preallocate newendpeventmap2, neweventnnz2 and eventmapstack
    newendpeventmap2(numeventgroup).second = [];
    neweventnnz2 = zeros(1,numeventgroup);
    eventmapstack = zeros(1,endpnvc2);
    
    for eventgroupcount = 1:numeventgroup;
        eventnnzcount = 0;
        neweventmap2 = zeros(numevent(eventgroupcount),endpnvc2);
        for nvccount = 1:endpnvc2
            for eventcount = 1:numevent(eventgroupcount);
                refmark = endpeventmap2(eventgroupcount).second(eventcount,nvccount);
                if refmark ~= 0;
                    if eventgroupstack(eventgroupcount).eventstack2(refmark) ~= 0;
                        eventnnzcount = eventnnzcount + 1;
                        neweventmap2(eventcount,nvccount) = eventnnzcount;
                    end
                end
            end
        end
        neweventnnz2(eventgroupcount) = eventnnzcount;
        newendpeventmap2(eventgroupcount).second = neweventmap2;
        eventmapstack = eventmapstack + sum(neweventmap2,1);
    end
    
    % find endp map by adding obj stack to event stack
    endpindex2 = find(eventmapstack + objmapstack);
    
    % new endp map (updated to include events)
    newendpnvc2 = length(endpindex2);
    newendpvarmap2 = endpvarmap2(:,endpindex2);
    newendpobjmap2 = objmapstack(:,endpindex2);
    
    % get endpeventmap2
    for eventgroupcount = 1:numeventgroup;
        newendpeventmap2(eventgroupcount).second = newendpeventmap2(eventgroupcount).second(:,endpindex2);
    end
end

% define new derivative map
newderivativemap = probinfo.derivativemap;

% second derivative endp map
newderivativemap.endpnvc2 = newendpnvc2;
newderivativemap.endpvarmap2 = newendpvarmap2;
newderivativemap.endpobjmap2 = newendpobjmap2;
if numeventgroup ~= 0;
    newderivativemap.endpeventmap2 = newendpeventmap2;
end

% second derivative obj and event nnz
newderivativemap.objnnz2 = newobjnnz2;
if numeventgroup ~= 0;
    newderivativemap.eventnnz2 = neweventnnz2;
end

% second derivative cont map
newderivativemap.contnvc2 = newcontnvc2;
newderivativemap.contmap2 = newcontmap2;

% second derivative dynamics, path, and intergrand nnz
newderivativemap.dynamicsnnz2 = newdynamicsnnz2;
if sum(numpath,2) ~= 0;
    newderivativemap.pathnnz2 = newpathnnz2;
end
if sum(numintegral,2) ~= 0;
    newderivativemap.integrandnnz2 = newintegrandnnz2;
end