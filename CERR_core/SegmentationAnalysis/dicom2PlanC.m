%% Set source/destination paths
clear
counter = 0;
ping_time = 1;
first_run = 0;
% isSubset checks for differences in directory over 2 time points, if not a subset there are new files
isSubset = @(superSet,subSet)isempty(setdiff(subSet, superSet));
addpath(genpath('C:\Projects\CERR'))

%% sourceDir: where DICOM export data is being received
% sourceDir = 'H:\Treatment Planning\Ergys\For_Sharif\';
% sourceDir = 'H:\Treatment Planning\Elguindi\Inference_HN\dicomOutput\';
sourceDir = 'A:\';

%% dstDir: where data will be saved, tagged to DICOM UID in the name of the file
dstDir = 'H:\Treatment Planning\Elguindi\testBed\convertedData\';
% dstDir = 'H:\Treatment Planning\Elguindi\prostateAxT2\convertedData\';

%% dicom_Dir: holding directory for processed DICOM files, to be used when
% mask is received
dicom_dir = 'H:\Treatment Planning\Elguindi\testBed\dicomOutput\';
% dicom_dir = 'H:\Treatment Planning\Elguindi\prostateAxT2\dicomRaw\';


%% List of contours to store/save.  ListSearch is keyword search in DICOM. Ignores Z structures and _PRV/_mm structures.  ListReNamed is standard name (suggest TG-263)

% HEAD AND NECK
matchCase = 'EXACT';
% contourListSearch = ["Brainstem", "BrPlx_L", "BrPlx_R", "Chiasm", "Cochl_L", "Cochl_R", "Cord", "Esophagus", "Eye_L", "Eye_R", "Lacrimal_L", "Lacrimal_R", ... 
%                      "Larynx", "Lens_L", "Lens_R", "OptNrv_L", "OptNrv_R", "Mandible", "Oral_cav", "Parotid_L", "Parotid_R", "Submand_L", "Submand_R","Thyroid"];

% contourListSearch = ["Brainstem_F", "BrachialPlex_L_F", "BrachialPlex_R_F", "Chiasm", "Cochl_L", "Cochl_R", "SpinalCord_F", "Esophagus", "Eye_L", "Eye_R", "Lacrimal_L", "Lacrimal_R", ... 
%                      "Larynx", "Lens_L", "Lens_R", "OptNrv_L", "OptNrv_R", "Mandible_F", "Oral_cav", "Parotid_L_F", "Parotid_R_F", "Glnd_Submand_L_F", "Glnd_Submand_R_F","Thyroid"];

contourListSearch = ["Brainstem", "BrachialPlex_L", "BrachialPlex_R", "OpticChiasm", "Cochlea_L", "Cochlea_R", "SpinalCord", "Esophagus", "Eye_L", "Eye_R", "Glnd_Lacrimal_L", "Glnd_Lacrimal_R" ...
                      "Larynx", "Lens_L", "Lens_R", "OpticNrv_L", "OpticNrv_R", "Mandible", "Cavity_Oral", "Parotid_L", "Parotid_R", "Glnd_Submand_L", "Glnd_Submand_R", "Glnd_Thyroid"];

contourListReNamed = ["Brainstem", "BrachialPlex_L", "BrachialPlex_R", "OpticChiasm", "Cochlea_L", "Cochlea_R", "SpinalCord", "Esophagus", "Eye_L", "Eye_R", "Glnd_Lacrimal_L", "Glnd_Lacrimal_R" ...
                      "Larynx", "Lens_L", "Lens_R", "OpticNrv_L", "OpticNrv_R", "Bone_Mandible", "Cavity_Oral", "Parotid_L", "Parotid_R", "Glnd_Submand_L", "Glnd_Submand_R", "Glnd_Thyroid"];

% contourListSearch = contourListReNamed;
% PROSTATE
% matchCase = 0;
% % contourListSearch = ["Bladder_O_F", "CTV_PROST_F", "Penile_bulb_F", "Rectum_O_F", "Urethra_Foley_F", "Rectal_Spacer_F", "Bowel_Lg_F"];
% contourListSearch = ["Bladder", "CTV", "Penile", "Rectum", "Urethra", "Spacer", "Bowel"];
%        
% contourListReNamed = ["Bladder", "Prostate_SeminalVes", "PenileBulb", "Rectum", "Urethra_Foley", "RectalSpacer", "Bowel_Large"];

% contourListSearch = ["PTV1", "PTV2","PTV3", "PTV4"];
% contourListReNamed = contourListSearch;

%% Update CERROptions.json file with structure info
pathStr = getCERRPath;
optName = fullfile(pathStr,'CERROptions.json');
optS    = opts4Exe(optName);
optS.structuresToImport = contourListSearch;
optS.structuresImportMatchCriteria = matchCase;
saveJSONfile(optS, optName);


%% Listener Block
olddir = dir(strcat(sourceDir,'**\*.dcm'));
while true
  % Runs logic based on directory search between ping_time (in secs)
  pause(ping_time) % Checks directory every ping_time seconds
  newdir = dir(strcat(sourceDir,'**\*.dcm')); % gets list of all dicom files

  % if the dirs are not equal and not a subset of one another, process new files
  if ~isequal(newdir, olddir) && ~isSubset({olddir.name},{newdir.name}) 
    
    % First pause momentarily and check dir again, wait until all files are
    % copied
    pause(2)
    file_watcher = dir(strcat(sourceDir,'**\*.dcm'));  
    while length(file_watcher) > length(newdir)
        newdir = dir(strcat(sourceDir,'**\*.dcm'));
        pause(2)
        file_watcher = dir(strcat(sourceDir,'**\*.dcm'));
    end
    
    % Once all files are copied, set olddir to newest version 
    % and runs dicom conversion at this time point
    olddir = file_watcher;
    if ~isempty(olddir)
        fprintf('New studies found\n');
        diary dicom_conversion_log
        convert_dicom(olddir, dstDir, dicom_dir, sourceDir, contourListSearch, contourListReNamed, matchCase);
        diary off
        counter = 0;
    end
    
  % if directories are not equal, but new dir is subset, files are being
  % moved
  elseif ~isequal(newdir, olddir) && isSubset({olddir.name},{newdir.name})
    pause(2)
    file_watcher = dir(strcat(sourceDir,'**\*.dcm'));  
    while length(file_watcher) < length(newdir)
        newdir = dir(strcat(sourceDir,'**\*.dcm'));
        pause(2)
        file_watcher = dir(strcat(sourceDir,'**\*.dcm'));
    end
    olddir = file_watcher;
    if ~isempty(olddir)
       fprintf('studies removed\n')
    end
  
  % if not above 2 conditions, nothing in folder is occuring
  else
    clc
    if first_run == 0
        fprintf('First run, clearing data in folder\n');
        convert_dicom(newdir, dstDir, dicom_dir, sourceDir, contourListSearch, contourListReNamed, matchCase);
        first_run = 1;
    else
        fprintf('No new studies found for %d folder checks\n', counter);
    end
  end
  counter = counter + 1;
end

%% Using CERR calls, converts a folder of MIM exported dicom images to seperate patient planC and H5 files
function convert_dicom(d, dstDir, dicom_dir, sourceDir, contourListSearch, contourListReNamed, matchCase)
    
    % Get unique folders in directory
    [~, idx] = unique({d.folder});
    d = d(idx);
    
    % Put RTst set into same folder as scan (assumes MR or CT keyword)
    for x = {d.folder}
        if contains(x{1},'RTSTRUCT') == 1
            dirData = dir(strcat(x{1},'\*.dcm'));
        else
            dirData = {};
        end

        if ~isempty(dirData) == 1
            patient_root = strsplit(erase(dirData.folder,sourceDir),'\');
            patient_root = patient_root{1};
            for z = {d.folder}
                patient_root_cur = strsplit(erase(z{1},sourceDir),'\');
                patient_root_cur = patient_root_cur{1};
                if contains(z{1},'MR') == 1 && ~contains(z{1},'RTSTRUCT') && contains(patient_root_cur, patient_root)
                    movefile(fullfile(dirData.folder,dirData.name),z{1})
                elseif contains(z{1},'CT') == 1 && ~contains(z{1},'RTSTRUCT') == 1 && contains(patient_root_cur, patient_root)
                    movefile(fullfile(dirData.folder,dirData.name),z{1})
                else

                end
            end
        end             
    end
    
    % Start loop through each folder and get DICOM and convert to planC
    % export SCAN/MASK H5 + planC file
    for x = {d.folder}
        dirData = dir(strcat(x{1},'\*.dcm'));
        checkFiles = size(dirData);
        fprintf('Converting study: %s\n', x{1});

        if checkFiles(1) > 2
                       
            init_ML_DICOM;
            try
                patient = scandir_mldcm(x{1});
            catch
                continue;
            end
            
            if length(patient.PATIENT) > 1
                patient.PATIENT = patient.PATIENT(1);
            end
            
            planC = dcmdir2planC(patient.PATIENT,'No');
            indexS = planC{end};
            scanNum = 1;
            scan3M = double(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
            [xScanVals, yScanVals, zScanVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
            scanFile = strcat(dstDir, 'data_', strrep(planC{1,3}.uniformScanInfo.patientName,'^','_'),planC{1,3}.uniformScanInfo.DICOMHeaders.PatientID,'.mat');
            
            % Get Dose File if it exists and save it
            try
                dose3M = planC{indexS.dose}(scanNum).doseArray;
            catch ME
                if (strcmp(ME.identifier, 'Index exceeds matrix dimensions.'))
                    disp('no dose file in PlanC')
                end
            end
             
            if exist('dose3M', 'var')
                [xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(scanNum));
                [X,Y,Z] = meshgrid(xDoseVals, yDoseVals, zDoseVals);
                [Xs,Ys,Zs] = meshgrid(xScanVals, yScanVals, zScanVals);
                doseResized = interp3(X,Y,Z,dose3M,Xs,Ys,Zs,'linear');
            else
                doseResized = 0;
            end

            fprintf('Storing structure data\n');
%             [~] = storePlanC(contourListSearch, contourListReNamed, planC, scan3M, scanFile, doseResized, 'NONE', matchCase);
            [~] = add2PlanC(contourListSearch, contourListReNamed, planC, scan3M, scanFile, doseResized, 'NONE', matchCase);
            
            base = strsplit(strrep(x{1},sourceDir,''),'\');
            movefile(strcat(sourceDir,base{1}),dicom_dir)
            
        end
    end
end
