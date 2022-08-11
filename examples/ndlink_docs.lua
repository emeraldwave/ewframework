--(c) Emerald Wave, 2014

-----------------------------------------------------------------
-- Class() function
-- Compatible with Lua 5.1 (not 5.0).
-----------------------------------------------------------------

function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if class_tbl.init then
       class_tbl.init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt) 
   return c
end

ndlinkUtils = class()

-- Calculate bounding rectangle and return width and height
function ndlinkUtils:calculateBoundingBox( w, h, rotation )
	local rectangleWidth = w
    local rectangleHeight = h
    local newHeightUp, newHeightLow, newWidthLeft, newWidthRight

    -- calculate new bounding rectangle
    newWidthLeft = math.abs( rectangleWidth * math.cos( math.rad( rotation )))
    newHeightLow = math.abs( rectangleWidth * math.sin( math.rad( rotation )))
    newHeightUp = math.abs( rectangleHeight * math.cos( math.rad( rotation )))
    newWidthRight = math.abs( rectangleHeight * math.sin( math.rad( rotation )))

    return math.floor( newWidthLeft + newWidthRight ), math.floor( newHeightUp + newHeightLow )
end

-- Given a bounding rectangle and a rotation of a rectangle, calculate an exact fit rectangle
-- ratio is the width to height of the rectangle
function ndlinkUtils:calculateMaxRect( wBoundingBox, hBoundingBox, rotation, ratio )
	local rotationRad = math.rad( rotation )
	local sinRotation = math.sin( rotationRad )
	local cosRotation = math.cos( rotationRad )
	local absSinRotation = math.abs( sinRotation )
	local absCosRotation = math.abs( cosRotation )

	local width = ( ratio * wBoundingBox ) / ( absSinRotation + ratio * absCosRotation )
	local height = wBoundingBox / ( absSinRotation + ratio * absCosRotation )

	return width, height
end

function ndlinkUtils:addDebugEvent( text )
	if text ~= dbgEvents[ dbgCounter ] then
		dbgCounter = dbgCounter + 1
		dbgEvents[ dbgCounter ] = text
	end
end

--Scale an Image into a given bounding box.
--Pass in the width and height of the current image, it's rotation, and the width and height of the bounding box to scale in to.
--Returns the new scaled width and height of the rotated image
--function ndlinkUtils:scaleImage(scaledNaturalWidth, scaledNaturalHeight, rotation, wBoundingBox, hBoundingBox)
--	local wB, wH = self:calculateBoundingBox(scaledNaturalWidth, scaledNaturalHeight, rotation)
--
--	--Scale the image by the same amount as the ratio of the old bounding box to the new bounding box.
--	scaledNaturalWidth = scaledNaturalWidth * wBoundingBox / wB
--	scaledNaturalHeight = scaledNaturalHeight * hBoundingBox / wH
--
--	return scaledNaturalWidth, scaledNaturalHeight
--end

--o.foo(o, x) is the same as o:foo(x)


--These tables don't exist anymore outside of the NSpire, so we need our own.
-----------------------------------------------------------------
--NSpire Resource table
-----------------------------------------------------------------
_R = {}
_R.IMG = {}
local numberOfImagesToLoad = 0 -- we need this number immediately

function setupImageResources()
	local imgResourceDetails = window:getImageResourceDetails() 
	
	_R.IMG.images = {}
	_R.IMG.width = {}
	_R.IMG.height = {}
	_R.IMG.name = {}
	_R.IMG.base64 = {}

	if imgResourceDetails then
		numberOfImagesToLoad = imgResourceDetails.length

		for i=0, imgResourceDetails.length - 1 do
			local fileSrc = imgResourceDetails[i].fileSrc
			local name = imgResourceDetails[i].name
			
			_R.IMG[name] = fileSrc
			_R.IMG.images[i+1] = _R.IMG[name]
			_R.IMG.width[ _R.IMG[name] ] = imgResourceDetails[i].width
			_R.IMG.height[ _R.IMG[name] ] = imgResourceDetails[i].height
			_R.IMG.name[ _R.IMG[ name ]] = name

			if imgResourceDetails[ i ].base64 then
				_R.IMG.base64[ _R.IMG[ name ]] = imgResourceDetails[ i ].base64
			end
		end
	end
end

--Add your resources into the *_init.lua file.  Instead of being in the resource file, your file is now on the web server.
--Example: _R.IMG.blue_vector_arrows = "blue_vector_arrows.png"
-----------------------------------------------------------------

-----------------------------------------------------------------
--NSpire image() table
-----------------------------------------------------------------
image = {}
setmetatable(image, { __index = function() end })		--Handle any calls that we weren't anticipating.

function image.new( resource )
	return gc.images[ resource ]
end

function image:copy( wBoundingBox, hBoundingBox )
	-- check if w and h is 0 or nil
	if wBoundingBox == nil or wBoundingBox == 0 then wBoundingBox = self.scaledNaturalWidth end
	if hBoundingBox == nil or hBoundingBox == 0 then hBoundingBox = self.scaledNaturalHeight end

	--Create and load a new image.
	local img = gc:copyImage( self.imageSrcName )

	--Copy the current rotation into the new image
	img.rotation = self.rotation

	local newbbw, newbbh = ndlinkUtils:calculateBoundingBox(img.scaledNaturalWidth, img.scaledNaturalHeight, img.rotation)

	img.sfw = wBoundingBox / newbbw
	img.sfh = hBoundingBox / newbbh

	--The bounding box for the image was determined by the client.
	img.boundingBoxWidth = wBoundingBox
	img.boundingBoxHeight = hBoundingBox

	--If this image is copied from the original, then point to the original so that it can know when the image is loaded.\\
	if img.parent == nil then img.parent = self end

	return img
end


--Rotate n degrees from current rotation.
function image:rotate(n)

	--Create and load a new image.
	local img = gc:copyImage( self.imageSrcName )

	--Store the total rotation into the image.  The image is not actually rotated until drawing occurs.
	img.rotation = (self.rotation + n) % 360
	if img.rotation < 0 then img.rotation = 360 + img.rotation end

	--Store the current image width and height into the new image.
	img.scaledNaturalWidth = self.scaledNaturalWidth
	img.scaledNaturalHeight = self.scaledNaturalHeight

	img.sfw = self.sfw
	img.sfh = self.sfh

	--Since the image is being rotated, we must calculate a new bounding box.
	img.boundingBoxWidth, img.boundingBoxHeight = ndlinkUtils:calculateBoundingBox(img.scaledNaturalWidth * self.sfw, img.scaledNaturalHeight * self.sfh, img.rotation)

	return img
end

function image:width()
	return self.boundingBoxWidth
end

function image:height()
	return self.boundingBoxHeight
end

function image:isLoaded()
	return self.imageLoaded
end


-----------------------------------------------------------------
--NSpire platform() table
-----------------------------------------------------------------
platform = {}
setmetatable(platform, { __index = function() end })
platform.window = {}
platform.window.invalidate = function(self, x, y, w, h) ndPaint(x, y, w, h) end		--Repaint the screen.
platform.getStringHeightWhitespace = function() return 1.25 end	--There is about 15% extra whitespace in TI version that is not in DOM version of string height.
platform.getPlatformType = function() return "ndlink" end	--Inform the script that it is using ndlink, not the regular TI version.
platform.hw = function() return 7 end	--Inform the script that this is Windows or Mac.  In the future, add value for Android and iOS
platform.isDeviceModeRendering = function() return false end	--This is not the NSPire handheld
platform.isTabletModeRendering = function() return false end	--This is not the NSPire handheld

--withGC passes in a function and a variable number of parameters.  The gc is passed at the end, so we can't use fn(..., gc) because that fails.
--Instead, We need to put all of these params into an array and then
--add the gc to pass to the function.
--platform.withGC = function(fn, ...)  w,h = fn((select(1,...)), (select(2,...)), (select(3,...)), (select(4,...)), gc) return w, h end
platform.withGC = function(fn, ...)
	local args = {...}	--Place the arguments into an array.
	local count = #args
	args[count+1] = gc			--Add in the gc to the args list.
	return fn(unpack(args))	--Unpack the array to send into the function, then return the returned arguments back up to the caller.
	end

--renderToCanvas is a function that is being defined here.
renderToCanvas = function(width, height, renderFunction)
	local offscreenCanvas = window.document:createElement('canvas')
	offscreenCanvas.height = .95 * window.innerHeight	--Take 95% of the window height because otherwise we seem to get a scroll bar.
	offscreenCanvas.width = .95 * window.innerWidth
	local gc2 = GraphicsContext(offscreenCanvas)
	renderFunction(gc2)
	return gc2.canvas
end

function ndPaint(x, y, w, h)
	--cached is returned by the function called renderToCanvas and contains the image to send to the GPU.
-- USE THESE TWO LINES FOR OFFSCREEN DRAWING
	--local cached = renderToCanvas(w, h, function(gc2) on.paint(gc2) end)
	--gc:renderImage(cached, x, y)

	-- OR - USE THIS NEXT LINE FOR DIRECT DRAWING
	if x ~= nil and y ~= nil and w ~= nil and h ~= nil then
		--gc:clipRect("set", x, y, w, h)
	end

	-- SOLUTION
	local thisx = x or 0
	local thisy = y or 0
	local thisw = w or onscreenCanvas.width
	local thish = h or onscreenCanvas.height

	--gc.context:drawImage( gc.clearImg, thisx, thisy, thisw, thish )
	gc:clear( thisx, thisy, thisw, thish )

	-- Solution 1
	--gc:clear();

	-- Solution 2
	--[[local img = gc.context:createImageData(w, h)
	for i = 0, img.data.length do --i >= 0; )
  		img.data[i] = 0
  	end

	gc.context:putImageData(img, x,y)]]

	-- Solution 3
	--gc.context:drawImage( gc.clearImg, x, y, w, h )

	if on.paint then
		on.paint(gc)
	end

	--[[for i=1, dbgCounter do
        gc:setColorRGB( 0, 0, 0 )
        gc:drawString(dbgEvents[i], 120, (20*i))
    end]]

	gc:clipRect("reset")
end

-----------------------------------------------------------------
--NSpire time() table
-----------------------------------------------------------------
timerID = 0
timer = {}
setmetatable(timer, { __index = function() end })
--d:getMilliseconds only returns 0-999, so it is not good enough for a randomseed().  Instead, we use d:getTime() which is ms. since 1970.
timer.getMilliSecCounter = function() d = window.Date.new() return d:getTime() end
timer.start = function(interval) timerID = window:setInterval(function() ndOnTimer() end, interval*1000) end 	--Nspire interval is in seconds.  on.timer() is supplied by calling program.
timer.stop = function() window:clearInterval(timerID) end
function ndOnTimer() on.timer() end

-----------------------------------------------------------------
--NSpire cursor() table
-----------------------------------------------------------------
cursor = {}
setmetatable(cursor, { __index = function() end })
cursor.set = function(iconstr) end
cursor.show = function() end
cursor.hide = function() end


-----------------------------------------------------------------
--NSpire toolpalette() table
-----------------------------------------------------------------
toolpalette = {}	--toolpalette functions are already created, so we need to handle them.
setmetatable(toolpalette, { __index = function() end })
toolpalette.register = function() end	--The key called 'register' is now placed into the table and it's value is a function that does nothing.
toolpalette.enableCut = function() end	
toolpalette.enableCopy = function() end	
toolpalette.enablePaste = function() end	
--toolpaletteHandler = {}
--toolpaletteHandler.__index = function(tbl, func) end
--Events like on.paint(gc)
--setmetatable(toolpalette, toolpaletteHandler)
--Process all 'toolpalette' calls that nobody is handling here.

--setmetatable(on, eventHandler)

--Process all 'on' events that nobody is handling here.
--eventHandler = {}
--eventHandler.__index = function(tbl, event) end

--if (on.construction == nil) then
--	on.construction = function() end
--end


-----------------------------------------------------------------
--NSpire math() table
-----------------------------------------------------------------
--math = {}	--math functions are already created, so we need to handle them.
--setmetatable(math, { __index = function() end })

-- math table already exists in moonshine(eg, math.random, math.randomseed )

math.eval = function(p_string)
	p_string = p_string:gsub("math", "Math")
	return window:eval( p_string );
end

--print( math.eval( "math.pow(10,2)+20+30" ))
-----------------------------------------------------------------
--NSpire on() events
-----------------------------------------------------------------

on = {}		-- function on.paint(gc) is defined in your file, so we need the initial table.
--setmetatable(platform, { __index = on })

-----------------------------------------------------------------
--NSpire touch() events
-----------------------------------------------------------------

touch = {}
touch.isEnabled = nil

--Create a fake input box that will trick the iPad Safari browser into opening the soft keyboard.
--This input field takes up no space and is invisible.
--[[touch.fakeInput = window.document:createElement("INPUT")
touch.fakeInput:setAttribute("type", "text")
touch.fakeInput:setAttribute("value", "")
touch.fakeInput.style.width = 0
touch.fakeInput.style.height = 0
touch.fakeInput.style.opacity = 0
window.document.body:appendChild(touch.fakeInput)]]

function touch.isKeyboardVisible()
	return false
end

--Call the browser to make a TouchEvent.  If it fails, then touch() is not available.
function touch.enabled()
	if touch.isEnabled == nil then
		touch.isEnabled = pcall(function() window.document:createEvent("TouchEvent") end)		--Only call once.
		
		-- these are for Mozilla Firefox
		local str = " -webkit- -moz- -o- -ms- "
		local tblPrefix = {}
		local mq = function(query) return window:matchMedia(query).matches; end
		for token in string.gmatch( str, "%S+") do tblPrefix[#tblPrefix+1] = token end
  		local query = "(touch-enabled),(" .. table.concat( tblPrefix, "touch-enabled),(" ) .. "touch-enabled),(heartz)" -- query for matching media, 

  		-- this will be true when one of these conditions returns true
		touch.isEnabled = touch.isEnabled -- previous value of touch.isEnabled
			or ( window.navigator.msMaxTouchPoints and window.navigator.msMaxTouchPoints > 0 ) -- for Edge/IE
			or ( window.navigator.maxTouchPoints and window.navigator.maxTouchPoints > 0 ) -- for Edge/IE
			or ( window.navigator.MaxTouchPoints and window.navigator.MaxTouchPoints > 0 ) -- for Edge/IE
			or mq( query ) -- for FireFox
			or window.DocumentTouch -- interface used to provide convenience methods for creating Touch and TouchList objects
	end

	return touch.isEnabled

end

--This is a hack to get the keyboard to display on iPad.  This function requires a hidden INPUT box in the window.
--http://4pcbr.com/topic/how_to_open_keyboard_on_ipad_with_js
function touch.showKeyboard(b)
		if window.event then
			window.event:stopPropagation()
			window.event:preventDefault()
		end
		local clone = touch.fakeInput:cloneNode(true)
        local parent = touch.fakeInput.parentElement
        parent:appendChild(clone)
        parent:replaceChild(clone, touch.fakeInput)
        touch.fakeInput = clone
		window:setTimeout(function() touch.fakeInput.value = "" touch.fakeInput:focus() end, 0)
end
	--window.onclick = function(e) print("onclic") touch.fakeInput:focus() end
	--inp.onclick = function(e) print("inp click") inp:focus() end
	--touch.fakeInput.onclick = function(e) print("inp click") touch.fakeInput:focus() end
	--self.context.canvas:addEventListener("click", function(e) print("click") myclick() end, false)

-- this is to check if the user's device is an android or an apple device
function touch.isDeviceTouch()
	local isAndroid = window:isAndroid()
	local isIPhone = window:isIphone()
	local isDeviceIpad = false
	local isDeviceIphone = false
	local isDeviceTouch = window:isTouchDevice()
	local screenWidth, screenHeight = window.screen.width, window.screen.height

	if window.isDeviceIpad then
		isDeviceIpad = window:isDeviceIpad( screenWidth, screenHeight )
	end

	if window.isDeviceIphone then
		isDeviceIphone = window:isDeviceIphone( screenWidth, screenHeight )
	end

	return isAndroid or isIPhone or isDeviceIphone or isDeviceIpad --or isDeviceTouch
end


-----------------------------------------------------------------
--NSpire string extensions
-----------------------------------------------------------------

--(string, start position, length)
function string.usub(s, start, len)
	return string.sub(s, start, len)   --Unicode?
end

function string.uchar(s)
	return window.String.fromCharCode(s)
end

-----------------------------------------------------------------
--NSpire clipboard() table
-----------------------------------------------------------------
clipboard = {}	--clipboard functions are already created, so we need to handle them.
setmetatable(clipboard, { __index = function() end })
clipboard.clipboardData = ""

function clipboard:addText(text)
	clipboard.clipboardData = tostring(text)
end

function clipboard:getText()
	return clipboard.clipboardData
end

function clipboard:copyToSystemClipboard(text)
	window:copyToSystemClipboard(text)
end

function clipboard:sendModuleCompletion(text)
	window:copyToSystemClipboard(text, true)
end

-----------------------------------------------------------------
--NSpire gc() to DOMAPI mapping
-----------------------------------------------------------------

GraphicsContext = class()

function GraphicsContext:init(canvas)
	self.context = canvas:getContext("2d")
	--self.context.setLineDash = nil
	--print("self.context.setLineDash", self.context.setLineDash)
	self.fontsize = 96/72*10
	self.canvas = canvas
	self.fontFamily = "sansserif"
	self.fontStyle = "r"
	self.fontSizeNSpire = 11

	--[[self.clearImg = window.document:createElement("img")	--Handle to the DOMAPI image.
	self.clearImg.src = "clearpx.png"
	self.clearImg.onload = function ( ... )
		-- body
		print( "clearimage load")
	end]]
	self.images = {}
	self.lineStyle = "smooth"
	self.lineStyleValues = {["smooth"] = {0}, ["dotted"] = {2}, ["dashed"] = {5}}
end

function GraphicsContext:setFont(font, style, size)
	local fontFamily, fontStyle, fontSize
	local oldFontFamily = self.fontFamily
	local oldFontStyle = self.fontStyle
	local oldFontSizeNSpire = self.fontSizeNSpire

	self.fontFamily = font
	self.fontStyle = style
	self.fontSizeNSpire = size

	self.fontsize = 96/72 * size	--Convert from pts to px and store this for use by getStringHeight().

	-- "normal 20px Georgia"
	if font == "sansserif" then -- Lynne. Changed, from "sanserif"
		font = "sans-serif"
	end
	if style == "b" then
		style = "bold"
	else
		style = "normal"
	end
	self.context.font = style.." "..tostring(self.fontsize).."px " .. font


	return oldFontFamily, oldFontStyle, oldFontSizeNSpire
end

--The lower left corner of text is at x,y in DOM, but the upper left corner of text is at x,y in NSpire
function GraphicsContext:drawString(s, x, y)
	self.context:fillText(s, x, y+self.fontsize)
end

function GraphicsContext:getStringWidth(s)
	return self.context:measureText(s).width
end

function GraphicsContext:getStringHeight(s)
	-- LYNNE: Modified this from 1.1 to 1.25
	return 1.25*self.fontsize	--Multiplying by 1.1 factors in that the TI seems to have more white space above and below the font.
end

function GraphicsContext:setColorRGB(r, g, b)
	local color = "rgb("..tostring(r)..","..tostring(g)..","..tostring(b)..")"
	self.context.fillStyle = color
	self.context.strokeStyle = color
end

--"thin", "medium" or "thick"
--"smooth", "dotted", "dashed"
function GraphicsContext:setPen(size, style)
	if size == "medium" then
		self.context.lineWidth = "2"
	elseif size == "thick" then
		self.context.lineWidth = "3"
	else
		self.context.lineWidth = "1"
	end
	
	if style == nil then
		self.lineStyle = "smooth"		--defaults to smooth line
	else
		self.lineStyle = style
	end
	
end

function GraphicsContext:drawLine(x1, y1, x2, y2)
	self.context:beginPath()
	self.context:save()
	
	if self.context.setLineDash ~= nil then
		self.context:setLineDash(self.lineStyleValues[self.lineStyle])
	end
	
	if self.lineStyle == "dashed" and self.context.setLineDash == nil then
		local pointArray = self:calcPointsDashedLine(x1, y1, x2, y2)
		self:drawDashedLines(pointArray)
	else
		self.context:moveTo(x1,y1)
		self.context:lineTo(x2,y2)
	end
	
	self.context:stroke()
	self.context:closePath()
	self.context:restore()
end

function GraphicsContext:drawRect(x, y, w, h)
	self.context:beginPath()
	self.context:save()
	
	if self.context.setLineDash ~= nil then
		self.context:setLineDash(self.lineStyleValues[self.lineStyle])
	end
	
	if self.lineStyle == "dashed" and self.context.setLineDash == nil then
		local xRect = {x, x+w}
		local yRect = {y, y+h}
		local pointArray = {}
		
		pointArray[1] = self:calcPointsDashedLine(xRect[1], yRect[1], xRect[1], yRect[2])
		pointArray[2] = self:calcPointsDashedLine(xRect[2], yRect[1], xRect[2], yRect[2])
		pointArray[3] = self:calcPointsDashedLine(xRect[1], yRect[1], xRect[2], yRect[1])
		pointArray[4] = self:calcPointsDashedLine(xRect[1], yRect[2], xRect[2], yRect[2])
		
		for i=1, #pointArray do
			self:drawDashedLines(pointArray[i])
		end
		
		self.context:stroke()
	else
		self.context:strokeRect(x,y,w,h)
	end
	
	self.context:closePath()
	self.context:restore()
end

function GraphicsContext:fillRect(x, y, w, h)
	self.context:beginPath()
	self.context:fillRect(x,y,w,h)
	self.context:closePath()
end

--img from call to Image.new(), x, y
function GraphicsContext:drawImage(img, x, y)

	--Store the new position into the image.  This position will be invalidated if onload is called after this call.
	img.x, img.y = x, y
	img.image.width, img.image.height = img:width(), img:height()
	img.image.alt = img.name

	if img.image.complete == true and img.image.didComplete == true then -- the image has completed loading/downloading, the only time to draw.
		-- start draw process
		local context = self.context

		context:save() -- save canvas

		local sfw = img.sfw - 1
		local sfh = img.sfh - 1

		-- move the top left
		local originalBoundingBoxWidth, originalBoundingBoxHeight = ndlinkUtils:calculateBoundingBox( img.scaledNaturalWidth, img.scaledNaturalHeight, img.rotation )
		x = x + ( originalBoundingBoxWidth ) * 0.5 - img.scaledNaturalWidth * 0.5
		y = y + ( originalBoundingBoxHeight ) * 0.5 - img.scaledNaturalHeight * 0.5

		-- translate position for canvas
		local translateX = x + img.scaledNaturalWidth * 0.5
		local translateY = y + img.scaledNaturalHeight * 0.5

		-- scale the canvas based on the change of width and height of the bounding box
		context:setTransform( img.sfw, 0, 0, img.sfh, -( img.x * sfw ), -( img.y * sfh ))

		-- translate and rotate the canvas
		context:translate( translateX, translateY )
		context:rotate( math.rad( -img.rotation ))
		context:translate( -translateX, -translateY ) -- translate the canvas back

		-- draw the image
		context:drawImage( img.image, x, y, img.scaledNaturalWidth, img.scaledNaturalHeight )

		--context:resetTransform()

		-- restore the canvas
		context:restore()
	else
		-- the image is not complete or the image did not complete or had an error.
		-- 1. Use fillrect instead.
		--self:fillRect( x, y, img:width(), img:height() )

		-- 2. Text
		--[[print( img.name )

		local oldFontFamily, oldFontStyle, oldFontSizeNSpire = self:setFont( "sansserif", "r", 8 )
		self:drawString( img.name, x, y )
		self:setFont( oldFontFamily, oldFontStyle, oldFontSizeNSpire )]]

		-- 3. Do nothing
	end
end

--Renders the offscreen context into the canvas
function GraphicsContext:renderImage(canvas, x, y)
	self.context:drawImage(canvas, x, y)
end

function GraphicsContext:fillPolygon(points)
	self.context:beginPath()
	self.context:moveTo(points[1], points[2])
	for i=3,#points,2 do
		self.context:lineTo(points[i], points[i+1])
	end
	self.context:closePath()
	self.context:fill()
end

function GraphicsContext:drawPolyLine(points)
	self.context:beginPath()
	self.context:save()
	
	if self.context.setLineDash ~= nil then
		self.context:setLineDash(self.lineStyleValues[self.lineStyle])
	end
	
	if self.lineStyle == "dashed" and self.context.setLineDash == nil then
		local j
		local pointArray = {}
		pointArray[1] = self:calcPointsDashedLine(points[1], points[2], points[3], points[4])
		j = 2
		
		for i=3, #points, 2 do
			if i+2 < #points then
				pointArray[j] = self:calcPointsDashedLine(points[i], points[i+1], points[i+2], points[i+3])
				j = j + 1
			end
		end
		
		for i=1, #pointArray do
			self:drawDashedLines(pointArray[i])
		end
		
		self.context:stroke()
	else
		self.context:moveTo(points[1], points[2])
		for i=3,#points,2 do
			self.context:lineTo(points[i], points[i+1])
		end
	end
	
	--self.context:closePath()
	self.context:restore()
	self.context:stroke()
end

--x/y in Nspire is upper left corner.  In DOM, x/y are center of circle.
--w/h are diameters in NSpire.  For DOM, we can only use one radius, so we'll use w and divide by 2.
--sA,eA are start angle and turn angle.  (Nspire docs say end angle, but really it's turn angle)
--NSpire angles are degrees.  DOM angles are radians.
--NSpire default is counterclockwise.  If tA >= 0 then turn clockwise, else turn counterclockwise.
function GraphicsContext:fillArc(x, y, w, h, sA, tA)
	--self.context:beginPath()
	--self.context:moveTo(x+w/2, y+h/2)
	--self.context:arc(x+w/2,y+h/2,w/2,(-sA)*math.pi/180,(-sA+-tA)*math.pi/180, (tA >= 0))
	--self.context:lineTo(x+w/2, y+h/2)
	--self.context:closePath()
	--self.context:fill()


        self.context:save() 		-- save state
        self.context:beginPath()
		self.context:moveTo(x+w/2, y+h/2)

        self.context:translate((x+w/2)-(w/2), (y+h/2)-(h/2))
        self.context:scale(w/2, h/2);
        self.context:arc(1, 1, 1, (-sA)*math.pi/180, (-sA+-tA)*math.pi/180, (tA >= 0))

        self.context:restore() 	-- restore to original state
		self.context:lineTo(x+w/2, y+h/2)
		self.context:closePath()
		self.context:fill()

--[[
	function ellipse(context, cx, cy, rx, ry){
        context.save(); // save state
        context.beginPath();

        context.translate(cx-rx, cy-ry);
        context.scale(rx, ry);
        context.arc(1, 1, 1, 0, 2 * Math.PI, false);

        context.restore(); // restore to original state
        context.stroke();
	}
--]]
end

function GraphicsContext:drawArc(x, y, w, h, sA, tA)
	--self.context:beginPath()
	--self.context:arc(x+w/2,y+h/2,w/2,(-sA)*math.pi/180,(-sA+-tA)*math.pi/180, (tA >= 0))
	--self.context:stroke()

		self.context:save() 		-- save state
		self.context:beginPath()
		
		if self.lineStyle == "dashed" then
			local pointArray = self:calcPointsDashedArc(x+.5*w, y+.5*h, w, h, sA, tA)
			self:drawDashedLines(pointArray)
		else
			self.context:translate((x+w/2)-(w/2), (y+h/2)-(h/2))
			self.context:scale(w/2, h/2);
			self.context:arc(1, 1, 1, (-sA)*math.pi/180, (-sA+-tA)*math.pi/180, (tA >= 0))
		end
		
		self.context:restore()		-- restore to original state
		self.context:stroke()
		self.context:closePath()
end

function GraphicsContext:drawDashedLines(pointsArray)
	for i=1, #pointsArray do
		self.context:moveTo(pointsArray[i].x, pointsArray[i].y)
		self.context:lineTo(pointsArray[i].ex, pointsArray[i].ey)
	end
end

function GraphicsContext:clipRect(op, x, y, w, h)
	if op == "set" then
		self.context:save()
		self.context:beginPath()
		self.context:rect(x, y, w, h)
		self.context:clip()
		self.context:closePath()
	elseif op == "reset" then
		self.context:restore()
	end
end

function GraphicsContext:clear( x, y, w, h )
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if w == nil then w = onscreenCanvas.width end
	if h == nil then h = onscreenCanvas.height end

	self.context:clearRect(x, y, w, h);
end

--preLoadImages is not part of NSpire gc
-- predownload all images needed.
local imageCounter = 0 -- NOTE: the number of images to load is counted on setupImageResources
local imageTimeout = 8000
local hasImageTimeoutPassed = false

function GraphicsContext:preLoadImages( callback )
	if setupImageResources and numberOfImagesToLoad == 0 then
		if _R.IMG.images then
			for i,v in pairs(_R.IMG.images) do
				numberOfImagesToLoad = numberOfImagesToLoad + 1
			end
		end
	end

	if _R.IMG.images then
		for i,v in pairs(_R.IMG.images) do
			self.images[v] = self:copyImage( v, callback )
		end
	end

	-- we are putting an 8-second limit.
	-- past this, we need to let all the other images that hasn't loaded yet know that it shouldn't continue retrying.
	imageTimeout = window:setTimeout( function()
		hasImageTimeoutPassed = true -- flag that will be used by the image's event errors
	end, imageTimeout )
end

--copyImage is not part of NSpire gc
-- Copy an image object.
function GraphicsContext:copyImage( resource, callback )
	local obj = {}
	setmetatable(obj, { __index = image }) -- base table added to tell Lua how to access the image() methods.

	if self.images[resource] and self.images[resource].image.didComplete == true then
		obj.image = self.images[resource].image
	else
		self:createImgElement( resource, obj, callback )
	end

	obj.name = _R.IMG.name[ resource ] or resource
	obj.imageSrcName = resource				-- Filename of the image without the URL
	obj.imageLoaded = true
	obj.rotation = 0						-- Amount of rotation in degrees
	obj.x = 0
	obj.y = 0
	obj.sfw = 1 						-- scale factor of the width, for the setTransform inside the drawImage
	obj.sfh = 1 						-- scale factor of the height for the setTransform inside the drawImage
	obj.parent = nil					-- If additional images are copied, then this property will point to the first image created.

	-- We don't know the natural width and height yet so we rely on resource file
	obj.naturalWidth = _R.IMG.width[ resource ]
	obj.naturalHeight = _R.IMG.height[ resource ]

	obj.ratio = obj.naturalWidth / obj.naturalHeight

	-- Two lines below will store width and height from copy function
	obj.scaledNaturalWidth = obj.naturalWidth
	obj.scaledNaturalHeight = obj.naturalHeight

	-- The line below will store current width and height
	obj.boundingBoxWidth, obj.boundingBoxHeight = obj.naturalWidth, obj.naturalHeight

	return obj
end

function GraphicsContext:createImgElement( resource, obj, callback )
	local errorWaitTime = window.IMAGE_WAIT_TIME or 5000		--wait time for image loading error
	local imageElem = window.document:createElement("img")	--Handle to the DOMAPI image.
	local timeout
	local abortImage = function() -- this sets the image to figure
		imageElem.onload = nil
		imageElem.onerror = nil
		imageElem.onabort = nil
		obj.imageLoaded = false
	end

	--?L not sure if this is still needed. FOR REVIEW
	local addTimeout = function() -- timeout for when we use the URL of the image
		-- after first srcing, start the timeout for the image
		timeout = window:setTimeout( function()
			-- if it goes here, it means that the image loading has already exceeded the wait time.

			abortImage()

			if platform.window.invalidate and on and on.paint then -- invalidate only when the function is available
				platform.window:invalidate( obj.x, obj.y, obj.naturalWidth, obj.naturalHeight ) --?L
			end

		end, errorWaitTime );
	end

	local retryOnImageError = function()
		-- re-do the src-ing
		imageElem.didComplete = false
		
		local strWrongPath = "";

		if window.DEBUG_IMAGE_ERROR and window.DEBUG_IMAGE_ERROR == true then
			strWrongPath = "/wrongpath/"
		end
		
		if _R.IMG.URL and _R.IMG.URL[resource] then
			imageElem.src = strWrongPath .. _R.IMG.URL[resource]..resource					-- Filename of the image, including URL
		else
			imageElem.src = strWrongPath .. resource
		end
	end

	imageElem.onload = function(...)
		if( timeout ) then window:clearTimeout( timeout ); end -- stop the timeout for image error

		imageElem.onload = nil 
		imageElem.didComplete = true
		obj.imageLoaded = true

		imageCounter = imageCounter + 1

		if imageCounter == numberOfImagesToLoad then -- all images are done loading/possibly broken/reached set timeout.
			if( imageTimeout ) then window:clearTimeout( imageTimeout ); end -- stop the timeout for image error

			callback()
		end

		--[[if platform.window.invalidate and on and on.paint then -- invalidate only when the function is available
			platform.window:invalidate( obj.x, obj.y, obj.naturalWidth, obj.naturalHeight ) --?L
		end]]
	end
	
	imageElem.onabort = function(...)
		if hasImageTimeoutPassed then -- if it goes here, it means that the image loading has already exceeded the wait time.
			imageCounter = imageCounter + 1

			abortImage()

			if imageCounter == numberOfImagesToLoad then -- all images are done loading/possibly broken/reached set timeout.
				if( imageTimeout ) then window:clearTimeout( imageTimeout ); end -- stop the timeout for image error
				callback()
			end
		else retryOnImageError()
		end
		
	end
	
	imageElem.onerror = function(...)
		if hasImageTimeoutPassed then -- if it goes here, it means that the image loading has already exceeded the wait time.
			imageCounter = imageCounter + 1

			abortImage()

			if imageCounter == numberOfImagesToLoad then -- all images are done loading/possibly broken/reached set timeout.
				if( imageTimeout ) then window:clearTimeout( imageTimeout ); end -- stop the timeout for image error
				callback()
			end
		else retryOnImageError()
		end
	end

	-- add the file's src
	local strWrongPath = "";

	if window.DEBUG_IMAGE_ERROR and window.DEBUG_IMAGE_ERROR == true then
		strWrongPath = "/wrongpath/"
	end
	
	-- we are starting with this.
	if _R.IMG.URL and _R.IMG.URL[resource] then -- base64 is not available. load this one instead.
		imageSource = "url"
		imageElem.src = strWrongPath .._R.IMG.URL[resource]..resource					-- Filename of the image, including URL

		--addTimeout() --?L
	else
		imageSource = "resource"
		imageElem.src = strWrongPath ..resource

		--addTimeout() --?L
	end
	
	obj.image = imageElem
end

function GraphicsContext:calcPointsDashedLine(x1, y1, x2, y2)
	local points = {} 
	
	if x1 == x2 and y1 == y2 then
		table.insert(points, {["x"] = x1, ["y"] = y1, ["ex"] = x2, ["ey"] = y2})
	elseif x1 == x2 then
		points = self:computePointsVerticalLine(x1, y1, x2, y2)
	else
		points = self:computePoints(x1, y1, x2, y2)
	end
	
	return points
end

function GraphicsContext:computePointsVerticalLine(x1, y1, x2, y2)
	local m = 0		--slope
	local increment = 5 
	local hideSegment = false
	local points = {}
	local startX, endX = x1, x2
	local startY, endY = y1, y2
	if y1 > y2 then 
		startX, endX = x2, x1 
		startY, endY = y2, y1
	end
	
	for i =	startY, endY, increment do
		if hideSegment == false then
			local ey = i+increment
			
			table.insert(points, {["x"] = startX, ["y"] = i, ["ex"] = endX, ["ey"] = ey})
		end
		
		i = i + increment
		hideSegment = not hideSegment
	end
	
	if #points > 0 then points = self:checkEndPts(points, m, endX, endY) end
	
	return points
end

function GraphicsContext:computePoints(x1, y1, x2, y2)
	local points = {}
	local increment = 5 
	local hideSegment = false
	local m = (y2 - y1)/(x2 - x1)		--slope
	local b = y1 - m*x1		--intercept
	local startX, endX = x1, x2
	local startY, endY = y1, y2
	if x1 > x2 then 
		startX, endX = x2, x1 
		startY, endY = y2, y1
	end
	
	for i =	startX, endX, increment do
		if hideSegment == false then
			local sy = m*i + b
			local ex = i+increment
			local ey = m*ex + b
			
			table.insert(points, {["x"] = i, ["y"] = sy, ["ex"] = ex, ["ey"] = ey})
		end
		
		i = i + increment
		hideSegment = not hideSegment
	end
	
	if #points > 0 then points = self:checkEndPts(points, m, endX, endY, b) end
	
	return points
end

function GraphicsContext:checkEndPts(pointsArray, m, endX, endY, b)
	--use the negative value because y position in lua goes from top to bottom
	if -m > 0 then 		--line leans to the right
		pointsArray[#pointsArray].ex = math.min(pointsArray[#pointsArray].ex, endX)
		pointsArray[#pointsArray].ey = math.max(pointsArray[#pointsArray].ey, m*pointsArray[#pointsArray].ex + b)
	elseif m == 0 then		--vertical
		pointsArray[#pointsArray].ex = math.min(pointsArray[#pointsArray].ex, endX)
		pointsArray[#pointsArray].ey = math.min(pointsArray[#pointsArray].ey, endY)
	else		--line leans to the left
		pointsArray[#pointsArray].ex = math.min(pointsArray[#pointsArray].ex, endX)
		pointsArray[#pointsArray].ey = math.min(pointsArray[#pointsArray].ey, m*pointsArray[#pointsArray].ex + b)
	end
	
	return pointsArray
end

--calculate points for dashed arc
function GraphicsContext:calcPointsDashedArc(cx, cy, w, h, sA, tA)
	if sA >= 0 and tA < 0 then 
		sA = sA + tA
		
		if sA < 0 then
			sA = sA + 360
		end
		
		tA = math.abs(tA)
	elseif sA < 0 and tA < 0 then 
		sA = sA + 360 + tA
		tA = math.abs(tA)
	elseif sA < 0 and tA > 0 then 
		sA = sA + 360
	end
	
	local dashLength = .5
	local radiusW, radiusH = .5*w, .5*h
	local n = radiusW/dashLength
	local alpha = 2 * math.pi / n
	local points = {}
	local startAngle = math.rad(sA)
	local i = startAngle/alpha	
	local theta, theta2 = 0, 0
	local endAngle = sA + math.abs(tA) 
	
	while math.deg(theta2) < endAngle do
		theta = alpha * i
		theta2 = math.min( alpha * (i+1), math.rad(endAngle) )
		if theta == theta2 then theta = math.rad(endAngle-3) end
		
		table.insert(points, {["x"] = radiusW * math.cos(theta) + cx, ["y"] = -radiusH * math.sin(theta) + cy, ["ex"] = radiusW * math.cos(theta2) + cx, ["ey"] = -radiusH * math.sin(theta2) + cy})
		i = i + 2
	end
	
	return points
end

-----------------------------------------------------------------
-- user
-- connects to the database to get user and module details 
-----------------------------------------------------------------
user = {}
setmetatable(user, { __index = function() end })

-- returns a table that has details of user's completion on a module.
function user:getModuleCompletion()
	if window.getModuleDetails then -- only use the function if the version of the module will detect this function 
		return window:getModuleDetails() 
	end

	return
end

-- values is a table
function user:setModuleCompletion( values )
	if window.updateCompletion then -- only use the function if the version of the module will detect this function
		window:updateCompletion( values ) 
	end
end

function user:getData()
	local dataTbl = {}
	local count = 0

	local moduleData = self:getModuleCompletion()
	if moduleData then dataTbl["moduleData"] = self:getModuleCompletion(); count = count + 1; end
	
	if window.isUserPaid then dataTbl["isAuthorized"] = window:isUserPaid(); count = count + 1; end
	if window.goToAProblem then dataTbl["goToLearnProblem"] = window:goToAProblem(); count = count + 1; end
	if window.getSelectedMode then dataTbl["selectedMode"] = window:getSelectedMode(); count = count + 1; end
	if window.getGuestDialogMessage then dataTbl["guestMessage"] = window:getGuestDialogMessage(); count = count + 1; end
	if window.getDailySkillCompletion then dataTbl["dailySkill"] = window:getDailySkillCompletion(); count = count + 1; end

	if count > 0 then
		return dataTbl
	else
		return
	end
end

function user:requestLogIn()
	if window.requestLogIn then -- only use the function if the version of the module will detect this function
		window:requestLogIn() 
	end
end

function user:setDailySkillCompletion(timeCompleted, score, totalProblems, hintsCounter)
	if window.setDailySkillCompletion then -- only use the function if the version of the module will detect this function
		window:setDailySkillCompletion(timeCompleted, score, totalProblems, hintsCounter)
	end
end

local isModuleReady = false
-----------------------------------------------------------------
--NSpire Event Loop
-----------------------------------------------------------------
ndlink = class()

function ndlink:start()
	print( "ndlink version = docs" )

	onscreenCanvas = window.document:getElementById("myCanvas")
	onscreenCanvas.style.marginLeft = onscreenCanvas.marginLeft
	onscreenCanvas.style.offsetTop = onscreenCanvas.offsetTop
	--window.document.body:appendChild(onscreenCanvas)

	window.onkeydown = function(e) self:keydown(e) end
	window.onkeypress = function(e) self:keypress(e) end

	onscreenCanvas:addEventListener( "resize", function( e ) 
		self:resize( e ); 
		ndPaint(); -- there's a need to call ndPaint to avoid the white space while resizing the window
	end )

	window.onresize = function(e) 
		self:resize(e) 
		ndPaint(); -- there's a need to call ndPaint to avoid the white space while resizing the window
	end

	-- event binding
	-- PointEvent will be used if the browser supports PointEvent because of the Edge touch on touchscreen laptop
	if( window.PointerEvent ) then -- this browser supports PointEvent
		onscreenCanvas:addEventListener( "pointerdown", function( e ) self:pointerDown( e ) end )
		window:addEventListener( "pointermove", function( e ) self:pointerMove( e ) end )
		onscreenCanvas:addEventListener( "pointerup", function( e ) self:pointerUp( e ) end )
		onscreenCanvas:addEventListener( "pointercancel", function( e ) self:pointerCancel( e ) end )
		onscreenCanvas:addEventListener( "pointerover", function( e ) self:pointerOver( e ) end )
		onscreenCanvas:addEventListener( "pointerenter", function( e ) self:pointerEnter( e ) end )
		onscreenCanvas:addEventListener( "pointerout", function( e ) self:pointerOut( e ) end )
		onscreenCanvas:addEventListener( "pointerleave", function( e ) self:pointerLeave( e ) end )
		onscreenCanvas:addEventListener( "gotpointercapture", function( e ) self:gotPointerCapture( e ) end )
		onscreenCanvas:addEventListener( "lostpointercapture", function( e ) self:lostPointerCapture( e ) end )

	else -- no PointEvent, bind normally
		-- mouse events
		onscreenCanvas:addEventListener( "mousedown", function(e) self:mousedown(e) end )
		onscreenCanvas:addEventListener( "mouseup", function(e) self:mouseup(e) end )
		window:addEventListener( "mousemove", function(e) self:mousemove(e) end )

		-- touch events
		onscreenCanvas:addEventListener( "touchstart", function(e) self:touchstart(e) end, { passive = false })
		onscreenCanvas:addEventListener( "touchend", function(e) self:touchend(e) end, { passive = false })
		window:addEventListener( "touchmove", function(e) self:touchmove(e) end, { passive = false })

		onscreenCanvas:addEventListener( "touchcancel", function(e) self:touchcancel(e) end, { passive = false })
	end

	gc = GraphicsContext(onscreenCanvas)
	
	local startOnEvents = function()

		local userData = user:getData()

		-- open document sequence chart based on Texas Instruments guide
		----------------------------------------------------------------

		if on.construction then -- on.construction is only for API Level > 1.0
			on.construction( userData )
		end

		if on.restore then -- uses state table when on.save is used
			-- on.restore( userData ) --(unsupported) If we ever use this, please put the state table on the userData table
		end

		self:resize() -- use our own resize instead of on.resize

		if on.activate then
			on.activate()
		end

		if on.getFocus then
			on.getFocus()
		end

		if on.create then -- on.create() is only for API Level == 1.0
			-- on.create() --(unsupported)
		end

		ndPaint() -- use our own paint instead of on.paint

		onscreenCanvas:focus() -- put the focus on the canvas
		
		isModuleReady = true
	end
	
	gc:preLoadImages( startOnEvents )		--Preload any images for performance.


	

	----------------------------------------------------------------
end

ndTimerCounter = 0	--This is used to track the time between a touchstart and mousedown used on Android Chrome
function ndlink:mousedown(e)
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	local x = e.clientX - tonumber(marginLeft)
	local y = e.clientY - tonumber(marginTop)

	--Only allow the mousedown() if it's been at least 5 seconds since touchstart.  This way we can ignore the Android Chrome forced mousedown()
	if (timer.getMilliSecCounter() - ndTimerCounter > 5000) or ndTimerCounter == -1 then
		if isModuleReady then on.mouseDown(x, y) end		--Make sure on.mouseDown is ready to receive events; on event handlers are not yet ready while the module is still loading.
		ndTimerCounter = 0
	else
	ndTimerCounter = -1	--Tell this function that now that we've ignored the first mousedown, we can hopefully safely take the next one.
	end
end

function ndlink:mouseup(e)
	local x, y
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	x = e.clientX - tonumber(marginLeft)
	y = e.clientY - tonumber(marginTop)
	if isModuleReady then on.mouseUp(x, y) end	--Make sure on.mouseUp is ready to receive events; on event handlers are not yet ready while the module is still loading.
end

function ndlink:mousemove(e)
	e:preventDefault()

	local x, y
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	x = e.clientX - tonumber(marginLeft)
	y = e.clientY - tonumber(marginTop)
	if x <= onscreenCanvas.width and y <= onscreenCanvas.height then
		if isModuleReady then on.mouseMove(x, y) end	--Make sure on.mouseMove is ready to receive events; on event handlers are not yet ready while the module is still loading.
	end
end

function ontouchstart(x,y)
	ndTimerCounter = timer.getMilliSecCounter()
	if isModuleReady then on.touchStart(x,y) end	--Make sure on.touchStart is ready to receive events; on event handlers are not yet ready while the module is still loading.
end

function ndlink:touchstart(e)
	local x, y
	e:preventDefault() --This is needed to stop Android Chrome from calling a mousedown() event (doesn't seem to work properly).
	local touch = e.touches[0]
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"

	x = touch.pageX - tonumber(marginLeft) y = touch.pageY - tonumber(marginTop)
	ontouchstart(x, y)
end

function ndlink:touchend(e)
	e:preventDefault()
	local x, y
	local touch = e.changedTouches[0]
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	if touch.pageX ~= nil then
		x = touch.pageX - tonumber(marginLeft) y = touch.pageY - tonumber(marginTop)
	else
		x = 1 y = 1
	end
	if isModuleReady then on.mouseUp(x, y) end	--Make sure on.mouseUp is ready to receive events; on event handlers are not yet ready while the module is still loading.
end

function ndlink:touchcancel(e)
	local x, y
	local touch = e.changedTouches[0]
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	if touch.pageX ~= nil then
		x = touch.pageX - tonumber(marginLeft) y = touch.pageY - tonumber(marginTop)
	else
		x = 1 y = 1
	end
	if isModuleReady then on.mouseUp(x, y) end	--Make sure on.mouseUp is ready to receive events; on event handlers are not yet ready while the module is still loading.
end

function ndlink:touchmove(e)
	e:preventDefault()
	local touch = e.touches[0]
	local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
	local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
	local x = touch.pageX - tonumber(marginLeft)
	local y = touch.pageY - tonumber(marginTop)
	if isModuleReady then on.mouseMove(x, y) end	--Make sure on.mouseMove is ready to receive events; on event handlers are not yet ready while the module is still loading.
end

function ndlink:keydown(e)
	local kc = e.keyCode

	--Don't add window.event:preventDefault() here because it will stop keypress()
	if kc == 8 then
		e:preventDefault()	--We are handling this key, so stop the browser from handling it.
		on.backspaceKey()
	elseif kc == 9 then
		e:preventDefault()
		if e.shiftKey == true then
			on.backtabKey()
		else
			on.tabKey()
		end
	elseif kc == 13 then
		e:preventDefault()
		on.enterKey()
	elseif kc == 27 then
		e:preventDefault()
		on.escapeKey()
	elseif kc == 37 then
		e:preventDefault()
		if e.shiftKey == true then
			if on.shiftArrowLeft then on.shiftArrowLeft() end
		else
			on.arrowLeft()
		end
	elseif kc == 38 then
		e:preventDefault()
		on.arrowUp()
	elseif kc == 39 then
		e:preventDefault()
		if e.shiftKey == true then
			if on.shiftArrowRight then on.shiftArrowRight() end
		else
			on.arrowRight()
		end
	elseif kc == 40 then
		e:preventDefault()
		on.arrowDown()
	elseif e.ctrlKey and kc == 88 then
		e:preventDefault()
		if on.cut then on.cut() end
	elseif e.ctrlKey and kc == 67 then
		e:preventDefault()
		if on.copy then on.copy() end
	elseif e.ctrlKey and kc == 86 then
		e:preventDefault()
		if on.paste then on.paste() end
	elseif kc == 35 then
		e:preventDefault()
		if on.endKey then on.endKey() end
	elseif kc == 36 then
		e:preventDefault()
		if on.homeKey then on.homeKey() end
	elseif kc == 46 then
		e:preventDefault()
		if on.deleteKey then on.deleteKey() end
	--[[elseif kc == 190 then -- dot for dbgevents
		e:preventDefault()
		print( "DELETE PRINTS")
		dbgEvents = {}
		dbgCounter = 0
		ndPaint()]]
	end
end

function ndlink:keypress(e)

	--elseif kc >= 48 then
	--	on.charIn(string.char(kc))
	--window.extract()
	--print("keypress", window.event.keyCode, window.event.charCode)
	--local s = window.String.new("abc")
	--print("code at", s:charCodeAt(1))
	--print("static", window.String.fromCharCode(window.String, 65))
	--print("s=", s, s.length)
	--print("code=", s.fromCharCode(window.event.charCode))
	--if window.event.which == nil then
		--print ("char", canvas.String:fromCharCode(window.event.keyCode)) -- IE
	--elseif (window.event.which ~= 0 and window.event.charCode ~= 0) then
		--print("char2", window.document.String:fromCharCode(window.event.which))   -- the rest
	--	on.charIn(string.char(window.event.which))
	--else
	--	--print("char3 special key nil")	--special key
	--end

	if e.which == nil then
	elseif (e.which ~= 0 and e.charCode ~= 0) then
		on.charIn(string.char(e.which))
	else
	end
end

function ndlink:pointerDown(e)
	e:preventDefault() 
	local pointerType = e.pointerType

	if pointerType == "mouse" or pointerType == "pen" then -- mouse/pen input is detected
		self:mousedown(e)
	elseif pointerType == "touch" then -- touch input is detected
		if e.isPrimary then
			local x, y
			local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
			local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
			x = e.pageX - tonumber(marginLeft) 
			y = e.pageY - tonumber(marginTop)

			ontouchstart(x, y)
		end
	else
		print( "pointerType", pointerType )
	end
end

function ndlink:pointerMove( e )
	e:preventDefault()
	local pointerType = e.pointerType

	if pointerType == "mouse" or pointerType == "pen" then -- mouse/pen input is detected
		self:mousemove(e)
	elseif pointerType == "touch" then -- touch input is detected
		if e.isPrimary then
			local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
			local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
			local x = e.pageX - tonumber(marginLeft)
			local y = e.pageY - tonumber(marginTop)
			if isModuleReady then on.mouseMove(x, y) end	--Make sure on.mouseMove is ready to receive events; on event handlers are not yet ready while the module is still loading.
		end
	else
		print( "pointerType", pointerType )
	end
end

function ndlink:pointerCancel( e )
	e:preventDefault()

	if pointerType == "touch" then -- touch input is detected
		self:pointerUp( e )
	end
end

function ndlink:pointerUp( e )
	local pointerType = e.pointerType

	if pointerType == "mouse" or pointerType == "pen" then -- mouse/pen input is detected
		self:mouseup(e)
	elseif pointerType == "touch" then
		if e.isPrimary then
			local x, y
			local marginLeft = string.gsub(onscreenCanvas.marginLeft, "px", "")	--Remove the "px"
			local marginTop = string.gsub(onscreenCanvas.offsetTop, "px", "")	--Remove the "px"
			if e.pageX ~= nil then
				x = e.pageX - tonumber(marginLeft) y = e.pageY - tonumber(marginTop)
			else
				x = 1 y = 1
			end
			if isModuleReady then on.mouseUp(x, y) end	--Make sure on.mouseUp is ready to receive events; on event handlers are not yet ready while the module is still loading.
		
		end
	end
end

function ndlink:pointerOver( e ) e:preventDefault() end
function ndlink:pointerEnter( e ) e:preventDefault() end
function ndlink:pointerOut( e ) e:preventDefault() end
function ndlink:pointerLeave( e ) e:preventDefault() end
function ndlink:gotPointerCapture( e ) e:preventDefault() end
function ndlink:lostPointerCapture( e ) e:preventDefault() end

function ndlink:resize()
	-- print( onscreenCanvas.width, onscreenCanvas.height )
	--onscreenCanvas.height = .95 * window.innerHeight	--Take 95% of the window height because otherwise we seem to get a scroll bar.
	--onscreenCanvas.width = .95 * window.innerWidth

	if on.resize then
		on.resize(onscreenCanvas.width, onscreenCanvas.height)
	end

	gc:clear(0, 0, onscreenCanvas.width, onscreenCanvas.height );
	--on.paint(gc) -- removed on.paint to align with the open sequence of TI
end