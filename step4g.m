% Initialize SPM
spm('Defaults','fMRI');
spm_jobman('initcfg');

% Prompt user to select the SPM folder
spm_path = uigetdir('', 'Please select the SPM folder');

TPM_file = fullfile(spm_path, 'tpm', 'TPM.nii');

% Prompt user to select the data folder
path = uigetdir('', 'Please select the data folder');

% Prompt user to select the list.txt file
[list_file, list_path] = uigetfile('*.txt', 'Please select the list.txt file');
list = textread(fullfile(list_path, list_file), '%s');

% Prompt user to select the cortical mask file
[gray_matter_mask_file, gray_matter_mask_path] = uigetfile('*.*', 'Please select the cortical mask file');

gray_matter_mask_filename = fullfile(gray_matter_mask_path, gray_matter_mask_file);


for i = 1:length(list)
    process_path = fullfile(path, list{i});
    cd(process_path);
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = {'Bold.nii,1'};
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {'T1.nii,1'};
    matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    matlabbatch{2}.spm.spatial.normalise.est.subj.vol = {'T1.nii,1'};
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.biasreg = 0.0001;
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.biasfwhm = 60;
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.tpm = {TPM_file};
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.affreg = 'eastern';
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.fwhm = 0;
    matlabbatch{2}.spm.spatial.normalise.est.eoptions.samp = 3;
    matlabbatch{3}.spm.util.defs.comp{1}.inv.comp{1}.def = {'y_T1.nii'};
    matlabbatch{3}.spm.util.defs.comp{1}.inv.space = {'Bold.nii'};
    matlabbatch{3}.spm.util.defs.out{1}.savedef.ofname = 'iT1';
    matlabbatch{3}.spm.util.defs.out{1}.savedef.savedir.saveusr = {process_path};
    matlabbatch{4}.spm.spatial.normalise.write.subj.def = {'y_iT1.nii'};
    matlabbatch{4}.spm.spatial.normalise.write.subj.resample = {gray_matter_mask_filename};
    matlabbatch{4}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                              78 76 85];
    matlabbatch{4}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{4}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{4}.spm.spatial.normalise.write.woptions.prefix = 'w';
    % Run the batch job
    spm_jobman('run', matlabbatch);
	
	% Copy file to destination folder
	new_filename = sprintf('w%s', gray_matter_mask_file);
    copyfile(fullfile(gray_matter_mask_path, new_filename), fullfile(process_path, 'individual_cortex.nii'));
end
