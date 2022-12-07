ctDirectory = uigetdir("",'Please select the folder with the CT images.');

labelDirectory = uigetdir("",'Please select the folder with the labels.');
ctFiles = dir(strcat(ctDirectory,'\*.nii.gz'));
counter=int16(1);
masks={};
netWorkDirectory= uigetdir("",'Please select the folder with the networks.');


modelNames = dir(strcat(netWorkDirectory,'\*.mat'));
    
speed_results=[];
for modelIndex=1:length (modelNames)

    modelFile = strcat(netWorkDirectory,'\',modelNames(modelIndex).name);
    iteration= split(modelFile,"_");
    iteration= char(iteration(4));
    net=load(modelFile);
    net=net.net;

    for i=1:length (ctFiles)
        try
            labelFile = strcat(labelDirectory,'\',ctFiles(i).name);
            labelImage = logical(load_nii(labelFile).img==1);
            
            ctFile=strcat(ctDirectory,'\',ctFiles(i).name);
            ctImage = gpuArray(load_nii(ctFile).img);
    
        catch 
            continue;
        end  
        
        labelImageIndex =find( sum(labelImage,[1,2])>0);
       
        if(length(labelImageIndex)<=0)
            continue;
        end
        speed_ctFile=[];
        for z=1:length(labelImageIndex)
            index=labelImageIndex(z);
            img=ctImage(:,:,index);
            img=uint8(img*255);
            rgb= cat(3,img,img,img);
                treshold= 0.5;
            try
                tmp_cunction= @() segmentObjects(net,rgb,Threshold=treshold);
                t = timeit(tmp_cunction);
            catch 
                disp('exception');
            end
            speed_ctFile(z)=t;
    
        end
        speed_results(i,counter)=mean(speed_ctFile);
        ctFile=[];
    end
    counter = counter +1;
end
