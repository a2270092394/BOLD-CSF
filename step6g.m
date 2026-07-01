% Prompt user to select the data folder
base_path = uigetdir('', 'Please select the data folder');

% Prompt user to select the list.txt file
[list_file, list_path] = uigetfile('*.txt', 'Please select the list.txt file');
list = textread(fullfile(list_path, list_file), '%s');

% Initialize variables for storing signals
all_average_csf_signals = [];
all_global_bold_signals = [];
all_ccfs = [];
all_derivative_ccfs = [];
all_neg_derivative_bolds = [];

% Prompt user to enter TR value
prompt = {'Please enter TR (repetition time) (in seconds):'};
dlg_title = 'Enter TR';
num_lines = 1;
defaultans = {'2.0'};

answer = inputdlg(prompt, dlg_title, num_lines, defaultans);

% Convert the user-entered TR value to numeric
if ~isempty(answer)
    TR = str2double(answer{1});
else
    error('User did not enter a TR value.');
end

% Display the user-entered TR value
disp(['TR value entered: ', num2str(TR), ' seconds']);


% Loop through each subject
for i = 1:length(list)
    subject = list{i};
    subject_path = fullfile(base_path, subject);
    
    % Build file paths
    gfmri_filename = fullfile(subject_path, 'gfmri.nii');
    cfmri_filename = fullfile(subject_path, 'cfmri.nii');
    csf_mask_filename = fullfile(subject_path, 'CSF_mask.nii');
    gray_matter_mask_filename = fullfile(subject_path, 'individual_cortex.nii');
    
    % Load fMRI data and CSF mask
    if exist(gfmri_filename, 'file') ~= 2 || exist(cfmri_filename, 'file') ~= 2 || exist(csf_mask_filename, 'file') ~= 2 || exist(gray_matter_mask_filename, 'file') ~= 2
        warning('File missing: %s', subject);
        continue;
    end
    
    fmri_info = niftiinfo(gfmri_filename);
    fmri_img = niftiread(gfmri_filename);

    csf_mask_info = niftiinfo(csf_mask_filename);
    csf_mask = niftiread(csf_mask_filename);

    % Check and resample CSF mask if necessary
    [x, y, z, t] = size(fmri_img);
    if ~isequal(size(csf_mask), [x, y, z])
        csf_mask = imresize3(csf_mask, [x, y, z], 'nearest');
    end

    % Extract and standardize time series signals from CSF regions
    csf_mask_reshaped = reshape(csf_mask, [], 1);
    csf_signals = zeros(sum(csf_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = fmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        csf_signals(:, time_point) = current_fmri_data_reshaped(csf_mask_reshaped > 0);
    end

    % Z-score standardization for each voxel
    csf_signals_zscored = zscore(csf_signals, 0, 2);

    % Compute mean CSF signal at each time point
    average_csf_signal = nanmean(csf_signals_zscored, 1);

    % Extract global BOLD signal
    gray_matter_mask_info = niftiinfo(gray_matter_mask_filename);
    gray_matter_mask = niftiread(gray_matter_mask_filename);

    if ~isequal(size(gray_matter_mask), [x, y, z])
        gray_matter_mask = imresize3(gray_matter_mask, [x, y, z], 'nearest');
    end

    gray_matter_mask_reshaped = reshape(gray_matter_mask, [], 1);
    gray_signals = zeros(sum(gray_matter_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = fmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        gray_signals(:, time_point) = current_fmri_data_reshaped(gray_matter_mask_reshaped > 0);
    end

    % Z-score standardization for each voxel
    gray_signals_zscored = zscore(gray_signals, 0, 2);

    % Compute mean BOLD signal at each time point
    global_bold_signal = nanmean(gray_signals_zscored, 1);

    % Compute negative first-order derivative of BOLD signal
    neg_derivative_bold = -diff(global_bold_signal);
    all_neg_derivative_bolds = [all_neg_derivative_bolds; neg_derivative_bold];

    % Define time point array
    time_points = (0:length(neg_derivative_bold)-1) * TR;

    % Visualize and save negative derivative signal
    figure;
    plot(time_points, neg_derivative_bold, '-o');
    xlabel('Time (seconds)');
    ylabel('Negative First-order Derivative of BOLD Signal');
    title(['Negative First-order Derivative of BOLD Signal - ', subject]);
    grid on;
    saveas(gcf, fullfile(subject_path, [subject, '_neg_derivative_bold.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_neg_derivative_bold.tif']), '-dtiff', '-r300');
    
    % Compute cross-correlation function
    average_csf_signal = average_csf_signal(1:end-1); % Remove the last time point
    fs = 1 / TR; % Sampling frequency (Hz)
    time_lag_seconds = TR * 5; % Time lag range (seconds)
    max_lag = time_lag_seconds * fs; % Maximum lag in samples

    [ccf_derivative, lags] = xcorr(neg_derivative_bold, average_csf_signal, max_lag, 'coeff');

    % Convert lag samples to time lag
    lags = lags * TR;

    % Restrict lag range
    valid_range = (lags >= -time_lag_seconds) & (lags <= time_lag_seconds);
    ccf_derivative = ccf_derivative(valid_range);

    % Append data to summary variables
    all_derivative_ccfs = [all_derivative_ccfs; ccf_derivative];

    % Visualize and save cross-correlation function
    figure;
    plot(lags(valid_range), ccf_derivative, '-o');
    xlabel('Lag (seconds)');
    ylabel('Cross-correlation coefficient');
    title(['Cross-correlation Function - ', subject]);
    grid on;
    saveas(gcf, fullfile(subject_path, [subject, '_cross_correlation_derivative.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_cross_correlation_derivative.tif']), '-dtiff', '-r300');
end

% Save negative derivative signals from all subjects to an Excel file, one row per subject
writematrix(all_neg_derivative_bolds, fullfile(base_path, 'all_neg_derivative_bolds.xlsx'), 'Sheet', 1, 'Range', 'A1');

% Save cross-correlation functions from all subjects to an Excel file, one row per subject
writematrix(all_derivative_ccfs, fullfile(base_path, 'all_derivative_ccfs.xlsx'), 'Sheet', 1, 'Range', 'A1');
