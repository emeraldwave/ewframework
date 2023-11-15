function createLinkTag( elem, onclickFunc, linkName, params, linkId ) {
	var a = document.createElement( "a" ),
		node = document.createTextNode( linkName )
		attrs = { "href": "#", "id": linkId };
		
	if( linkId == "" || linkId == null ) {
		attrs = { "href": "#" };
	}
		
	setAttributes( a, attrs );
	a.appendChild( node );
	a.onclick = function( e ){
		onclickFunc( params[0], params[1], params[2], params[3], params[4] );
	};
	
	if( elem ) {
		elem.appendChild( a );
	}
	
	return a;
}

function createButtonTag( elem, onclickFunc, buttonName, params, buttonId ){
    var btn = document.createElement( "button" ),
		node = document.createTextNode( buttonName )
		attrs = {};
		
	if( buttonId ) {
		attrs.id = buttonId;
	}
		
	setAttributes( btn, attrs );
	btn.appendChild( node );
	
	if( elem ) {
		elem.appendChild( btn );
	}
	
	btn.onclick = function( e ){
		onclickFunc( params[0], params[1], params[2], params[3], params[4], params[5] );
	};
	
	return btn;
}

function createDivTag( divId, attrs ) {
	var div = document.createElement( "div" );

	div.setAttribute( "id", divId );
	setAttributes( div, attrs );
	
	return div;
}

function createImgTag( elem, attrs ) {
	var img = document.createElement( "img" );
	setAttributes( img, attrs );
	
	if( elem ) {
		elem.appendChild( img );
	}
	
	return img;
}

function createImageLink( divId, params, linkName, imageSrc ) {
	var imgAttrs = { "aria-describedby": "caption-attachment", 
					"src": imageSrc, 
					"alt": linkName, 
					"class": "wp-image-" + divId + " size-medium",
					"width": "auto",
					"height": "auto",
					"sizes": "(max-width: 300px) 100vw, 300px",
	}
	
	var div = createDivTag( divId, { "class": "wp-caption alignnone image_link_div" } );
	
	var a = createLinkTag( div, selectModule, "", params, divId + "-link" ),
		img = createImgTag( a, imgAttrs );
	
	var p = document.createElement( "p" ),
		node = document.createTextNode( linkName );
		
	setAttributes( p, { "id": "caption-attachment", "class": "wp-caption-text" } );
	p.appendChild( node );
	div.appendChild( p );
	
	return div;
}

function createScriptTag( src, callback ) {
	var s = document.createElement( 'script' );
	
	s.setAttribute( 'src', src );
	
	if( callback ) {
    	s.onload = function() {
    		callback();
    	};
	}
	
	return s;
}

function updateMessage() {
	var p = document.getElementById( 'message' );
	var msg = sessionStorage.getItem( 'message' );
	var isErrorMessage = sessionStorage.getItem( 'isErrorMessage' ) == "y" ;
	var isLoggedOutFromLink = sessionStorage.getItem( 'signOutFromLink' ) == "y" ;

	if( msg != null ) {
		if( isErrorMessage ){
			p.innerHTML = "<font style='color:red;'>" + msg + "</font>";
		}
		else{
			p.innerHTML = msg;
		}
		
		if( isLoggedOutFromLink ) {
			sessionStorage.removeItem( "signOutFromLink" );
			sessionStorage.removeItem( "message" );
		}
	}
}

function setMessage( msg ) {
	sessionStorage.setItem( 'message', msg );
	sessionStorage.setItem( 'isErrorMessage', "n" );
}

function setErrorMessage( msg ) {
	var p = document.getElementById( "errorMessage" );
	var m = document.getElementById( 'message' );
	
	if( msg != null && msg != "" ) {
		if( p ){ 
		    p.innerHTML = msg;
		    p.removeAttribute( "hidden" );
		}
		
		if( m ) { m.setAttribute( "hidden", true ); }
	}
}

function goToPage( pagePath ) {
	window.location.href = pagePath; 
}

function updateSelectedTopicTitle( selectedTopic ) {
	document.getElementsByClassName( "header-post-title-class" )[0].innerHTML = selectedTopic;
}

function setAttributes( el, attrs ) {
	for( var key in attrs ) {
		el.setAttribute( key, attrs[key] );
	}
}

function requestLogIn(){
	goToPage( studentLogInUrl );
	setMessage("You don't have access to Practice/Quiz mode. Please subscribe to continue.");
}

function proceedToLogIn() {
	goToPage( studentLogInUrl );
}

function removeStoredCurriculumValues() {
	sessionStorage.removeItem( 'curriculumName' );
	sessionStorage.removeItem( 'sectionsData' );
	sessionStorage.removeItem( 'sectionIds' );
	sessionStorage.removeItem( 'unitIds' );
	sessionStorage.removeItem( 'unitsData' );
	sessionStorage.removeItem( 'modulesData' );
}

//msgId: p tag id ; visible: boolean
function setMessageVisibility( msgId, visible ) {
	var msg = document.getElementById( msgId );
	
	if( msg ) {
		if( visible ) {
			msg.removeAttribute( "hidden" );
		}
		else {
			msg.setAttribute( "hidden", true );
		}
	}
}

function updateFilesDropdown( documentID, unitsID, restrictionMap, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getFiles( unitsID, myFunc, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateWorksheetsDropdown( documentID, unitsID, restrictionMap, tblAdditionalOptions  ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getWorksheets( unitsID, myFunc, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateTeacherDropdown( documentID, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().email_address + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getTeacherList( myFunc );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateSectionsDropdown( documentID, curriculumId, restrictionMap, tblAdditionalOptions, funcDone ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getSectionsList( myFunc, curriculumId, restrictionMap, funcDone );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );

}

function updateModuleDropdownUsingClass( documentID, classID, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		console.log( doc.data().displayName );
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getModuleDropdownUsingClass( myFunc, classID );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateModuleDropdownUsingClassNoStudent( documentID, classID, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getModuleDropdownUsingClassNoStudent( myFunc, classID );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateResetStudentProgress(){
	var db = firebase.firestore();
	updateStudentsInClassList( "reset-student-student-list", document.getElementById( "reset-student-class-list" ).value )
	document.getElementById( "reset-student-module-list" ).innerHTML = "";

	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getResetStudentProgress( myFunc, document.getElementById( "reset-student-class-list" ).value );
	}

	updateDropdown( "reset-student-module-list", null, getInnerHTMLText, firebaseFunc );
}

function updateCurriculumDropdown( documentID, restrictionMap, tblAdditionalOptions, funcDone ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getCurriculumList( myFunc, restrictionMap, funcDone );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateUnitsDropdown( documentID, curriculumID, restrictionMap, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getUnitsList( myFunc, curriculumID, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateUnitsDropdownUsingSection( documentID, sectionID, restrictionMap, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getUnitsListFromSection( myFunc, sectionID, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateUnitsDropdownAll( documentID, curriculumID, restrictionMap, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getAllUnits( myFunc, curriculumID, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateModuleDropdown( documentID, unitsID, restrictionMap, tblAdditionalOptions ){
	var getInnerHTMLText = function( doc ){
		return "<option value='" + doc.id + "'>" + doc.data().displayName + "</option>";
	}

	var firebaseFunc = function( myFunc ){
		getModulesList( myFunc, unitsID, restrictionMap );
	}

	updateDropdown( documentID, tblAdditionalOptions, getInnerHTMLText, firebaseFunc );
}

function updateDropdown( documentID, tblAdditionalOptions, innerHTMLText, firebaseFunc ){
	var myFunc = function( querySnapshot, funcDone ){
		var innerHTML = "";

		if( tblAdditionalOptions ){
			for( var i=0; i<tblAdditionalOptions.length; i++){
				innerHTML = innerHTML + "<option value='" + tblAdditionalOptions[i][0] + "'>" + tblAdditionalOptions[i][1] + "</option>";
			}
		}

		querySnapshot.forEach( function( doc ){
			innerHTML = innerHTML + innerHTMLText( doc );
		});

		document.getElementById( documentID ).innerHTML = innerHTML;

		hideLoading();
		
		if( funcDone ){ funcDone(); }
	}

	firebaseFunc( myFunc );
}

function createUnitsForSections( documentID, curriculumId, op, sectionId ){
	var myFunc = function( querySnapshot ){
		querySnapshot.forEach( function( doc ){
			if( !doc.data().sectionId || ( op == "modify" && doc.data().sectionId == sectionId )){ // get all units with no sections yet.
				var cb = document.createElement( "input" );
				var label = document.createElement( "label" );
				var node = document.createTextNode( doc.data().name );
				cb.setAttribute( "id", "units_" + doc.id );
				cb.setAttribute( "type", "checkbox" );
				cb.setAttribute( "value", doc.id );
				if( doc.data().sectionId && doc.data().sectionId == sectionId ){
					cb.setAttribute( "checked", true );
				}
				label.htmlFor = "units_" + doc.id;
				label.appendChild( node );
				document.getElementById( documentID ).appendChild( cb );
				document.getElementById( documentID ).appendChild( label );
			}
		});
		
		hideLoading();
		document.getElementById( "admin-content" ).removeAttribute( "hidden" );
	}

	getUnitsListFromCurriculumAndSections( myFunc, curriculumId, sectionId );
}

function updateUnitsFromClass( classID, restrictionMap ){
	var myFunc = function( doc ){
		if( doc.exists ){
			updateUnitsDropdown( "add-module-unit-list", doc.data().curriculumId, restrictionMap, [["choose", "Choose..."]])
			updateSectionsDropdown( "add-module-section-list", doc.data().curriculumId, restrictionMap, [[ "choose", "Choose..." ]])
		}
		else{
			document.getElementById( "add-module-unit-list" ).innerHTML = "";
			document.getElementById( "add-module-list" ).innerHTML = "";
		}
	}

	getUnitsFromClass( classID, myFunc );
}

function updateModifyUnit( id ){
	var func = function( doc ){
		if( doc.exists ){
			document.getElementById( "modify-unit-name" ).value = doc.data().name;

			var myFunc = function( querySnapshot ){
				var innerHTML = "";

				querySnapshot.forEach( function( doc ){
					innerHTML = innerHTML + "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
				});

				document.getElementById( "modify-unit-curriculum" ).innerHTML = innerHTML;
				document.getElementById( "modify-unit-curriculum" ).value = doc.data().curriculumId;
				
				var myFunc2 = function( querySnapshot1 ){
					var innerHTML1 = "<option value='choose'>Choose...</option>";

					querySnapshot1.forEach( function( doc1 ){
						innerHTML1 = innerHTML1 + "<option value='" + doc1.id + "'>" + doc1.data().name + "</option>";
					});

					document.getElementById( "modify-unit-section" ).innerHTML = innerHTML1;

					if( doc.data().sectionId ){
						document.getElementById( "modify-unit-section" ).value = doc.data().sectionId;
					}
				}

				getSectionsList( myFunc2, doc.data().curriculumId )
			}

			getCurriculumList( myFunc );
		}
		else{
			document.getElementById( "modify-unit-name" ).value = "";
			document.getElementById( "modify-unit-idx" ).value = "";
			document.getElementById( "modify-unit-curriculum" ).innerHTML = "";
			document.getElementById( "modify-unit-section" ).innerHTML = "";
		}
	}

	getModifyUnit( id, func );
}

function updateModifySectionList( id ){
	var func = function( doc ){
		document.getElementById( "modify-section-name" ).value = doc.data().name;

		var myFunc = function( querySnapshot ){
			var innerHTML = "";

			querySnapshot.forEach( function( doc ){
				innerHTML = innerHTML + "<option value='" + doc.id + "'>" + doc.data().name + "</option>";
			});

			document.getElementById( "modify-section-curriculum" ).innerHTML = innerHTML;
			document.getElementById( "modify-section-curriculum" ).value = doc.data().curriculumId;

			document.getElementById( "modify-section-unitlist" ).innerHTML = "";
			createUnitsForSections( "modify-section-unitlist", doc.data().curriculumId, "modify", id );

		}

		getCurriculumList( myFunc )
	}

	getModifySectionList( id, func );
}

function updateModifyCurriculumList( id ){
	var myFunc = function( doc ){
		if( doc.exists ){
			document.getElementById( "modify-curriculum-name" ).value = doc.data().name;
			document.getElementById( "modify-curriculum-idx" ).value = doc.data().idx;
		}
		else{
			document.getElementById( "modify-curriculum-name" ).value = "";
			document.getElementById( "modify-curriculum-idx" ).value = "";
		}
	}

	getModifyCurriculumList( id, myFunc );
}

function updateCurriculumList( documentID, restrictionMap ){
	var myFunc = function( querySnapshot ){

		var innerHTML = "";
		document.getElementById( documentID ).innerHTML = innerHTML;

		querySnapshot.forEach( function( doc ){
			console.log( "foreach" );
			var a = document.createElement( "a" );
			var node = document.createTextNode( doc.data().name );
			a.setAttribute( "id", "curriculum_" + doc.id );
			a.setAttribute( "href", "#" );
			a.appendChild( node );
			document.getElementById( documentID ).appendChild( a );
			document.getElementById( "curriculum_" + doc.id ).onclick = function( e ){
				//updateUnitsList(documentID, doc.id, restrictionMap );
				sessionStorage.setItem( "curriculum", doc.id );
				window.location.href = "units.html"
			}
			var br = document.createElement("br")
			document.getElementById( documentID ).appendChild( br );
		});

		//document.getElementById( documentID ).innerHTML = innerHTML;
	}
	getCurriculumList( myFunc, restrictionMap );
}

function updateUnitsList( documentID, curriculumID, restrictionMap ){
	var myFunc = function( querySnapshot ){
		var innerHTML = "";
		document.getElementById( documentID ).innerHTML = innerHTML;

		querySnapshot.forEach( function( doc ){
			console.log( "update units list")
			//innerHTML = innerHTML + '<a href="#" onclick="updateModuleList(\'' + documentID + '\', \'' + doc.id + '\')">' + doc.data().name + '</a><br>';
			var a = document.createElement( "a" );
			var node = document.createTextNode( doc.data().name );
			a.setAttribute( "id", "unit_" + doc.id );
			a.setAttribute( "href", "#" );
			a.appendChild( node );
			document.getElementById( documentID ).appendChild( a );
			document.getElementById( "unit_" + doc.id ).onclick = function( e ){
				//updateModuleList(documentID, doc.id, restrictionMap );
				sessionStorage.setItem( "units", doc.id );
				window.location.href = "modules.html"
			}
			var br = document.createElement("br")
			document.getElementById( documentID ).appendChild( br );    
		});

		//document.getElementById( documentID ).innerHTML = innerHTML;
	}

	getUnitsList( myFunc, curriculumID, restrictionMap );
}

function updateModuleList( documentID, unitsID, restrictionMap ){
	var myFunc = function( querySnapshot ){
		var innerHTML = "";

		querySnapshot.forEach( function( doc ){
			innerHTML = innerHTML + '<a href="#" onclick="goToModulePage(\'' + doc.id + '\')">' +  doc.data().displayName + '</a><br>';
		});

		document.getElementById( documentID ).innerHTML = innerHTML;
	}

	getModulesList( myFunc, unitsID, restrictionMap );
}

function updateModuleListDiv( documentID, value, restrictionMap ){
	var myFunc = function( querySnapshot, querySnapshot1, querySnapshot2 ){
		console.log( querySnapshot, querySnapshot1, querySnapshot2 );

		var innerHTML = "";
		querySnapshot.forEach( function( doc ){
			sessionStorage.setItem( 'modulePath', doc.data().pathToModule );
			innerHTML = innerHTML + '<a href ="#" onclick="checkCompletion(\'' + doc.id + '\')">Learn ' + doc.data().displayName + '</a>'; 
		
			if( querySnapshot2 && querySnapshot2[doc.id] ){
				innerHTML = innerHTML + '<a href ="#" onclick="downloadFile(\'' + querySnapshot2[doc.id].data().pathToFile + '\', \'' + querySnapshot2[doc.id].data().fileName + '\')">Download TNS File</a>'; 
			}

			if( querySnapshot1 && querySnapshot1[doc.id] ){
				innerHTML = innerHTML + '<a href ="#" onclick="downloadFile(\'' + querySnapshot1[doc.id].data().pathToWorksheet + '\', \'' + querySnapshot1[doc.id].data().worksheetName + '\')">Download worksheet</a>';
			}

			innerHTML = innerHTML + '<br>';
		});

		document.getElementById( documentID ).innerHTML = innerHTML;

		hideLoading();
	}

	if( value == "all" ){ value = null }

	getModulesFilesWorksheets( myFunc, value, restrictionMap );
}

function updateError( errorText ){
	document.getElementById( "error-content" ).innerHTML = errorText;
}

function hideLoader( activeDocument ){
	if( document.getElementById( "loader" )){ document.getElementById( "loader" ).style.display = "none"; }
	if( document.getElementById( activeDocument )){ document.getElementById( activeDocument ).style.display = "block"; }
}

function showLoader( activeDocument ){
	if( document.getElementById( "loader" )){ document.getElementById( "loader" ).style.display = "block"; }
	if( document.getElementById( activeDocument )){ document.getElementById( activeDocument ).style.display = "none"; }
}

// tblOptionalName is replacement name for the breadcrump path.
function updateBreadcrumbPath( tblPath, tblOptionalName ){
    //console.log( tblPath );
    
    var innerHTML = "";
    
    for( var a=0; a<tblPath.length; a++ ){
    	var name = tblPath[a][0];

    	if( tblOptionalName && tblOptionalName[a] ){
    		name = tblOptionalName[a];
    	}

        innerHTML += '<a href=' + tblPath[a][1] + '>' + name + '</a>';
        
        if( a<tblPath.length-1 ){
            innerHTML += " > ";
        }
    }

    document.getElementById( "div-bread-crumb" ).innerHTML = innerHTML;
}

function titleCase(str) {
   var splitStr = str.toLowerCase().split(' ');
   for (var i = 0; i < splitStr.length; i++) {
       // You do not need to check if i is larger than splitStr length, as your for does that for you
       // Assign it back to the array
       splitStr[i] = splitStr[i].charAt(0).toUpperCase() + splitStr[i].substring(1);     
   }
   // Directly return the joined string
   return splitStr.join(' '); 
}

// CANVAS Manipulation
function drawCanvas( p_canvasName ) {
	document.getElementsByTagName("body")[0].innerHTML += '<canvas id="' + p_canvasName + '" style="touch-action: none;"></canvas>';
}

function getCanvas( p_canvasName ) { return document.getElementById( p_canvasName ); }

function setCanvasMargin( p_canvasName, p_top, p_left ) {
	// set left and top values of the margin. NOTE: only left and top values are used on ndlink for now
	// feel free to add right and bottom values BUT take note if there's a need to modify ndlink for that
	var canvas = getCanvas( p_canvasName );
	canvas.marginTop = p_top;
	canvas.marginLeft = p_left;
}

function setCanvasWidthHeight( p_canvasName, p_width, p_height ) {
	var canvas = getCanvas( p_canvasName );
	canvas.width = p_width;
	canvas.height = p_height;
}

function resizeCanvas( p_canvasName ) {
	var base_width = getBaseWidth();
	var base_height = getBaseHeight();
	var w = base_width * 0.99
	var h = base_height * 0.99

	setCanvasWidthHeight( p_canvasName, w, h );
	
}

function addLoading() {
	var c = getCanvas("myCanvas");
	var ctx = c.getContext("2d");

	ctx.font= getBaseWidth() * 0.05 + "px Verdana"; // fonts size based on the inner width of the window so 

	// Create gradient
	var gradient=ctx.createLinearGradient(0,0,c.width,0);
	gradient.addColorStop("0","blue");
	gradient.addColorStop("0.5","green");
	gradient.addColorStop("1.0","red");

	// Fill with gradient
	ctx.fillStyle=gradient;

	var txt = "Loading...";
	var txtWidth = ctx.measureText(txt).width; // get width of the text
	ctx.fillText(txt, c.width * 0.5 - txtWidth, c.height * 0.5); // based on current width and height of the browser
}

// end CANVAS Manipulation

// WINDOW Manipulation
function resizePage( p_canvasName ) {
	resizeCanvas( p_canvasName );

	window.scroll( 0, 1 )
}

function getBaseWidth(){
	var viewportwidth;
  
	// the more standards compliant browsers (mozilla/netscape/opera/IE7) use window.innerWidth and window.innerHeight

	if (typeof window.innerWidth != 'undefined')
	{
		viewportwidth = window.innerWidth
	}

	// IE6 in standards compliant mode (i.e. with a valid doctype as the first line in the document)

	else if (typeof document.documentElement != 'undefined'
	&& typeof document.documentElement.clientWidth !=
	'undefined' && document.documentElement.clientWidth != 0)
	{
		viewportwidth = document.documentElement.clientWidth
	}
					
	// older versions of IE

	else
	{
		viewportwidth = document.getElementsByTagName('body')[0].clientWidth
	}

	return viewportwidth
}

function getBaseHeight(){
 	var viewportheight;
	  
	// the more standards compliant browsers (mozilla/netscape/opera/IE7) use window.innerWidth and window.innerHeight

	if (typeof window.innerHeight != 'undefined')
	{
		viewportheight = window.innerHeight
	}

	// IE6 in standards compliant mode (i.e. with a valid doctype as the first line in the document)

	else if (typeof document.documentElement != 'undefined'
	&& typeof document.documentElement.clientWidth !=
	'undefined' && document.documentElement.clientWidth != 0)
	{
		viewportheight = document.documentElement.clientHeight
	}

	// older versions of IE

	else
	{
		viewportheight = document.getElementsByTagName('body')[0].clientHeight
	}

	return viewportheight
};

// end WINDOW Manipulation

function resizeVideo( p_sidebarName, p_videoID ) {
	if( isSidebarActive() ) {
		var video_width = getTutorialVideoWidth();
		var video_height = getTutorialVideoHeight();
		var right_sidebar = getRightSidebar( p_sidebarName );
		var right_sidebar_width = removeAlphaAndConvertToNumber( right_sidebar.style.width )
		var right_sidebar_height = removeAlphaAndConvertToNumber( right_sidebar.style.height )
		var scaleFactor = Math.min( right_sidebar_width/video_width, right_sidebar_height/video_height );
		setVideoWidthHeight( p_videoID, video_width * scaleFactor, video_height * scaleFactor );
	}
}

function getTutorialVideoWidth(){ return 320 };
function getTutorialVideoHeight(){ return 240 };

function removeAlphaAndConvertToNumber( p_string ) {
	// this function is used to remove all non digit character and convert it to number format and return something.
	return parseInt( p_string.replace(/[^-\d\.]/g, ''));
}

function setVideoWidthHeight( p_videoID, p_width, p_height ) {
	if( isSidebarActive() ) {
		var video_tutorial = getObjectBasedOnID( p_videoID );

		if( video_tutorial != null ){
			// update 05052016: added null checker
			video_tutorial.style.width = p_width+"px";
			video_tutorial.style.height = p_height+"px";
		}
	}
}

function playPause() {
	// video play and pause
	var myVideo = document.getElementById( "video_tutorial")
	alert( myVideo.duration )
	if ( myVideo.paused ) myVideo.play();
    else myVideo.pause();
}

function getObjectBasedOnID( p_objectID ) { return document.getElementById( p_objectID ); }

function setupCanvas() {
	// canvas init values/settings.
	var canvas = getCanvas( "myCanvas" );
	setCanvasMargin( "myCanvas", 0, 0 );
	setCanvasWidthHeight( "myCanvas", getBaseWidth(), getBaseHeight() );
	
	resizePage( "myCanvas", "right_sidebar", "video_tutorial" ); // resize all the elements
	addLoading(); // "Loading... Please Wait." text
}

function matchMediaQuery( query ) {
	return window.matchMedia(query).matches;
}

function isTouchDevice() { // check if device is touch
	var prefixes = ' -webkit- -moz- -o- -ms- '.split(' '); // media prefix for different browsers
	var query = ['(', prefixes.join('touch-enabled),('), 'heartz', ')'].join(''); // heartz is when a Modernizr is used
  	
  	return (( 'ontouchstart' in window ) // test if TouchEvent.touchstart exists
		|| ( window.DocumentTouch && document instanceof DocumentTouch ) // Interface used to provide convenience methods for creating Touch and TouchList objects
		|| ( navigator.MaxTouchPoints > 0 ) // MaxTouchPoints = The maximum number of supported touch points ( for IE )
		|| ( navigator.msMaxTouchPoints > 0 ) // For Internet Explorer lower than version 11
		|| matchMediaQuery( query ) // For Mozilla Firefox
		|| navigator.maxTouchPoints > 0 ); // For Edge and Internet Explorer also
}