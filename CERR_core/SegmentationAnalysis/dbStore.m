
dstDir = 'H:\Treatment Planning\Elguindi\prostateAxT2\convertedData\';
olddir = dir(strcat(dstDir,'data*.mat'));
% contourList = ["Brainstem", "BrachialPlex_L", "BrachialPlex_R", "Glnd_Submand_L", ...
%                "Glnd_Submand_R","Parotid_L", "Parotid_R", "Bone_Mandible", "SpinalCord"];
contourList = ["Bladder", "Prostate_SeminalVes", "PenileBulb", "Rectum", "Urethra_Foley", "RectalSpacer", "Bowel_Large"];
           
new_data = cell(length(olddir)+1,(length(contourList)*2)+4);

new_data{1,1} = 'MRN';
new_data{1,end-2} = 'basePath';
new_data{1,end-1} = 'PlanCFileName';
new_data{1,end} = 'Datetime';

for i = 1:length(olddir)
    cerrFileName = fullfile(olddir(i).folder, olddir(i).name)
    planCfilename = strrep(cerrFileName,'data','PlanC');
    data = load(cerrFileName);
    data = data.data;
    MRN = olddir(i).name(end-12:end-4);
    new_data{i+1,1} = MRN;
    new_data{i+1,end-2} = olddir(i).folder;
    new_data{i+1,end-1} = olddir(i).name;
    new_data{i+1,end} = data{2,18};
    k = 2;
    for struct = contourList

        idxStruct = strmatch(struct,cellstr(data(:,1)));
        idxsliceDSC = strmatch('sliceDSC', cellstr(data(1,:)));
        idxVDSC = strmatch('VDSC', cellstr(data(1,:)));
    
        header_1 = cellstr(strcat(struct,'_DSC',',',num2str(idxStruct)));
        header_2 = cellstr(strcat(struct,'_pctMinor',',',num2str(idxStruct)));
        new_data(1,k) = header_1;
        new_data(1,k+1) = header_2;
        
        sliceDCE = data{idxStruct,idxsliceDSC};
        arrCheck = size(sliceDCE);
        if arrCheck(1) == 3
            for j = 1:length(sliceDCE)
                if sliceDCE(1,j) > 0.95
                    sliceDCE(1,j) = 1;
                end
            end
            oar = sum(all(~diff(sliceDCE)))/(sum(sliceDCE(3,:)));
        else
            oar = [];
        end
        
        VDSC = data{idxStruct,idxVDSC};
        new_data{i+1,k} = VDSC;
        new_data{i+1,k+1} = oar;
        k = k + 2;
    end
    
end

xlswrite(strcat(dstDir,'prostateDB.xlsx'),new_data);




