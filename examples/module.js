var vm = new shine.VM(shine.DOMAPI);
var isModuleLoaded = false;

function loadModule(){
	vm.load( "./module_init.lua.json" );
}

function getFilePath() {
	return sessionStorage.getItem( "modulePath" );
}

function getNdlinkFileName() {
    return "ndlink";
}

function getImageResourceDetails() {
    return JSON.parse( sessionStorage.getItem( "imgResources" ) );
}

function getGuestDialogMessage(){
	var allMessageData = JSON.parse( sessionStorage.getItem("guestMessage") ),
	    moduleType = sessionStorage.getItem("moduleType"); 
	var msg = {1: "", 2: ""};
	
	if( allMessageData && allMessageData.guestNoAccessMessage ){       //guest message file is successfully obtained from server
	    if( moduleType == "regular" ){
	        msg = {1: allMessageData.guestNoAccessMessage.regular[0], 2: allMessageData.guestNoAccessMessage.regular[1]};
	    } else {
	        msg = {1: allMessageData.guestNoAccessMessage.exam[0], 2: allMessageData.guestNoAccessMessage.exam[1]};
	    }
	} else {
	    msg = {1: "Cannot continue with this", 2: "module."};
	}

	return msg;
}

function afterFileLoad() {
    isModuleLoaded = true;
}

function isAndroid(){
	return window.navigator.userAgent.indexOf( "Android" ) > -1
}

function isIphone(){
	return window.navigator.userAgent.indexOf( "iPhone" ) > -1
}

var clipboardStr;

function copyToSystemClipboard(str, isModuleCompletionData){
    var isDeviceWithIpadIndicator = ( window.navigator.userAgent.indexOf("iPad") > -1 ),
			isIphone = ( window.navigator.userAgent.indexOf("iPhone") > -1 ),
			isAndroid = ( window.navigator.userAgent.indexOf("Android") > -1 ),
			isBrowserWithoutIpadIndicator = ( isDeviceIpad( screen.width, screen.height ) && window.navigator.userAgent.indexOf("Macintosh") > -1 );    //to handle iPad browsers that don't have iPad indicator in userAgent
	var isIpad = ( isDeviceWithIpadIndicator || isBrowserWithoutIpadIndicator );
	var today = new Date();

	if( isModuleCompletionData ){
	    var moduleEmoji = "";
	    var moduleId = sessionStorage.getItem("moduleId");
	    var ver;
	    
	    if( moduleEmojis[ moduleId ] != null ){
	        moduleEmoji = moduleEmojis[ moduleId ];
	        
	        if( isIphone || isIpad ){
    	        ver = iOSversion();
	        
    	        if( (ver == null || ver[0] < 14) && moduleId == "7-21-4" ){      //Fly emoji is not present in this iOS version. Replace with dragon emoji.    
    	            moduleEmoji = "\uD83D\uDC32";
    	        }
	        } else if( isAndroid ) {
	            ver = androidV();
	            
	            if( ver < 11 && moduleId == "7-21-4" ){      //Fly emoji is not present in this iOS version. Replace with dragon emoji.
	                moduleEmoji = "\uD83D\uDC32";
	            }
	        }
	    } 
	    
	    str = "Emerald Wave\n" + moduleEmoji + "\n" + str;
    	str += "\n" + today.toDateString();
	}

    if( isIpad ){
        var modal = document.getElementById("myModal");
        modal.style.display = "block";
        
        var span = document.getElementsByClassName("close")[0];
        
        span.onclick = function() {
            modal.style.display = "none";
        }
        
        clipboardStr = str;
        
	} else if( isIphone ){

        if( navigator.share ){
        	//iPhone solution
            const shareData = {
                text: str,
            }
        	
        	navigator.share(shareData).then(function(){
        	    alert("Copied results to clipboard.");
        	}, function(e){
        	    if( e.code != 20 ){ //Don't show error when user just closed the share menu.
        	        alert(e);
        	    }
        	});
        } else {
            var modal = document.getElementById("myModal");
            modal.style.display = "block";
            
            var span = document.getElementsByClassName("close")[0];
            
            span.onclick = function() {
              modal.style.display = "none";
            }
            
            clipboardStr = str;
        }
        
        
	} else {

    	navigator.clipboard.writeText(str).then(function() {
    		// clipboard successfully set
    		alert("Copied results to clipboard.");
    	}, function(e) {
    		// clipboard write failed
    		console.log("clipboard write failed " + e);
    		alert("clipboard write failed " + e);
    	});
	}
}

function iOSversion() {
    if (/iP(hone|od|ad)/.test(navigator.platform)) {
        var v = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/);
        
        if( v != null ){
            return [parseInt(v[1], 10), parseInt(v[2], 10), parseInt(v[3] || 0, 10)];
        } else {
            return;
        }
    }
}

function androidV(ua) {
    ua = (ua || navigator.userAgent).toLowerCase(); 
    var match = ua.match(/android\s([0-9\.]*)/i);
    return match ? match[1] : undefined;
};

function setModuleValues() {
	var moduleName = "EWFramework";	
	
	addModuleImageResources();
	sessionStorage.setItem( "modulePath", moduleName );
}

function addModuleImageResources(){
	var imgArray = [
		{ "name": "hourglass", "fileSrc": "../images/hourglass.png", "width": 128, "height": 256 },
		{ "name": "clipboardicon", "fileSrc": "../images/clipboardicon.png", "width": 200, "height": 200 },
		{ "name": "yellowarrow", "fileSrc": "../images/yellow_arrow.png", "width": 225, "height": 299 },
	];
	
	sessionStorage.setItem( "imgResources", JSON.stringify(imgArray) );
}