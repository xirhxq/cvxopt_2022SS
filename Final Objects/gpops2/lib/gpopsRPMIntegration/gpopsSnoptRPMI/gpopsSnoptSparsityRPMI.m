function [grdjacnonlinpat, iGrow, jGcol, probinfo] = gpopsSnoptSparsityRPMI(probinfo)

% sparsity pattern for SNOPT
% combine cost gradient to Jacobian
% evaluate only nonlinear functions, add grdjaclinpat to nonlinear Jacobian

% get grdjacnonlinpat
[grdjacnonlinpat, probinfo] = gpopsGrdJacPatRPMI(probinfo);

% find nonzero locations of grdjaclinpat
[grdjaclinpat(:,1), grdjaclinpat(:,2)] = find(probinfo.grdjaclinMat);

% get combined nonlinear index
Gindex = union(grdjaclinpat, grdjacnonlinpat,'rows');
iGrow = Gindex(:,1);
jGcol = Gindex(:,2);

% make sparse matrix with the index as value
nonlinindexMat = sparse(iGrow, jGcol, (1:length(jGcol))', probinfo.nlpnumcon+1, probinfo.nlpnumvar);

% get ref index for Jacnz and Janlin
grdjacnzref = sub2ind([probinfo.nlpnumcon+1, probinfo.nlpnumvar], grdjacnonlinpat(:,1), grdjacnonlinpat(:,2));
%Jaclinref = sub2ind([probinfo.nlpnumcon+1, probinfo.nlpnumvar], grdjaclinpat(:,1), grdjaclinpat(:,2));

% assign  size of assignment index for Jacnz 
probinfo.snJacnonlinnnz = length(jGcol);
probinfo.grdjacnzasgindex = full(nonlinindexMat(grdjacnzref));