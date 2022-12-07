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
        dice_results=zeros(20,1);
        rvd_results=zeros(20,1);
        jaccard_results=zeros(20,1);
        accuracy_results=zeros(20,1);

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
                    catch 
                        disp('exception');
                        continue;
                    end
                    mask_result= any(masks,3);
                    groundTruth=labelImage(:,:,index);
                    kidneyPixel=sum(groundTruth==1,'all');
                    if all(size(mask_result)>0) 
                        
                        dice_res = dice(mask_result,groundTruth);
                        difference = abs((mask_result-groundTruth));
                        rvd = 100*(sum(difference,"all")/sum(groundTruth,"all"));
                        rd_res = jaccard(mask_result,groundTruth);
                        jaccard_res = jaccard(mask_result,groundTruth);
                        accuracy = sum(mask_result == groundTruth,'all')/numel(groundTruth);
    
                    end
                    pixelCount = numel(mask_result);
                    if ~isnan(dice_res) && all(size(labels) >0)
                        for counter= 1:20
                            ma= (counter*5)/100;
                            mi= ((counter-1)*5)/100;
                            if dice_res<=ma && dice_res>mi
                                dice_results(counter,1)=
                                dice_results(counter,1)+kidneyPixel;
                            end
                        end                        
                    end

                    if ~isnan(rvd) && all(size(labels) >0)
                        for counter= 1:20
                            ma= (counter*5.5);
                            mi= ((counter-1)*5.5);
                            if rvd<=ma && rvd>mi
                                rvd_results(counter,1)=
                                rvd_results(counter,1)+kidneyPixel;
                            end
                        end                         
                    end
    
                    if ~isnan(jaccard_res) && all(size(labels) >0)
                        for counter= 1:20
                            ma= (counter*5)/100;
                            mi= ((counter-1)*5)/100;
                            if jaccard_res<=ma && jaccard_res>mi
                                jaccard_results(counter,1)=
                                jaccard_results(counter,1)+kidneyPixel;
                            end
                        end                         
                    end
                    if ~isnan(accuracy) && all(size(labels) >0)
                        for counter= 1:20
                            ma= (counter*5)/100;
                            mi= ((counter-1)*5)/100;
                            if accuracy<=ma && accuracy>mi
                                accuracy_results(counter,1)=
                                accuracy_results(counter,1)+kidneyPixel;
                            end
                       end                         
                    end
                end
                counter = counter +1;
            end     
        end
        dice_sum=sum(dice_results(:,1));
        rvd_sum=sum(rvd_results(:,1));
        jaccard_sum=sum(jaccard_results(:,1));
        accuracy_sum=sum(accuracy_results(:,1));

        dice_length=length(dice_results(:,1));
        rvd_length=length(dice_results(:,1));
        jaccard_length=length(dice_results(:,1));
        accuracy_length=length(dice_results(:,1));

        for l=1:dice_length
            dice_results(l,2) = sum(dice_results(l:dice_length,1))/dice_sum;
        end
        for l=1:rvd_length
            rvd_results(l,2) = sum(rvd_results(l:dice_length,1))/rvd_sum;
        end
        for l=1:jaccard_length
            jaccard_results(l,2) = sum(jaccard_results(l:dice_length,1))/jaccard_sum;
        end
        for l=1:accuracy_length
            accuracy_results(l,2) = sum(accuracy_results(l:dice_length,1))/accuracy_sum;
        end
end

toc
% % 
writematrix(accuracy_results,'G:\checkpoint\06\aligDist\accuracy_results.csv') ;
writematrix(jaccard_results,'G:\checkpoint\06\aligDist\jaccard_results.csv') ;
writematrix(rvd_results,'G:\checkpoint\06\aligDist\rvd_results.csv') ;
writematrix(dice_results,'G:\checkpoint\06\aligDist\dice_results.csv') ;
% writematrix(time_results,'G:\checkpoint\06\aligDist\time.csv') ;

