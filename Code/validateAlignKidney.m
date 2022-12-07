tic
ctDirectory = uigetdir("",'Please select the folder with the CT images.');

labelDirectory = uigetdir("",'Please select the folder with the labels.');

netWorkDirectory= uigetdir("",'Please select the folder with the networks.');


modelNames = dir(strcat(netWorkDirectory,'\*.mat'));
    

for modelIndex=1:length (modelNames)
    modelFile = strcat(netWorkDirectory,'\',modelNames(modelIndex).name);
    iteration= split(modelFile,"_");
    iteration= char(iteration(4));
    net=load(modelFile);
    net=net.net;
        ctFiles = dir(strcat(ctDirectory,'\*.nii.gz'));
        counter=int16(1);
        masks={};
        dice_results=[];
        rvd_results=[];
        jaccard_results=[];
        accuracy_results=[];
        time_results=[];
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
            % spy(labelImage(:,:,z)) to check
           
            if(length(labelImageIndex)<=0)
                continue;
            end
     
            for z=1:length(labelImageIndex)
                index=labelImageIndex(z);
                img=ctImage(:,:,index);
                img=uint8(img*255);
                rgb= cat(3,img,img,img);
        
                for t=5:5
                    dice_res=NaN;
                    rvd=NaN;
                    jaccard_res=NaN;
                    accuracy=NaN;
    
                    treshold= 0.1*t;
                    try
                        [masks,labels,~] = segmentObjects(net,rgb,Threshold=treshold);
                        timeFunction = @()segmentObjects(net,rgb,Threshold=treshold);
                        time_result=timeit(timeFunction);
                    catch 
                        disp('exception');
                        continue;
                    end
                    mask_result= any(masks,3);
                    groundTruth=labelImage(:,:,index);
                    if all(size(mask_result)>0) 
                        
                        dice_res = dice(mask_result,groundTruth);
                        difference = abs((mask_result-groundTruth));
                        rvd = 100*(sum(difference,"all")/sum(groundTruth,"all"));
                        if(rvd > 1000)
                            disp("RVD over 100 at ctFile: " + ctFiles(i).name + ...
                                "at slice: "+ ...
                                string(index) +" with threshold: "+string(treshold) );
                        end
                        jaccard_res = jaccard(mask_result,groundTruth);
                        accuracy = sum(mask_result == groundTruth,'all')/numel(groundTruth);
    
                    end
                    if ~isnan(dice_res) && all(size(labels) >0)
                        dice_results(counter,i)=dice_res;
                    end
                    if ~isnan(rvd) && all(size(labels) >0)
                        rvd_results(counter,i)=rvd;
                    end
    
                    if ~isnan(jaccard_res) && all(size(labels) >0)
                        jaccard_results(counter,i)=jaccard_res;
                    end
                    if ~isnan(accuracy) && all(size(labels) >0)
                        accuracy_results(counter,i)=accuracy;
                    end
                    time_results(counter,i)=time_result;
                end
                counter = counter +1;
            end     
        end
        dice_results=dice_results;
        rvd_results=rvd_results;
        jaccard_results=jaccard_results;
        accuracy_results=accuracy_results;
end

toc

ncol=size(time_results,2);
for c=1:ncol
    l = length(nonzeros(time_results(:,c)));
    x(1:l,c)= nonzeros(time_results(:,c));
end


idx2keep_columns = sum(abs(x),1)>0 ;
idx2keep_rows    = sum(abs(x),2)>0 ;

time_results = x(idx2keep_rows,idx2keep_columns) ;