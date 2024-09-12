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
	print("Finished");
}

function processImage(title, image, table_name, temp_csv){
run("Select None");
original = title;
selectImage(original);
//Find colocalised spots
puncta_found=find_puncta(original);
// Save results to OMERO
csv_file = getDir("temp") + "PunctaResults.csv";
selectWindow("PunctaResults");
saveAs("Results", csv_file);
file_id = Ext.addFile("Image",image, csv_file);
deleted=File.delete(csv_file);
selectWindow("PunctaResults.csv");
run("Close");
// Save ROIs to OMERO
Ext.saveROIs(image, "");
roiManager("reset");
selectImage(image_name);
close("\\Others");
selectWindow("Log");
run("Close");
selectImage(image_name);
close();
selectWindow("Results");
run("Close");
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
if (roiManager("count")>0){
	return true
} else {
	return false
}
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}
