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
/////////////////////////////////////////////////////////////////////////////////////////////
function openFile(){
	path = File.openDialog("open file");
	open(path);
	return(path);
}
/////////////////////////////////////////////////////////////////////////////////////////////
	  
function zProject(){ 
	// porjection type (MAX or Mean)
	var projectionType = newArray("Max Intensity","Average intensity");
	
	// Image stack dimension
	getDimensions(width, height, channels, slices, frames)
	
	// DIALOG: input parameters
	Dialog.create("Inital parameters");
	Dialog.addMessage("........ Z-Projection ..........\n");
	Dialog.addNumber("Start:",1);
	Dialog.addNumber("Stop:", slices);
	Dialog.addChoice("Projection type",projectionType);
	Dialog.addCheckbox("Split channels",true);
	Dialog.show();
	
	start		= Dialog.getNumber();
	stop		= Dialog.getNumber();
	splitChannels	= Dialog.getChoice();
	projection 	= Dialog.getChoice();

	if (splitChannels){
		// split channels
		// loop over images
		// z project
		// save individual channesl to folder
	}
	
	stack_parameters = "start="+start+" stop="+stop+" projection=["+projection+"]";
	

	run("Z Project...", stack_parameters);
}
/////////////////////////////////////////////////////////////////////////////////////////////










macro "split and project [x]"{

	// clean up the ROI manager (make sure that nothing is left-behind from previous analysis)
	cleanupROI();
	
	// define measurements to be done on the stack
	run("Set Measurements...", "area mean centroid feret's integrated stack display redirect=None decimal=3");
	
	// open original stack
	path = File.openDialog("open file")
	open(path)
	saveTitle = getTitle();
	
	// find image data
	getDimensions(width, height, channels, slices, frames);
	
	var projectionType = newArray("Max Intensity","Average intensity");
	
	//---------------------- Generate Dialog ----------------------
	Dialog.create("Inital parameters");
	Dialog.addMessage("........ Z-Projection\n");
	Dialog.addNumber("Start:",1);
	Dialog.addNumber("Stop:", slices);
	Dialog.addChoice("Projection type",projectionType);
	Dialog.addMessage("........ Choose Smoothing\n");
	Dialog.addNumber("Sigma smoothing:", 2); 
	Dialog.addMessage("Particle Size values (um)\n");
	Dialog.addNumber("Particle Size [Min]:", 40);
	Dialog.addNumber("Particle Size [Max]:", 120);
	Dialog.addCheckbox("Adjust Brightness/Contrast", false);
	Dialog.show();
	//---------------------- get Dialog input ------------------------
	start		= Dialog.getNumber();
	stop		= Dialog.getNumber();
	projection 	= Dialog.getChoice();
	sigmaSmoothing	= Dialog.getNumber();
	pSizeMin 	= Dialog.getNumber();
	pSizeMax 	= Dialog.getNumber();
	brightnessContrast = Dialog.getCheckbox();
	
	if (brightnessContrast){
		run("Brightness/Contrast...");
		waitForUser("Click APPLY and then OK when you're done");
	}

	// z-projection (all slides)
	stack_parameters = "start="+start+" stop="+stop+" projection=["+projection+"]";
	run("Z Project...", stack_parameters);
	
	// split channels
	run("Split Channels");

	
	for (i=1; i<=channels ; i++){
		// convert to grays
		run("Grays");
		
		// Invert the lookup table (Black on White)
		run("Invert LUT");

		//work on a backup
		run("Duplicate...","title=temp");
		
		// gaussian blur on the image
		run("Gaussian Blur...","sigma="+sigmaSmoothing+" scaled stack");
		
		run("Auto Local Threshold", "method=Bernsen radius=15 parameter_1=0 parameter_2=0 white");
		
		run("Watershed");
		
		// find particles
		run ("Analyze Particles...", "size="+pSizeMin+"-"+pSizeMax+" circularity=0.80-1.00 show=Ellipses  clear add stack");
		
		close();
		close();

		roiManager("Set Fill Color","blue");
		run ("Labels...", "color=white font=12");
		roiManager("Show All");
		waitForUser("results OK?");
		close();
		//measure
		//save data to file
		
	}
	cleanupROI();
	close();
	
}
	

	// select channel 1
//	selectWindow("C2-MAX_"+saveTitle);
	
	// change color to particles
//	roiManager("Set Fill Color","blue");
//	run ("Labels...", "color=white font=12 draw");
//	roiManager("Show All");
//	waitForUser("results OK?");
	
	if(ok){
	close image
	save resutls to file
	}
	close();


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