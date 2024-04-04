run("OMERO Extensions");

//Enter details for connection to OMERO and select Macro to run on Dataset
#@ String (label = "username", value = "public") user
#@ String (label = "password", style="password", value = "public") pass
#@ String (label = "server", value = "camdu.warwick.ac.uk") host
#@ Integer (label = "port", value = 4064) port
#@ Integer (label = "Dataset ID", value = 10000) dataset_id

//Connect to server and apply macro to each image in dataset
connected = Ext.connectToOMERO(host,port,user,pass);
table_name="NumberSpotsInCells.csv"
if (connected=="true"){
imageList = Ext.list("images", "dataset", dataset_id);
image=split(imageList, ",");
print(dataset_id);
for (i = 0; i < image.length; i++) {
	print("start download");
	Ext.getImage(image[i]);
	print(image[i]);
	title=getTitle();
	processImage(title,image[i],table_name);
	roiManager("reset");
}
Ext.disconnect();
print("Finished");
}

function processImage(title, image, table_name){
//open image
run("Select None");
original = title;
// Segment all cells from channel 2
Stack.setPosition(2, 1, 1);
run("Median...", "radius=10 slice");
run("Directional Filtering", "type=Max operation=Erosion line=60 direction=32");
run("Morphological Segmentation");
// wait for window to load
wait(1000);
call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance=50.0", "calculateDams=true", "connectivity=4");
call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Catchment basins");
wait(1000);
call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
run("Remove Border Labels", "left right top bottom");
run("Label Size Filtering", "operation=Greater_Than size=2000");
cellsImage=getTitle();
setThreshold(1.0000, 1000000000000000000000000000000.0000);
run("Analyze Particles...", "add");
selectImage(original);
// Identify spots in channel 1
Stack.setPosition(1, 1, 1);
roiManager("Deselect");
roiManager("Combine");
run("Find Maxima...", "prominence=500 output=[Point Selection]");
roiManager("add");
// Delete rois except points
roiManager("Deselect");
regions=roiManager("count");
roiManager("Select", Array.getSequence(regions-1));
roiManager("Delete");
run("Select None");
// Count number of spots per cell
selectImage(cellsImage);
run("Set Measurements...", "modal redirect=None decimal=3");
roiManager("Measure");
modes=Table.getColumn("Mode");
Array.getStatistics(modes, min, max, mean, stdDev);
run("Distribution...", "parameter=Mode or="+max+1+" and=0-"+max+1);
selectWindow("Mode Distribution");
Plot.getValues(values,counts)
Array.sort(counts,values);
number_of_spots=Array.deleteValue(counts, 0);
num_cells=lengthOf(number_of_spots);
Array.reverse(values);
cell_ID=Array.trim(values, num_cells);
Array.reverse(cell_ID);
Array.show("Spots Per Cell", cell_ID, number_of_spots);
// Save results to OMERO
csv_file = getDir("temp") + table_name + "_" + image;
selectWindow("Spots Per Cell");
saveAs("Results", csv_file);
file_id = Ext.addFile("Image",image, csv_file);
deleted=File.delete(csv_file);
// Close windows
selectWindow("Mode Distribution");
run("Close");
selectWindow("Results");
run("Close");
selectWindow(table_name + "_" + image);
run("Close");
// Create ROIs for individual cells
selectImage(cellsImage);
run("Label Morphological Filters", "operation=Erosion radius=1 from_any_label");
setThreshold(1.0000, 1000000000000000000000000000000.0000);
run("Analyze Particles...", "add");
selectImage(original);
Stack.setPosition(2, 1, 1);// select channel 2
for (i = 1; i <= num_cells; i++) {
roiManager("Select", 1);
run("Enlarge...", "enlarge=1 pixel");
roiManager("Add");
roiManager("Select", 1);
roiManager("Delete");
}
// Rename cells with corresponding ID
selectImage(cellsImage);
for (i = 1; i < num_cells; i++) {
roiManager("Select", i);
run("Measure");
mode=Table.get("Mode", 0);
mode=Math.ceil(mode);
roiManager("Rename",mode);
selectWindow("Results");
run("Close");
}
// Close additional windows
selectImage(original);
close("\\Others");
selectWindow("Log");
run("Close");
//Save ROIs to OMERO
Ext.saveROIs(image, "");
roiManager("reset");
selectImage(original);
close();
}