%1
clear
clc
close all
%% 
%% START HERE; LOAD IMAGES
load('background.mat');
%% Take Images
cam = webcam('HP USB Webcam');

choice = 2;
figure()
while choice ~= 0
    choice = 2;
    foreground = snapshot(cam);
    %% Subtract Image
    img = background-foreground;
    subtracted = img;
    imshow(img)
    %% Green Filter
    img = colorfilter(img,[60 180]);
    imshow(img)
    %% Binarize
    img = im2bw(img, 0.30);
    imshow(img)
    %% Erode Image
    se = strel('disk',2);
    img = imerode(img,se);
    imshow(img)
    %% Dialate Image
    se2 = strel('disk',1);
    img = imdilate(img,se2);
    imshow(img)
    %% Props
    props = regionprops(img);
    %% Colors Only Image
    reconstructed = imcomplement(subtracted);
    streched = immultiply(imsubtract(reconstructed,128),2);
    %% Invert Image
    img = xor(img,1);
    imshow(img)
    %% Annotate Shapes
    lines = {};
    angles = {};
    shapes = {};
    for i = 1:size(props)
        rectangle('Position',props(i).BoundingBox);
        if props(i).Area > 530
            str = 'Circle';
        elseif props(i).Area > 372
            str = 'Square';
        else 
            str = 'Triangle';
        end
        shape.shape = str;
        shape.position = [round(props(i).Centroid(1),0),round(props(i).Centroid(2))];
        % determine average color for pixels surrounding centroid
        starting_x = shape.position(1);
        starting_y = shape.position(2);
%         colors = {};
%         for j = (starting_x-1):(starting_x+1)
%             for k = (starting_y-1):(starting_y+1)
%                 colors = [colors, [255-subtracted(j,k,1),255-subtracted(j,k,2),255-subtracted(j,k,3)]];
%             end
%         end
%         m_colors = cell2mat(colors);
        %color = [mean(m_colors(1,1:3:end)), mean(m_colors(1,2:3:end)), mean(m_colors(1,3:3:end))];
        color = streched(starting_y,starting_x , :);
        shape.rgb = color;
        if (color(3) > color(2)+10) && (color(3) > color(1)+10)
            %super blue
            shape.color = 'Blue';
        elseif (color(2) > color(1)+10) && (color(2) > color(3))
            %super green
            shape.color = 'Green';
        elseif (color(1) > color(2)+30) && (color(1) > color(3))
            %super red
            shape.color = 'Red';
        else
            shape.color = 'Yellow';
        end
        str2 = [num2str(color(1)) ', ' num2str(color(2)) ' ,' num2str(color(3))];
        str3 = shape.color;
        txt = {str, str3};
        t = text(props(i).Centroid(1) + 20, props(i).Centroid(2) + 20, txt );
        t.FontSize = 8;

        %position of the motor
        x = 640/2;
        y = 560;
        lines = [ lines, line([round(props(i).Centroid(1),0) ,x],[round(props(i).Centroid(2),0) ,y] )];
        diff = (atan((y-round(props(i).Centroid(2),0))/(x-round(props(i).Centroid(1),0))) - atan((x-x)/(y-0))) * 180/pi;
        if diff > 0
            angle = (90 - diff); 
        elseif diff < 0
            angle = (90 + diff).*-1;
        else
            angle = 0;
        end
        shape.angle = angle;
        angles = [angles, angle];
        t = text(props(i).Centroid(1) - 20, props(i).Centroid(2) - 20, num2str(angle) );
        t.FontSize = 8;
        shapes = [shapes, shape];
    end
    %% Give the user options to select  
    options = size(shapes);
    if options ~= 0
        menu_options{1} = "RUN";
        for i = 2:(options(2)+1)
            menu_options{i} = strcat(shapes{i-1}.color, " ", shapes{i-1}.shape, " ", num2str(shapes{i-1}.angle));
        end
        j = 1;
        while choice ~= 0 && choice ~= 1
            choice = menu('Choose the desired object', menu_options{:});

            if choice == 0 || choice == 1 
                run_angles(j) = 0;
            else
                run_angles(j) = shapes{choice-1}.angle;
            end
            j=j+1;
        end
        for k=1:j-1
            set_param('project3/angle','Value',num2str(run_angles(k)));
            pause(2);
        end
        clear menu_options;
        clear run_angles;
    end
end