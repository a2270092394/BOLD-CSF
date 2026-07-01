% Prompt user to select the source folder containing preprocessed data
source_path = uigetdir('', 'Please select the preprocessed data folder');

% Prompt user to select the destination folder
dest_path = uigetdir('', 'Please select the destination folder');

% Prompt user to select the list.txt file
[list_file, list_path] = uigetfile('*.txt', 'Please select the list.txt file');
list = textread(fullfile(list_path, list_file), '%s');

% Prompt user to select the global fMRI image folder
funImg_global_path = uigetdir(source_path, 'Please select the global fMRI image folder');

% Prompt user to select the CSF fMRI image folder
funImg_CSF_path = uigetdir(source_path, 'Please select the CSF fMRI image folder');

% Prompt user to select the structural MRI image folder
t1Img_path = uigetdir(source_path, 'Please select the structural MRI (T1Img) folder');

% Loop through the folder list
for i = 1:length(list)
    folder_name = list{i};
	
    global_source_folder_FunImg = fullfile(funImg_global_path, folder_name);
    CSF_source_folder_FunImg = fullfile(funImg_CSF_path, folder_name);	
    source_folder_T1ImgCoreg = fullfile(t1Img_path, folder_name);
	
    % Process files in the globalFunImg folder
    cd(global_source_folder_FunImg);
    
    % Get the unique .nii file in the folder
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'gfmri.nii';
    
    % Generate destination folder path
    dest_folder = fullfile(dest_path, folder_name);
    
    % Create destination folder if it does not exist
    if ~exist(dest_folder, 'dir')
        mkdir(dest_folder);
    end
    
    % Copy file to destination folder
    copyfile(fullfile(global_source_folder_FunImg, old_name), fullfile(dest_folder, old_name));
    
    % Switch to destination folder and rename the file
    cd(dest_folder);
    movefile(old_name, new_name);
	
	% Process files in the CSF_FunImg folder
    cd(CSF_source_folder_FunImg);
    
    % Get the unique .nii file in the folder
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'cfmri.nii';
    
    % Copy file to destination folder
    copyfile(fullfile(CSF_source_folder_FunImg, old_name), fullfile(dest_folder, old_name));
    
    % Switch to destination folder and rename the file
    cd(dest_folder);
    movefile(old_name, new_name);
    
    % Process files in the T1ImgCoreg folder
    cd(source_folder_T1ImgCoreg);
    
    % Get the unique .nii file in the folder
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'T1.nii';
    
    % Copy file to destination folder
    copyfile(fullfile(source_folder_T1ImgCoreg, old_name), fullfile(dest_folder, old_name));
    
    % Switch to destination folder and rename the file
    cd(dest_folder);
    movefile(old_name, new_name);
end
