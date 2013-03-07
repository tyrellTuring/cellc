import os
import numpy as np
import scipy as sp
import pylab as pl
import img2arr
import pymorph
import mahotas
from scipy import ndimage
from libtiff import TIFF, TIFFfile
import pdb

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
		self.colours    = kwargs.get('colours',('b','g','r'))  # colour of each channel
		self.rgb        = kwargs.get('rgb',False)              # whether to treat the image as an rgb
		self.zres       = kwargs.get('zres',1)                 # z resolution (in um/slice)
		self.findtissue = kwargs.get('findtissue',False)       # whether to get a tissue mask for the image

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

			# initialize the array holders
			if 'slices' in self.info and 'channels' in self.info:
				self.array = np.empty([self.info['ImageWidth'],
															 self.info['ImageLength'],
															 self.info['slices'],
															 self.info['channels']],dtype=np.uint8)
				self.imgtype = 'XYZC'
			elif 'slices' in self.info:
				self.array = np.empty([self.info['ImageWidth'],
															 self.info['ImageLength'],
															 self.info['slices']],dtype=np.uint8)
				self.imgtype = 'XYZ'
			elif 'channels' in self.info:
				self.array = np.empty([self.info['ImageWidth'],
															 self.info['ImageLength'],
															 self.info['channels']],dtype=np.uint8)
				self.imgtype = 'XYC'
			else:
				self.array = np.empty([self.info['ImageWidth'],
															 self.info['ImageLength']],dtype=np.uint8)
				self.imgtype = 'XY'

			# get the raw array data and store it in the holder
			if self.imgtype == 'XYZC':
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

			if self.imgtype == 'XYZ':
				samples = original.get_samples()[0][0]
				for s in range(self.info['slices']):
					self.array[:,:,s] = np.uint8(samples[s,:,:])

			if self.imgtype == 'XYC':
				samples = original.get_samples()[0][0]
				for c in range(self.info['channels']):

					# sort the colors if requested
					if self.rgb and self.info['channels'] == 3:
						if   self.colours[c] == 'b': ca = 2
						elif self.colours[c] == 'g': ca = 1
						elif self.colours[c] == 'r': ca = 0
					else: ca = c

					self.array[:,:,ca] = np.uint8(samples[c,:,:])

			if self.imgtype == 'XY':
				samples = original.get_samples()[0][0]
				self.array[:,:] = np.uint8(samples[:,:])

		########################################################
	  ### 3. CREATE THE XYZ INFO

		if self.imgtype == 'XYZC':
			self.x = np.empty(self.array.shape)
			self.y = np.empty(self.array.shape)
			self.z = np.empty(self.array.shape)
			self.c = np.empty(self.array.shape)
			for c in range(self.info['channels']):
				zstep = 0
				self.c[:,:,:,c] = self.c
				for s in range(self.info['slices']):
					[self.x[:,:,s,c], self.y[:,:,s,c]] = np.meshgrid(np.arange(0,self.info['XResolution']*self.info['ImageWidth'],self.info['XResolution']),
					                                                 np.arange(0,self.info['YResolution']*self.info['ImageLength'],self.info['YResolution']))
					self.z[:,:,s,:] = zstep
					zstep += self.zres

		if self.imgtype == 'XYZ':
			self.x = np.empty(self.array.shape)
			self.y = np.empty(self.array.shape)
			self.z = np.empty(self.array.shape)
			zstep = 0
			for s in range(self.info['slices']):
				[self.x[:,:,s], self.y[:,:,s]] = np.meshgrid(np.arange(0,self.info['XResolution']*self.info['ImageWidth'],self.info['XResolution']),
																										 np.arange(0,self.info['YResolution']*self.info['ImageLength'],self.info['YResolution']))
				self.z[:,:,s] = zstep
				zstep += self.zres

		if self.imgtype == 'XYC':
			self.x = np.empty(self.array.shape)
			self.y = np.empty(self.array.shape)
			self.c = np.empty(self.array.shape)
			for c in range(self.info['channels']):
				zstep = 0
				self.c[:,:,c] = self.c
				[self.x[:,:,c], self.y[:,:,c]] = np.meshgrid(np.arange(0,self.info['XResolution']*self.info['ImageWidth'],self.info['XResolution']),
																										 np.arange(0,self.info['YResolution']*self.info['ImageLength'],self.info['YResolution']))

		if self.imgtype == 'XY':
			self.x = np.empty(self.array.shape)
			self.y = np.empty(self.array.shape)
			[self.x[:,:], self.y[:,:]] = np.meshgrid(np.arange(0,self.info['XResolution']*self.info['ImageWidth'],self.info['XResolution']),
																							 np.arange(0,self.info['YResolution']*self.info['ImageLength'],self.info['YResolution']))

		########################################################
	  ### 3. GET A MASK OF NON-TISSUE

###############################################################################
class Counter:

	##########################################################
	def __init__(self, image, **kwargs):

		# parse the kwargs
		self.sigma   = kwargs.get('sigma',5)	
		self.arealim = kwargs.get('arealim',[200,800])	
		self.athresh = kwargs.get('athresh',1)

		# store the array of the image
		self.image  = image.array
		self.x      = image.x
		self.y      = image.y
		self.res    = image.info['XResolution']

		# smooth the image
		self.smooth = ndimage.gaussian_filter(self.image,self.sigma)

		# get a threshold for the image to get rid of background pixels and then identify cellular
		# tissue
		self.bkgrT = mahotas.thresholding.otsu(self.smooth,ignore_zeros=False)
		self.cellT = mahotas.thresholding.otsu(self.smooth*(self.smooth > self.bkgrT),ignore_zeros=True)

		# find the peaks in the smoothed image to get the potential cells
		#self.peaks = pymorph.regmax(self.smooth > np.max(self.bkgrT,self.cellT*self.athresh))
		self.peaks = pymorph.regmax(self.smooth > self.cellT*self.athresh)
		[labels,n] = ndimage.label(self.peaks)

		# get the distance transform
		#dist = ndimage.distance_transform_edt(self.smooth > np.max(self.bkgrT,self.cellT*self.athresh))
		dist = ndimage.distance_transform_edt(self.smooth > self.cellT*self.athresh)
		dist = dist.max() - dist
		dist -= dist.min()
		dist = dist/float(dist.ptp()) * 255
		dist = dist.astype(np.uint8)
		self.dist = dist

		# determine the region of each putative cell and its area
		cells = pymorph.cwatershed(dist,labels)
		areas = pymorph.blob(cells,'area',output='image')

		# eliminate cells outside of the area limits
		cells = cells * np.bitwise_and(areas >= self.arealim[0],areas <= self.arealim[1])

		# re-label the cells, count them, get their areas, centres, and bounding rectangles
		[self.cells, self.n] = ndimage.label(cells > 0)
		self.area   = pymorph.blob(self.cells,'area',output='data') * (self.res ** 2)
		self.centre = pymorph.blob(self.cells,'centroid',output='data')
		self.box    = pymorph.blob(self.cells,'boundingbox',output='data')

		# get the image intensity for each cell
