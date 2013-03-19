///////////////////////////////////////////////////////////////////////////////////////////
//MADE BY: 	Leonardo Restivo | Franklandlab
//DATE:	Feb/2013
//DESCRIPTION:
//	Process images for amygdala project (z- project, split channels, particle analysis define ROIs)
/////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////// Global function for clearing up the ROI manager/////////////////
function cleanupROI(){
	counter = roiManager("count");
	for (i = 0; i <counter; i++){
		roiManager("Select", 0);
		roiManager("Delete");
	}
}
///////////////////////////////Global function for opening file/////////////////////////////////////
function openFile(){
	path = File.openDialog("open file");
	open(path);
	return(path);
}


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
	
	// clean up the ROi manager (make sure that nothing is left over from previous analysis)
	cleanupROI()
	
	// define measurements to be done on the stack
	run("Set Measurements...", "area mean centroid feret's integrated stack display redirect=None decimal=3");

	// open original stack
	path = File.openDialog("open file")
	open(path)

	// get title of the original stack. used to save the processed file
	saveTitle = getTitle();

	//open image controls (brightness and threshold), threshold is set to zero
	//run("Brightness/Contrast...");
	//run ("Threshold...");
	//resetThreshold();
	  
	  // generate Dialog for getting:
	  // [1] Sigma smoothing value
	  // [2] Noise tolerance
	  Dialog.create("Inital parameters");
	  // The following values are perfect for my staining (Leo)
	  Dialog.addMessage("Choose Smoothing and Noise tolerance for local maxima\n");
	  Dialog.addNumber("Sigma smoothing:", 3); 
	  Dialog.addNumber("Noise tolerance:", 10);
	  Dialog.addMessage("Particle Size values (um)\n");
	  Dialog.addNumber("Particle Size [Min]:", 5);
	  Dialog.addNumber("Particle Size [Max]:", 150);
	  Dialog.addCheckbox("Adjust Brightness/Contrast", false);
	  Dialog.show();
	  sigmaSmoothing= Dialog.getNumber();
	  tolerance 	= Dialog.getNumber();
	  pSizeMin 	= Dialog.getNumber();
	  pSizeMax	= Dialog.getNumber();
	  brightnessContrast = Dialog.getCheckbox();

	if (brightnessContrast){
		run("Brightness/Contrast...");
		waitForUser("Click APPLY and then OK when you're done");
	}
	
	// convert to grays
	run("Grays");

	// Invert the lookup table (Black on White)
	run("Invert LUT");

	// gaussian blur on the whole stack
	run("Gaussian Blur...","sigma="+sigmaSmoothing+" scaled stack");
	
	// find maxima in every slice of the stack
	setBatchMode(true);
	input = getImageID();
	n = nSlices();
	for (i=1; i<=n; i++) {
		showProgress(i, n);
		selectImage(input);
	 	setSlice(i);
	 	run("Find Maxima...", "noise="+ tolerance +" output=[Maxima Within Tolerance] light");
	 	if (i==1)
	        	output = getImageID();
	    	else  {
		 	run("Select All");
		        run("Copy");
		        close();
		        selectImage(output);
		        run("Add Slice");
		        run("Paste");
	    	}
	  }
	  run("Select None");
	  setBatchMode(false);

	// Clear results before doing particle analysis
	run("Clear Results");
	
	// Analyze particles detected with Local Maxima
	run ("Analyze Particles...", "size="+pSizeMin+"-"+pSizeMax+" circularity=0.00-1.00 show=Ellipses  clear add stack");

	// Close the original image
	selectWindow(saveTitle);
	roiManager("Measure");

	// save the Results (text file) to the original directory
//	saveAs("Results", File.directory+File.nameWithoutExtension+"_"+saveTitle+".txt");

	// TO DO: close all the remaining windows
//	selectWindow(xxx);
//	run("Close");


//	ACTIVATE this when doing the actual analysis
//	cleanupROI();
	
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