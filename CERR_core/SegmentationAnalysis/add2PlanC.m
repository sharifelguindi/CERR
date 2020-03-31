function [data] = add2PlanC(contourListSearch, contourListRenamed, planC, scanM, scanFile, dose, modelVersion, matchCase)

% Add correct CERR version
addpath(genpath('H:\Public\Elguindi\CERR'))

% Get Scan
arrSize = size(scanM);
spacing = [planC{1,3}.uniformScanInfo.grid1Units, planC{1,3}.uniformScanInfo.grid2Units, planC{1,3}.uniformScanInfo.sliceThickness];
% dataHeaders = ["structName", "VolumeInitial", "VolumeFinal", "SurfaceInitial", "SurfaceFinal", "NumofSlices", "PctPerfectSlices", "initialArray", "finalArray", "DiffMap", "VDSC", "sliceDSC", "BoundingBox", "scanSize", "voxelSize", "scanRaw","doseRaw"];
% data = cell(length(contourListSearch)+1, length(dataHeaders)); 
% for k = 1:length(dataHeaders)
%     data{1,k} = dataHeaders(k);
% end

i = 2;
j = 1;
contourComparisonData = strrep(scanFile,'PlanC','data');
data = load(contourComparisonData);
data = data.data;
for struct = contourListSearch
    struct
    contourListRenamed(j)
%     data{i,1} = contourListReNamed(j);
    % Get auto contour
    if modelVersion ~= 'NONE'
        n = getMASKfromPlanC(planC, strcat(struct, '_', modelVersion), scanM, matchCase);
    else
        n = getMASKfromPlanC(planC, struct, scanM, matchCase);
    end
    
    
    % Get clinical contour, if it Exists
    idxStruct = strmatch(contourListRenamed(j),cellstr(data(:,1)));
    idxColumnArray = strmatch('finalArray', cellstr(data(1,:)));
    m_clip = data{idxStruct, idxColumnArray};
    
    idxColumnBbox = strmatch('BoundingBox', cellstr(data(1,:)));
    bbox = data{idxStruct, idxColumnBbox};

    idxColumnVolF = strmatch('VolumeFinal', cellstr(data(1,:)));
    volume_m = data{idxStruct, idxColumnVolF};
 
    
    m = zeros(arrSize);
    
    if ~isempty(bbox)
        if bbox(1) < 1
            bbox(1) = 1;
        end
        if bbox(2) > arrSize(1)
            bbox(2) = arrSize(1);
        end

        if bbox(3) < 1
            bbox(3) = 1;
        end

        if bbox(4) > arrSize(2)
            bbox(4) = arrSize(2);
        end

        if bbox(5) < 1
            bbox(5) = 1;
        end

        if bbox(6) > arrSize(3)
            bbox(6) = arrSize(3);
        end

        m(bbox(1):bbox(2),bbox(3):bbox(4),bbox(5):bbox(6)) = m_clip;
    end
    
    if length(size(m)) < 3  || length(size(n)) < 3 || max(m(:)) == 0 || max(n(:)) == 0 
        i = i + 1;
        j = j + 1;
    else
        idx = logical(n); 
        ind = find(idx); 
        [row, col, pag] = ind2sub(size(n),ind);
        [~,cornerpoints_n, volume_n, surface_n] = minboundbox(row,col,pag,'v',3);

        
        Cornerpoints = vertcat([bbox(1), bbox(3),bbox(5)], [bbox(2), bbox(4),bbox(6)], cornerpoints_n);
        bbox = [floor(min(Cornerpoints(:,1))), ceil(max(Cornerpoints(:,1))), floor(min(Cornerpoints(:,2))), ceil(max(Cornerpoints(:,2))), floor(min(Cornerpoints(:,3))), ceil(max(Cornerpoints(:,3)))];

        DCE = computeVDSC(n,m);
        sliceDCE = computeSliceDSC(n,m,volume_m);


        % Ensure bbox handles edge structures

        if bbox(1) < 1
            bbox(1) = 1;
        end
        if bbox(2) > arrSize(1)
            bbox(2) = arrSize(1);
        end

        if bbox(3) < 1
            bbox(3) = 1;
        end

        if bbox(4) > arrSize(2)
            bbox(4) = arrSize(2);
        end

        if bbox(5) < 1
            bbox(5) = 1;
        end

        if bbox(6) > arrSize(3)
            bbox(6) = arrSize(3);
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
        data{i,4} = surface_n;
        data{i,6} = num_of_slices;
        data{i,7} = pct_perfect;
        data{i,8} = n_clip;
        data{i,9} = m_clip;
        data{i,10} =diffMap; % Final - Initial: +1 means contour was increased, -1 means contour was decreased
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

    