directory = uigetdir;
tic
% load files into variable files and get its count
files = dir (strcat(directory,'\*.nii.gz'));
files_count= length (files);

% generating arrays for each dimension
dim_x = ones(1,files_count);
dim_y = ones(1,files_count);
dim_z = ones(1,files_count);

% go through each file

local_min=zeros(files_count);
local_max=zeros(files_count);
parfor i=1:files_count
    file = strcat(directory,'\',files(i).name);
    image = load_nii(file).img;
    
    % Set size of images
    s=size(image);
    dim_x(i)= s(1);
    dim_y(i)= s(2);
    dim_z(i)= s(3);
    % Search for global min and max
    %%
    local_max(i)= max(image,[],'all');
    local_min(i)= min(image,[],'all');

end
global_max = max(local_max);
global_min = min(local_min);
global_max=global_max(1);
global_min=global_min(1);

parfor i=1:files_count
    file = strcat(directory,'\',files(i).name);
    image = load_nii(file);
    image.img = mat2gray(image.img,[global_min,global_max]);
    %Todo: Insert destination
    save_nii(image, strcat( Todo:Insert Destination ,files(i).name));
end

toc
disp(mean(dim_x))
disp(mean(dim_y))
disp(mean(dim_z))