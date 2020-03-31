function [data] = storePlanC(contourListSearch, contourListReNamed, planC, scanM, scanFile, dose, modelVersion, matchCase)

% Get Scan
arr_size = size(scanM);
spacing = [planC{1,3}.uniformScanInfo.grid1Units, planC{1,3}.uniformScanInfo.grid2Units, planC{1,3}.uniformScanInfo.sliceThickness];
dataHeaders = ["structName", "VolumeInitial", "VolumeFinal", "SurfaceInitial", "SurfaceFinal", "NumofSlices", "PctPerfectSlices", "initialArray", "finalArray", "DiffMap", "VDSC", "sliceDSC", "BoundingBox", "scanSize", "voxelSize", "scanRaw","doseRaw"];
data = cell(length(contourListSearch)+1, length(dataHeaders)); 
for k = 1:length(dataHeaders)
    data{1,k} = dataHeaders(k);
end

i = 2;
j = 1;
for struct = contourListSearch

    data{i,1} = contourListReNamed(j);
            
    if i == 2
        data{i,16} = scanM;
        data{i,17} = dose;
    else  
        data{i,16} = [];
        data{i,17} = [];
    end
    
    % Get auto contour
    if modelVersion ~= 'NONE'
        n = getMASKfromPlanC(planC, strcat(struct, '_', modelVersion), scanM, matchCase);
    else
        n = 0;
    end
    
    % Get clinical contour
    m = getMASKfromPlanC(planC, struct, scanM, matchCase);
    
    % if no auto contour, still store final contour information
    if length(size(n)) < 3
        n = zeros(size(m));
    end
    
    if length(size(m)) < 3  || length(size(n)) < 3 || max(m(:)) == 0 
        i = i + 1;
        j = j + 1;
    else
        struct
        idx = logical(m); 
        ind = find(idx); 
        [row, col, pag] = ind2sub(size(m),ind);
        [~,cornerpoints_m, volume_m, surface_m] = minboundbox(row, col, pag,'v',3);
        
        idx = logical(n); 
        ind = find(idx); 
        [row, col, pag] = ind2sub(size(n),ind);
        
        if isempty(row) || isempty(col) || isempty(pag)
            cornerpoints_n = cornerpoints_m;
            volume_n = 0;
            surface_n = 0;
        else
            [~,cornerpoints_n, volume_n, surface_n] = minboundbox(row,col,pag,'v',3);
        end
        
        Cornerpoints = vertcat(cornerpoints_m, cornerpoints_n);
        bbox = [floor(min(Cornerpoints(:,1))), ceil(max(Cornerpoints(:,1))), floor(min(Cornerpoints(:,2))), ceil(max(Cornerpoints(:,2))), floor(min(Cornerpoints(:,3))), ceil(max(Cornerpoints(:,3)))];

        DCE = computeVDSC(n,m);
        sliceDCE = computeSliceDSC(n,m,volume_m);


        % Ensure bbox handles edge structures

        if bbox(1) < 1
            bbox(1) = 1;
        end
        if bbox(2) > arr_size(1)
            bbox(2) = arr_size(1);
        end

        if bbox(3) < 1
            bbox(3) = 1;
        end

        if bbox(4) > arr_size(2)
            bbox(4) = arr_size(2);
        end

        if bbox(5) < 1
            bbox(5) = 1;
        end

        if bbox(6) > arr_size(3)
            bbox(6) = arr_size(3);
        end


        n_clip = n(bbox(1):bbox(2),bbox(3):bbox(4),bbox(5):bbox(6));
        m_clip = m(bbox(1):bbox(2),bbox(3):bbox(4),bbox(5):bbox(6));
        pct_perfect = sum(all(~diff(sliceDCE)))/(sum(sliceDCE(3,:)));
        num_of_slices = sum(sliceDCE(3,:));

        if max(n(:)) == 0
            n_clip = 0;
            diffMap = 0;
            sliceDCE = 0;
        else
            diffMap = m_clip - n_clip;
        end
   
        
        data{i,2} = volume_n;
        data{i,3} = volume_m;
        data{i,4} = surface_n;
        data{i,5} = surface_m;
        data{i,6} = num_of_slices;
        data{i,7} = pct_perfect;
        data{i,8} = n_clip;
        data{i,9} = m_clip;
        data{i,10} = diffMap; % Final - Initial: +1 means contour was increased, -1 means contour was decreased
        data{i,11} = DCE;
        data{i,12} = sliceDCE;
        data{i,13} = bbox;
        data{i,14} = size(scanM);
        data{i,15} = spacing;
        
        if i == 2
            data{i,16} = scanM;
            data{i,17} = dose;
        else  
            data{i,16} = [];
            data{i,17} = [];
        end
        
        j = j + 1;
        i = i + 1;
    end
end

contourComparisonData = strrep(scanFile,'PlanC','data');
save(contourComparisonData, 'data');

end

    