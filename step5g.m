% 询问使用者数据的文件夹位置
base_path = uigetdir('', '请选择数据文件夹');

% 询问使用者list.txt的位置
[list_file, list_path] = uigetfile('*.txt', '请选择list.txt文件');
list = textread(fullfile(list_path, list_file), '%s');

% 初始化存储信号的变量
all_average_csf_signals = [];
all_global_bold_signals = [];
all_ccfs = [];
all_derivative_ccfs = [];
all_neg_derivative_bolds = [];

% 弹出对话框让用户输入TR值
prompt = {'请输入TR（重复时间）（单位：秒）：'};
dlg_title = '输入TR';
num_lines = 1;
defaultans = {'2.0'};

answer = inputdlg(prompt, dlg_title, num_lines, defaultans);

% 将用户输入的TR值转换为数字
if ~isempty(answer)
    TR = str2double(answer{1});
else
    error('用户未输入TR值。');
end

% 显示用户输入的TR值
disp(['用户输入的TR值为：', num2str(TR), ' 秒']);


% 遍历每个被试
for i = 1:length(list)
    subject = list{i};
    subject_path = fullfile(base_path, subject);
    
    % 构建文件路径
    gfmri_filename = fullfile(subject_path, 'gfmri.nii');
    cfmri_filename = fullfile(subject_path, 'cfmri.nii');
    csf_mask_filename = fullfile(subject_path, 'CSF_mask.nii');
    gray_matter_mask_filename = fullfile(subject_path, 'individual_cortex.nii');
    
    % 加载fMRI数据和CSF掩膜
    if exist(gfmri_filename, 'file') ~= 2 || exist(cfmri_filename, 'file') ~= 2 || exist(csf_mask_filename, 'file') ~= 2 || exist(gray_matter_mask_filename, 'file') ~= 2
        warning('文件缺失: %s', subject);
        continue;
    end
    
    fmri_info = niftiinfo(gfmri_filename);
    fmri_img = niftiread(gfmri_filename);

    sfmri_info = niftiinfo(cfmri_filename);
    sfmri_img = niftiread(cfmri_filename);

    csf_mask_info = niftiinfo(csf_mask_filename);
    csf_mask = niftiread(csf_mask_filename);

    % 检查并重新采样CSF掩膜
    [x, y, z, t] = size(fmri_img);
    if ~isequal(size(csf_mask), [x, y, z])
        csf_mask = imresize3(csf_mask, [x, y, z], 'nearest');
    end

    % 提取并标准化CSF区域的时间序列信号
    csf_mask_reshaped = reshape(csf_mask, [], 1);
    csf_signals = zeros(sum(csf_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = fmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        csf_signals(:, time_point) = current_fmri_data_reshaped(csf_mask_reshaped > 0);
    end

    % 对每个体素进行Z分数标准化
    csf_signals_zscored = zscore(csf_signals, 0, 2);

    % 计算每个时间点的平均CSF信号
    average_csf_signal = nanmean(csf_signals_zscored, 1);

    % 提取全局BOLD信号
    gray_matter_mask_info = niftiinfo(gray_matter_mask_filename);
    gray_matter_mask = niftiread(gray_matter_mask_filename);

    if ~isequal(size(gray_matter_mask), [x, y, z])
        gray_matter_mask = imresize3(gray_matter_mask, [x, y, z], 'nearest');
    end

    gray_matter_mask_reshaped = reshape(gray_matter_mask, [], 1);
    gray_signals = zeros(sum(gray_matter_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = sfmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        gray_signals(:, time_point) = current_fmri_data_reshaped(gray_matter_mask_reshaped > 0);
    end

    % 对每个体素进行Z分数标准化
    gray_signals_zscored = zscore(gray_signals, 0, 2);

    % 计算每个时间点的平均BOLD信号
    global_bold_signal = nanmean(gray_signals_zscored, 1);

    % 计算时间点
    time_points = (0:t-1) * TR;

    % 绘制原始信号
    figure;
    subplot(2, 1, 1);
    plot(time_points, average_csf_signal);
    title(['Average CSF Signal - ', subject]);
    xlabel('Time (seconds)');
    ylabel('Signal Intensity');
    subplot(2, 1, 2);
    plot(time_points, global_bold_signal);
    title(['Global BOLD Signal - ', subject]);
    xlabel('Time (seconds)');
    ylabel('Signal Intensity');
    % 保存图像
    saveas(gcf, fullfile(subject_path, [subject, '_signals.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_signals.tif']), '-dtiff', '-r300');

    % 计算互相关函数
    fs = 1 / TR; % 采样频率 (Hz)
    time_lag_seconds = TR * 5; % 时间滞后范围 (秒)
    max_lag = time_lag_seconds * fs; % 最大滞后样本点数

    [ccf, lags] = xcorr(global_bold_signal, average_csf_signal, max_lag, 'coeff');

    % 转换滞后样本点数为时间滞后
    lags = lags * TR;

    % 限制滞后范围
    valid_range = (lags >= -time_lag_seconds) & (lags <= time_lag_seconds);
    ccf = ccf(valid_range);

    % 可视化互相关结果
    figure;
    plot(lags(valid_range), ccf);
    xlabel('Time Lag (seconds)');
    ylabel('Cross-correlation coefficient');
    title(['Cross-correlation between global BOLD signal and average CSF signal - ', subject]);
    % 保存图像
    saveas(gcf, fullfile(subject_path, [subject, '_cross_correlation.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_cross_correlation.tif']), '-dtiff', '-r300');

    % 保存信号到.txt文件
    output_filename = fullfile(subject_path, [subject, '_fmri_signals.txt']);
    fileID = fopen(output_filename, 'w');

    fprintf(fileID, 'Average CSF Signal:\n');
    fprintf(fileID, '%f\n', average_csf_signal);

    fprintf(fileID, '\nGlobal BOLD Signal:\n');
    fprintf(fileID, '%f\n', global_bold_signal);

    fprintf(fileID, '\nCross-correlation function (CCF):\n');
    fprintf(fileID, '%f\n', ccf);

    fclose(fileID);
    
    % 将数据添加到汇总变量中
    all_average_csf_signals = [all_average_csf_signals; average_csf_signal];
    all_global_bold_signals = [all_global_bold_signals; global_bold_signal];
    all_ccfs = [all_ccfs; ccf];
end

% 保存所有被试的信号到Excel文件，每个被试一行
writematrix(all_average_csf_signals, fullfile(base_path, 'all_average_csf_signals.xlsx'), 'Sheet', 1, 'Range', 'A1');
writematrix(all_global_bold_signals, fullfile(base_path, 'all_global_bold_signals.xlsx'), 'Sheet', 1, 'Range', 'A1');
writematrix(all_ccfs, fullfile(base_path, 'all_ccfs.xlsx'), 'Sheet', 1, 'Range', 'A1');
