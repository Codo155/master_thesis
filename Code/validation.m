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

    [dice_results,rvd_results,jaccard_results,accuracy_results] = validationFunction(net,labelDirectory,ctDirectory);
    dice_Name= strcat(netWorkDirectory,"\dice_",iteration,".xls");
    rvd_Name= strcat(netWorkDirectory,"\rvd_",iteration,".xls");
    jaccard_Name= strcat(netWorkDirectory,"\jaccard_",iteration,".xls");
    accuracy_Name= strcat(netWorkDirectory,"\accuracy_",iteration,".xls");
   
    writematrix(dice_results,dice_Name);
    writematrix(rvd_results,rvd_Name);
    writematrix(jaccard_results,jaccard_Name) ;
    writematrix(accuracy_results,accuracy_Name) ;

end

toc

