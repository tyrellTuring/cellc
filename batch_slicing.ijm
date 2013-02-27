///////////////////////////////////////////////////////////////////////////////////////////
//MADE BY: 	Leonardo Restivo | Franklandlab
//DATE:	Feb/2013
//DESCRIPTION:
//	Process images for amygdala project (z- project, split channels, particle analysis define ROIs)
/////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////// BATCH SLICING & STACKING ///////////////////////////////////////////////////////
macro "batch slicing [b]"{

	dir1 = getDirectory("Choose Source Directory ");
	list = getFileList(dir1);

	// get marker name
	m1 = getString("prompt", "marker")
	
	dapiDir = dir1+"dapi"+File.separator;
	markerDir = dir1+m1+File.separator;
	fosDir = dir1+"fos"+File.separator;
	wfaDir = dir1+"wfa"+File.separator;
	
	File.makeDirectory(dapiDir);
	File.makeDirectory(markerDir); 
	File.makeDirectory(fosDir); 
	File.makeDirectory(wfaDir); 
	
	for (i=0; i<list.length; i++) {
		setBatchMode(true);
	    	showProgress(i+1, list.length);
	    	open(dir1+list[i]);
	    	stack_parameters = "start=1 stop="+nSlices/4+" projection=[Max Intensity]";
		run("Z Project...", stack_parameters);
		run("Split Channels");
		saveAs("tiff", wfaDir+"wfa"+list[i]);
		close();
		saveAs("tiff", fosDir+"fos"+list[i]);
		close();
		saveAs("tiff", markerDir+m1+list[i]);
		close();
		saveAs("tiff", dapiDir+"dapi"+list[i]);
		close();
		close();
		setBatchMode(false);
	}

	function stackify(DirToStack,fileName){
	
		listToStack = getFileList(DirToStack);
	
		for (i=0; i<listToStack.length; i++) {
			setBatchMode(true);
		    	showProgress(i+1, listToStack.length);
		    	open(DirToStack+listToStack[i]);
		    	setBatchMode(false);
		}
		run("Images to Stack");
		saveAs("tiff", dir1+fileName);
		close();
	}
	stackify(dapiDir,"dapi");
	stackify(markerDir,m1);
	stackify(fosDir,"fos");
	stackify(wfaDir,"wfa");
}


////////////////////////////////////////// PARTICLE-ANALYSIS ///////////////////////////////////////////////////////

macro "particleMe [p]"{

	run("Set Measurements...", "area mean centroid feret's integrated stack display redirect=None decimal=3");

	path = File.openDialog("open AMYGDALA file")
	open(path)
	
	saveTitle = getTitle();
	
	run("Brightness/Contrast...");
	
	run ("Threshold...");
	resetThreshold();

	waitForUser("Threshold set?");

	run("Convert to Mask", "method=Default background=Dark");
	
	run ("Analyze Particles...", "size=40-150 circularity=0.00-1.00 show=Ellipses  clear add stack");

	selectWindow("Drawing of "+saveTitle);
	run("Close");
	
	selectWindow(saveTitle);
	run("Close");

	run("Close");
	
	open(path);
	
	roiManager("Measure");

	saveAs("Results", File.directory+File.nameWithoutExtension+"_"+saveTitle+".txt");

	selectWindow(saveTitle);
	run("Close");

	selectWindow("Results");
	run("Close");

	counter = roiManager("count");
	// Cleanup ROIs
	for (i = 0; i <counter; i++){
		roiManager("Select", 0);
		roiManager("Delete");
	}
	
}


//////////////////////////////////// DEFINE-ROIs /////////////////////////////////////////////////

macro "Regions [r]" {

	// set measurements
	run("Set Measurements...","area centroid stack display decimal=3");

	// array of labels
	var selectMe = newArray("LA","BLA","CeL","CeM","ITC");

	// selction labels
	function foo(labelSet){
		Dialog.create("Label ROI");
		Dialog.addChoice("Label", labelSet)
		Dialog.show();
		lbl = Dialog.getChoice();
		return lbl;
	};
	
	// Open original file
	path = File.openDialog("open AMYGDALA file");
	open(path);

	saveTitle = File.nameWithoutExtension;

	// Set the ROIs
	var regionCounter=0;
	for (s = 0; s <nSlices; s++){
		setSlice(s+1);
		nROI = getNumber("Select the number of ROIs", 0);
		selected_labels = newArray(nROI);
		for (i = 0; i <nROI; i++){
			waitForUser("Select Roi");
			roiManager("Add");
			roiManager("Select", regionCounter);
			tempLabel = foo(selectMe);
			selected_labels[i] = tempLabel;
			// roiManager("Show All")
			print(selected_labels[i]);
			run ("Labels...","color=white font=10 show use draw bold");
			roiManager("Select", regionCounter);
			sliceNumber = getSliceNumber();
			saveAs("XY Coordinates", File.directory+saveTitle+"_"+selected_labels[i]+"_"+sliceNumber+".txt");
			regionCounter++;			
		}
	}

	// Save Roi file
	roiManager("Save", File.directory+saveTitle+"_roi.zip");
	
	// Cleanup ROIs
	for (i = 0; i <regionCounter; i++){
		roiManager("Select", 0);
		roiManager("Delete");
	}

	// Extract & Save measures from roi manager
	roiManager ("Measure");
	saveAs("Results", File.directory+saveTitle+"_RESULTS.txt");
}