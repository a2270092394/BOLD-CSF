% 询问使用者预处理数据的文件夹位置
source_path = uigetdir('', '请选择预处理数据文件夹');

% 询问使用者需要复制到的文件夹位置
dest_path = uigetdir('', '请选择目标文件夹');

% 询问使用者list.txt的位置
[list_file, list_path] = uigetfile('*.txt', '请选择list.txt文件');
list = textread(fullfile(list_path, list_file), '%s');

% 询问使用者global功能磁共振图像文件夹位置
funImg_global_path = uigetdir(source_path, '请选择global功能磁共振图像文件夹');

% 询问使用者CSF功能磁共振图像文件夹位置
funImg_CSF_path = uigetdir(source_path, '请选择CSF功能磁共振图像文件夹');

% 询问使用者结构磁共振图像文件夹位置
t1Img_path = uigetdir(source_path, '请选择结构磁共振图像 (T1Img) 文件夹');

% 遍历文件夹列表
for i = 1:length(list)
    folder_name = list{i};
	
    global_source_folder_FunImg = fullfile(funImg_global_path, folder_name);
    CSF_source_folder_FunImg = fullfile(funImg_CSF_path, folder_name);	
    source_folder_T1ImgCoreg = fullfile(t1Img_path, folder_name);
	
    % 处理 globalFunImg 文件夹中的文件
    cd(global_source_folder_FunImg);
    
    % 获取文件夹中的唯一 .nii 文件
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'gfmri.nii';
    
    % 生成目标文件夹路径
    dest_folder = fullfile(dest_path, folder_name);
    
    % 如果目标文件夹不存在，则创建
    if ~exist(dest_folder, 'dir')
        mkdir(dest_folder);
    end
    
    % 复制文件到目标文件夹
    copyfile(fullfile(global_source_folder_FunImg, old_name), fullfile(dest_folder, old_name));
    
    % 切换到目标文件夹并重命名文件
    cd(dest_folder);
    movefile(old_name, new_name);
	
	% 处理CSF_FunImg文件夹中的文件
    cd(CSF_source_folder_FunImg);
    
    % 获取文件夹中的唯一 .nii 文件
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'cfmri.nii';
    
    % 复制文件到目标文件夹
    copyfile(fullfile(CSF_source_folder_FunImg, old_name), fullfile(dest_folder, old_name));
    
    % 切换到目标文件夹并重命名文件
    cd(dest_folder);
    movefile(old_name, new_name);
    
    % 处理 T1ImgCoreg 文件夹中的文件
    cd(source_folder_T1ImgCoreg);
    
    % 获取文件夹中的唯一 .nii 文件
    files = dir('*.nii');
    old_name = files(1).name;
    new_name = 'T1.nii';
    
    % 复制文件到目标文件夹
    copyfile(fullfile(source_folder_T1ImgCoreg, old_name), fullfile(dest_folder, old_name));
    
    % 切换到目标文件夹并重命名文件
    cd(dest_folder);
    movefile(old_name, new_name);
end

