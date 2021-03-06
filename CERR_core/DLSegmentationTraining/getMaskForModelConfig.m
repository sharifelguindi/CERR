function outMask3M = getMaskForModelConfig(planC,mask3M,cropS)
% cropScanAndMask.m
% Create mask for deep learning based on input configuration file.
%
% AI 7/23/19
%--------------------------------------------------------------------------
%INPUTS:
% planC         
% mask3M       : Mask
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_to_str', 'crop_around_center', 'none'.
%--------------------------------------------------------------------------
% AI 7/23/19

origMask3M = mask3M;
methodC = {cropS.method};
maskC = cell(length(methodC),1);

for m = 1:length(methodC)
    
    method = methodC{m};
    paramS = cropS(m).params;
    
    switch(lower(method))
        
        case 'crop_fixed_amt'
            cropDimV = paramS.margins;
            if ~isempty(origMask3M)
                outMask3M = false(size(origMask3M));
                outMask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6)) = true;
                maskC{m} = outMask3M;
            end
            
        case 'crop_to_bounding_box'
            %Use to crop around one of the structures to be segmented
            label = paramS.label;
            if ~isempty(origMask3M)
                outMask3M = origMask3M == label;
                maskC{m} = outMask3M;
            end
            
        case 'crop_to_str'
            %Use to crop around different structure
            %mask3M = []
            strName = paramS.structureName;
            indexS = planC{end};
            strC = {planC{indexS.structures}.structureName};
            strIdx = getMatchingIndex(strName,strC,'EXACT');
            if ~isempty(strIdx)
                scanIdx = getStructureAssociatedScan(strIdx,planC);
                outMask3M = false(size(getScanArray(scanIdx,planC)));
                rasterM = getRasterSegments(strIdx,planC);
                [slMask3M,slicesV] = rasterToMask(rasterM,scanIdx,planC);
                outMask3M(:,:,slicesV) = slMask3M;
                maskC{m} = outMask3M;
            end
            
            
            
        case 'crop_around_center'
            % Use to crop around center
            cropDimV = paramS.margins;
            scanSizV = size(scan3M);
            
            cx = ceil(scanSizV(1)/2);
            cy = ceil(scanSizV(2)/2);
            x = cropDimV(1)/2;
            y = cropDimV(2)/2;
            minr = cx - y;
            maxr = cx + y-1;
            minc = cy - x;
            maxc = cy + x-1;
            mins = 1;
            maxs = scanSizV(3);
            
            if ~isempty(origMask3M)
                outMask3M = false(size(origMask3M));
                outMask3M(minr:maxr,minc:maxc,mins:maxs) = true;
                maskC{m} = outMask3M;
            end
            
        case 'none'
            %Skip
            
    end
    
    if m>1
        switch lower(cropS(m).operator)
            case 'union'
                outMask3M = or(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
            case 'intersection'
                outMask3M = and(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
        end
    end
    
end


outMask3M = maskC{end};

end




