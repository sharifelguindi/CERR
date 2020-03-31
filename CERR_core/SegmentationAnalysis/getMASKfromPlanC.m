function [m] = getMASKfromPlanC(planC, mask_name, target, matchCase)

if matchCase == 1
    for structNum = 1:length(planC{4})
        strucName = planC{4}(structNum).structureName;
        if strcmpi(strucName, (mask_name)) == 1 && contains(upper(strucName),'Z') == 0
            m = zeros(size(target));
            size(target);
            [rasterSegments, planC, ~] = getRasterSegments(structNum,planC);
            [mask3M, uniqueSlices] = rasterToMask(rasterSegments, 1, planC);
            for slice = 1:length(uniqueSlices)
                m(:,:,uniqueSlices(slice)) = mask3M(:,:,slice);
            end
        end
    end
else
    for structNum = 1:length(planC{4})
        strucName = planC{4}(structNum).structureName;
        if contains(upper(strucName), upper(mask_name)) == 1 && ...
                                   contains(upper(strucName),'Z') == 0 && ...
                                   contains(upper(strucName),'MM') == 0 && ...
                                   contains(upper(strucName),'PRV') == 0 && ...
                                   contains(upper(strucName),'NEW') == 0 && ...
                                   contains(upper(strucName),'NOT') == 0 && ...
                                   contains(upper(strucName),'GWV') == 0 && ...
                                   contains(upper(strucName),'NECK') == 0 && ...
                                   contains(upper(strucName),'DLV3') == 0 && ...
                                   contains(upper(strucName),'_Z') == 0
            m = zeros(size(target));
            size(target);
            [rasterSegments, planC, ~] = getRasterSegments(structNum,planC);
            [mask3M, uniqueSlices] = rasterToMask(rasterSegments, 1, planC);
            for slice = 1:length(uniqueSlices)
                m(:,:,uniqueSlices(slice)) = mask3M(:,:,slice);
            end
        end
    end
end

if exist('m','var') ~= 1
    m = 0;
end

end


