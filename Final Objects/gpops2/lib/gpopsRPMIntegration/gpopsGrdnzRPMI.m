function grdnz = gpopsGrdnzRPMI(Z, probinfo)

% gpopsGrdnzRPMI
% this function computes the values of the Gradient nonzeros that correspond
% to the locations of the Gradient nonzeros sparsity pattern

% NLP variable order
% [states*(nodes+1); controls*nodes; t0; tf, Q] for each phase
% [stack all phases(1;...;numphase); parameters]

% OCP endpoint input
endpinput = gpopsEndpInputRPMI(Z, probinfo);

% get first derivatives of objective
if probinfo.analyticflag;
    endpgrd = feval(probinfo.endpgrd, endpinput);
    objgrd = endpgrd.objectivegrd;
else
    objgrd = feval(probinfo.objgrd, endpinput, probinfo);
end

% get objective nonzeros
grdnz = objgrd(probinfo.derivativemap.objfunmap1)';