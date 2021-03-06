function [iArow, jAcol, AA, grdjacpat, iGrow, jGcol, JaclinMat, probinfo] = gpopsSnoptSparsityRPMD(probinfo)

% sparsity pattern for SNOPT
% combine cost gradient to Jacobian
% evaluate only nonlinear functions, add JacLinC to nonlinear Jacobian

[grdjacpat, probinfo] = gpopsGrdJacPatRPMD(probinfo);
[jaclindiag, jaclinoffdiag] = gpopsJacLinearRPMD(probinfo);

% linear part
iArow = jaclinoffdiag(:,1) + 1;
jAcol = jaclinoffdiag(:,2);
AA = jaclinoffdiag(:,3);

% nonlinear part (add grdjacpat and jaclindiag together)
% add 1 to all rows to account for objective
jaclindiag(:,1) = jaclindiag(:,1) + 1;

% Get JaclinMat
JaclinMat = sparse(jaclindiag(:,1), jaclindiag(:,2), jaclindiag(:,3), probinfo.nlpnumcon+1, probinfo.nlpnumvar);

% get combined nonlinear index
Gindex = union(jaclindiag(:,1:2), grdjacpat,'rows');
iGrow = Gindex(:,1);
jGcol = Gindex(:,2);

% make sparse matrix with the index as value
nonlinMat = sparse(iGrow, jGcol, (1:length(jGcol))', probinfo.nlpnumcon+1, probinfo.nlpnumvar);

% get ref index for Jacnz and Janlin
Jacnzref = sub2ind([probinfo.nlpnumcon+1, probinfo.nlpnumvar], grdjacpat(:,1), grdjacpat(:,2));

% assign  size of assignment index for Jacnz 
probinfo.snJacnonlinnnz = length(jGcol);
probinfo.Jacnzasg = full(nonlinMat(Jacnzref));