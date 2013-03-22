CellProfiler Pipeline: http://www.cellprofiler.org
Version:1
SVNRevision:11710

LoadImages:[module_num:1|svn_version:\'Unknown\'|variable_revision_number:11|show_window:True|notes:\x5B\'WORKS on high density regions \x5Bi.e. ITC, EC, DG(?)\x5D\'\x5D]
    File type to be loaded:individual images
    File selection method:Text-Exact match
    Number of images in each group?:3
    Type the text that the excluded images have in common:Do not use
    Analyze all subfolders within the selected folder?:None
    Input image file location:Default Input Folder\x7CNone
    Check image sets for missing or duplicate files?:Yes
    Group images by metadata?:No
    Exclude certain files?:No
    Specify metadata fields to group by:
    Select subfolders to analyze:
    Image count:1
    Text that these images have in common (case-sensitive):163_BW
    Position of this image in each group:1
    Extract metadata from where?:None
    Regular expression that finds metadata in the file name:^(?P<Plate>.*)_(?P<Well>\x5BA-P\x5D\x5B0-9\x5D{2})_s(?P<Site>\x5B0-9\x5D)
    Type the regular expression that finds metadata in the subfolder path:.*\x5B\\\\/\x5D(?P<Date>.*)\x5B\\\\/\x5D(?P<Run>.*)$
    Channel count:1
    Group the movie frames?:No
    Grouping method:Interleaved
    Number of channels per group:3
    Load the input as images or objects?:Images
    Name this loaded image:imageIN
    Name this loaded object:Nuclei
    Retain outlines of loaded objects?:No
    Name the outline image:LoadedImageOutlines
    Channel number:1
    Rescale intensities?:Yes

CorrectIlluminationCalculate:[module_num:2|svn_version:\'Unknown\'|variable_revision_number:2|show_window:True|notes:\x5B\x5D]
    Select the input image:imageIN
    Name the output image:IllumBlue
    Select how the illumination function is calculated:Regular
    Dilate objects in the final averaged image?:No
    Dilation radius:1
    Block size:60
    Rescale the illumination function?:Yes
    Calculate function for each image individually, or based on all images?:Each
    Smoothing method:No smoothing
    Method to calculate smoothing filter size:Automatic
    Approximate object size:10
    Smoothing filter size:10
    Retain the averaged image for use later in the pipeline (for example, in SaveImages)?:No
    Name the averaged image:IllumBlueAvg
    Retain the dilated image for use later in the pipeline (for example, in SaveImages)?:No
    Name the dilated image:IllumBlueDilated
    Automatically calculate spline parameters?:Yes
    Background mode:auto
    Number of spline points:5
    Background threshold:2
    Image resampling factor:2
    Maximum number of iterations:40
    Residual value for convergence:0.001

Smooth:[module_num:3|svn_version:\'Unknown\'|variable_revision_number:1|show_window:True|notes:\x5B\x5D]
    Select the input image:IllumBlue
    Name the output image:FilteredImage
    Select smoothing method:Median Filter
    Calculate artifact diameter automatically?:No
    Typical artifact diameter, in  pixels:2
    Edge intensity difference:0.1

IdentifyPrimaryObjects:[module_num:4|svn_version:\'Unknown\'|variable_revision_number:8|show_window:True|notes:\x5B\x5D]
    Select the input image:FilteredImage
    Name the primary objects to be identified:Nuclei
    Typical diameter of objects, in pixel units (Min,Max):7,300
    Discard objects outside the diameter range?:Yes
    Try to merge too small objects with nearby larger objects?:No
    Discard objects touching the border of the image?:Yes
    Select the thresholding method:RobustBackground PerObject
    Threshold correction factor:1
    Lower and upper bounds on threshold:0.000000,1.000000
    Approximate fraction of image covered by objects?:0.8
    Method to distinguish clumped objects:Intensity
    Method to draw dividing lines between clumped objects:Intensity
    Size of smoothing filter:10
    Suppress local maxima that are closer than this minimum allowed distance:7
    Speed up by using lower-resolution image to find local maxima?:Yes
    Name the outline image:PrimaryOutlines
    Fill holes in identified objects?:Yes
    Automatically calculate size of smoothing filter?:Yes
    Automatically calculate minimum allowed distance between local maxima?:Yes
    Manual threshold:0.5
    Select binary image:None
    Retain outlines of the identified objects?:Yes
    Automatically calculate the threshold using the Otsu method?:Yes
    Enter Laplacian of Gaussian threshold:0.5
    Two-class or three-class thresholding?:Two classes
    Minimize the weighted variance or the entropy?:Entropy
    Assign pixels in the middle intensity class to the foreground or the background?:Foreground
    Automatically calculate the size of objects for the Laplacian of Gaussian filter?:Yes
    Enter LoG filter diameter:5
    Handling of objects if excessive number of objects identified:Continue
    Maximum number of objects:500
    Select the measurement to threshold with:FileName

OverlayOutlines:[module_num:5|svn_version:\'Unknown\'|variable_revision_number:2|show_window:True|notes:\x5B\x5D]
    Display outlines on a blank image?:No
    Select image on which to display outlines:imageIN
    Name the output image:OrigOverlay
    Select outline display mode:Color
    Select method to determine brightness of outlines:Max of image
    Width of outlines:1
    Select outlines to display:PrimaryOutlines
    Select outline color:Yellow

MeasureObjectSizeShape:[module_num:6|svn_version:\'1\'|variable_revision_number:1|show_window:True|notes:\x5B\x5D]
    Select objects to measure:Nuclei
    Calculate the Zernike features?:No

ExportToSpreadsheet:[module_num:7|svn_version:\'Unknown\'|variable_revision_number:7|show_window:True|notes:\x5B\x5D]
    Select or enter the column delimiter:Tab
    Prepend the output file name to the data file names?:Yes
    Add image metadata columns to your object data file?:Yes
    Limit output to a size that is allowed in Excel?:No
    Select the columns of measurements to export?:Yes
    Calculate the per-image mean values for object measurements?:No
    Calculate the per-image median values for object measurements?:No
    Calculate the per-image standard deviation values for object measurements?:No
    Output file location:Default Output Folder\x7CNone
    Create a GenePattern GCT file?:No
    Select source of sample row name:Metadata
    Select the image to use as the identifier:None
    Select the metadata to use as the identifier:None
    Export all measurements, using default file names?:Yes
    Press button to select measurements to export:Nuclei\x7CAreaShape_Center_Y,Nuclei\x7CAreaShape_Center_X,Nuclei\x7CAreaShape_Area
    Data to export:Do not use
    Combine these object measurements with those of the previous object?:No
    File name:DATA.csv
    Use the object name for the file name?:Yes

Resize:[module_num:8|svn_version:\'Unknown\'|variable_revision_number:4|show_window:True|notes:\x5B\'use this to segment high density ROIs\'\x5D]
    Select the input image:imageIN
    Name the output image:ResizedBlue
    Select resizing method:Resize by a fraction or multiple of the original size
    Resizing factor:0.1
    Width of the final image, in pixels:100
    Height of the final image, in pixels:100
    Interpolation method:Nearest Neighbor
    How do you want to specify the dimensions?:Manual
    Select the image with the desired dimensions:None
    Additional image count:0
