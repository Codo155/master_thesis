tic
ctDirectory = uigetdir("",'Please select the folder with the CT images.');

labelDirectory = uigetdir("",'Please select the folder with the labels.');


rgbImagesFolder = uigetdir("",'Please select the destination folder for the RGB images');
checkpointPath = uigetdir("",'Please select the destination folder for checkpoints');

ctFiles = dir(strcat(ctDirectory,'\*.nii.gz'));

counter=int16(1);           
masks={};
for i=1:length (ctFiles)
    try
        labelFile = strcat(labelDirectory,'\',ctFiles(i).name);
        labelImage = load_nii(labelFile).img;
        
        ctFile=strcat(ctDirectory,'\',ctFiles(i).name);
        ctImage = load_nii(ctFile).img;
    catch exception
        continue;
    end


    labelImageIndex=[];
    
    [xSlices,ySlices,zSlices] = size(labelImage);
    
    for z = 1:zSlices
        boxes=[];
        imageCategory={};
        mask=[];
        left = logical(labelImage(1:(xSlices/2),:,z)==1);
        right = logical(labelImage((1+(xSlices/2):xSlices),:,z)==1);
    
        %% left side
        [xCoordinate,yCoordinate,boxWidth,boxHeight] = getCoordinates(left);
        if boxWidth  ~= 0 && boxHeight ~= 0 
            mask(1:(xSlices/2),:,1)=left;
            mask((1+(xSlices/2):xSlices),:,1)=0;
            boxes(1,:)=[xCoordinate yCoordinate boxWidth boxHeight];
        end
        %% right side
        [xCoordinate,yCoordinate,boxWidth,boxHeight] = getCoordinates(right);
        if boxWidth  ~= 0 && boxHeight ~= 0 
            [x,y,zMaskSize]=size(mask);
            if(zMaskSize==0 || x==0)
                mask((1+(xSlices/2):xSlices),:,1)=right;
                mask(1:(xSlices/2),:,1)=0;
            else
                mask(1:(xSlices/2),:,2)=0;
                mask((1+(xSlices/2):xSlices),:,2)=right;
            end
            [xBoxSize,~]=size(boxes);
            if(xBoxSize==0)
                boxes(1,:)=  [ xCoordinate yCoordinate boxWidth boxHeight];
            else
                boxes(2,:)= [ xCoordinate yCoordinate boxWidth boxHeight];
            end
                end
        %%
        masks(counter,1)={logical(mask==1)};
        %% label with bounding boxes
        [x,~]=size(boxes);
        if(x==1)
            box{counter,1}=boxes;
            imageCategory{1}='kidney';
            box{counter,2}=imageCategory;
            counter=counter+1;
            labelImageIndex= [labelImageIndex,z];
        elseif(x==2)
            box{counter,1}=boxes;
            imageCategory=cell(2,1);
            imageCategory{1}='kidney';
            imageCategory{2}='kidney';
            box{counter,2}=imageCategory;
            counter=counter+1;
            labelImageIndex= [labelImageIndex,z];
        end
    end
    
    for z=1:length(labelImageIndex)
        img=ctImage(:,:,labelImageIndex(z));
        img=uint8(img*255);
        rgb= cat(3,img,img,img);
        outputBaseName=
        strcat(ctFiles(i).name,"_",int2str(labelImageIndex(z)),".png");
        fullDestinationFileName = fullfile(rgbImagesFolder, outputBaseName);
        imwrite(rgb, fullDestinationFileName,'png');
    end
end
ctds = imageDatastore(rgbImagesFolder);

table = cell2table(box,'VariableNames',{'Boxes','Labels'});
lockds= boxLabelDatastore(table);
lables=arrayDatastore(masks,"ReadSize",1,"OutputType","same");
ds= combine(ctds,lockds,lables);


trainClassNames = {'kidney'};
numClasses = length(trainClassNames);
imageSizeTrain = [512 512 3];
net = maskrcnn("resnet50-coco",trainClassNames,InputSize=imageSizeTrain);

options = trainingOptions("sgdm", ...
    InitialLearnRate=0.002, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropPeriod=1, ...
    LearnRateDropFactor=0.95 , ...
    Plot="none", ...
    Momentum=0.9, ...
    MaxEpochs=10, ...
    MiniBatchSize=1, ...
    BatchNormalizationStatistics="moving", ...
    ResetInputNormalization=false, ...
    ExecutionEnvironment="gpu", ...
    CheckpointPath=checkpointPath,...
    CheckpointFrequency=1,...
    CheckpointFrequencyUnit='epoch',...
    VerboseFrequency=1000);

modelDateTime = string(datetime("now",Format="yyyy-MM-dd-HH-mm-ss"));
netPath = strcat(checkpointPath,'\',"trainedMaskRCNN-"+modelDateTime+".mat");
infoPath= strcat(checkpointPath,'\',"info-"+modelDateTime+".mat");
doTraining = true;
if doTraining
    [net,info] = trainMaskRCNN(ds,net,options,FreezeSubNetwork="backbone");
    modelDateTime = string(datetime("now",Format="yyyy-MM-dd-HH-mm-ss"));
    save(netPath,"net");
    save(infoPath,"info");
end
toc
