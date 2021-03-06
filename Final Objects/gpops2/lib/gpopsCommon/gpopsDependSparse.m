function derivativemap = gpopsDependSparse(probinfo, setup)

% gpopsDependSparse
% This function gets the optimal control problem dependencies for either
% the first or second derivative levels, the functions of the optimal
% control problem are sampled at several points, then the locations of the
% zeros are removed from the derivative map the resulting derivative map 
% will only have locations of nonzero derivatives

% get number of samples
numsamples = setup.derivatives.numsamples;

if probinfo.derivativelevel == 1;
    % start by initiating a full first derivative level
    probinfo.derivativemap = gpopsDependFull(probinfo, 1);
    
    % get the first derivative of the continuous and endpoint functions
    % at random sample points
    [contgrdsamples, endpgrdsamples] = gpopsRandomGrd(setup, probinfo, numsamples);
    
    % remove first derivative zeros
    derivativemap = gpopsRemoveZeros1(probinfo, contgrdsamples, endpgrdsamples);
else
    % probinfo.derivativelevel == 2;
    % start by initiating a full second derivative level
    probinfo.derivativemap = gpopsDependFull(probinfo, 1);
    
    % get the first derivative of the continuous and endpoint functions
    % at random sample points
    [contgrdsamples, endpgrdsamples] = gpopsRandomGrd(setup, probinfo, numsamples);
    
    % remove first derivative zeros
    derivativemap = gpopsRemoveZeros1(probinfo, contgrdsamples, endpgrdsamples);
    
    % estimate second derivative map from first derivative map
    probinfo.derivativemap = gpopsDependSecondFromFirst(derivativemap, probinfo);
    
    % get sample second derivatives
    [conthessamples, endphessamples] = gpopsRandomHes(setup, probinfo, numsamples);
    
    % remove second derivative zeros
    derivativemap = gpopsRemoveZeros2(probinfo, conthessamples, endphessamples);
end