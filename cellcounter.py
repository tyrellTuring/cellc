import os
import numpy as np
import scipy as sp
import pylab as pl
import img2arr
import pymorph
import mahotas
from scipy import ndimage
from libtiff import TIFF, TIFFfile

###############################################################################
class Image:
	"""
	Contains data regarding a microscopy image, including:
	- info regarding the image
	- matrix form of image
	- array of X, Y & Z pixel locations in image
	- binary mask of tissue in the image (if some non-tissue area)
	"""

	##########################################################
	def __init__(self, filename, **kwargs):

		# parse the kwargs
		self.colours  = kwargs.get('colours',('b','g','r'))  # colour of each channel
		self.rgb      = kwargs.get('rgb',False)              # whether to treat the image as an rgb
		self.zres     = kwargs.get('zres',1)                 # z resolution (in um/slice)

		########################################################
		### 1. OBTAIN INFO ABOUT THE IMAGE

		# store the filename
		self.filename = filename

		# make sure the file exits
		if not(os.path.isfile(self.filename)): Exception('specfied image file not found')

		# get the directory, basename, and extension of the file
		(self.directory, self.basename)  = os.path.split(self.filename)
		(self.givenname, self.extension) = os.path.splitext(self.basename)
		
		# determine the image type
		if   '.tiff'.find(self.extension.lower()) >= 0: self.filetype = 'tiff'
		elif '.jpeg'.find(self.extension.lower()) >= 0: self.filetype = 'jpeg'
		elif '.jpg'.find(self.extension.lower())  >= 0: self.filetype = 'jpeg'
		else:
			self.filetype = 'unknown'
			Exception('unsupported file type')

		# act depending on file type
		if self.filetype is 'tiff':
			
			# get the file info
			tiffile = TIFF.open(filename)
			infostr = tiffile.info().split('\n')
			tiffile.close()

			# initialize the info dictionary
			self.info = dict()

			# step through the info, parse it and store it
			for s in infostr:

				# check whether the key is contained in this entry
				if len(s) > 0:
					entry = s.split(': ')
					if entry[0] == 'ImageDescription':
						imagej = entry[1].split('=')
						self.info[imagej[0]] = imagej[1]
					elif len(entry) == 1:
						value = entry[0].split('=')
						self.info[value[0]] = value[1]
					else:
						self.info[entry[0]] = entry[1]

			for key in self.info:

				if   key == 'BitsPerSample': self.info[key] = int(self.info[key])
				elif key == 'images':        self.info[key] = int(self.info[key])
				elif key == 'slices':        self.info[key] = int(self.info[key])
				elif key == 'channels':      self.info[key] = int(self.info[key])
				elif key == 'loop':
					if self.info[key] == 'true': self.info[key] = True
					else:                        self.info[key] = False
				elif key == 'hyperstack': 
					if self.info[key] == 'true': self.info[key] = True
					else:                        self.info[key] = False
				elif key == 'ImageWidth':    self.info[key] = int(self.info[key])
				elif key == 'ImageLength':   self.info[key] = int(self.info[key])
				elif key == 'XResolution':   self.info[key] = float(self.info[key])
				elif key == 'YResolution':   self.info[key] = float(self.info[key])
								

		########################################################
	  ### 2. LOAD THE IMAGE INTO A NUMPY ARRAY
		if self.filetype is 'tiff':
		
			# load the original tif file
			original = TIFFfile(self.filename)

			# initialize the array holderis
			self.array = np.empty([self.info['ImageWidth'],
			                       self.info['ImageLength'],
			                       self.info['slices'],
			                       self.info['channels']],dtype=np.uint8)

			# get the raw array data and store it in the holder
			samples = original.get_samples()[0][0]
			for c in range(self.info['channels']):

				# sort the colors if requested
				if self.rgb and self.info['channels'] == 3:
					if   self.colours[c] == 'b': ca = 2
					elif self.colours[c] == 'g': ca = 1
					elif self.colours[c] == 'r': ca = 0
				else: ca = c

				for s in range(self.info['slices']):
					self.array[:,:,s,ca] = np.uint8(samples[s*self.info['channels'] + c,:,:])

###############################################################################
class Counter:

	##########################################################
	def __init__(self, image, **kwargs):

		# parse the kwargs
		self.sigma = kwargs.get('sigma',5)	

		# store the array of the image
		self.image = image.array

		# smooth the image
		self.smooth = ndimage.gaussian_filter(self.array,self.sigma)

		# find the peaks in the smoothed image
		self.peaks = 
