run("OMERO Extensions");

// Enter details for connection to OMERO and select Macro to run on Dataset
#@ String (label = "username", value = "public") user
#@ String (label = "password", style="password", value = "public") pass
#@ String (label = "server", value = "camdu.warwick.ac.uk") host
#@ Integer (label = "port", value = 4064) port
#@ Integer (label = "Dataset ID", value = 10000) dataset_id
//#@ String (label = "Image name contains", value="2.5x") file_contains

// Connect to server and apply macro to each image in dataset
print("connecting...");
connected = Ext.connectToOMERO(host,port,user,pass);
print(connected);
table_name="NumberSpotsInCells.csv";
if (connected=="true"){
	print("collecting image list from dataset " +dataset_id);
	imageList = Ext.list("images", "dataset", dataset_id);
	image=split(imageList, ",");
	print("image list collected, analysing images...");
	temp_csv="0";
	for (i = 0; i < image.length; i++) {
		image_name=Ext.getName("image",image[i]);
	    print("start download");
	    Ext.getImage(image[i]);
	    print(image[i]);
	    title=getTitle();
	    temp_csv=processImage(title,image[i],table_name,temp_csv);
	    roiManager("reset");
	}
	open(temp_csv);
	selectWindow("Spots Per Cell.csv");
	// Save results to OMERO
	csv_file = getDir("temp") + table_name;
	selectWindow("Spots Per Cell.csv");
	saveAs("Results", csv_file);
	file_id = Ext.addFile("Dataset",dataset_id, csv_file);
	deleted=File.delete(csv_file);
	Ext.disconnect();
	print("Finished");
}

function processImage(title, image, table_name, temp_csv){
run("Select None");
original = title;
selectImage(original);
//Find colocalised spots
find_puncta(original);
// Save results to OMERO
csv_file = getDir("temp") + "PunctaResults.csv";
selectWindow("PunctaResults");
saveAs("Results", csv_file);
file_id = Ext.addFile("Image",image, csv_file);
deleted=File.delete(csv_file);
selectWindow("PunctaResults.csv");
run("Close");
selectWindow("Results");
run("Close");
// Segment all cells from channel 3
Stack.setPosition(3, 1, 1);
//run("Median...", "radius=5 slice");
run("Directional Filtering", "type=Max operation=Erosion line=20 direction=32");
run("Morphological Segmentation");
// wait for window to load");
wait(1000);
call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance=500.0", "calculateDams=true", "connectivity=4");
call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Catchment basins");
wait(1000);
call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
run("Remove Border Labels", "left right top bottom");
run("Label Size Filtering", "operation=Greater_Than size=2000");
run("Remap Labels");
run("Conversions...", " ");
run("8-bit");
run("Conversions...", "scale");
cellsImage=getTitle();

// Count number of spots Per cell
selectImage(cellsImage);
run("Set Measurements...", "modal redirect=None decimal=3");
roiManager("Measure");
modes=Table.getColumn("Mode");
Array.getStatistics(modes, min, max, mean, stdDev);
run("Distribution...", "parameter=Mode or="+max+1+" and=0-"+max+1);
selectWindow("Mode Distribution");
Plot.getValues(values,counts);
// Format Results
Array.sort(counts,values);
curr_number_of_spots=Array.deleteValue(counts, 0);
num_cells=lengthOf(curr_number_of_spots);
Array.reverse(values);
curr_cell_id=Array.trim(values, num_cells);
curr_cell_id=Array.reverse(curr_cell_id);
curr_image_id = newArray(num_cells);
Array.fill(curr_image_id, image);
Array.sort(curr_cell_id,curr_image_id,curr_number_of_spots);
// Close windows
selectWindow("Mode Distribution");
run("Close");
selectWindow("Results");
run("Close");
// Create ROIs for individual cells
selectImage(cellsImage);
run("Label Morphological Filters", "operation=Erosion radius=1 from_any_label");
setThreshold(1.0000, 1000000000000000000000000000000.0000);
roiManager("Deselect");
run("Select None");
number_puncta=roiManager("count");
run("Analyze Particles...", "add");
selectImage(original);
Stack.setPosition(3, 1, 1);
// select channel 3
for (i = number_puncta; i <= roiManager("count"); i++) {
roiManager("Select", number_puncta);
run("Enlarge...", "enlarge=1 pixel");
roiManager("Add");
roiManager("Select", number_puncta);
roiManager("Delete");
}
// Rename cells with corresponding ID
selectImage(cellsImage);
num_cells=roiManager("count")-number_puncta;
roi_names=newArray(num_cells);
roi_names[0]=0;
for (i = 1; i <= num_cells; i++) {
roiManager("Select", i+number_puncta-1);
run("Measure");
mode=Table.get("Mode", 0);
roiManager("Rename",mode);
roi_names[i]=mode;
selectWindow("Results");
run("Close");
}
Array.sort(roi_names);
for (i = 0; i < lengthOf(roi_names); i++) {
	if ( !contains(curr_cell_id, roi_names[i]) ) {
		curr_cell_id=Array.concat(curr_cell_id,roi_names[i]);
		curr_image_id=Array.concat(curr_image_id,image);
		curr_number_of_spots=Array.concat(curr_number_of_spots,0);
	}
}
Array.sort(curr_cell_id,curr_image_id,curr_number_of_spots);
Array.show("For current image",curr_image_id,curr_cell_id,curr_number_of_spots);
Table.deleteRows(0, 0, "For current image");
curr_image_id=Table.getColumn("curr_image_id");
curr_cell_id=Table.getColumn("curr_cell_id");
curr_number_of_spots=Table.getColumn("curr_number_of_spots");
selectWindow("For current image");
run("Close");
//Format all results
if ( !matches(temp_csv, "0")){
//if (isOpen("Spots Per Cell.csv")){;
    open(temp_csv);
	selectWindow("Spots Per Cell.csv");
	prev_image_id=Table.getColumn("image_ID");
	image_ID=Array.concat(prev_image_id,curr_image_id);
	prev_cell_id=Table.getColumn("cell_ID");
	cell_ID=Array.concat(prev_cell_id,curr_cell_id);
	prev_spots=Table.getColumn("number_of_spots");
	number_of_spots=Array.concat(prev_spots,curr_number_of_spots);
	run("Close");
} else {
	image_ID=curr_image_id;
	cell_ID=curr_cell_id;
	number_of_spots=curr_number_of_spots;
}
Array.show("Spots Per Cell.csv",image_ID,cell_ID,number_of_spots);
temp_csv= getDir("temp") + "Spots Per Cell.csv";
saveAs("Results", temp_csv);
run("Close");
// Close additional windows
selectImage(original);
// Save ROIs to OMERO
Ext.saveROIs(image, "");
roiManager("reset");
selectImage(image_name);
close("\\Others");
selectWindow("Log");
run("Close");
selectImage(image_name);
close();
return temp_csv;
}


function find_puncta(initial_stack) {
	selectImage(initial_stack);
run("Duplicate...", "title=[c1 copy] duplicate channels=1");
run("Despeckle");
run("Find Maxima...", "prominence=600 output=[Point Selection]");//Parameter that can be changed
//Create regions around puncta - circles with 9 pixel diameter around each point
run("Enlarge...", "enlarge=4 pixel");//Parameter that can be changed
newImage("PunctaRegions", "8-bit black", 512, 512, 1);
run("Restore Selection");
setForegroundColor(255, 255, 255);
run("Fill", "slice");
run("Watershed");
run("Select None");
//Add regions to ROI manager
run("Analyze Particles...", "exclude add");
//Close unrequired image
selectImage("PunctaRegions");
close();
selectImage("c1 copy");
close();
wait(1000);
//Measure colocalisation (Manders)
selectImage(initial_stack);
//waitForUser("0");
run("BIOP JACoP", "channel_a=1 channel_b=2 threshold_for_channel_a=Default threshold_for_channel_b=Huang manual_threshold_a=0 manual_threshold_b=0 crop_rois get_manders costes_block_size=5 costes_number_of_shuffling=100");
wait(1000);
//Tidy up BIOP JACoP output
Table.deleteRows(0, (roiManager("count")-1)); //for some reason BIOP JACoP creates a load of rows with 0 values, this removes them
image_list=getList("image.titles"); //Close all the report windows from BIOP JACoP
for (i = 0; i < lengthOf(image_list); i++) {
	if (matches(image_list[i],".*Report.*")) {
		selectImage(image_list[i]);
		close();
	}
}
//Keep only ROIs/puncta that have a high M1 value
count=0;
row_array=newArray(nResults());
for (i = 0; i < nResults(); i++) {
    v = getResult("Thresholded M1", i);
    if (v<0.75){//Parameter that can be changed
    	roi_name= getResultString("ROI", i);
    	roiManager("Select",count);
    	r_name=Roi.getName();
    	//Catch errors if table and roi manager get out of sync
    	if (matches(r_name,roi_name)){
    		roiManager("delete");
    	} else {
    		print(r_name + " and " + roi_name + "do not match, not deleting");
    	}
    } else {
    	count++;
    	row_array[i]=i+1;
    }
}
row_array=Array.deleteValue(row_array,0);
headers=newArray("Image A","ROI","Threshold A","Threshold B","Thresholded M1","Thresholded M2");
Table.create("PunctaResults");
for(j=0;j<lengthOf(headers);j++){
	result_string=newArray(lengthOf(row_array));
	for (i = 0; i < lengthOf(row_array); i++) {
		result_string[i]=getResultString(headers[j], row_array[i]-1);
	}
	Table.setColumn(headers[j], result_string);
}
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}
