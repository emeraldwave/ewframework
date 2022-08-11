local ndlinkFileName = window:getNdlinkFileName()
require (ndlinkFileName)	--The NSpire to DOMAPI Lua script

-----------------------------------------------------------------
--Image resources will be added here
if setupImageResources then
	setupImageResources()
else
	print("This module uses old ndlink version.")
	
	local imgResourceDetails = window:getImageResourceDetails() 
	
	_R.IMG.images = {}
	_R.IMG.width = {}
	_R.IMG.height = {}
	
	if imgResourceDetails then
		for i=0, imgResourceDetails.length - 1 do
			local fileSrc = imgResourceDetails[i].fileSrc
			local name = imgResourceDetails[i].name
			
			_R.IMG[name] = fileSrc
			_R.IMG.images[i+1] = _R.IMG[name]
			_R.IMG.width[ _R.IMG[name] ] = imgResourceDetails[i].width
			_R.IMG.height[ _R.IMG[name] ] = imgResourceDetails[i].height
		end
	end
end
-----------------------------------------------------------------

------------------------------------------
--Require your Lua file here.
-- Any calls to gc:drawImage() must have two extra parameters due to the onload() issue of browsers.
--Example gc:drawImage(img, x, y, width_scale_factor, height_scale_factor)
------------------------------------------
local moduleFileName = window:getFilePath()
require (moduleFileName)

------------------------------------------
--Launch the Nspire to DOMAPI Event Loop
------------------------------------------
ndlink:start()

window:afterFileLoad()