function [xCoordinate,yCoordinate,boxWidth,boxHeight]= getCoordinates(i)
    boxWidth=0;
    boxHeight=0;
    xCoordinate=0;
    yCoordinate=0;
    [rows, columns] = size(i);
    parfor row = 1 : rows
        % Make measurements of all lines of 1's.
        props = regionprops(i(row,: ), 'Area');
        % Extract all the lengths into a vector and then put into a cell.
        R{row} = [props.Area];
        R{row}= sum(R{row}) 
    end
    sumR = cellfun(@sum,R);
    boxWidth=max(sumR); 
    if boxWidth ~= 0
        lineMaxWidth = find(sumR==boxWidth); 

        for  counter =1 : length(lineMaxWidth)
            rowOfIntrest=i(lineMaxWidth(counter),:);
            y(counter)= find(rowOfIntrest~=0,1,'first');
        end
        yCoordinate=min(y);
        xCoordinate= find(sumR~=0,1,'first');
        boxHeight= find(sumR~=0,1,'last')- xCoordinate;
    end 
end