function derivativemap = gpopsContHesMap(probinfo, derivativemap)

% gpopsContHesMap
% this function builds a map for the hessian of the nonlinear program based
% on the first and second continuous function derivativemaps from of the
% optimal control problem

% get OCP info
numphase = probinfo.numphase;
numstate = probinfo.numstate;
numcontrol = probinfo.numcontrol;
numparameter = probinfo.numparameter;

% preallocate conthesmapand hesnvc
derivativemap.contmap2(numphase).conthesmap = [];
hesnvc = zeros(1,numphase);

for phasecount = 1:numphase;
    % OCP info for phase
    numstatep = numstate(phasecount);
    numcontrolp = numcontrol(phasecount);
    
    % total number of variables in phase
    numOCPcontvar = numstatep+numcontrolp+1+numparameter;
    
    % number of elements in lower triangle
    numOCPconttri = (numOCPcontvar.^2 + numOCPcontvar)/2;
    
    % time variable number
    tvarnum = numstatep + numcontrolp + 1;
    
    % get first and second derivative variable map for phase
    contvarmap1 = derivativemap.contmap1(phasecount).contvarmap1;
    contvarmap2 = derivativemap.contmap2(phasecount).contvarmap2;
    
    sizevarmap1 = size(contvarmap1,2);
    sizevarmap2 = size(contvarmap2,2);
    
    if sizevarmap1 == 0 && sizevarmap2 == 0;
        % conthesmap is empty
        conthesmap = [];
    elseif sizevarmap2 == 0;
        % only a function of first derivatives
        % hesnvc is equal to the number of first derivatives
        hesnvc(phasecount) = sizevarmap1;
        conthesmap = [tvarnum*ones(1,sizevarmap1); contvarmap1; 1:sizevarmap1; zeros(1,sizevarmap1)];
    else
        % preallocate conthesmap and markers
        conthesmap = zeros(4,numOCPconttri);
        asgmarker1 = 1;
        refmarker1 = 1;
        refmarker2 = 1;
        for varcount1 = 1:numOCPcontvar;
            for varcount2 = 1:varcount1;
                if varcount1 < tvarnum;
                    if refmarker2 <= sizevarmap2;
                        if contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2;
                            % second derivatives
                            conthesmap(:,asgmarker1) = [varcount1; varcount2; 0; refmarker2];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker2 = refmarker2 + 1;
                        end
                    end
                elseif varcount1 == tvarnum;
                    if refmarker1 <= sizevarmap1 && refmarker2 <= sizevarmap2;
                        if contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2 && contvarmap1(refmarker1) == varcount2;
                            % first and second derivatives
                            conthesmap(:,asgmarker1) = [varcount1; varcount2; refmarker1; refmarker2];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker1 = refmarker1 + 1;
                            refmarker2 = refmarker2 + 1;
                        elseif contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2;
                            % second derivatives
                            conthesmap(:,asgmarker1) = [varcount1; varcount2; 0; refmarker2];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker2 = refmarker2 + 1;
                        elseif contvarmap1(refmarker1) == varcount2;
                            % first derivatives
                            conthesmap(:,asgmarker1) = [varcount1; varcount2; refmarker1; 0];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker1 = refmarker1 + 1;
                        end
                    elseif refmarker1 <= sizevarmap1;
                        % first derivatives
                        conthesmap(:,asgmarker1) = [varcount1; contvarmap1(refmarker1); refmarker1; 0];
                        asgmarker1 = asgmarker1 + 1;
                        refmarker1 = refmarker1 + 1;
                    elseif refmarker2 <= sizevarmap2;
                        % second derivatives
                        conthesmap(:,asgmarker1) = [varcount1; contvarmap2(2,refmarker2); 0; refmarker2];
                        asgmarker1 = asgmarker1 + 1;
                        refmarker2 = refmarker2 + 1;
                    end
                else
                    if varcount2 == tvarnum;
                        if refmarker1 <= sizevarmap1 && refmarker2 <= sizevarmap2;
                            if contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2 && contvarmap1(refmarker1) == varcount1;
                                % first and second derivatives
                                conthesmap(:,asgmarker1) = [varcount1; varcount2; refmarker1; refmarker2];
                                asgmarker1 = asgmarker1 + 1;
                                refmarker1 = refmarker1 + 1;
                                refmarker2 = refmarker2 + 1;
                            elseif contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2;
                                % second derivatives
                                conthesmap(:,asgmarker1) = [varcount1; varcount2; 0; refmarker2];
                                asgmarker1 = asgmarker1 + 1;
                                refmarker2 = refmarker2 + 1;
                            elseif contvarmap1(refmarker1) == varcount1;
                                % first derivatives
                                conthesmap(:,asgmarker1) = [varcount1; varcount2; refmarker1; 0];
                                asgmarker1 = asgmarker1 + 1;
                                refmarker1 = refmarker1 + 1;
                            end
                        elseif refmarker1 <= sizevarmap1;
                            % first derivatives
                            conthesmap(:,asgmarker1) = [varcount1; contvarmap1(refmarker1); refmarker1; 0];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker1 = refmarker1 + 1;
                        elseif refmarker2 <= sizevarmap2;
                            % second derivatives
                            conthesmap(:,asgmarker1) = [varcount1; contvarmap2(2,refmarker2); 0; refmarker2];
                            asgmarker1 = asgmarker1 + 1;
                            refmarker2 = refmarker2 + 1;
                        end
                    else
                        if refmarker2 <= sizevarmap2;
                            if contvarmap2(1,refmarker2) == varcount1 && contvarmap2(2,refmarker2) == varcount2;
                                % second derivatives
                                conthesmap(:,asgmarker1) = [varcount1; varcount2; 0; refmarker2];
                                asgmarker1 = asgmarker1 + 1;
                                refmarker2 = refmarker2 + 1;
                            end
                        end
                    end
                end
                
            end
        end
        % hesnvc is equal to number of columns in conthesmap in phase
        hesnvc(phasecount) = asgmarker1 - 1;
        % remove unneeded columns from conthesmap in phase
        conthesmap(:,asgmarker1:end) = [];
    end
    % place the conthesmap into the derivativemap.contmap2 structure
    derivativemap.contmap2(phasecount).conthesmap = conthesmap;
end
% add hesnvc to derivativemap structure
derivativemap.hesnvc = hesnvc;