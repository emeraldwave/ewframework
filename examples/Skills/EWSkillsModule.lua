platform.apiLevel = "2.3"

local app = {VERSION = "2022.08.17.1023", TITLE = "Skills Module", COPYRIGHT = "2021"}

print("Version = "..app.VERSION)

--##CONTROLLER - MODULE
-------------------------------------------------------
ModuleController = class()

function ModuleController:init()
    self.currentProblem = 0
    self.numberCorrect = 0
    self.hintsCounter = 0
    self.hintTimerStart = 0  
    self.totalProblems = 0
    self.activityStartTime = 0
    self.activityTotalTime = 0
	self.sleepStartTime = 0
    self.activity = nil
    self.practiceMode = app.model.practiceModes.ADDITION
    self.quizLevel = app.model.quizLevels.BEGINNER
    self.continueFromSleep = false
end

function ModuleController:stateInit(page) if page.stateInit then page:stateInit() end end

function ModuleController:stateEnd(page)
    if self.activity == app.model.activitiesList.PRACTICE or self.activity == app.model.activitiesList.QUIZ then
        app.timer:stop(app.model.timerIDs.SLEEPTIMER)
        app.timer:stop(app.model.timerIDs.HINTTIMER)

        if self.currentProblem < self.totalProblems then        

            --There are more problems, continue with activity.
            if self.activity == app.model.activitiesList.QUIZ then
                local pageID
        
                if self.quizLevel == app.model.quizLevels.BEGINNER then
                    pageID = app.model.pageIDs.ADDITION_PAGE
                elseif self.quizLevel == app.model.quizLevels.ADVANCED then
                    if app.controller.moduleController.currentProblem % 2 == 0 then 
                        pageID = app.model.pageIDs.ADDITION_PAGE
                    else
                        pageID = app.model.pageIDs.SUBTRACTION_PAGE
                    end
                end
                        
                app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
                app.controller:switchPages(pageID)
            elseif self.activity == app.model.activitiesList.PRACTICE then

                app.controller:setNextState(app.controller.activePageID, app.model.statesList.ACTIVITY, app.model.subStatesList.START)
                app.controller:dispatch(app.controller.activePageID)
            end
        else
            --Activity complete.
            app.timer:stop(app.model.timerIDs.MAINTIMER)
            app.controller.moduleController.activityTotalTime = math.floor( math.floor( ( timer.getMilliSecCounter() - app.controller.moduleController.activityStartTime ) / 100 ) / 10 )
        
            local pageID = app.model.pageIDs.SCORE_PAGE
            app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
            app.controller:switchPages(pageID)
        end
    end
    
    if page.stateEnd then page:stateEnd() end
end

--function ModuleController:nextSubState(page)
--    if app.isPlatformSlow() then 
--        page.view.button1:setFillColor(page.view.button1.mouseDownColor)       --This acts like hourglass mouse cursor
--        
--        --Give check button a chance to paint.
--        app.controller:postMessage( function(...) self:goToNextSubState(page) end )
--    else
--        self:goToNextSubState(page)
--    end    
--end

function ModuleController:nextSubState(page)
    local nextSubState = app.model.nextSubStateTable[page.subState]

    if nextSubState ~= nil then page.nextSubState = nextSubState end

    app.controller:dispatch(page.pageID)
end

function ModuleController:handleMenu(menuID, subMenuID)
    app.frame:disableMenuArrow()    --Just in case the user pressed the physical ENTER key on the NSpire

    app.timer:stop(app.model.timerIDs.SLEEPTIMER)   --Switching pages stops the sleep timer.
    app.timer:stop(app.model.timerIDs.HINTTIMER)

    app.frame.selectedMenuID = menuID
    app.frame.selectedSubMenuID = subMenuID
    
    if app.frame.selectedMenuID == app.model.menuChoicesList.ABOUT then
        self.activity = nil

        app.controller:setNextState(app.model.pageIDs.ABOUT_PAGE, app.model.statesList.INIT, nil)
        app.controller:switchPages(app.model.pageIDs.ABOUT_PAGE)
    elseif app.frame.selectedMenuID == app.model.menuChoicesList.PRACTICE then
        local pageID = app.model.pageIDs.ADDITION_PAGE

        self.activity = app.model.activitiesList.PRACTICE

        if app.frame.selectedSubMenuID == app.model.subMenuChoicesList.ADDITION then
            self.practiceMode = app.model.quizLevels.ADDITION
            self.totalProblems = app.model.MAX_PROBLEMS_PRACTICE
        elseif app.frame.selectedSubMenuID == app.model.subMenuChoicesList.SUBTRACTION then
            self.practiceMode = app.model.quizLevels.SUBTRACTION
            pageID = app.model.pageIDs.SUBTRACTION_PAGE
            self.totalProblems = app.model.MAX_PROBLEMS_PRACTICE
        end
        
        self.currentProblem = 0; self.numberCorrect = 0; self.hintsCounter = 0;

        app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
        app.controller:switchPages(pageID)

    elseif app.frame.selectedMenuID == app.model.menuChoicesList.QUIZ then
        local pageID = app.model.pageIDs.ADDITION_PAGE

        self.activity = app.model.activitiesList.QUIZ
        
        if app.frame.selectedSubMenuID == app.model.subMenuChoicesList.BEGINNER then
            self.quizLevel = app.model.quizLevels.BEGINNER
            self.totalProblems = app.model.MAX_PROBLEMS_QUIZ
        elseif app.frame.selectedSubMenuID == app.model.subMenuChoicesList.ADVANCED then
            self.quizLevel = app.model.quizLevels.ADVANCED
            self.totalProblems = app.model.MAX_PROBLEMS_QUIZ
        end
        
        self.currentProblem = 0; self.numberCorrect = 0; self.hintsCounter = 0 
        
        app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
        app.controller:switchPages(pageID)
    end    
end

function ModuleController:beginPractice(pageID)
    self.activity = app.model.activitiesList.PRACTICE
    self.totalProblems = app.model.MAX_PROBLEMS_PRACTICE
    self.currentProblem = 0; self.numberCorrect = 0; self.hintsCounter = 0;
    app.frame.border_color = app.model.BORDER_COLOR
    self.activityStartTime = timer.getMilliSecCounter()
    app.timer:start(app.model.timerIDs.MAINTIMER)

    app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
    app.controller:switchPages(pageID)
end

function ModuleController:beginQuiz()
    local pageID = app.model.pageIDs.ADDITION_PAGE
    
    self.activity = app.model.activitiesList.QUIZ
    self.currentProblem = 0; self.numberCorrect = 0; self.hintsCounter = 0 
    app.frame.border_color = app.model.BORDER_COLOR
    self.activityStartTime = timer.getMilliSecCounter()
    app.timer:start(app.model.timerIDs.MAINTIMER)

    app.controller:setNextState(pageID, app.model.statesList.INIT, nil)
    app.controller:switchPages(pageID)
end

function ModuleController:handleMainTimer()
    local view = app.frame.views[app.frame.activeViewID]
    
    if app.timer.timers[app.model.timerIDs.MAINTIMER] == true then
        if view.timerText and view.timerText.visible == true then
            view:updateStopwatch()
        end
    end
end

function ModuleController:handleHintTimer()
    local view = app.frame.views[app.frame.activeViewID]
    local timeLapsed = ( (app.timer:getMilliSecCounter() - self.hintTimerStart) / 1000 )      --in seconds

    if timeLapsed >= app.model.hintWaitTimeIntervals[2] then
        view:updateHint(2)
        app.timer:stop(app.model.timerIDs.HINTTIMER)
    elseif timeLapsed >= app.model.hintWaitTimeIntervals[1] then
        view.page.hintUsed = true
        view:updateHint(1)
    end
end

--Called before switching to Sleep Page.
function ModuleController:preSleep()
    app.timer:stop(app.model.timerIDs.HINTTIMER)
    app.frame.menu:hide()       --In case the user had the menu open, close the menu so that the correct objects are deactivated when the hourglass shows on slow platforms
end

--Called before continuing from Sleep Page.
function ModuleController:postSleep(view)
    if app.controller.pages[ app.controller.activePageID ].state == app.model.statesList.ACTIVITY then -- only re-start the hint timer when the user is doing activity.
        app.timer:start(app.model.timerIDs.HINTTIMER)
    end
    
    self.continueFromSleep = true
    app.controller.moduleController.sleepStartTime = app.timer:getMilliSecCounter()  --Reset sleep counter
    app.frame.pageView.moduleView:showFooterObjects(view) 
end
    
--##CONTROLLER - MODULE END

--##PAGE - ADDITION
------------------------------------------------------------------------
------------------------------------------------------------------------
AdditionPage = class()

function AdditionPage:init(name)
    self.name = name
    self.pageID, self.viewID, self.view = nil, nil, nil
    self.nextState = app.model.statesList.INIT  
    self.nextSubState = nil
    self.problemSet = AdditionProblemSet() 
    self.answeredWrong = false
    self.hintUsed = false
    self.validityFlags = nil
end

--State INIT
--Call this state as a reset.
function AdditionPage:stateInit()
    self.view = app.frame.views[self.viewID]

    --DEBUG ONLY when this is Startup page.
    --if app.frame.selectedMenuID == nil then app.frame.selectedMenuID = app.model.menuChoicesList.PRACTICE end
    --if app.frame.selectedSubMenuID == nil then app.frame.selectedSubMenuID = app.model.subMenuChoicesList.ADDITION end

    self.problemSet:configure()
    
    self.view:stateInit() 

    app.controller.moduleController.activityStartTime = timer.getMilliSecCounter()
    app.timer:start(app.model.timerIDs.MAINTIMER)
    
    app.controller:setNextState(self.pageID, app.model.statesList.ACTIVITY, app.model.subStatesList.START)
end

--State ACTIVITY
function AdditionPage:subStateStart()
    self.problemSet:generateProblem()
    app.controller.moduleController.currentProblem = app.controller.moduleController.currentProblem + 1
    self.answeredWrong = false
    self.hintUsed = false

    self.view:subStateStart()
    app.controller.moduleController.sleepStartTime = app.timer:getMilliSecCounter() 
    app.timer:start(app.model.timerIDs.SLEEPTIMER)

    app.controller:setNextState(self.pageID, app.model.statesList.ACTIVITY, app.model.subStatesList.USER_INPUT)
end

function AdditionPage:subStateUserInput() 
    self.view:subStateUserInput()
    
    app.controller.moduleController.sleepStartTime = app.timer:getMilliSecCounter() 
    self:startHintTimer()
end

function AdditionPage:subStateProcessInput() 
    local view = self.view

	self.validityFlags = self.problemSet:validateAnswers({view.textbox1:getText()})

    if self.validityFlags[1] == true then
        self:correctAnswer()
    elseif self.validityFlags[1] == false then 
        self:wrongAnswer()
    else 
        self:emptyAnswer()
    end
end

function AdditionPage:subStateWaitForNext() 
    self.view:subStateWaitForNext()
end

--State END
function AdditionPage:stateEnd() end 

function AdditionPage:correctAnswer()
    app.timer:stop(app.model.timerIDs.HINTTIMER)
    
    if self.hintUsed == true then app.controller.moduleController.hintsCounter = app.controller.moduleController.hintsCounter + 1 end
    if self.answeredWrong ~= true then app.controller.moduleController.numberCorrect = app.controller.moduleController.numberCorrect + 1 end 

    self.view:correctAnswer()

    app.controller:setNextState(app.model.pageIDs.ADDITION_PAGE, app.model.statesList.ACTIVITY, app.model.subStatesList.WAIT_FOR_NEXT)
end

function AdditionPage:wrongAnswer()
    self.answeredWrong = true   --Any wrong answer triggers this flag.
    self.view:wrongAnswer()
end

function AdditionPage:emptyAnswer()
    self.view:emptyAnswer()
end

function AdditionPage:startHintTimer()
    if app.timer.timers[app.model.timerIDs.HINTTIMER] ~= true then
        app.timer:start(app.model.timerIDs.HINTTIMER)
        app.controller.moduleController.hintTimerStart = app.timer:getMilliSecCounter()
    end
end

--## 
------------------------------------------------------------------------
AdditionView = class()

function AdditionView:init(name)
    self.name = name
    self.title = app.TITLE
    self.needsViewSetup = true
    self.needsResize = nil  --Neutral until the first on.resize() is called by the OS
    self.needsLayout = nil  --Once needsLayout is set to true, it will always be true
    self.scrollPane = nil
    self.panex = 1;  self.paney = 1;  self.panew = 1;  self.paneh = 1;
    self.x = 0; self.y = 0; self.w = 1; self.h = 1;
    self.scaleFactor = 1
	self.numberOfColumns = 1
    self.viewStyle = app.viewStyles.STANDARD   --STANDARD, LARGE
    self.toAddVHWhitespace = false -- flag that tells us that whitespace should be added
    self.backgroundColor = { app.BACKGROUND_COLOR }
    self.hasTouched = false
    self.layouts = AdditionLayouts(self)
    self.setups = AdditionSetups(self)
    self.modifys = AdditionModifys(self)
    self.clears = AdditionClears(self)
end

function AdditionView:stateInit()
    --Frame UI    
    app.frame.imageWaitCursor:setVisible(false)
    app.frame:hideFooterObjects()   --Hide all the current footer objects since the footer is shared between pages.
    app.frame.footer:setVisible(true)
    app.frame.buttonMenu:setActive(true)    --The menu button may have been disabled during switchPages()
    app.frame.keyboard.lockVisibility = true    --Don't allow the framework to hide the keyboard automatically.

    --View UI
    self.modifys:modifyView()
    self:hideStopwatch()
    self.clears:clearHints()
    self.textbox1:setActive(true)    --The textbox may have been disabled during switchPages()
    self.scrollPane:scrollIntoView("TOP", 0)        --reset the scroll percentage

    app.frame.UIMgr:switchFocus(self.initFocus)     --switchFocus after all objects have been enabled and set visible.
    app.frame.pageView:updateView(self)               --Reposition scrollpane objects and update vh        
end

function AdditionView:subStateStart()
    self.button1:setFillColor(self.button1.initFillColor)
    self.buttonNext:setFillColor(self.buttonNext.initFillColor)
    self.hint2:setVisible(false)
    self.hint3:setVisible(false)
    self.textbox1:setActive(true)
    self.textbox1:setText("")
    self.modifys:modifyProblemString()
    self.feedbackTextbox1:setVisible(false)
    app.frame.pageView.moduleView:modifyFooter(self)

    self.initFocus = self.textbox1.name
    app.frame.UIMgr:switchFocus(self.initFocus)     --switchFocus after all objects have been enabled and set visible.
end

function AdditionView:subStateUserInput()
    local hideTable = { app.frame.imageWaitCursor, self.buttonNext, }
    local visibleTable = { app.frame.footer, self.paragraphProblem, self.textbox1, self.button1, app.frame.keyboard }
    local activeTable = { self.button1, self.textbox1, }

    app.frame.pageView:setObjectVisibility(visibleTable, hideTable, activeTable)
    app.frame.pageView.moduleView:showFooterObjects(self) 
end

function AdditionView:subStateWaitForNext()
    self.button1:setVisible(false)
    self.buttonNext:setVisible(true); self.buttonNext:setActive(true)
    self.initFocus = self.buttonNext.name
    app.frame.UIMgr:switchFocus(self.initFocus)     --Button is now only element that will work.
    app.frame.pageView.moduleView:showFooterObjects(self)
end

function AdditionView:stateEnd() end

function AdditionView:correctAnswer()
    self.textbox1:setActive(false)
    self.feedbackTextbox1:setVisible(true)
    self.feedbackTextbox1:setStyle("CheckMark")
end

function AdditionView:wrongAnswer()
    self.initFocus = self.textbox1.name
    self.feedbackTextbox1:setVisible(true)
    self.feedbackTextbox1:setStyle("CrossMark")

    self.button1:setFillColor(self.button1.initFillColor)
    app.frame.UIMgr:switchFocus(self.initFocus)     --For an empty answer, set focus back to a textbox.
end

function AdditionView:emptyAnswer()
    self.initFocus = self.textbox1.name
    self.feedbackTextbox1:setVisible(false)

    self.button1:setFillColor(self.button1.initFillColor)
    app.frame.UIMgr:switchFocus(self.initFocus)     --For an empty answer, set focus back to a textbox.
end

function AdditionView:updateHint(hintNumber)
    local updateHintFuncs = { function(...) self:updateHint1(...) end, function(...) self:updateHint2(...) end }
    
    updateHintFuncs[hintNumber]()
end

function AdditionView:showStopwatch()
    self.timerText:setVisible(true)
end

function AdditionView:hideStopwatch()
    self.timerText:setVisible(false)
end

function AdditionView:updateStopwatch()
    self.timerText:setText( "Time: ".. string.format( "%.1f", math.floor( ( timer.getMilliSecCounter() - app.controller.moduleController.activityStartTime ) / 100 ) / 10 ))
end

function AdditionView:updateHint1()
    self.modifys:modifyHintStrings()
    self.hint2:setVisible(true)
end

function AdditionView:updateHint2()
    self.hint2:setVisible(false)
    self.hint3:setVisible(true)
end

function AdditionView:clickButton1(view, event) if event == app.model.events.EVENT_MOUSE_UP then app.controller.moduleController:nextSubState(self.page) end end
function AdditionView:clickButtonNext(view, event) if event == app.model.events.EVENT_MOUSE_UP then app.controller.moduleController:stateEnd(self.page) end end

function AdditionView:layoutY() if self.page.state then return self.layouts:layoutY() end end 
function AdditionView:layoutXOneColumn() if self.page.state then return self.layouts:layoutXOneColumn() end end 
function AdditionView:layoutFooter() return app.frame.pageView.moduleView:layoutFooter(self) end
function AdditionView:setupView() self.setups:setupView(); self.needsViewSetup = false end
function AdditionView:updateView() self.modifys:updateView() end

function AdditionView:enterKey()
    if self.buttonNext and self.buttonNext.hasFocus then
        app.controller.moduleController:stateEnd(self.page)
    else
        app.controller.moduleController:nextSubState(self.page)
    end
end 

--##
------------------------------------------------------
--Functions to be called only once for the life of the module to create widgets.
AdditionSetups = class()

function AdditionSetups:init(view)
    self.view = view
end

function AdditionSetups:setupView()
    self:setupSimpleStrings()
    self:setupButtons()
    self:setupInputBoxes()
    self:setupKeyboard()
    self:setupFeedbacks()
    self:setupRectangles()
    self:setupZOrders()
    self:addTabs()
    app.frame.pageView.moduleView:setupFooter(self.view)
    
    self.view.initFocus = self.view.textbox1.name
end

function AdditionSetups:setupButtons()
    local view = self.view
    
    view.button1 = app.frame.widgetMgr:newWidget("BUTTON", view.pageID.."_button1", {label = "", initSizeAndPosition = {24, 26, .23, 0}, octagonStyle = true,
                drawCallback = function(...) app.frame.pageView:drawCheckMark(...) end } )  
    view.button1:addListener(function( event, ...) return view:clickButton1(view, event, ...) end)       
    view.scrollPane:addObject(view.button1)  
    app.frame.UIMgr:addListener( view.pageID, function(...) return view.button1:UIMgrListener(...) end )   

    view.buttonNext = app.frame.widgetMgr:newWidget("BUTTON", view.pageID.."_buttonNext", {initSizeAndPosition = {41, 27, .23, 0}, initFontSize = 10, octagonStyle = true,
                drawCallback = nil, label = "Next" } )  
    view.buttonNext:addListener(function( event, ...) return view:clickButtonNext(view, event, ...) end)       
    view.scrollPane:addObject(view.buttonNext)  
    app.frame.UIMgr:addListener( view.pageID, function(...) return view.buttonNext:UIMgrListener(...) end ) 
end

function AdditionSetups:setupInputBoxes()
    local view = self.view

    view.textbox1 = app.frame.widgetMgr:newWidget("TEXTBOX", view.pageID.."_textbox1", {initSizeAndPosition = {40, 21, .26, .21}, minWidth = 40, labelPosition = "left", maxChar = 5, text = "", initLabelFontSize = 10, keyboardYPosition = 1, allowScroll = false, isDynamicWidth = true, hasGrab = false })
    view.textbox1:addListener(function( event, ...) return view.modifys:textboxListener(event, ...) end) 
    app.frame.UIMgr:addListener(view.pageID,  function(...) return view.textbox1:UIMgrListener(...) end )
    app.frame.keyboard:setTextbox(view.textbox1) 
    view.scrollPane:addObject(view.textbox1)
end

function AdditionSetups:setupSimpleStrings()
    local view = self.view
    
    view.paragraphProblem = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID.."_paragraphProblem", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = " = ", active = false })
    view.scrollPane:addObject( view.paragraphProblem )
    
    view.hintAddend1 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintAddend1", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "", active = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject( view.hintAddend1 )
    
    view.hintAddend2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintAddend2", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "", active = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject( view.hintAddend2 )
    
    view.hintOperation = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintOperation", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "+", active = false, visible = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject(view.hintOperation)
    
    view.hint1 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint1", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint1)
    
    view.hint2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint2", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint2)

    view.hint3 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint3", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint3)

    view.timerText = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_timerText", { initSizeAndPosition = {0, 0, 0, 0}, text = "Time: 0.0", active = false, initFontSize = 8, visible = true })
    view.scrollPane:addObject( view.timerText )
end

function AdditionSetups:setupFeedbacks()
    local view = self.view
    
	view.feedbackTextbox1 = app.frame.widgetMgr:newWidget("FEEDBACK", view.pageID.."_feedbackTextbox1", {visible = false, initSizeAndPosition = {0, 0, 0, 0} })
	view.feedbackTextbox1:setStyle("CrossMark")
    view.scrollPane:addObject(view.feedbackTextbox1)
end

function AdditionSetups:setupRectangles()
    local view = self.view

    view.equalLine = app.frame.widgetMgr:newWidget("RECTANGLE", view.pageID.."_equalLine", { initSizeAndPosition = { 1, 2, 0, 0 }, visible = false })
    view.equalLine.fillColor = app.graphicsUtilities.Color.blue
    view.equalLine.borderColor = app.graphicsUtilities.Color.blue
    view.scrollPane:addObject( view.equalLine )
end

function AdditionSetups:setupKeyboard()
	local view = self.view
	
	app.frame.pageView:attachKeyboard(view) -- attach the keyboard on this page's scrollpane
    view.scrollPane:addObject(app.frame.keyboard)
    app.frame.keyboard.hasGrab = true
    app.frame.keyboard.showDragIcon = true
end

function AdditionSetups:setupZOrders()
	local view = self.view

--    view.scrollPane:setZOrder( view.critterPath.name, 1 )   --Below everything
    view.scrollPane:setZOrder( app.frame.keyboard.name, #view.scrollPane.zOrder )   --Above everything
end

function AdditionSetups:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr
    
    local list = {app.frame.buttonMenu, view.textbox1, view.button1, view.buttonNext}
                                     
    UIMgr:addPageTabObjects(view.pageID, list)
    UIMgr:setPageTabSequence(view.pageID, list) 
end

--##
-------------------------------------------------------
--Functions to position widgets initially and for resize.
AdditionLayouts = class()

function AdditionLayouts:init(view)
    self.view = view
end

function AdditionLayouts:layoutY()
    local view = self.view
    local anchorData = {}       
    local idx = 1

    app.frame.keyboard.keysIndex = 1

    anchorData, idx = self:layoutYStandard(anchorData, idx)

    return anchorData
end

function AdditionLayouts:layoutYStandard(anchorData, idx)
    local view = self.view
    
    anchorData[idx] = {object = view.paragraphProblem, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -20}; idx = idx + 1
    anchorData[idx] = {object = view.textbox1, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -20}; idx = idx + 1
    anchorData[idx] = { object = view.button1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.buttonNext, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend2, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hintOperation, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint1, anchorTo = view.hintOperation, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint2, anchorTo = view.textbox1, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint3, anchorTo = view.textbox1, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox1, anchorTo = view.textbox1, anchorPosition = "Top", position = "Bottom", offset = -5 } idx = idx + 1
    anchorData[idx] = { object = view.timerText, anchorTo = view.scrollPane, anchorPosition = "PaneBottom", position = "Bottom", offset = -10 } idx = idx + 1

    return anchorData, idx
end
    
function AdditionLayouts:layoutXOneColumn()
    local view = self.view
    local anchorData = {}       
   
    anchorData = self:layoutXStandard()
    
    return anchorData
end

function AdditionLayouts:layoutXStandard()
    local view = self.view
    local anchorData = {}
    local idx = 1
    local sf = 1
    local counter1 = 0
    local counter2 = 0
    
    local maxaddend = math.max( counter1, counter2 )
    
    anchorData[idx] = {object = view.paragraphProblem, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -40}; idx = idx + 1
    anchorData[idx] = {object = view.textbox1, anchorTo = view.paragraphProblem, anchorPosition = "Right", position = "Left", offset = 0} idx = idx + 1
    anchorData[idx] = { object = view.button1, anchorTo = view.textbox1, anchorPosition = "Right", position = "Left", offset = 10 } idx = idx + 1
    anchorData[idx] = { object = view.buttonNext, anchorTo = view.textbox1, anchorPosition = "Right", position = "Left", offset = 10 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend1, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend2, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hintOperation, anchorTo = view.hintAddend2, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hint1, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.timerText, anchorTo = view.scrollPane, anchorPosition = "PaneLeft", position = "Left", offset = 5 } idx = idx + 1

    return anchorData
end

--##
------------------------------------------------------------------------
--Functions to modify widgets in response to user actions.
AdditionModifys = class()

function AdditionModifys:init(view)
    self.view = view
end

function AdditionModifys:modifyView()
    local view = self.view
    
--    view.scrollPane.allowClip = false       --Allow the critter to overlap the scrollpane.
    self:modifyProblemString()
    self:modifyKeyboard()
    self:modifyStopwatch()
    app.frame.pageView.moduleView:modifyFooter(view)
end

function AdditionModifys:modifyProblemString()
    local view = self.view
    local addend1 = tostring(view.page.problemSet.value1)
    local addend2 = tostring(view.page.problemSet.value2)
    local operation = view.page.problemSet.operationString

    local text = addend1.." "..operation.." "..addend2.." = "
    view.paragraphProblem:modifyProperties({ text = text })
    view.paragraphProblem:setPosition( view.textbox1.pctx - view.paragraphProblem:calculateWidth( view.paragraphProblem.scaleFactor ) / view.paragraphProblem.panew, view.paragraphProblem.pcty )
end

function AdditionModifys:modifyStopwatch()
    self.view.timerText:setText("Time: 0.0")
end

function AdditionModifys:updateView()
end

function AdditionModifys:textboxListener( event, ... )
    local view = self.view

    app.frame.keyboard:textBoxListener( event, ... )

    return true
end

function AdditionModifys:modifyKeyboard()
    if app.frame.keyboard.active == true then app.frame.keyboard:setVisible(true) end
end

function AdditionModifys:modifyHintStrings()
    local view = self.view

    local addend1 = view.page.problemSet.value1
    local addend2 = view.page.problemSet.value2
    
    view.hintAddend1:modifyProperties({ text = tostring(addend1), visible = false })
    view.hintAddend2:modifyProperties({ text = tostring(addend2), visible = false })
    view.hintOperation:modifyProperties({ visible = false })
    view.hint1:modifyProperties({ text = tostring( app.rationals:add(addend1, addend2)), visible = false })
    view.hint2:modifyProperties({ text = self:formatHint(addend1, addend2), visible = false })
    view.hint2:setPosition( view.paragraphProblem.pctx, view.hint2.pcty )
    view.hint3:modifyProperties({ text = view.hint2.text..tostring(addend1 + addend2) , visible = false })
    view.hint3:setPosition( view.paragraphProblem.pctx, view.hint3.pcty )
end

function AdditionModifys:formatHint( addend1, addend2 )
    local ans = app.rationals:add( addend1, addend2 )
    local txt = nil

    local mod = app.rationals:mod( ans, 10 )
    local quotient = app.rationals:divide( ans, 10 )
    local newAddend2 = addend2 - mod
    local hasNoZero = addend1 ~= 0 or addend2 ~= 0
    local isGreaterThan1 = addend1 > 1 or addend2 > 1
    
    if addend2 == 11 or addend2 == 12 or addend2 == 15 or addend2 == 16  then
        newAddend2 = 10
        mod = addend2 - 10
    end
        
    if mod > 0 and quotient > 1 and newAddend2 > 0 and hasNoZero and isGreaterThan1 then -- the answer is more than 10
        txt = addend1 .. " + " .. addend2 .. " = ( " .. addend1 .. " + " .. newAddend2 .. " ) + " .. mod .. " = "
    else
        txt = addend1 .. " + " .. addend2 .. " = "
    end
    
    return txt
end

--##
------------------------------------------------------------------------
--Functions to clear widgets at start of activity.
AdditionClears = class()

function AdditionClears:init(view)
    self.view = view
end

function AdditionClears:clearHints()
    local view = self.view
    
    view.hint2:setVisible(false)
    view.hint3:setVisible(false)
end

--##
----------------------------------------------------------------------
--Functions to generate problem data
AdditionProblemSet = class()

function AdditionProblemSet:init()
    self.value1, self.value2, self.answer = 0, 0, 0
    self.leftAddend = 0
    self.multiplier = 0
    self.operationString = "+"
    
    --Left addend min, left addend max, right addend min, right addend max 
    self.minMax = {0, 12, 1, 12}
end

function AdditionProblemSet:configure()
    self.leftMin, self.leftMax, self.rightMin, self.rightMax = self.minMax[1], self.minMax[2], self.minMax[3], self.minMax[4]
    self.leftAddend = self.leftMin  --Starting value. 
end

function AdditionProblemSet:generateProblem()
    self.value1, self.value2, self.answer = self:createAdditionExpression()
end

function AdditionProblemSet:createAdditionExpression()
    local value1, value2 = math.random(self.leftMin, self.leftMax), math.random(self.rightMin, self.rightMax)
        
    return value1, value2, value1 + value2
end

function AdditionProblemSet:validateAnswers(userAnswers)
	local validityFlags = {}

	validityFlags[1] = self:validateAnswer(self.answer, userAnswers[1])
 	
	return validityFlags
end

function AdditionProblemSet:validateAnswer(realAnswer, userAnswer)
    local ret = nil
        
    if userAnswer ~= "" and userAnswer ~= " " and userAnswer ~= nil then
        local userAnswer2 = tonumber( app.rationals:simplifyRational( app.rationals:removeWhiteSpace( tostring( userAnswer ))))
        
        if userAnswer2 and math.abs( userAnswer2 ) >= 0 then -- answer is not nil, and answer is a valid number. Remember tonumber() on web
            if realAnswer == userAnswer2 then
                ret = true
            else
                ret = false
            end
        end
    end
    
    return ret
end

--##PAGE - SUBTRACTION
------------------------------------------------------------------------
------------------------------------------------------------------------
SubtractionPage = class()

function SubtractionPage:init(name)
    self.name = name
    self.pageID, self.viewID, self.view = nil, nil, nil
    self.nextState = app.model.statesList.INIT  
    self.nextSubState = nil
    self.problemSet = SubtractionProblemSet() 
    self.answeredWrong = false
    self.hintUsed = false
    self.validityFlags = nil
end

--State INIT
--Call this state as a reset.
function SubtractionPage:stateInit()
    self.view = app.frame.views[self.viewID]

    --DEBUG ONLY when this is Startup page.
    --if app.frame.selectedMenuID == nil then app.frame.selectedMenuID = app.model.menuChoicesList.PRACTICE end
    --if app.frame.selectedSubMenuID == nil then app.frame.selectedSubMenuID = app.model.subMenuChoicesList.SUBTRACTION end

    self.problemSet:configure()
    
    self.view:stateInit() 

    app.controller.moduleController.activityStartTime = timer.getMilliSecCounter()
    app.timer:start(app.model.timerIDs.MAINTIMER)
    
    app.controller:setNextState(self.pageID, app.model.statesList.ACTIVITY, app.model.subStatesList.START)
end

--State ACTIVITY
function SubtractionPage:subStateStart()
    self.problemSet:generateProblem()
    app.controller.moduleController.currentProblem = app.controller.moduleController.currentProblem + 1
    self.answeredWrong = false
    self.hintUsed = false

    self.view:subStateStart()
    app.controller.moduleController.sleepStartTime = app.timer:getMilliSecCounter() 
    app.timer:start(app.model.timerIDs.SLEEPTIMER)

    app.controller:setNextState(self.pageID, app.model.statesList.ACTIVITY, app.model.subStatesList.USER_INPUT)
end

function SubtractionPage:subStateUserInput() 
    self.view:subStateUserInput()
    
    app.controller.moduleController.sleepStartTime = app.timer:getMilliSecCounter() 
    self:startHintTimer()
end

function SubtractionPage:subStateProcessInput() 
    local view = self.view

	self.validityFlags = self.problemSet:validateAnswers({view.textbox1:getText(), view.textbox2:getText()})

    if self.validityFlags[1] == true and self.validityFlags[2] == true then
        self:correctAnswer()
    elseif self.validityFlags[1] == nil or self.validityFlags[2] == nil then 
        self:emptyAnswer()
    elseif self.validityFlags[1] == false or self.validityFlags[2] == false then 
        self:wrongAnswer()
    end
end

function SubtractionPage:subStateWaitForNext() 
    self.view:subStateWaitForNext()
end

--State END
function SubtractionPage:stateEnd() end

function SubtractionPage:correctAnswer()
    app.timer:stop(app.model.timerIDs.HINTTIMER)
    
    if self.hintUsed == true then app.controller.moduleController.hintsCounter = app.controller.moduleController.hintsCounter + 1 end
    if self.answeredWrong ~= true then app.controller.moduleController.numberCorrect = app.controller.moduleController.numberCorrect + 1 end 

    self.view:correctAnswer()

    app.controller:setNextState(app.model.pageIDs.SUBTRACTION_PAGE, app.model.statesList.ACTIVITY, app.model.subStatesList.WAIT_FOR_NEXT)
end

function SubtractionPage:wrongAnswer()
    self.answeredWrong = true   --Any wrong answer triggers this flag.
    self.view:wrongAnswer()
end

function SubtractionPage:emptyAnswer()
    self.view:emptyAnswer()
end

function SubtractionPage:startHintTimer()
    if app.timer.timers[app.model.timerIDs.HINTTIMER] ~= true then
        app.timer:start(app.model.timerIDs.HINTTIMER)
        app.controller.moduleController.hintTimerStart = app.timer:getMilliSecCounter()
    end
end

--## 
------------------------------------------------------------------------
SubtractionView = class()

function SubtractionView:init(name)
    self.name = name
    self.title = app.TITLE
    self.needsViewSetup = true
    self.needsResize = nil  --Neutral until the first on.resize() is called by the OS
    self.needsLayout = nil  --Once needsLayout is set to true, it will always be true
    self.scrollPane = nil
    self.panex = 1;  self.paney = 1;  self.panew = 1;  self.paneh = 1;
    self.x = 0; self.y = 0; self.w = 1; self.h = 1;
    self.scaleFactor = 1
	self.numberOfColumns = 1
    self.viewStyle = app.viewStyles.STANDARD   --STANDARD, LARGE
    self.toAddVHWhitespace = false -- flag that tells us that whitespace should be added
    self.backgroundColor = { app.BACKGROUND_COLOR }
    self.hasTouched = false
    self.layouts = SubtractionLayouts(self)
    self.setups = SubtractionSetups(self)
    self.modifys = SubtractionModifys(self)
    self.clears = SubtractionClears(self)
end

function SubtractionView:stateInit()
    --Frame UI    
    app.frame.imageWaitCursor:setVisible(false)
    app.frame:hideFooterObjects()   --Hide all the current footer objects since the footer is shared between pages.
    app.frame.footer:setVisible(true)
    app.frame.buttonMenu:setActive(true)    --The menu button may have been disabled during switchPages()
    app.frame.keyboard.lockVisibility = true    --Don't allow the framework to hide the keyboard automatically.

    --View UI
    self.modifys:modifyView()
    self:hideStopwatch()
    self.clears:clearHints()
    self.textbox1:setActive(true)    --The textbox may have been disabled during switchPages()
    self.scrollPane:scrollIntoView("TOP", 0)        --reset the scroll percentage

    app.frame.UIMgr:switchFocus(self.initFocus)     --switchFocus after all objects have been enabled and set visible.
    app.frame.pageView:updateView(self)               --Reposition scrollpane objects and update vh        
end

function SubtractionView:subStateStart()
    self.button1:setFillColor(self.button1.initFillColor)
    self.buttonNext:setFillColor(self.buttonNext.initFillColor)
    self.hint2:setVisible(false)
    self.hint3:setVisible(false)
    self.textbox1:setText("")
    self.textbox1:setActive(true)
    self.textbox2:setText("")
    self.textbox2:setActive(true)
    self.modifys:modifyProblemString()
    self.feedbackTextbox1:setVisible(false)
    self.feedbackTextbox2:setVisible(false)
    app.frame.pageView.moduleView:modifyFooter(self)

    self.initFocus = self.textbox1.name
    app.frame.UIMgr:switchFocus(self.initFocus)     --switchFocus after all objects have been enabled and set visible.
end

function SubtractionView:subStateUserInput()
    local hideTable = { app.frame.imageWaitCursor, self.buttonNext, }
    local visibleTable = { app.frame.footer, self.paragraphProblem, self.paragraphProblem2, self.textbox1, self.textbox2, self.button1, app.frame.keyboard }
    local activeTable = { self.button1, self.textbox1, self.textbox2}
    
    app.frame.pageView:setObjectVisibility(visibleTable, hideTable, activeTable)
    app.frame.pageView.moduleView:showFooterObjects(self)
end

function SubtractionView:subStateWaitForNext()
    self.button1:setVisible(false)
    self.buttonNext:setVisible(true); self.buttonNext:setActive(true)
    self.initFocus = self.buttonNext.name
    app.frame.UIMgr:switchFocus(self.initFocus)     --Button is now only element that will work.
    app.frame.pageView.moduleView:showFooterObjects(self)
end

function SubtractionView:stateEnd() end

function SubtractionView:correctAnswer()
    self.textbox1:setActive(false)
    self.textbox2:setActive(false)
    self.feedbackTextbox1:setVisible(true)
    self.feedbackTextbox1:setStyle("CheckMark")
    self.feedbackTextbox2:setVisible(true)
    self.feedbackTextbox2:setStyle("CheckMark")
end

function SubtractionView:wrongAnswer()
    if self.page.validityFlags[1] == false then 
        self.initFocus = self.textbox1.name
        self.feedbackTextbox1:setVisible(true)
        self.feedbackTextbox1:setStyle("CrossMark")
    end
    
    if self.page.validityFlags[2] == false then 
        if self.page.validityFlags[1] ~= false then self.initFocus = self.textbox2.name end
        self.feedbackTextbox2:setVisible(true)
        self.feedbackTextbox2:setStyle("CrossMark")
    end

    self.button1:setFillColor(self.button1.initFillColor)
    app.frame.UIMgr:switchFocus(self.initFocus)     --For an empty answer, set focus back to a textbox.
end

function SubtractionView:emptyAnswer()
    if self.page.validityFlags[1] == nil then 
        self.initFocus = self.textbox1.name
        self.feedbackTextbox1:setVisible(false)
    end
    
    if self.page.validityFlags[2] == nil then 
        if self.page.validityFlags[1] ~= nil then self.initFocus = self.textbox2.name end
        self.feedbackTextbox2:setVisible(false)
    end

    self.button1:setFillColor(self.button1.initFillColor)
    app.frame.UIMgr:switchFocus(self.initFocus)     --For an empty answer, set focus back to a textbox.
end

function SubtractionView:updateHint(hintNumber)
    local updateHintFuncs = { function(...) self:updateHint1(...) end, function(...) self:updateHint2(...) end }
    
    updateHintFuncs[hintNumber]()
end

function SubtractionView:showStopwatch()
    self.timerText:setVisible(true)
end

function SubtractionView:hideStopwatch()
    self.timerText:setVisible(false)
end

function SubtractionView:updateStopwatch()
    self.timerText:setText( "Time: ".. string.format( "%.1f", math.floor( ( timer.getMilliSecCounter() - app.controller.moduleController.activityStartTime ) / 100 ) / 10 ))
end

function SubtractionView:updateHint1()
    self.modifys:modifyHintStrings()
    self.hint2:setVisible(true)
end

function SubtractionView:updateHint2()
    self.hint2:setVisible(false)
    self.hint3:setVisible(true)
end

function SubtractionView:clickButton1(view, event) if event == app.model.events.EVENT_MOUSE_UP then app.controller.moduleController:nextSubState(self.page) end end
function SubtractionView:clickButtonNext(view, event) if event == app.model.events.EVENT_MOUSE_UP then app.controller.moduleController:stateEnd(self.page) end end

function SubtractionView:layoutY() if self.page.state then return self.layouts:layoutY() end end 
function SubtractionView:layoutXOneColumn() if self.page.state then return self.layouts:layoutXOneColumn() end end 
function SubtractionView:layoutFooter() return app.frame.pageView.moduleView:layoutFooter(self) end
function SubtractionView:setupView() self.setups:setupView(); self.needsViewSetup = false end
function SubtractionView:updateView() self.modifys:updateView() end

function SubtractionView:enterKey()
    if self.buttonNext and self.buttonNext.hasFocus then
        app.controller.moduleController:stateEnd(self.page)
    else
        app.controller.moduleController:nextSubState(self.page)
    end
end 

--##
------------------------------------------------------
--Functions to be called only once for the life of the module to create widgets.
SubtractionSetups = class()

function SubtractionSetups:init(view)
    self.view = view
end

function SubtractionSetups:setupView()
    self:setupSimpleStrings()
    self:setupButtons()
    self:setupInputBoxes()
    self:setupFeedbacks()
    self:setupKeyboard()
    self:setupRectangles()
    self:setupZOrders()
    self:addTabs()
    app.frame.pageView.moduleView:setupFooter(self.view)
    
    self.view.initFocus = self.view.textbox1.name
end

function SubtractionSetups:setupButtons()
    local view = self.view
    
    view.button1 = app.frame.widgetMgr:newWidget("BUTTON", view.pageID.."_button1", {label = "", initSizeAndPosition = {24, 26, .23, 0}, octagonStyle = true,
                drawCallback = function(...) app.frame.pageView:drawCheckMark(...) end } )  
    view.button1:addListener(function( event, ...) return view:clickButton1(view, event, ...) end)       
    view.scrollPane:addObject(view.button1)  
    app.frame.UIMgr:addListener( view.pageID, function(...) return view.button1:UIMgrListener(...) end )   

    view.buttonNext = app.frame.widgetMgr:newWidget("BUTTON", view.pageID.."_buttonNext", {initSizeAndPosition = {41, 27, .23, 0}, initFontSize = 10, octagonStyle = true,
                drawCallback = nil, label = "Next" } )  
    view.buttonNext:addListener(function( event, ...) return view:clickButtonNext(view, event, ...) end)       
    view.scrollPane:addObject(view.buttonNext)  
    app.frame.UIMgr:addListener( view.pageID, function(...) return view.buttonNext:UIMgrListener(...) end ) 
end

function SubtractionSetups:setupInputBoxes()
    local view = self.view

    view.textbox1 = app.frame.widgetMgr:newWidget("TEXTBOX", view.pageID.."_textbox1", {initSizeAndPosition = {40, 21, .26, .21}, minWidth = 40, labelPosition = "left", maxChar = 5, text = "", initLabelFontSize = 10, keyboardYPosition = 1, allowScroll = false, isDynamicWidth = true, hasGrab = false })
    view.textbox1:addListener(function( event, ...) return view.modifys:textboxListener(event, ...) end) 
    app.frame.UIMgr:addListener(view.pageID,  function(...) return view.textbox1:UIMgrListener(...) end )
    app.frame.keyboard:setTextbox(view.textbox1) 
    view.scrollPane:addObject(view.textbox1)

    view.textbox2 = app.frame.widgetMgr:newWidget("TEXTBOX", view.pageID.."_textbox2", {initSizeAndPosition = {40, 21, .26, .21}, minWidth = 40, labelPosition = "left", maxChar = 5, text = "", initLabelFontSize = 10, keyboardYPosition = 1, allowScroll = false, isDynamicWidth = true, hasGrab = false })
    view.textbox2:addListener(function( event, ...) return view.modifys:textboxListener(event, ...) end) 
    app.frame.UIMgr:addListener(view.pageID,  function(...) return view.textbox2:UIMgrListener(...) end )
    view.scrollPane:addObject(view.textbox2)
end

function SubtractionSetups:setupSimpleStrings()
    local view = self.view
    
    view.paragraphProblem = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID.."_paragraphProblem", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = " = ", active = false })
    view.scrollPane:addObject( view.paragraphProblem )
    
    view.paragraphProblem2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID.."_paragraphProblem2", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = " = ", active = false })
    view.scrollPane:addObject( view.paragraphProblem2 )
    
    view.hintAddend1 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintAddend1", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "", active = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject( view.hintAddend1 )
    
    view.hintAddend2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintAddend2", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "", active = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject( view.hintAddend2 )
    
    view.hintOperation = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hintOperation", {initSizeAndPosition = {50, 21, 0, 0}, fontStyle = "r", fontFamily = "sansserif", text = "+", active = false, visible = false, fontColor = app.graphicsUtilities.Color.blue })
    view.scrollPane:addObject(view.hintOperation)
    
    view.hint1 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint1", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint1)
    
    view.hint2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint2", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint2)

    view.hint3 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_hint3", { initSizeAndPosition = {0, 0, 0, 0}, fontColor = app.graphicsUtilities.Color.blue, text = "", active = false, visible = false })
    view.scrollPane:addObject(view.hint3)

    view.timerText = app.frame.widgetMgr:newWidget("SIMPLE_STRING", view.pageID .. "_timerText", { initSizeAndPosition = {0, 0, 0, 0}, text = "Time: 0.0", active = false, initFontSize = 8, visible = true })
    view.scrollPane:addObject( view.timerText )
end

function SubtractionSetups:setupFeedbacks()
    local view = self.view
    
	view.feedbackTextbox1 = app.frame.widgetMgr:newWidget("FEEDBACK", view.pageID.."_feedbackTextbox1", {visible = false, initSizeAndPosition = {0, 0, 0, 0} })
	view.feedbackTextbox1:setStyle("CrossMark")
    view.scrollPane:addObject(view.feedbackTextbox1)

	view.feedbackTextbox2 = app.frame.widgetMgr:newWidget("FEEDBACK", view.pageID.."_feedbackTextbox2", {visible = false, initSizeAndPosition = {0, 0, 0, 0} })
    view.feedbackTextbox2:setStyle("CrossMark")
    view.scrollPane:addObject(view.feedbackTextbox2)
end

function SubtractionSetups:setupRectangles()
    local view = self.view

    view.equalLine = app.frame.widgetMgr:newWidget("RECTANGLE", view.pageID.."_equalLine", { initSizeAndPosition = { 1, 2, 0, 0 }, visible = false })
    view.equalLine.fillColor = app.graphicsUtilities.Color.blue
    view.equalLine.borderColor = app.graphicsUtilities.Color.blue
    view.scrollPane:addObject( view.equalLine )
end

function SubtractionSetups:setupKeyboard()
	local view = self.view
	
	app.frame.pageView:attachKeyboard(view) -- attach the keyboard on this page's scrollpane
    view.scrollPane:addObject(app.frame.keyboard)
    app.frame.keyboard.hasGrab = true
    app.frame.keyboard.showDragIcon = true
end

function SubtractionSetups:setupZOrders()
	local view = self.view

--    view.scrollPane:setZOrder( view.critterPath.name, 1 )   --Below everything
    view.scrollPane:setZOrder( app.frame.keyboard.name, #view.scrollPane.zOrder )   --Above everything
end

function SubtractionSetups:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr
    
    local list = {app.frame.buttonMenu, view.textbox1, view.textbox2, view.button1, view.buttonNext}
                                     
    UIMgr:addPageTabObjects(view.pageID, list)
    UIMgr:setPageTabSequence(view.pageID, list) 
end

--##
-------------------------------------------------------
--Functions to position widgets initially and for resize.
SubtractionLayouts = class()

function SubtractionLayouts:init(view)
    self.view = view
end

function SubtractionLayouts:layoutY()
    local view = self.view
    local anchorData = {}       
    local idx = 1

    app.frame.keyboard.keysIndex = 1

    anchorData, idx = self:layoutYStandard(anchorData, idx)

    return anchorData
end

function SubtractionLayouts:layoutYStandard(anchorData, idx)
    local view = self.view
    
    anchorData[idx] = {object = view.paragraphProblem, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -40}; idx = idx + 1
    anchorData[idx] = {object = view.textbox1, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -40}; idx = idx + 1
    anchorData[idx] = {object = view.paragraphProblem2, anchorTo = view.paragraphProblem, anchorPosition = "Bottom", position = "Top", offset = 40}; idx = idx + 1
    anchorData[idx] = {object = view.textbox2, anchorTo = view.paragraphProblem2, anchorPosition = "Middle", position = "Middle", offset = 0}; idx = idx + 1
    anchorData[idx] = { object = view.button1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.buttonNext, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend2, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hintOperation, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint1, anchorTo = view.hintOperation, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint2, anchorTo = view.textbox1, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.hint3, anchorTo = view.textbox1, anchorPosition = "Bottom", position = "Top", offset = 5 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox1, anchorTo = view.textbox1, anchorPosition = "Top", position = "Bottom", offset = -5 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox2, anchorTo = view.textbox2, anchorPosition = "Top", position = "Bottom", offset = -5 } idx = idx + 1
    anchorData[idx] = { object = view.timerText, anchorTo = view.scrollPane, anchorPosition = "PaneBottom", position = "Bottom", offset = -10 } idx = idx + 1

    return anchorData, idx
end
    
function SubtractionLayouts:layoutXOneColumn()
    local view = self.view
    local anchorData = {}       
   
    anchorData = self:layoutXStandard()
    
    return anchorData
end

function SubtractionLayouts:layoutXStandard()
    local view = self.view
    local anchorData = {}
    local idx = 1
    local sf = 1
    local counter1 = 0
    local counter2 = 0
    
    local maxaddend = math.max( counter1, counter2 )
    
    anchorData[idx] = {object = view.paragraphProblem, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -40}; idx = idx + 1
    anchorData[idx] = {object = view.textbox1, anchorTo = view.paragraphProblem, anchorPosition = "Right", position = "Left", offset = 0} idx = idx + 1
    anchorData[idx] = {object = view.paragraphProblem2, anchorTo = view.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = -40}; idx = idx + 1
    anchorData[idx] = {object = view.textbox2, anchorTo = view.paragraphProblem, anchorPosition = "Right", position = "Left", offset = 0} idx = idx + 1
    anchorData[idx] = { object = view.button1, anchorTo = view.textbox1, anchorPosition = "Right", position = "Left", offset = 10 } idx = idx + 1
    anchorData[idx] = { object = view.buttonNext, anchorTo = view.textbox1, anchorPosition = "Right", position = "Left", offset = 10 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend1, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hintAddend2, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hintOperation, anchorTo = view.hintAddend2, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.hint1, anchorTo = view.paragraphProblem, anchorPosition = "Left", position = "Right", offset = -8 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox1, anchorTo = view.textbox1, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.feedbackTextbox2, anchorTo = view.textbox2, anchorPosition = "Middle", position = "Middle", offset = 0 } idx = idx + 1
    anchorData[idx] = { object = view.timerText, anchorTo = view.scrollPane, anchorPosition = "PaneLeft", position = "Left", offset = 5 } idx = idx + 1

    return anchorData
end

--##
------------------------------------------------------------------------
--Functions to modify widgets in response to user actions.
SubtractionModifys = class()

function SubtractionModifys:init(view)
    self.view = view
end

function SubtractionModifys:modifyView()
    local view = self.view
    
    self:modifyProblemString()
    self:modifyKeyboard()
    self:modifyStopwatch()
    app.frame.pageView.moduleView:modifyFooter(view)
end

function SubtractionModifys:modifyProblemString()
    local view = self.view
    local addend1 = tostring(view.page.problemSet.value1[1])
    local addend2 = tostring(view.page.problemSet.value2[1])
    local operation = view.page.problemSet.operationString

    local text = addend1.." "..operation.." "..addend2.." = "
    view.paragraphProblem:modifyProperties({ text = text })
    view.paragraphProblem:setPosition( view.textbox1.pctx - view.paragraphProblem:calculateWidth( view.paragraphProblem.scaleFactor ) / view.paragraphProblem.panew, view.paragraphProblem.pcty )

    addend1 = tostring(view.page.problemSet.value1[2])
    addend2 = tostring(view.page.problemSet.value2[2])
    text = addend1.." "..operation.." "..addend2.." = "
    view.paragraphProblem2:modifyProperties({ text = text })
    view.paragraphProblem2:setPosition( view.textbox1.pctx - view.paragraphProblem2:calculateWidth( view.paragraphProblem2.scaleFactor ) / view.paragraphProblem2.panew, view.paragraphProblem2.pcty )
end

function SubtractionModifys:modifyStopwatch()
    self.view.timerText:setText("Time: 0.0")
end

function SubtractionModifys:updateView()
end

function SubtractionModifys:textboxListener( event, ... )
    local view = self.view

    app.frame.keyboard:textBoxListener( event, ... )

    return true
end

function SubtractionModifys:modifyKeyboard()
    if app.frame.keyboard.active == true then app.frame.keyboard:setVisible(true) end
end

function SubtractionModifys:modifyHintStrings()
    local view = self.view

    local addend1 = view.page.problemSet.value1[1]
    local addend2 = view.page.problemSet.value2[1]
    
    view.hintAddend1:modifyProperties({ text = tostring(addend1), visible = false })
    view.hintAddend2:modifyProperties({ text = tostring(addend2), visible = false })
    view.hintOperation:modifyProperties({ visible = false })
    view.hint1:modifyProperties({ text = tostring( app.rationals:add(addend1, addend2)), visible = false })
    view.hint2:modifyProperties({ text = self:formatHint(addend1, addend2), visible = false })
    view.hint2:setPosition( view.paragraphProblem.pctx, view.hint2.pcty )
    view.hint3:modifyProperties({ text = view.hint2.text..tostring(addend1 - addend2) , visible = false })
    view.hint3:setPosition( view.paragraphProblem.pctx, view.hint3.pcty )
end

function SubtractionModifys:formatHint( addend1, addend2 )
--    local ans = app.rationals:add( addend1, addend2 )
    local txt = nil

--    local mod = app.rationals:mod( ans, 10 )
--    local quotient = app.rationals:divide( ans, 10 )
--    local newAddend2 = addend2 - mod
--    local hasNoZero = addend1 ~= 0 or addend2 ~= 0
--    local isGreaterThan1 = addend1 > 1 or addend2 > 1
    
--    if addend2 == 11 or addend2 == 12 or addend2 == 15 or addend2 == 16  then
--        newAddend2 = 10
--        mod = addend2 - 10
--    end
        
--    if mod > 0 and quotient > 1 and newAddend2 > 0 and hasNoZero and isGreaterThan1 then -- the answer is more than 10
--        txt = addend1 .. " - " .. addend2 .. " = ( " .. addend1 .. " - " .. newAddend2 .. " ) + " .. mod .. " = "
--    else
        txt = addend1 .. " - " .. addend2 .. " = "
--    end
    
    return txt
end

--##
------------------------------------------------------------------------
--Functions to clear widgets at start of activity.
SubtractionClears = class()

function SubtractionClears:init(view)
    self.view = view
end

function SubtractionClears:clearHints()
    local view = self.view
    
    view.hint2:setVisible(false)
    view.hint3:setVisible(false)
end

--##
----------------------------------------------------------------------
--Functions to generate problem data
SubtractionProblemSet = class()

function SubtractionProblemSet:init()
    self.value1, self.value2, self.answer = {0, 0}, {0, 0}, {0, 0}
    self.leftAddend = 0
    self.multiplier = 0
    self.operationString = "-"
    
    --Left addend min, left addend max, right addend min, right addend max 
    self.minMax = {6, 12, 0, 6}
end

function SubtractionProblemSet:configure()
    self.leftMin, self.leftMax, self.rightMin, self.rightMax = self.minMax[1], self.minMax[2], self.minMax[3], self.minMax[4]
    self.leftAddend = self.leftMin  --Starting value. 
end

function SubtractionProblemSet:generateProblem()
    self.value1[1], self.value2[1], self.answer[1] = self:createSubtractionExpression()
    self.value1[2], self.value2[2], self.answer[2] = self:createSubtractionExpression()
end

function SubtractionProblemSet:createSubtractionExpression()
    local value1, value2 = math.random(self.leftMin, self.leftMax), math.random(self.rightMin, self.rightMax)
        
    return value1, value2, value1 - value2
end

function SubtractionProblemSet:validateAnswers(userAnswers)
	local validityFlags = {}

	validityFlags[1] = self:validateAnswer(self.answer[1], userAnswers[1])
	validityFlags[2] = self:validateAnswer(self.answer[2], userAnswers[2])
 	
	return validityFlags
end

function SubtractionProblemSet:validateAnswer(realAnswer, userAnswer)
    local ret = nil
        
    if userAnswer ~= "" and userAnswer ~= " " and userAnswer ~= nil then
        local userAnswer2 = tonumber( app.rationals:simplifyRational( app.rationals:removeWhiteSpace( tostring( userAnswer ))))
        
        if userAnswer2 and math.abs( userAnswer2 ) >= 0 then -- answer is not nil, and answer is a valid number. Remember tonumber() on web
            if realAnswer == userAnswer2 then
                ret = true
            else
                ret = false
            end
        end
    end
    
    return ret
end

--##PAGE - SLEEP
------------------------------------------------------------------------
SleepPage = class()

function SleepPage:init(name)
    self.name = name
    self.pageID, self.viewID, self.view = nil, nil, nil
    self.nextState = app.model.statesList.INIT   
    self.nextSubState = nil
    self.pauseStartTime = 0
end

function SleepPage:stateInit()
    self.view = app.frame.views[self.viewID]

    self.pauseStartTime = app.timer:getMilliSecCounter()
    app.timer:start( app.model.timerIDs.SLEEPTIMER )

    self.view:stateInit()    
end

function SleepPage:handleSleepTimer()
    -- only have a sleep page when there's no problem data detected
    if app.controller.moduleController.isDailySkillMode then
        return
    end
    
    if app.controller.activePageID == self.pageID then
        if app.timer:getMilliSecCounter() - self.pauseStartTime >= app.model.RESET_PAUSE_TIME then -- switch from sleep page to about page
                app.timer:stop( app.model.timerIDs.SLEEPTIMER )
            app.controller:switchPages(app.model.pageIDs.ABOUT_PAGE)
        end
    else
        if app.timer:getMilliSecCounter() - app.controller.moduleController.sleepStartTime >= app.model.PAUSE_TIME then
            app.timer:stop( app.model.timerIDs.SLEEPTIMER )
            app.controller.moduleController:preSleep()
            app.controller:setNextState(app.model.pageIDs.SLEEP_PAGE, app.model.statesList.INIT, nil)
            app.controller:switchPages( app.model.pageIDs.SLEEP_PAGE )
        end
    end
end

function SleepPage:startOver()
    if app.controller.moduleController.activity == app.model.activitiesList.PRACTICE then
        app.controller.moduleController:beginPractice(app.controller.previousPageID)
    elseif app.controller.moduleController.activity == app.model.activitiesList.QUIZ then
        app.controller.moduleController:beginQuiz()
    end
end

function SleepPage:resume()
    if app.frame.keyboard.active == true then app.frame.keyboard:setVisible(true) end   --Keyboard may have been hidden by Sleep Page
    app.controller.moduleController:postSleep(app.frame.views[app.controller.previousPageID])
    app.timer:start( app.model.timerIDs.SLEEPTIMER )
    app.controller:setNextState(app.controller.previousPageID, app.controller.pages[app.controller.previousPageID].state, app.controller.pages[app.controller.previousPageID].subState)
    app.controller:switchPages(app.controller.previousPageID)
end

------------------------------------------------------------------------
SleepView = class()

function SleepView:init(name)
    self.name = name
    self.title = app.TITLE
    self.needsViewSetup = true
    self.needsResize = nil  --Neutral until the first on.resize() is called by the OS
    self.needsLayout = nil  --Once needsLayout is set to true, it will always be true
    self.scrollPane = nil
    self.panex = 1;  self.paney = 1;  self.panew = 1;  self.paneh = 1;
    self.x = 0; self.y = 0; self.w = 1; self.h = 1;
    self.scaleFactor = 1
	self.numberOfColumns = 1
    self.viewStyle = app.viewStyles.STANDARD   --STANDARD, LARGE
    self.toAddVHWhitespace = false -- flag that tells us that whitespace should be added
    self.backgroundColor = { app.BACKGROUND_COLOR }
end

function SleepView:setupView() 
    self:setupButtons()
    self:setupSimpleStrings()
    self:addTabs()
    self.initFocus = self.buttonB.name
    self.needsViewSetup = false
end

function SleepView:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr

    local list = {app.frame.buttonMenu}
                                     
    UIMgr:addPageTabObjects(self.pageID, list)
    UIMgr:setPageTabSequence(self.pageID, list) 
end

function SleepView:stateInit()
    --Frame UI
    app.frame.imageWaitCursor:setVisible(false)
    app.frame:hideFooterObjects()   --Hide all the current footer objects since the footer is shared between pages.
    app.frame.footer:setVisible(true)
    app.frame.buttonMenu:setActive(true)    --The menu button may have been disabled during switchPages()
    app.frame.keyboard:setVisible(false)

    --View UI
    self:modifySimpleStrings()
    self:modifyButtons()
    self.buttonA:setActive(true)    --UI objects may have been disabled during switchPages()
    self.buttonB:setActive(true)    

    app.frame.UIMgr:switchFocus(self.initFocus)
    self.scrollPane:scrollIntoView("TOP", 0)        --reset the scroll percentage
    app.frame.pageView:updateView(self)               --Reposition scrollpane objects and update vh        
end

function SleepView:layoutY()
    local anchorData = {}
    local idx = 1
    
    anchorData[idx] = {object = self.asleepText, anchorTo = self.scrollPane, anchorPosition = "PaneTop", position = "Top", offset = 30}; idx = idx + 1
    anchorData[idx] = {object = self.buttonA, anchorTo = self.asleepText, anchorPosition = "Bottom", position = "Top", offset = 20}; idx = idx + 1
    anchorData[idx] = {object = self.buttonB, anchorTo = self.buttonA, anchorPosition = "Middle", position = "Middle", offset = 0}; idx = idx + 1
    
    return anchorData
end

function SleepView:layoutXOneColumn()
    local anchorData = {}
    local idx = 1
    
    anchorData[idx] = {object = self.asleepText, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}; idx = idx + 1
    anchorData[idx] = {object = self.buttonA, anchorTo = self.asleepText, anchorPosition = "PaneMiddle", position = "Right", offset = -10}; idx = idx + 1
    anchorData[idx] = {object = self.buttonB, anchorTo = self.buttonA, anchorPosition = "PaneMiddle", position = "Left", offset = 10}; idx = idx + 1
    
    return anchorData
end

function SleepView:setupButtons()
    self.buttonA = app.frame.widgetMgr:newWidget("BUTTON", self.pageID.."_buttonA", {label = "Start Over", initSizeAndPosition = {80, 27, .45, 0}, initFontSize = 10, octagonStyle = true,} )  
    self.buttonA:addListener(function( event, ...) return self:clickButtonA(event, ...) end)       
    app.frame.UIMgr:addListener(self.pageID,  function(...) return self.buttonA:UIMgrListener(...) end )      
    self.scrollPane:addObject(self.buttonA)  

    self.buttonB = app.frame.widgetMgr:newWidget("BUTTON", self.pageID.."_buttonB", {label = "Continue", initSizeAndPosition = {70, 27, .45, 0}, initFontSize = 10, octagonStyle = true,} )
    self.buttonB:addListener(function( event, ...) return self:clickButtonB(event, ...) end)           
    app.frame.UIMgr:addListener(self.pageID,  function(...) return self.buttonB:UIMgrListener(...) end )   
    self.scrollPane:addObject(self.buttonB)  
end

function SleepView:modifyButtons()
    self.buttonA:modifyProperties( {fillColor = self.buttonA.initFillColor})
    self.buttonB:modifyProperties( {fillColor = self.buttonB.initFillColor})
end

function SleepView:setupSimpleStrings()
    self.asleepText = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_asleepText", {initFontSize = 16, fontStyle = "b", fontFamily = "sansserif", fontColor = app.graphicsUtilities.Color.cyanish2,
       initSizeAndPosition = {200, 10, .10, 0}, active = false } )
    self.scrollPane:addObject(self.asleepText)
end

function SleepView:modifySimpleStrings()
    self.asleepText:setText( "Did you fall asleep?" )
end

function SleepView:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr
    
    local list = {app.frame.buttonMenu, app.frame.buttonView, self.buttonA, self.buttonB}
                     
    app.frame.UIMgr:addPageTabObjects(self.pageID, list)
    app.frame.UIMgr:setPageTabSequence(self.pageID, list) 
end

function SleepView:enterKey()
    if self.buttonA.hasFocus then
        self.buttonA:setFillColor(self.buttonA.mouseDownColor)    --This acts like hourglass mouse cursor
        self.page:startOver()
    elseif self.buttonB.hasFocus then
        self.buttonB:setFillColor(self.buttonB.mouseDownColor)    --This acts like hourglass mouse cursor
        self.page:resume()
    end
end

function SleepView:clickButtonA(event)
    if event == app.model.events.EVENT_MOUSE_UP then
        self.buttonA:setFillColor(self.buttonA.mouseDownColor)    --This acts like hourglass mouse cursor
        app.controller:postMessage({function(...) self.page:startOver() end})    --Give Start Over button a chance to paint 
    end
end

function SleepView:clickButtonB(event)
    if event == app.model.events.EVENT_MOUSE_UP then
        self.buttonB:setFillColor(self.buttonB.mouseDownColor)    --This acts like hourglass mouse cursor
        app.controller:postMessage({function(...) self.page:resume() end})    --Give Resume button a chance to paint 
    end
end

--##PAGE - SCORE
------------------------------------------------------------------------
ScorePage = class()

function ScorePage:init(name)
    self.name = name
    self.pageID, self.viewID, self.view = nil, nil, nil
    self.nextState = app.model.statesList.INIT   
    self.nextSubState = nil
end

function ScorePage:stateInit()
    self.view = app.frame.views[self.viewID]

    self.view:stateInit()    
end

------------------------------------------------------------------------
ScoreView = class()

function ScoreView:init(name)
    self.name = name
    self.title = app.TITLE
    self.needsViewSetup = true
    self.needsResize = nil  --Neutral until the first on.resize() is called by the OS
    self.needsLayout = nil  --Once needsLayout is set to true, it will always be true
    self.scrollPane = nil
    self.panex = 1;  self.paney = 1;  self.panew = 1;  self.paneh = 1;
    self.x = 0; self.y = 0; self.w = 1; self.h = 1;
    self.scaleFactor = 1
	self.numberOfColumns = 1
    self.viewStyle = app.viewStyles.STANDARD   --STANDARD, LARGE
    self.toAddVHWhitespace = false -- flag that tells us that whitespace should be added
    self.backgroundColor = { app.BACKGROUND_COLOR }
end

function ScoreView:setupView() 
    self:setupCompleteMessage()
    self:addTabs()
    self.initFocus = "frame_buttonmenu"
    self.needsViewSetup = false
end

function ScoreView:stateInit()
    --Frame UI
    app.frame.imageWaitCursor:setVisible(false)
    app.frame:hideFooterObjects()   --Hide all the current footer objects since the footer is shared between pages.
    app.frame.footer:setVisible(true)
    app.frame.buttonMenu:setActive(true)    --The menu button may have been disabled during switchPages()

    --View UI
    self:modifyCompleteMessage()

    self.scrollPane:scrollIntoView("TOP", 0)        --reset the scroll percentage
    app.frame.UIMgr:switchFocus(self.initFocus)
    app.frame.pageView:updateView(self)               --Reposition scrollpane objects and update vh        
end

function ScoreView:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr
    
    local list = {app.frame.buttonMenu}
                         
    app.frame.UIMgr:addPageTabObjects(self.pageID, list)
    app.frame.UIMgr:setPageTabSequence(self.pageID, list) 
end

function ScoreView:layoutY()
    local anchorData = {}
    local idx = 1
    
    anchorData[idx] = {object = self.completeMsg1, anchorTo = self.scrollPane, anchorPosition = "PaneTop", position = "Top", offset = 20}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg2, anchorTo = self.completeMsg1, anchorPosition = "Bottom", position = "Top", offset = 10}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg3, anchorTo = self.completeMsg2, anchorPosition = "Bottom", position = "Top", offset = 10}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg4, anchorTo = self.completeMsg2, anchorPosition = "Bottom", position = "Top", offset = 10}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg5, anchorTo = self.completeMsg4, anchorPosition = "Bottom", position = "Top", offset = 10}; idx = idx + 1

    return anchorData
end

function ScoreView:layoutXOneColumn()
    local anchorData = {}
    local idx = 1
    
    anchorData[idx] = {object = self.completeMsg1, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg2, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg3, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg4, anchorTo = self.completeMsg3, anchorPosition = "Right", position = "Left", offset = 20}; idx = idx + 1
    anchorData[idx] = {object = self.completeMsg5, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}; idx = idx + 1

    return anchorData
end

function ScoreView:setupCompleteMessage()
    self.completeMsg1 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_completeMsg1", {initFontSize = 16, fontStyle = "b", fontColor = app.graphicsUtilities.Color.cyanish, visible = true } )
    self.scrollPane:addObject(self.completeMsg1)
    
    self.completeMsg2 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_completeMsg2", {initFontSize = 12, fontStyle = "b", fontColor = app.graphicsUtilities.Color.black, visible = true } )
    self.scrollPane:addObject(self.completeMsg2)
    
    self.completeMsg3 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_completeMsg3", {initFontSize = 12, fontStyle = "b", fontColor = app.graphicsUtilities.Color.black, visible = true } )
    self.scrollPane:addObject(self.completeMsg3)

    self.completeMsg4 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_completeMsg4", {initFontSize = 12, fontStyle = "b", fontColor = app.graphicsUtilities.Color.black, visible = true } )
    self.scrollPane:addObject(self.completeMsg4)

    self.completeMsg5 = app.frame.widgetMgr:newWidget("SIMPLE_STRING", self.pageID.."_completeMsg5", {initFontSize = 12, fontStyle = "b", fontColor = app.graphicsUtilities.Color.black, visible = true } )
    self.scrollPane:addObject(self.completeMsg5)
end

function ScoreView:modifyCompleteMessage()
    local txtMessage1 = "Practice Complete!"
	if app.controller.moduleController.activity == app.model.activitiesList.QUIZ then txtMessage1 = "Quiz Complete!" end
    local txtMessage2 = app.model.subMenuMessagesList[app.frame.selectedSubMenuID]
    local txtMessage3 = app.controller.moduleController.numberCorrect.." out of "..app.controller.moduleController.totalProblems
    local txtMessage4 = "("..app.controller.moduleController.hintsCounter.." hints)"
    local txtMessage5 = app.controller.moduleController.activityTotalTime.." seconds"

    self.completeMsg1:setText(txtMessage1)
    self.completeMsg2:setText(txtMessage2)
    self.completeMsg3:setText(txtMessage3)
    self.completeMsg4:setText(txtMessage4)
    self.completeMsg5:setText(txtMessage5)
end

--##PAGE - ABOUT
------------------------------------------------------------------------
AboutPage = class()

function AboutPage:init(name)
    self.name = name
    self.pageID, self.viewID, self.view = nil, nil, nil
    self.nextState = app.model.statesList.INIT  
    self.nextSubState = nil
end

function AboutPage:stateInit()
    self.view = app.frame.views[self.viewID]

    self.view:stateInit()    

    self.view.showVersion = true
end

------------------------------------------------------------------------
AboutView = class()

function AboutView:init(name)
    self.name = name
    self.title = app.TITLE
    self.needsViewSetup = true
    self.needsResize = nil  --Neutral until the first on.resize() is called by the OS
    self.needsLayout = nil  --Once needsLayout is set to true, it will always be true
    self.scrollPane = nil
    self.panex = 1;  self.paney = 1;  self.panew = 1;  self.paneh = 1;
    self.x = 0; self.y = 0; self.w = 1; self.h = 1;
    self.scaleFactor = 1
	self.numberOfColumns = 1
    self.viewStyle = app.viewStyles.STANDARD   --STANDARD, LARGE
    self.toAddVHWhitespace = false -- flag that tells us that whitespace should be added
    self.backgroundColor = { app.BACKGROUND_COLOR }
    self.showVersion = false 

    --Image Sizes
    self.imageCoverSplash_initWidth, self.imageCoverSplash_initHeight = 486*.4, 598*.4     --This image is only on the opening screen. 
    self.imageCoverSplash_initPctX, self.imageCoverSplash_initPctY = .05, .15 
    self.imageSplash_initWidth, self.imageSplash_initHeight = 486*.2, 598*.2   --This image is on the About page.
    self.imageEWLogo_initWidth, self.imageEWLogo_initHeight = 80, 24
    
    -- Image Offset
    self.imageSplash_xOffset, self.imageSplash_yOffset = 0, 5
    self.imageEWLogo_yOffset = -20
end

function AboutView:setupView() 
    self:setupImages()
    self:setupFooter()
    self:addTabs()
    self.initFocus = "frame_buttonmenu"
    self.needsViewSetup = false
end

function AboutView:stateInit()
    --Frame UI
    app.frame.imageWaitCursor:setVisible(false)
    app.frame:hideFooterObjects()   --Hide all the current footer objects since the footer is shared between pages.
    app.frame.footer:setVisible(true)
    app.frame.buttonMenu:setActive(true)    --The menu button may have been disabled during switchPages()

    --View UI
    if self.showVersion then 
        self:modifyImages()
        self:modifyFooter()
    end    

    self.scrollPane:scrollIntoView("TOP", 0)        --reset the scroll percentage
    app.frame.UIMgr:switchFocus(self.initFocus)
    app.frame.pageView:updateView(self)               --Reposition scrollpane objects and update vh        
end

function AboutView:addTabs()
    local view = self.view
    local UIMgr = app.frame.UIMgr
    
    local list = {app.frame.buttonMenu}
                                     
    UIMgr:addPageTabObjects(self.pageID, list)
    UIMgr:setPageTabSequence(self.pageID, list) 
end

function AboutView:resize( x, y, w, h, scaleFactor )
    self.panex = x  self.paney = y  self.panew = w  self.paneh = h
    self.x = x; self.y = y; self.w = w; self.h = h; self.scaleFactor = scaleFactor

    app.frame.pageView:resizeScrollPane( self )
    
    if self.imageCoverSplash then self.imageCoverSplash:resize( x, y, w, h, scaleFactor ) end

    self.needsLayout = true     --This will remain true forever (per page)
    self.needsResize = false
end

function AboutView:paint( gc )
    self.scrollPane:paint(gc)       --Paint the scroll pane and its objects
    
    if self.imageCoverSplash then self.imageCoverSplash:paint( gc ) end
end

function AboutView:layoutY()
    local anchorData = {}
    
    anchorData[1] = {object = self.imageSplash1, anchorTo = self.scrollPane, anchorPosition = "PaneTop", position = "Top", offset = self.imageSplash_yOffset}
    anchorData[2] = {object = self.imageObject1, anchorTo = self.scrollPane, anchorPosition = "PaneBottom", position = "Bottom", offset = self.imageEWLogo_yOffset}

    return anchorData
end

function AboutView:layoutXOneColumn()
    local anchorData = {}
    
    anchorData[1] = {object = self.imageSplash1, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = self.imageSplash_xOffset }
    anchorData[2] = {object = self.imageObject1, anchorTo = self.scrollPane, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}

    return anchorData
end

function AboutView:layoutFooter()
    local anchorDataX, anchorDataY = {}, {}

    anchorDataX[1] = {object = self.footerProgramCopyright, anchorTo = app.frame.footer, anchorPosition = "PaneLeft", position = "Left", offset = 9}
    anchorDataY[1] = {object = self.footerProgramCopyright, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}

    anchorDataX[2] = {object = self.footerVersion, anchorTo = app.frame.footer, anchorPosition = "PaneRight", position = "Right", offset = -15}
    anchorDataY[2] = {object = self.footerVersion, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}
    
    return anchorDataX, anchorDataY
end

function AboutView:setupFooter()
    local name = self.pageID.."_footerVersion"
    self.footerVersion = app.frame:addFooterObject(name, function() return app.frame.widgetMgr:newWidget("SIMPLE_STRING", name, {initFontSize = 6, fontStyle = "b", fontColor = {0, 0, 0} } ) end)

    name = self.pageID.."_footerProgramCopyright"
    self.footerProgramCopyright = app.frame:addFooterObject(name, function() return app.frame.widgetMgr:newWidget("SIMPLE_STRING", name, {initFontSize = 6, fontStyle = "b", fontColor = {0, 0, 0} } ) end)
end

function AboutView:modifyFooter()
    self.footerVersion:modifyProperties( {text = "Version: " .. app.VERSION, visible = self.showVersion} ) 
    
    if self.showVersion == true then
        self.footerProgramCopyright:modifyProperties( {text = "Copyright "..app.COPYRIGHT, visible = true } )
    else
        self.footerProgramCopyright:modifyProperties( {text = "Copyright "..app.COPYRIGHT, visible = false } )
    end
end

function AboutView:setupImages()
    self.imageSplash1 = app.frame.widgetMgr:newWidget("IMAGE", self.pageID.."_imageSplash1", _R.IMG.splash, {initSizeAndPosition = {self.imageSplash_initWidth, self.imageSplash_initHeight, 0, 0}, visible = false} )
    self.scrollPane:addObject(self.imageSplash1)

    self.imageObject1 = app.frame.widgetMgr:newWidget("IMAGE", self.pageID.."_imageObject1", _R.IMG.EWLogo, {initSizeAndPosition = {self.imageEWLogo_initWidth, self.imageEWLogo_initHeight, 0, 0}, visible = false} )
    self.scrollPane:addObject(self.imageObject1)
    
    if app.model.hasCoverSplash then
        self.imageCoverSplash = app.frame.widgetMgr:newWidget("IMAGE", self.pageID.. "_imageCoverSplash", _R.IMG.splash, {initSizeAndPosition = {self.imageCoverSplash_initWidth, self.imageCoverSplash_initHeight, self.imageCoverSplash_initPctX, self.imageCoverSplash_initPctY}} )
    end
end

function AboutView:modifyImages()
    if app.model.hasCoverSplash then
        self.imageCoverSplash:setVisible( not self.showVersion )
        self.imageObject1:setVisible( self.showVersion )
        self.imageSplash1:setVisible( self.showVersion )
    end
end

--##VIEW - MODULE
-------------------------------------------------------
ModuleView = class()

function ModuleView:init() end

function ModuleView:updateFocus(view)
--    local validityFlagsIdx = app.model.validityFlagsIdx
    
--    if view.page.validityFlags[validityFlagsIdx.ALL] == nil then             --deal with empty textboxes first
        self:setFocusToEmptyInput(view)
--    elseif view.page.validityFlags[validityFlagsIdx.ALL] == false then
--        self:setFocusToWrongAnswer(view)
--    end
end

function ModuleView:setFocusToEmptyInput(view)

--    local list = view.validityPriorityList[ view.page.problemState ]
    
--    for i=1, #list do
--        if view.page.validityFlags[list[i][1]] == nil then
--            view.initFocus = list[i][2].name
--            if list[i][3] ~= nil then list[i][2]:setFocusAt(list[i][3]) end  --Set focus to child object.
--            break
--        end
--    end        
end

function ModuleView:layoutFooter(view)
    local anchorDataX, anchorDataY = {}, {}
    local offset1 = 0
    local offset2 = 0
    
    anchorDataX[1] = {object = view.footerLeft, anchorTo = app.frame.footer, anchorPosition = "PaneLeft", position = "Left", offset = 7}
    anchorDataX[2] = {object = view.footerMiddle, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}
    anchorDataX[3] = {object = view.footerRight, anchorTo = app.frame.footer, anchorPosition = "PaneRight", position = "Right", offset = -12}

    anchorDataY[1] = {object = view.footerLeft, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}
    anchorDataY[2] = {object = view.footerMiddle, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}
    anchorDataY[3] = {object = view.footerRight, anchorTo = app.frame.footer, anchorPosition = "PaneMiddle", position = "Middle", offset = 0}

    return anchorDataX, anchorDataY
end

function ModuleView:setupFooter(view)
    local name = "frame_footerLeft"
    view.footerLeft = app.frame:addFooterObject(name,  function() return app.frame.widgetMgr:newWidget("SIMPLE_STRING", name, {initFontSize = 9, fontStyle = "b", fontColor = {0, 0, 0} } ) end)

    local name = "frame_footerMiddle"
    view.footerMiddle = app.frame:addFooterObject(name,  function() return app.frame.widgetMgr:newWidget("SIMPLE_STRING", name, {initFontSize = 9, fontStyle = "b", fontColor = {0, 0, 0} } ) end)

    local name = "frame_footerRight"
    view.footerRight = app.frame:addFooterObject(name,  function() return app.frame.widgetMgr:newWidget("SIMPLE_STRING", name, {initFontSize = 9, fontStyle = "b", fontColor = {0, 0, 0} } ) end)
end

function ModuleView:modifyFooter(view)
    local footerProgramModeText, foterProgramDifficultyText, footerProgramLevelText

    local txtLeft = app.controller.moduleController.currentProblem.." of "..app.controller.moduleController.totalProblems
    local txtMiddle = app.model.subMenuMessagesList[app.frame.selectedSubMenuID]
    local txtRight = app.model.menuMessagesList[app.frame.selectedMenuID]

--    if self.moduleController.currentProblemMode == app.model.problemModeList.PRACTICEMODE then 
--        footerProgramModeText = self.moduleController.problemNum .. " of " .. view.page.problemSet.problemTotal
--        footerProgramLevelText = "Practice"
--        footerProgramDifficultyText = app.model.activityMessages[self.moduleController.activityType]
--    else
--        footerProgramModeText = self.moduleController.problemNum .. " of " .. app.model.MAX_QUIZ_SCORE
--        footerProgramLevelText = "" 
--        footerProgramDifficultyText = app.model.difficultyMessages[ self.moduleController.difficulty ]
--    end

    view.footerLeft:modifyProperties( {text = txtLeft, visible = true} )
    view.footerMiddle:modifyProperties( {text = txtMiddle, visible = true} )
    view.footerRight:modifyProperties( {text = txtRight, visible = true} )
    app.frame.footer:setVisible(true)
end

function ModuleView:showFooterObjects(view)
    if app.controller.moduleController.continueFromSleep == true then
        view.footerLeft:setVisible(true)
        view.footerMiddle:setVisible(true)
        view.footerRight:setVisible(true)
        app.frame.footer:setVisible(true)
        app.controller.moduleController.continueFromSleep = false
    end
end

--##VIEW MODULE END

--##KEYBOARD LAYOUT
-----------------------------------------------------------
KeyboardLayout = class()

function KeyboardLayout:init()
    self.keys, self.frameSize, self.framePctPositions, self.grabIconXY = {}, {}, {}, {}
    local idx
       
    --Horizontal layout
    idx = 1
    self.keys[idx] = { {"-", .01, .025, 25, 25}, {"1", .14, .025, 25, 25}, {"2", .27, .025, 25, 25}, {"3", .40, .025, 25, 25}, {"4", .53, .025, 25, 25}, {"5", .66, .025, 25, 25}, {app.charBackspaceArrow, .79, .025, 25, 25},
                                                {"6", .14, .5, 25, 25}, {"7", .27, .5, 25, 25}, {"8", .40, .5, 25, 25}, {"9", .53, .5, 25, 25}, {"0", .66, .5, 25, 25}, {"Enter", .79, .5, 41, 25},   
                    -- {"clipboardIcon", .01, .5, 25, 25}, {"6", .14, .5, 25, 25}, {"7", .27, .5, 25, 25}, {"8", .40, .5, 25, 25}, {"9", .53, .5, 25, 25}, {"0", .66, .5, 25, 25}, {"Enter", .79, .5, 41, 25},   
    }
    local topRow, bottomRow = 7, 6
    for i=2, topRow do self.keys[idx][i][2] = self.keys[idx][1][2] + .13*(i-1); self.keys[idx][i][3] = .025 end
    for i=2, bottomRow do self.keys[idx][i+topRow][2] = self.keys[idx][1+topRow][2] + .13*(i-1); self.keys[idx][i+topRow][3] = .52 end 
        
    self.frameSize[idx] = {232, 60}
    self.grabIconXY[idx] = {-12, 0} 
    self.framePctPositions[idx] = {.02, .65}

    --Number pad layout
    idx = 2
    self.keys[idx] = { {"1", .015, .02, 25, 25}, {"2", .34, .02, 25, 25}, {"3", .665, .02, 25, 25}, {"4", .015, .22, 25, 25}, {"5", .34, .22, 25, 25}, {"6", .665, .22, 25, 25},  
                                          {"7", .015, .42, 25, 25}, {"8", .34, .42, 25, 25}, {"9", .665, .42, 25, 25}, {"-", .015, .62, 25, 25}, {"0", .34, .62, 25, 25}, {app.charBackspaceArrow, .665, .62, 25, 25},
                                          {"Enter", .46, .81, 41, 25}, 
                                              
    }

    self.frameSize[idx] = {81, 135}
    self.grabIconXY[idx] = {-70, 112} 
    self.framePctPositions[idx] = {.8, .65}

    --Small Horizontal layout
    idx = 3
    self.keys[idx] = { {"-", .01, .025, 23, 23}, {"1", 0, 0, 23, 23}, {"2", 0, 0, 23, 23}, {"3", 0, 0, 23, 23}, {"4", 0, 0, 23, 23}, {"5", 0, 0, 23, 23}, {app.charBackspaceArrow, 0, 0, 23, 23},
                                                {"6", .14, .52, 23, 23}, {"7", 0, 0, 23, 23}, {"8", 0, 0, 23, 23}, {"9", 0, 0, 23, 23}, {"0", 0, 0, 23, 23}, {"Enter", 0, 0, 37, 23},   
    }

    --Replace the 0 placeholders with calculated positions.
    local topRow, bottomRow = 7, 6  --Number of keys each row
    for i=2, topRow do self.keys[idx][i][2] = self.keys[idx][1][2] + .13*(i-1); self.keys[idx][i][3] = .025 end
    for i=2, bottomRow do self.keys[idx][i+topRow][2] = self.keys[idx][1+topRow][2] + .13*(i-1); self.keys[idx][i+topRow][3] = .52 end 
        
    self.frameSize[idx] = {202, 50}
    self.grabIconXY[idx] = {-12, 39} 
    self.framePctPositions[idx] = {.02, .65}
end
--##KEYBOARD LAYOUT END

------------------------------------------------------------
--##MODEL
------------------------------------------------------------
Model = class()

function Model:init()
    ------------
    --APP
    ------------
    app.rationals = Rationals()
    
    ------------
    --CONTROLLER
    ------------
    self.statesList = app.enum({ "INIT", "ACTIVITY", "END", "TRANSITION" })
    self.subStatesList = app.enum({ "START", "USER_INPUT", "PROCESS_INPUT", "WAIT_FOR_NEXT"})    --Use these only for the ACTIVITY state.

    self.stateFunctions = {
        [self.statesList.ACTIVITY] = {
            [self.subStatesList.START] = function(page) return page:subStateStart() end,
            [self.subStatesList.USER_INPUT] = function(page) return page:subStateUserInput() end,
            [self.subStatesList.PROCESS_INPUT] = function(page) return page:subStateProcessInput() end,
            [self.subStatesList.WAIT_FOR_NEXT] = function(page) return page:subStateWaitForNext() end,
        },
    }
    
    --Sequence of control for Race page.  The current substate points to the next substate.
    self.nextSubStateTable = { [self.subStatesList.START] = self.subStatesList.USER_INPUT, [self.subStatesList.USER_INPUT] = self.subStatesList.PROCESS_INPUT, }
    
    self.pageIDs = app.enum({ "ABOUT_PAGE", "SLEEP_PAGE", "SCORE_PAGE", "ADDITION_PAGE", "SUBTRACTION_PAGE" }) -- enum for the page ids

    --Logic Page, View, Page Name   
    self.pageList = {
        [self.pageIDs.ABOUT_PAGE] = {AboutPage, AboutView, "ABOUT"},
        [self.pageIDs.SLEEP_PAGE] = {SleepPage, SleepView, "SLEEP"},
        [self.pageIDs.SCORE_PAGE] = {ScorePage, ScoreView, "SCORE"},
        [self.pageIDs.ADDITION_PAGE] = {AdditionPage, AdditionView, "ADDITION"},
        [self.pageIDs.SUBTRACTION_PAGE] = {SubtractionPage, SubtractionView, "SUBTRACTION"},
    }

    self.activitiesList = app.enum({ "PRACTICE", "QUIZ" })
    self.practiceModes = app.enum({ "ADDITION", "SUBTRACTION" })
    self.quizLevels = app.enum({ "BEGINNER", "ADVANCED" })
    
    -------
    --FRAME
    -------
    self.allowUserInputCategories = app.enum({ "ANIMATION", "POST_MESSAGE" })   --add a category here to control the user input
    self.startupPageID = self.pageIDs.ABOUT_PAGE    
    self.PAGE_BORDER_SIZE = 6
    self.BACKGROUND_COLOR = app.graphicsUtilities.Color.white  
    self.FRAME_HAS_BORDER = true
    self.BORDER_COLOR = app.graphicsUtilities.Color.cyanish
    self.FRAME_HAS_DIVIDER = false
    self.MENU_ARROW_ENABLED = true
    self.MENU_ARROW_WAIT_TIME = 10000       --10 sec to show the yellow arrow
    self.HAS_KEYBOARD = true

    --------
    --TIMERS
    --------
    self.timerIDs = app.enum({ "DEFAULTTIMER", "MENUTIMER", "SLEEPTIMER", "TRANSITIONTIMER", "MENUARROWTIMER", "MAINTIMER", "HINTTIMER" })
    self.timerFunctions = { [self.timerIDs.DEFAULTTIMER] = function() end,
                            [self.timerIDs.MENUTIMER] = function() app.frame.menu:handleTimer() end,
                            [self.timerIDs.SLEEPTIMER] = function() app.controller.pages[app.model.pageIDs.SLEEP_PAGE]:handleSleepTimer() end,
                            [self.timerIDs.TRANSITIONTIMER] = function() app.controller:handleTransitionTimer() end,
                            [self.timerIDs.MENUARROWTIMER] = function() end,
                            [self.timerIDs.MAINTIMER] = function() app.controller.moduleController:handleMainTimer() end,
                            [self.timerIDs.HINTTIMER] = function() app.controller.moduleController:handleHintTimer() end,
    }  
    
    --------
    --EVENTS
    --------
    self.events = app.enum({"EVENT_NONE", "EVENT_MOUSE_MOVE", "EVENT_MOUSE_DOWN", "EVENT_MOUSE_UP", "EVENT_MOUSE_OUT", "EVENT_MOUSE_OVER",
    "EVENT_ARROW_LEFT", "EVENT_ARROW_RIGHT", "EVENT_PARAGRAPH_ANIMATION_END", "EVENT_CIRCLE_ANIMATION_END", "EVENT_HIGHLIGHT_ANIMATION_END",
    "EVENT_STADIUM_ANIMATION_END", "EVENT_LOST_FOCUS", "EVENT_GOT_FOCUS", "EVENT_SCROLL", "EVENT_BUTTON_NEXT", "EVENT_BUTTON_1",
    "EVENT_POPUP_KEYBOARD", "EVENT_SIZE_CHANGE", "EVENT_ENTER_KEY", "EVENT_CHAR_IN", "EVENT_BACKSPACE", "EVENT_MOVEMENT_END"})

    --------
    --MOVIES
    --------
    self.scenes = app.enum({"SCENE_1", "SCENE_2", "SCENE_3", "SCENE_4", "SCENE_5", "SCENE_6", "SCENE_7", "SCENE_8"})

    ------
    --MENU
    ------
    self.menuChoicesList = app.enum({"PRACTICE", "QUIZ", "ABOUT"})
    self.subMenuChoicesList = app.enum({"ADDITION", "SUBTRACTION", "BEGINNER", "ADVANCED"})
  
    self.menuItems = {
        {"Practice",
            {"Addition", function() app.controller.moduleController:handleMenu(self.menuChoicesList.PRACTICE, self.subMenuChoicesList.ADDITION) end},
            {"Subtraction", function() app.controller.moduleController:handleMenu(self.menuChoicesList.PRACTICE, self.subMenuChoicesList.SUBTRACTION) end},
        },
        {"Quiz",
            {"Beginner", function() app.controller.moduleController:handleMenu(self.menuChoicesList.QUIZ, self.subMenuChoicesList.BEGINNER) end},
            {"Advanced", function() app.controller.moduleController:handleMenu(self.menuChoicesList.QUIZ, self.subMenuChoicesList.ADVANCED) end},
        },
        {"About",
            {"About", function() app.controller.moduleController:handleMenu(self.menuChoicesList.ABOUT, self.subMenuChoicesList.ABOUT) end},
        },
    }

    ----------
    --MODULE
    ----------
    self.PAGE_MAX_LOAD_TIME_DESKTOP = 600       --in ms
    self.PAGE_MAX_LOAD_TIME_WEB = 800 
	self.MAX_PROBLEMS_PRACTICE = 2	   --10 is normal
	self.MAX_PROBLEMS_QUIZ = 3	   --10 is normal

    self.menuMessagesList = {[self.menuChoicesList.PRACTICE] = "Practice", [self.menuChoicesList.QUIZ] = "Quiz"}
    self.subMenuMessagesList = {[self.subMenuChoicesList.ADDITION] = "Addition", [self.subMenuChoicesList.SUBTRACTION] = "Subtraction", [self.subMenuChoicesList.BEGINNER] = "Beginner", [self.subMenuChoicesList.ADVANCED] = "Advanced"}
    self.keyboardInputs = {"textbox", "MixedNumberInput"}   --These are the widget types that are connected to the soft keyboard.

    ----------
    --DATABASE
    ----------

    ----------
    --ADDITION
    ----------
    self.STOPWATCH_VISIBLE_TIME = 2     -- Length of time to initially display stopwatch timer
    self.hintWaitTimeIntervals = {8, 16}   --hint wait time intervals, in seconds.
    
    ----------
    --SLEEP
    ----------
    self.PAUSE_TIME = 300000            --If no activity for this amount of time, show the Sleep page.  300000ms / 1000 = 300 sec. / 60 = 5 min.
    self.RESET_PAUSE_TIME = 300000      --After this amount, return to About page.

    ----------
    --SCORE
    ----------

    ----------
    --ABOUT
    ----------
    self.hasCoverSplash = true
    
    ------------
    --DEBUG
    ------------
    self.KEYBOARD_ON = false
    self.PLATFORM_IS_SLOW = false
end

-----------------------------------------------------------------
-----------------------------------------------------------------

--##FRAMEWORK
-----------------------------------------------------------------
Frame = class()

function Frame:init()
    self.name = "frame"
    self.scaleFactor = 1
    self.x = 0; self.y = 0; self.w = 1;  self.h = 1
    self.headerX = 1;  self.headerY = 1; self.footerX = 1; self.footerY = 1
    self.initHeaderHeight = 22      -- 20 pixel header
    self.initFooterHeight = 17      -- 15 pixel footer
    self.pages = {}
    self.background_color = app.model.BACKGROUND_COLOR
    self.border_color = app.model.BORDER_COLOR
    self.buttonMenu = nil -- menu button
    self.buttonView = nil -- button for changing the view to standard/large
    self.keyboardYPosition = 3
    self.keyboardYSize = 65
    self.pageNum = 1
    self.views = {}
    self.pageView = nil
    self.activeViewID = 0
    self.firstPageViewID = nil
    self.lastPageViewID = nil
    self.nextPageViewID = nil
    self.previousPageViewID = nil
    self.pageIdx = 1
    self.needsResize = nil
    self.allowUserInput = true
    self.allowUserInputEscapeKey = true  --true means allow this key
    self.allowUserInputCategories = app.model.allowUserInputCategories
    self.allowUserInputValues = {}
    self:initAllowUserInputValues()
    self.menuArrowEnabled = false
	self.menu_arrow_wait_time = app.model.MENU_ARROW_WAIT_TIME
	self.timer_count_menu_arrow = 0

    self.invalidateX = 0    
    self.invalidateY = 0   
    self.invalidateW = 0
    self.invalidateH = 0
    self.invalidateDirty = true
    self.invalidateXRight = -1
    self.invalidateYBottom = -1
    self.invalidateX2, self.invalidateY2 = 0, 0        --for debugging; stores the value of invalidate area for drawing the bounding rect
    self.invalidateW2, self.invalidateH2 = 0, 0
    self.invalidateX2Old, self.invalidateY2Old = 0, 0     --for debugging; helps in invalidating the previous invalidate area
    self.invalidateW2Old, self.invalidateH2Old = 0, 0
    self.boundingRectangle = false --true--     --for debugging
    self.hasCleared = true
    self.hasBorder = app.model.FRAME_HAS_BORDER
    self.hasDividerLines = app.model.FRAME_HAS_DIVIDER
    self.keyboardNeedsLayout = true
end

function Frame:resize(w, h)
    self.w = w
    self.h = h

    --Set the scale factor for the entire window.
    self.scaleFactor = math.min(self.w/app.HANDHELD_WIDTH, self.h/app.HANDHELD_HEIGHT)

    -- Resize the header and footer
    self:resizeHeader()
    self:resizeFooter()
    
    self.keyboardNeedsLayout = true
   
    --If the page has been sized at least once, then let the page know that it needs to be resized at a later time., but only if the view has been initialized.
    for i=1, #self.views do
        if self.views[i].needsResize == false then
            self.views[i].needsResize = true
        end
    end

    --If this is the first resize() call at startup, then setup the first page now that we have the frame size.
    if self.needsResize == nil then
        self.views[app.model.startupPageID].needsResize = true
        app.controller:switchPages(app.model.startupPageID, true)
    else
        --Resize and layout the active view.
        local view = self.views[self.activeViewID]
        view.needsResize = true
        self.pageView:updateView(view)
    end
     
    local pcty =  (self.buttonMenu.y + self.buttonMenu.h + 1*self.scaleFactor) / self.h      --We must calculate .pcty here because the header is based on pixel times scale factor.
    if app.model.menuItems then self.menu:resize(self.x, self.y, self.w, self.h, .03, pcty, 150, 20, self.scaleFactor) end

    if self.keyboard.attachedToScrollPane == nil then self.keyboard:resize(self.x, self.y, self.w, self.h, self.scaleFactor) end
    self.imageWaitCursor:resize(self.x, self.y, self.w, self.h, self.scaleFactor)
    self.imageMenuArrow:resize(self.x, self.y, self.w, self.h, self.scaleFactor)
    self:resizeTransitionMessage()

    self.widgetMgr.invalidateDirty = false

    --This is the end of the startup process.
    if self.needsResize == nil then
        app.startupTime = math.abs(timer.getMilliSecCounter() - app.startTime)
     
        self:startMenuArrowWaitTime()
    end
        
    self.needsResize = false
end

function Frame:paint(gc)
    local view = self.views[self.activeViewID]
    local sp = view.scrollPane
    
    local bgX, bgY, bgW, bgH = self.x, self.y, self.w, self.h -- default values for the position and size of the background
    
    if self.hasBorder then
        -- fill in the border
        gc:setColorRGB( unpack( self.border_color ))
        gc:fillRect( self.x, self.y, self.w, self.h )
        
        bgX, bgY, bgW, bgH = sp.x, self.h * 0.02, sp.clientWidth, self.h*.98 - self:getFooterHeight()
    end
    
    --Fill the background color
    gc:setColorRGB(unpack(self.background_color))
    gc:fillRect( bgX, bgY, bgW, bgH )

    self:drawHeader( gc )
    self.footer:paint(gc)
    
    if self.hasDividerLines == true then
        self:drawFooterLine(view, gc)
    end

    --Paint the active page.
    if app.controller.inTransition then
        if self.transition then self.transition:paintTransition(gc) end
    else
        self.pageView:paint(view, gc)
    end
     
    -- draw menu, keyboard and wait cursor last
    if self.keyboard.attachedToScrollPane == nil then self.keyboard:paint(gc) end -- paint when keyboard is not attached to any scrollpane
    self.imageWaitCursor:paint(gc)
    self.imageMenuArrow:paint(gc)
    self.menu:paint(gc)
    
    --Paint the bounding box for the invalidated area
    if self.boundingRectangle then
        gc:setColorRGB(0, 0, 255)
        gc:drawRect(self.invalidateX2, self.invalidateY2, self.invalidateW2, self.invalidateH2)
    end
    
    -- Paint the memory debug on top of everything
    if app and app.model and app.model.SHOW_MEMORY then
        gc:setColorRGB( 0, 0, 0 )
        gc:setFont( "sansserif", "r", 8 )
        
        if app.controller.memoryCounter then gc:drawString( "Memory consumed: " .. string.format( "%.4f", tostring( app.controller.memoryCounter *.001 )) .. " Mb", self.menu.x, self.menu.y ) end
    end
end

function Frame:setInvalidatedArea(x, y, w, h)
  local pad = 10   --Helps with flicker (at least on the emulator)  
  
  if self.hasCleared == true then
    self.invalidateX = x - pad
    self.invalidateY = y - pad
    self.invalidateW = w + 2*pad   
    self.invalidateH = h + 2*pad
    self.hasCleared = false
  else
    self.invalidateXRight = math.max(x+w, self.invalidateX+self.invalidateW - 2*pad)     --compare object right edge to whole right edge
    self.invalidateYBottom = math.max(y+h, self.invalidateY+self.invalidateH - 2*pad) 
   
    self.invalidateX = math.max(0, math.min(x, self.invalidateX + pad) - pad)    
    self.invalidateY = math.max(0, math.min(y, self.invalidateY + pad) - pad)
    self.invalidateW = self.invalidateXRight - self.invalidateX + 2*pad      
    self.invalidateH = self.invalidateYBottom - self.invalidateY + 2*pad 
  end

  if self.boundingRectangle then
    --Store the old values
    self.invalidateX2RightOld = math.max(self.invalidateX2+self.invalidateW2, self.invalidateX2Old+self.invalidateW2Old)
    self.invalidateY2BottomOld = math.max(self.invalidateY2+self.invalidateH2, self.invalidateY2Old+self.invalidateH2Old) 
    
    self.invalidateX2Old = math.min(self.invalidateX2, self.invalidateX2Old)
    self.invalidateY2Old = math.min(self.invalidateY2, self.invalidateY2Old)
    self.invalidateW2Old = self.invalidateX2RightOld - self.invalidateX2Old
    self.invalidateH2Old = self.invalidateY2BottomOld - self.invalidateY2Old
  
  --Update the bounding blue rectangle on screen
  self.invalidateX2, self.invalidateY2 = self.invalidateX, self.invalidateY
  self.invalidateW2, self.invalidateH2 = self.invalidateW, self.invalidateH
  end
  
  self.invalidateDirty = true
end

function Frame:invalidate()
  if self.invalidateDirty == true then
    if self.boundingRectangle == true then
      platform.window:invalidate(self.invalidateX2Old - 1, self.invalidateY2Old - 1, self.invalidateW2Old + 2, self.invalidateH2Old + 2)      --extra pixels will handle the pixel of the line used in drawRect
    end 
      
    platform.window:invalidate(self.invalidateX, self.invalidateY, self.invalidateW, self.invalidateH)
    self:clear()
  end
  
  --platform.window:invalidate()      --old invalidate
end

function Frame:clear()
  self.invalidateDirty = false
  self.invalidateX = 0-- -1
  self.invalidateY = 0-- -1
  self.invalidateW = 0
  self.invalidateH = 0
  self.hasCleared = true
  
  --Clear invalidate area for debugging
  self.invalidateX2Old, self.invalidateY2Old = 0, 0 -- -1, -1     
  self.invalidateW2Old, self.invalidateH2Old = 0, 0
end

function Frame:setupFrame()
    self.widgetMgr = WidgetMgr() --Initialize and start the Widget Manager
    self.pageView = PageView()
    self.menu = Menu()
    self.UIMgr = UIMgr(self.menu)
    self.keyboard = Keyboard("keyboard")
    if Transition then self.transition = Transition() end    

    self.UIMgr:reset()
    self:registerWidgets()
    self:setupHeader()
    self:setupFooterPane()
    self:setMenu()
    self:setupImages()
    if self.transition then self.transition:setupTransition() end
    if self.keyboard.keysLayout then self:setupKeyboard() end
end

function Frame:registerWidgets()
    self.widgetMgr:register("BUTTON", function(name, options) local widget = Button(name); self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("FOOTER_PANE", function(name, options) local pane = Footer(name) self.widgetMgr:addWidget(pane, options) return pane end)
    self.widgetMgr:register("SCROLL_PANE", function(name, options) local pane = ScrollPane(name) self.widgetMgr:addWidget(pane, options) return pane end)
    self.widgetMgr:register("SIMPLE_STRING", function(name, options) local widget = SimpleString(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("FEEDBACK", function(name, options) local widget = Feedback(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("TEXTBOX", function(name, options) local widget = TextBox(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("CIRCLE", function(name, options) local widget = Circle(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("RECTANGLE", function(name, options) local widget = Rectangle(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("SYMBOL", function( name, options ) local widget = Symbol(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("LINE", function(name, options) local widget = Line(name) self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("IMAGE", function(name, resource, options) local widget = Image(name); widget:loadImage(resource); self.widgetMgr:addWidget(widget, options) return widget end)
    self.widgetMgr:register("TRIANGLE", function(name, resource, options) local widget = FigureTriangle(name); self.widgetMgr:addWidget(widget, options) return widget end)
    
    --Register any custom widgets.
    if self.pageView.moduleView and self.pageView.moduleView.registerWidgets then self.pageView.moduleView.registerWidgets() end        
end

function Frame:setupHeader()
    local h = app.stringTools:getStringHeight( "A", "sansserif", "b", app.stringTools:scaleFont( 10, self.scaleFactor ))
    local menuButtonPcty = ((( h * 0.5 ) - 7)/ app.HANDHELD_HEIGHT )
    
    if self.hasBorder then
        menuButtonPcty = 0.025
    end
    
     self.buttonMenu = self.widgetMgr:newWidget("BUTTON", "frame_buttonmenu", {label = "menu", initSizeAndPosition = {34, 14, .03, menuButtonPcty}, initFontSize = 7,
                                drawCallback = nil, octagonStyle = true  })
                                
    self.buttonMenu:addListener(function( event, ...) return self:clickMenuButton(event, ...) end)
    self.UIMgr:addListener( 0, function(...) return self.buttonMenu:UIMgrListener(...) end )
    
    self.buttonView = self.widgetMgr:newWidget("BUTTON", "frame_buttonview", {label = "+/-", initSizeAndPosition = {18, 14, 0.93, menuButtonPcty}, initFontSize = 7,
                                    drawCallback = nil, octagonStyle = true, visible = false})    --+/- button
    self.buttonView:addListener(function( event, ...) return self:clickViewButton(event, ...) end)
    self.UIMgr:addListener( 0, function(...) return self.buttonView:UIMgrListener(...) end )
end

function Frame:resizeHeader()
    self.buttonMenu:resize(0, 0, self.w, self.h, self.scaleFactor)
    self.buttonView:resize(0, 0, self.w, self.h, self.scaleFactor)
end

function Frame:drawHeader( gc )
    local view = self.views[self.activeViewID]
    
    --Title
    gc:setColorRGB(0, 0, 0)
    gc:setFont( "sansserif", "b", app.stringTools:scaleFont( 10, self.scaleFactor ))
    
    local titleY = self.y+self.h*0
    if self.hasBorder then
        titleY = self.buttonMenu.y + self.buttonMenu.h * 0.5 - gc:getStringHeight(view.title) * 0.5
    end
    
    gc:drawString( view.title, self.buttonMenu.x + self.buttonMenu.w + .5*( self.w - (self.buttonMenu.x + self.buttonMenu.w) - gc:getStringWidth( view.title ) - self.buttonView.w - ( self.w - ( self.buttonView.x + self.buttonView.w ))), titleY ) -- x position formula needs improvement

    --Header line
    if self.hasDividerLines == true then
        gc:setPen("thin","smooth")
        gc:setColorRGB(0, 0, 0)
        gc:drawLine(self.x, self.y+self:getHeaderHeight()-1, self.x + self.w, self.y+self:getHeaderHeight()-1) 
    end
    
    -- draw menu button
    self.buttonMenu:paint( gc )
    
    -- draw view button
    self.buttonView:paint( gc )
end

function Frame:getHeaderHeight()
    return math.floor(self.initHeaderHeight*self.scaleFactor)
end

function Frame:setupFooterPane()
    if self.footer == nil then
        self.footer = self.widgetMgr:newWidget("FOOTER_PANE", "frame_footerpane", {pctx = 0, pcty = 0, initHeight = 100, initWidth = 100, progressPct = app.model.INIT_PROGRESSBAR_PCT} )
    end
end

function Frame:resizeFooter()
    self:setFooterSize()
    self.footer:setInitSizeAndPosition(self.footer.initWidth, self.footer.initHeight, self.footer.pctx, self.footer.pcty)    
    self.footer:setSize(self.footer.nonScaledWidth / self.scaleFactor, self.footer.nonScaledHeight / self.scaleFactor)     
    self.footer:resize(self.x, self.y, self.w, self.h, self.scaleFactor)
end

function Frame:setFooterSize()
    self.footer.pctx = 0
    self.footer.pcty = (app.frame.h - self:getFooterHeight()) / self.h
    self.footer.initHeight = self:getFooterHeight()
    self.footer.initWidth = self.w
end

function Frame:getFooterHeight()
    return math.floor(self.initFooterHeight*self.scaleFactor)
end

function Frame:drawFooterLine(view, gc)
    gc:setPen("thin","smooth")
    gc:setColorRGB(0, 0, 0)
    gc:drawLine(self.x, view.scrollPane.y+view.scrollPane.h, self.x + self.w, view.scrollPane.y+view.scrollPane.h) 
end

--First, make all footer objects inivisible, then allow page to make certain footer objects visible.
function Frame:hideFooterObjects()
    local view = self.views[self.activeViewID]

    for k, obj in pairs(self.footer.objects) do
        obj:setVisible(false)
    end

    self.footer:setProgressBarVisible(false)
end

function Frame:modifyTransitionFooter()
    local showFooter = app.model.transitionFooterVisibility[ app.controller.pageID ] 

    self.footer:setVisible(showFooter)
end

function Frame:addFooterObject(name, callback)
    local object = nil

    --Search to see if this object already exists in the footer.
    for k, obj in pairs(self.footer.objects) do
        if obj.name == name then
            object = obj
            break
        end
    end

    if object == nil then
        object = callback()         --Call back to create the object since it doesn't exist.  
        self.footer:addObject(object)     
    end

    return object 
end

function Frame:resizeTransitionMessage()
    if self.transition then self.transition:resizeTransitionMessage() end
end

function Frame:prepForTransition(mode, problemID, isStartOfSection)
    self.transition:modifyTransitionMessage(mode, problemID, isStartOfSection)
    self.transition:modifyTransitionFooter()
    self.buttonView:setActive(false)
    self.buttonMenu:setActive(false)
    self:setInvalidatedArea( 0, 0, self.w, self.h )  --This is necessary to invalidate the scrollpane view.
end

function Frame:modifyTransitionMessage(mode, problemID, isStartOfSection)
    self.transition:modifyTransitionMessage(mode, problemID, isStartOfSection)
end 
   
function Frame:setMenu()
    if app.model.menuItems then
        toolpalette.register(app.model.menuItems)
        self.menu:register(app.model.menuItems)       --Replicate the toolpalette
        self.menu:setPostMenuFunction(function() self:menuClosed() end) --callback function when menu is closed
    end
end

--Callback function for when the menu button is clicked.  This will not be called if calculator phyiscal Menu button is used. 
function Frame:clickMenuButton(event, ...)
    if event == app.model.events.EVENT_MOUSE_UP or event == app.model.events.EVENT_ENTER_KEY then
        local selectedItem = 0
    
        if self.UIMgr.mouseDownObject == nil then selectedItem = 1 end  --If calculator Select button used, then highlight the first menu item. 
        
        self:disableMenuArrow()
        
        self.UIMgr:deactivateObjects(self.activeViewID)       --Disable all UI objects execpt for the menu.
        self.menu:setActive(true)
    
        if app.model.menuItems then self.menu:show(selectedItem) end
    end
end

function Frame:clickViewButton(event, ...)
    if event == app.model.events.EVENT_MOUSE_UP or event == app.model.events.EVENT_ENTER_KEY then
        self.buttonView:setFillColor(self.buttonView.mouseDownColor)       --This acts like hourglass mouse cursor
        if app.isPlatformSlow() then self.imageWaitCursor:setVisible(true) end  --Only show wait cursor on non-calculator devices
        app.controller:postMessage({function(...) self:switchStyles() end})
    end
end

function Frame:switchStyles()
   if self.views[self.activeViewID].viewStyle == app.viewStyles.STANDARD then self:setViewStyle(app.viewStyles.LARGE) else self:setViewStyle(app.viewStyles.STANDARD) end 
   self.buttonView:setFillColor( self.buttonView.initFillColor)
   self.imageWaitCursor:setVisible(false)
end

function Frame:startMenuArrowWaitTime()
    self.timer_count_menu_arrow = timer.getMilliSecCounter()     
end

function Frame:disableMenuArrow()
    self.imageMenuArrow.enabled = false             --menu arrow should not show up anymore once menu button is clicked
    self.imageMenuArrow:setVisible(false)
    app.timer:stop( app.model.timerIDs.MENUARROWTIMER )
end

function Frame:setupKeyboard()
    local kIdx = self.keyboard.keysIndex
    local frameSize = self.keyboard.keysLayout.frameSize
    local keyboardPctx, keyboardPcty = self.keyboard.keysLayout.framePctPositions[kIdx][1], self.keyboard.keysLayout.framePctPositions[kIdx][2]
    self.keyboard:setInitSizeAndPosition(frameSize[kIdx][1],frameSize[kIdx][2], keyboardPctx, keyboardPcty)      --w, h, x, y
    self.keyboard.hasGrab = true
    self.widgetMgr:addWidget( self.keyboard )
    
    --If on NSpire platform, then there is no way to know if user is tapping the screen or using a mouse.  In this case, we always activate the keyboard.
    --If on browser, then we will get a touchStart notification and we will activate the keyboard only if the user actually taps the screen.
    if (touch.enabled() and app.platformType ~= "ndlink") or app.model.KEYBOARD_ON == true then
        self.keyboard.enabled = true
        self.keyboard:setActive( true )
    end
end

function Frame:setupImages()
    self.imageWaitCursor = self.widgetMgr:newWidget("IMAGE", "menu_imageWaitCursor", _R.IMG.hourglass, {initSizeAndPosition = {30, 60, 0, 0}, visible = false} )
    self.imageWaitCursor:setPosition(.45, .35)  --Make this centered.
    
    self.imageMenuArrow = self.widgetMgr:newWidget("IMAGE", "imageMenuArrow", _R.IMG.yellowarrow, {initSizeAndPosition = {30, 40, .035, .1}, visible = false,
                                                        enabled = app.model.MENU_ARROW_ENABLED, direction = 1} )
end

function Frame:handleTimer()
    self:showMenuArrow()
    self.widgetMgr:handleTimer()
    
    self:invalidate()
end

--The first parameter to addView() actually is a function call to initiate the class.
function Frame:addViews()
    for k, v in pairs(app.model.pageList) do
        self:addView(app.model.pageList[k][2](app.model.pageList[k][3].."_VIEW"), k, app.controller.pages[k])
    end
end

--Attaches the view and it's associated logic page to the frame.
function Frame:addView( view, pageID, page)
    view.pageID = pageID
    view.page = page
    app.controller.pages[pageID].viewID = pageID    --one-to-one pageID and viewID
    self.views[pageID] = view
end

function Frame:switchViews(viewID)
    local view = self.views[viewID]
    
    view.allowModifyLayout = false        --do not handle any widget size change or layout events.  View page must set this flag to true to enable widget change events.
    
    if self.menu.visible == true then self.menu:hide() end    --In case the user had the menu open, close the menu when switching pages
    if self.needsResize ~= nil or app.model.MENU_ARROW_ENABLED == false then self:disableMenuArrow() end   --physical menu button on calculator is pressed, hide menu arrow.  Only check after first resize of Frame.
    
    self.activeViewID = viewID
    self.UIMgr:setActiveViewID(viewID)
    
    self.pageView:setupView(view)      --First, create the scroll pane, menu button and other objects.

    self.pageView:updateView(view, false)   --Normally updateView does a layout, but here we don't want a layout just for switching views.
    
    self.UIMgr:setScrollPane(view.scrollPane)
    view.scrollPane:scrollIntoView(view.initFocus)

    self:setInvalidatedArea( 0, 0, app.frame.w, app.frame.h )   --Yes, we need this.  Invalidate everything when switching views.
end

function Frame:setViewStyle(viewStyle)
    local view = self.views[self.activeViewID]

    for i=1, #self.views do self.views[i].viewStyle = viewStyle end

    self.pageView:updateView(view)
end

function Frame:arrowLeft()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
        
        self:onUserInput()
    
        local ret = self.menu:arrowLeft()
        if ret ~= true then     --if menu did not handle the arrow up, then send the event on to the view.
            if view.handleUserAction then view:handleUserAction() end
            self.UIMgr:arrowLeft()
        end
    
        self:invalidate()
    end
end

function Frame:arrowRight()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
        
        self:onUserInput()
    
        local ret = self.menu:arrowRight()
        if ret ~= true then     --if menu did not handle the arrow up, then send the event on to the view.
            if view.handleUserAction then view:handleUserAction() end
            self.UIMgr:arrowRight()
        end
    
        self:invalidate()
    end
end

function Frame:arrowUp()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
        
        self:onUserInput()
    
        local ret = self.menu:arrowUp()
        if ret == false then     --if menu did not handle the arrow up, then send the event on to the view.
            if view.handleUserAction then view:handleUserAction() end
            
			ret = self.UIMgr:arrowUp() 				-- check if the object has an arrow up first
			
            if ret == false then                    --If the UIMgr doesn't handle the event, then send it on to the scrollbar.
			
                ret = view.scrollPane.scrollBar:arrowUp()
				
				if ret == false then				--If object does not handle arrow internally, then act as a backtab key.
					self.UIMgr:backTabKey()
				end
            end
        end
    
        self:invalidate()
    end
end

function Frame:arrowDown()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
        
        self:onUserInput()
    
        local ret = self.menu:arrowDown()
        if ret == false then     --if menu did not handle the arrow down, then send the event on to the view.
            if view.handleUserAction then view:handleUserAction() end
            
			ret = self.UIMgr:arrowDown() 				-- check if the object has an arrow down first
			
            if ret == false then                    --If the UIMgr doesn't handle the event, then send it on to the scrollbar.
			
                ret = view.scrollPane.scrollBar:arrowDown()
				
				if ret == false then				--If object does not handle arrow internally, then act as a tab key.
					self.UIMgr:tabKey()
				end
            end
        end
    
        self:invalidate()
    end
end

function Frame:mouseDown(x, y)
    if self.allowUserInput then
        self:onUserInput()
    
        local ret = self.menu:mouseDown(x,y)
		local mouseDownOnMenu = ret
        if ret ~= true then
            local view = self.views[self.activeViewID]
        
            ret = self.keyboard:mouseDown(x,y)
            if ret ~= true then             --If keyboard does not handle event, send event to page mgr.
                if view.handleUserAction then view:handleUserAction() end
            
                mouse_x = x; mouse_y = y    --For debugging where the user touches the screen.
            
                local ret = self.UIMgr:mouseDown(x, y)        --First allow UIMgr to check UI focusable objects.
                if ret ~= true then
                    ret = view.scrollPane:mouseDown(x,y)       --Notify scrollbar that mouse is down.
                end
            end
        end
		
		local onWeb = (app.platformType == "ndlink")
		local onFastWebDevice = ( onWeb and app.startupTime < app.model.PAGE_MAX_LOAD_TIME_WEB )
		local keyboardNotVisible = ( self.keyboard.visible == false )
    
		--We need to invalidate immediately, but only if performance is fast enough. If the performance is slow, the invalidation will happen on the next timer tick.
		--We normally don't invalidate here if the keyboard is visible, but in the case of a visible keyboard and a submenu tap, we need to invalidate now.
        if (not onWeb) or keyboardNotVisible or (onFastWebDevice and mouseDownOnMenu == true) then self:invalidate() end    
    end
end

function Frame:mouseUp(x, y)
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
        
        local ret = self.menu:mouseUp(x,y)
        if ret ~= true then
            ret = self.keyboard:mouseUp(x,y)
            if ret ~= true then             --If keyboard does not handle event, send event to frame.
                if view.handleUserAction then view:handleUserAction() end
                local ret = self.UIMgr:mouseUp(x, y)      --First allow UIMgr to check UI focusable objects.
                if ret ~= true then 
                    ret = view.scrollPane:mouseUp(x, y)
                end
            end
        end
    
		--We need to invalidate immediately, but only if performance is fast enough. If the performance is slow, the invalidation will happen on the next timer tick.
        if app.platformType ~= "ndlink" or self.keyboard.visible == false then self:invalidate() end    
    end
end

function Frame:mouseMove(x, y)
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self.keyboard:mouseMove(x, y)
        view.scrollPane.scrollBar:mouseMove(x, y)
        self.UIMgr:mouseMove(x, y)
    
		--We need to invalidate immediately, but only if performance is fast enough. If the performance is slow, the invalidation will happen on the next timer tick.
        if app.platformType ~= "ndlink" or self.keyboard.visible == false then self:invalidate() end    
    end
end

function Frame:grabDown(x, y)
    cursor.set("drag grab")
end

function Frame:grabUp(x, y)
    local view = self.views[self.activeViewID]

    if view.handleUserAction then view:handleUserAction() end
    view.scrollPane.scrollBar:grabUp(x, y)
    
    self.UIMgr:grabUp(x,y)
    cursor.set("drag grab")
end

function Frame:releaseGrab()
    local view = self.views[self.activeViewID]

    if view.handleUserAction then view:handleUserAction() end
    view.scrollPane.scrollBar:releaseGrab()
    self.UIMgr:releaseGrab()
    cursor.set("pointer")
end

function Frame:charIn(char)
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        local ret = self.menu:charIn( char ) -- we now have a special debug when the menu is open
        
        if not ret then -- menu did not do anything
            self:onUserInput()
            if view.handleUserAction then view:handleUserAction() end
            self.UIMgr:charIn(char)
        end
        
        self:invalidate()
    end
end

function Frame:backspaceKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:backspaceKey()
    
        self:invalidate()
    end
end

function Frame:tabKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:tabKey()
    
        self:invalidate()
    end
end

function Frame:backTabKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:backTabKey()
        
        self:invalidate()
    end
end

--Global decisions on the enter key.
function Frame:enterKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        
        if self.menu.visible == true then
            self.menu:enterKey()
        else
            if view.handleUserAction then view:handleUserAction() end
            if self.buttonMenu.hasFocus then self:clickMenuButton(app.model.events.EVENT_ENTER_KEY)
            elseif self.buttonView.hasFocus then self:clickViewButton(app.model.events.EVENT_ENTER_KEY)
            else
                local handled = self.UIMgr:enterKey()
                
                if not handled then self.pageView:enterKey(view) end
            end
        end
        
        self:invalidate()
    end
end

function Frame:selectKey()
    if self.allowUserInput then
        self:enterKey()
    end
end

function Frame:escapeKey()
    if self.allowUserInputEscapeKey then
        local view = self.views[self.activeViewID]
    
        self:disableMenuArrow()
        self:onUserInput()
        self.menu:escapeKey()
        
        if view.handleUserAction then view:handleUserAction() end
        self.pageView:escapeKey(view)
                
        self:invalidate()
    end
end

function Frame:cut()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:cut()
    
        self:invalidate()
    end
end

function Frame:copy()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:copy()
    
        self:invalidate()
    end
end

function Frame:paste()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:paste()
    
        self:invalidate()
    end
end

function Frame:shiftArrowRight()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:shiftArrowRight()
    
        self:invalidate()
    end
end

function Frame:shiftArrowLeft()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:shiftArrowLeft()
    
        self:invalidate()
    end
end

function Frame:homeKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:homeKey()
    
        self:invalidate()
    end
end

function Frame:endKey()
    if self.allowUserInput then
        local view = self.views[self.activeViewID]
    
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:endKey()
    
        self:invalidate()
    end
end

function Frame:deleteKey()
    if self.allowUserInput then
        local view = self.views[ self.activeViewID ]
        
        self:onUserInput()
        if view.handleUserAction then view:handleUserAction() end
        self.UIMgr:deleteKey()
        
        self:invalidate()
    end
end

--Returns the page size of a given page.  panex and paney are actual pixel locations.
function Frame:getPaneSize(viewID)
    return self.views[viewID].panex, self.views[viewID].paney, self.views[viewID].panew, self.views[viewID].paneh
end

--Scales a pane dimensions.  centerW and centerH are true to center the sub-pane horizontally or vertically.
--Returns: x, y, w, h, factor
function Frame:scalePane(x, y, w, h, centerW, centerH)
    local factor, extraPixels

    if h/app.HANDHELD_HEIGHT - w/app.HANDHELD_WIDTH > 0 then
        --The scale factor is calculated as a percentage of the initial designed-for width and height, scaling to match the original design, just bigger.
        factor = w/app.HANDHELD_WIDTH
        extraPixels = app.HANDHELD_HEIGHT*(h/app.HANDHELD_HEIGHT - w/app.HANDHELD_WIDTH)
        if centerH == true then   y = y + extraPixels/2   end
        h = h - extraPixels
    else
        factor = h/app.HANDHELD_HEIGHT
        extraPixels = app.HANDHELD_WIDTH*(w/app.HANDHELD_WIDTH - h/app.HANDHELD_HEIGHT)
        if centerW == true then  x = x + extraPixels/2    end
        w = w - extraPixels
    end

    return x, y, w, h, factor
end

--After menu closes, re-enable all UI objects.
function Frame:menuClosed()
    self.UIMgr:activateObjects(self.activeViewID)
end

-- take action on user input
function Frame:onUserInput()
    self:releaseGrab()        --Release anything that was grabbed on calculator.
end

function Frame:initAllowUserInputValues()
    for i, v in pairs(self.allowUserInputCategories) do
        self.allowUserInputValues[v] = true
    end
end

--catergoryID can be any of the ff: self.allowUserInputCategories = app.enum({ "ANIMATION", "POST_MESSAGE" }) 
--allowUserInput is true or false
function Frame:enableUserInput(catergoryID, allowUserInput)
    self.allowUserInputValues[catergoryID] = allowUserInput
    
    if self:shouldEnableUserInput() == true then self.allowUserInput = true else self.allowUserInput = false end  --enable user input only when allowed
end

--returns true if enabling user input is allowed; no ongoing animation, no post messages, etc.
function Frame:shouldEnableUserInput()
    local enableUserInput = true
    
    for i, v in pairs(self.allowUserInputValues) do
        if v == false then enableUserInput = false; break end
    end
    
    return enableUserInput
end

--escapeKey = true means allow this key
function Frame:enableUserInputEscapeKey(escapeKey)
    self.allowUserInputEscapeKey = escapeKey
end

function Frame:showMenuArrow()
    if self.imageMenuArrow.enabled == true and app.timer:getMilliSecCounter() - self.timer_count_menu_arrow >= self.menu_arrow_wait_time then
        self.imageMenuArrow:setVisible(true)
        app.timer:start( app.model.timerIDs.MENUARROWTIMER )
    end

    if app.timer.timers[app.model.timerIDs.MENUARROWTIMER] == true then self:handleMenuArrowTimer() end         --animate menu arrow
end

function Frame:handleMenuArrowTimer()
    local speed = .01
    local minPcty = self.buttonMenu.pcty + self.buttonMenu.h/self.buttonMenu.paneh
    local maxPcty = minPcty + .05
    
    if self.imageMenuArrow.pcty >= maxPcty then
        self.imageMenuArrow.direction = 2       --upward
    elseif self.imageMenuArrow.pcty <= minPcty then
        self.imageMenuArrow.direction = 1       --downward
    end
    
    if self.imageMenuArrow.direction == 2 then speed = -1 * speed end
    
    local pcty = math.max( math.min(self.imageMenuArrow.pcty + speed, maxPcty), minPcty )
    
    self.imageMenuArrow:setPosition( self.imageMenuArrow.pctx, pcty )
end

function Frame:attachKeyboard( scrollPane )
    if scrollPane and scrollPane.typeName == "scrollpane" then
        self.keyboard.attachedToScrollPane = scrollPane
    end
end

function Frame:detachKeyboard( scrollPane )
    if scrollPane and scrollPane.typeName == "scrollpane" and self.keyboard.attachedToScrollPane == scrollPane then
        self.keyboard.attachedToScrollPane = nil
    end    
end

--##
------------------------------------------------------------------------
PageView = class()

function PageView:init()
    if ModuleView then self.moduleView = ModuleView() end
end

function PageView:resize(view, x, y, w, h, scaleFactor)
    view.panex = x  view.paney = y  view.panew = w  view.paneh = h
    view.x = x; view.y = y; view.w = w; view.h = h; view.scaleFactor = scaleFactor

    self:resizeScrollPane(view)
    
    if view.resize then view:resize( x, y, w, h, scaleFactor ) end -- do all extra stuff that needs to be done
    
    view.needsLayout = true     --This will remain true forever (per page)
    view.needsResize = false
    
end

function PageView:paint(view, gc)
    view.scrollPane:paint( gc )
    if view.paint then view:paint( gc ) end
end

function PageView:resizeScrollPane(view)
    self:setScrollPaneSize(view)
    view.scrollPane:setInitSizeAndPosition(view.scrollPane.initWidth, view.scrollPane.initHeight, view.scrollPane.pctx,  view.scrollPane.pcty)    
    view.scrollPane:setSize(view.scrollPane.nonScaledWidth / view.scaleFactor, view.scrollPane.nonScaledHeight / view.scaleFactor)     
    view.scrollPane:resize(view.x, view.y, view.w, view.h, view.scaleFactor)
end

function PageView:setScrollPaneSize(view)
    view.scrollPane.pctx = app.model.PAGE_BORDER_SIZE * view.scaleFactor / view.w
    view.scrollPane.pcty = (app.frame:getHeaderHeight() - 1 + 1) / view.h
    view.scrollPane.initHeight = self:getScrollPaneHeight()
    view.scrollPane.initWidth = view.w - app.model.PAGE_BORDER_SIZE * view.scaleFactor
end

function PageView:modifyKeyboard()
    app.frame.keyboard.active = false
end

function PageView:calculateLayoutPercentsXY(pane, xPositions, yPositions, scaleFactor, panew, vh)
    self:calculateLayoutPercentsX(pane, xPositions, scaleFactor, panew)
    self:calculateLayoutPercentsY(pane, yPositions, scaleFactor, vh)
end

function PageView:calculateLayoutPercentsX(pane, xPositions, scaleFactor, panew)
    if xPositions ~= nil then
        for i, v in pairs(xPositions) do
            pane.objects[i].pctx = v / panew
        end
    end
end
    
function PageView:calculateLayoutPercentsY(pane, yPositions, scaleFactor, vh)
    if yPositions ~= nil then 
        for i, v in pairs(yPositions) do
            pane.objects[i].pcty = v / vh
        end
    end
end

--objects is an array of objects
function PageView:computeObjectsPcty(objects, vh)
    --update pcty of objects based on updated vh
    for i, v in pairs(objects) do
        self.scrollPane.objects[i].pcty = v / vh
    end
end

--xPositions and/or yPositions contains the list of objects to position.
--if yPositions == nil, then only xPositions will be used.
--if yPositions ~= nil, then yPositions is used as the iterator and xPositions must correspond exactly.
function PageView:positionElements(pane, xPositions, yPositions)
    if xPositions and yPositions == nil then
        for i, v in pairs(xPositions) do
            pane.objects[i]:setPosition( pane.objects[i].pctx, pane.objects[i].pcty )
        end
    end

    if yPositions then 
        for i, v in pairs(yPositions) do
            pane.objects[i]:setPosition( pane.objects[i].pctx, pane.objects[i].pcty )
        end
    end
end

--Anchors, calculates the percents and positions the elements.
function PageView:anchorAndPositionXY(view, pane, anchorDataX, anchorDataY)
    local scaleFactor = pane.innerScaleFactor1
    local panew = pane.innerWidth1Centered
    local vh = pane.virtualHeight
    
    local xPositions = self:anchorObjectsX(anchorDataX, scaleFactor, panew)

    local yPositions, vh = self:anchorObjectsY(view, anchorDataY, scaleFactor, vh)

    self:calculateLayoutPercentsXY(pane, xPositions, yPositions, scaleFactor, panew, vh)

    self:positionElements(pane, xPositions, yPositions, scaleFactor, panew, vh)
end

function PageView:anchorAndPositionX(pane, anchorDataX)
    local panew = pane.innerWidth1Centered
    local scaleFactor = pane.innerScaleFactor1
    local vh = pane.virtualHeight
  
    local xPositions = self:anchorObjectsX(anchorDataX, scaleFactor, panew)

    self:calculateLayoutPercentsX(pane, xPositions, scaleFactor, panew)

    self:positionElements(pane, xPositions, yPositions, scaleFactor, panew, vh)
end

function PageView:anchorAndPositionY(view, pane, anchorDataY)
    local scaleFactor = pane.innerScaleFactor1
    local vh1 = pane.virtualHeight
    local panew = pane.innerWidth1Centered

    local yPositions, vh2 = self:anchorObjectsY(view, anchorDataY, scaleFactor, vh1)

    --Use the original virtual height (vh1) to first layout the selected elements.
    self:calculateLayoutPercentsY(pane, yPositions, scaleFactor, vh1)
    self:positionElements(pane, xPositions, yPositions, scaleFactor, panew, vh1)

    --If there is a new virtual height, then recalculate all element y position percentages.
    --[[if vh1 ~= vh2 then
        --pane:setVirtualSize(pane.clientWidth, vh2)   --Set virtual height to new virtual height that uses calculated values of scroll pane objects.

        for k, v in pairs(pane.objects) do
            v:setPane(v.panex, v.paney, v.panew, vh2, v.scaleFactor)        --should be vh2?
            v.pcty = v.pcty * vh1 / vh2        --Original percentage times original vh, but now divided by new vh to get the new percentage.         
            v:setPosition(v.pctx, v.pcty)
        end
    end]]

end

--You may also use this routine if you have already laid out the anchor objects previously
--and then set anchorObjectUsePctX = true in the anchorData. 
function PageView:anchorObjectsX(anchorData, scaleFactor, panew)
    local x = 0
    local pctx
    local object, anchorObject, anchorPosition, offset, anchorChild, anchorObjectWidth, anchorChildPctxTbl, parent
    local xPositions = {}

    if anchorData ~= nil then
        for i, v in ipairs(anchorData) do
            object = v.object
            anchorObject = v.anchorTo
            anchorPosition = v.anchorPosition
            position = v.position
            offset = v.offset
            anchorChild = v.anchorChild
            parent = v.parent

            if object ~= nil then
                if anchorPosition == "usePctx" then
                    x = object.pctx * panew
                else
                    if anchorObject ~= nil then 
                        if anchorPosition == "PaneRight" then
                            x = panew + offset * scaleFactor
                        elseif anchorPosition == "PaneLeft" then
                            x = offset * scaleFactor
                        elseif anchorPosition == "PaneMiddle" then
                            x = .5 * panew + offset * scaleFactor
                        elseif anchorPosition == "Left" then   --start from the top of the anchor object
                             x = xPositions[anchorObject.name]
                            
                            if anchorChild ~= nil then 
                                anchorChildPctxTbl = anchorObject:calculateChildPositions( x/panew, anchorObject.pcty, scaleFactor, panew )
                                x = anchorChildPctxTbl[anchorChild.name] * panew
                            end
                            
                            x = x + offset * scaleFactor
                        elseif anchorPosition == "Right" then    --start from the bottom of the anchor object
                            anchorObjectWidth = anchorObject:calculateWidth(scaleFactor)
                            x = xPositions[anchorObject.name]

                            if anchorChild ~= nil then 
                                anchorChildPctxTbl = anchorObject:calculateChildPositions( x/panew, anchorObject.pcty, scaleFactor, panew )
                                x = anchorChildPctxTbl[anchorChild.name] * panew
                                anchorObjectWidth = anchorChild:calculateWidth(scaleFactor) 
                            end
--print("name", object.name, anchorObject.name)                  
                            x = x + anchorObjectWidth + offset * scaleFactor
                        elseif anchorPosition == "Middle" then    --centered horizontally in the middle of the anchor object
                            anchorObjectWidth = anchorObject:calculateWidth(scaleFactor)
                            x = xPositions[anchorObject.name]
                            
                            if anchorChild ~= nil then 
                                anchorChildPctxTbl = anchorObject:calculateChildPositions( x/panew, anchorObject.pcty, scaleFactor, panew )
                                x = anchorChildPctxTbl[anchorChild.name] * panew
                                anchorObjectWidth = anchorChild:calculateWidth(scaleFactor) 
                            end
--print("name", object.name, anchorObject.name)  
                            x = x + .5 * anchorObjectWidth + offset * scaleFactor
                        else
                            x = 0
                        end
                    end
                end
                
                if position == "Left" then  -- do nothing
                elseif position == "Right" then x = x - object:calculateWidth(scaleFactor) 
                elseif position == "Middle" then x = x - .5 * object:calculateWidth(scaleFactor)
                end
    
                if parent ~= nil then
                    parent:modifyChildProperties(object.name, {pctx = x/panew})
                else
                    xPositions[object.name] = x
                end
            end
        end
    end
    
    return xPositions     
end

--Find the y position of an object using anchoring tags.
function PageView:findObjectYPosition(y, v, yPositions, scaleFactor, vh)
    local vh1 = vh
    local object = v.object
    local position = v.position
    local anchorObject = v.anchorTo
    local anchorPosition = v.anchorPosition
    local offset = v.offset
    local objHeight = object:calculateHeight(scaleFactor)
    local anchorChild = v.anchorChild
    local anchorObjectHeight, anchorChildPctyTbl
    
    if object ~= nil then

        if anchorPosition == "usePcty" then
            y = object.pcty * vh1
        else
            if anchorObject ~= nil then            
                if anchorPosition == "PaneTop" then
                    y = offset * scaleFactor
                elseif anchorPosition == "PaneMiddle" then
                    y = .5 * vh1 + offset * scaleFactor
                elseif anchorPosition == "PaneBottom" then
                    y = vh1 + offset * scaleFactor
                elseif anchorPosition == "Top" then   --start from the top of the anchor object
                    y = yPositions[anchorObject.name]
                    
                    if anchorChild ~= nil then 
                        _, anchorChildPctyTbl = anchorObject:calculateChildPositions( anchorObject.pctx, y/vh1, scaleFactor, nil, vh1 )
                        y = anchorChildPctyTbl[anchorChild.name] * vh1
                    end
                    
                    y = y + offset * scaleFactor
                elseif anchorPosition == "Middle" then    --centered vertically in the middle of the anchor object
                    anchorObjectHeight = anchorObject:calculateHeight(scaleFactor)
                    y = yPositions[anchorObject.name]
                    
                    if anchorChild ~= nil then 
                        _, anchorChildPctyTbl = anchorObject:calculateChildPositions( anchorObject.pctx, y/vh1, scaleFactor, nil, vh1 )
                        y = anchorChildPctyTbl[anchorChild.name] * vh1
                        anchorObjectHeight = anchorChild:calculateHeight(scaleFactor) 
                    end
--print("name", object.name, anchorObject.name)        
                    y = y + .5 * anchorObjectHeight + offset * scaleFactor
                elseif anchorPosition == "Bottom" then    --start from the bottom of the anchor object
                    anchorObjectHeight = anchorObject:calculateHeight(scaleFactor)
                    y = yPositions[anchorObject.name]
                    
                    if anchorChild ~= nil then 
                        _, anchorChildPctyTbl = anchorObject:calculateChildPositions( anchorObject.pctx, y/vh1, scaleFactor, nil, vh1 )
                        y = anchorChildPctyTbl[anchorChild.name] * vh1
                        anchorObjectHeight = anchorChild:calculateHeight(scaleFactor) 
                    end
--print("name", object.name, anchorObject.name)        
                    y = y + anchorObjectHeight + offset * scaleFactor
                elseif anchorPosition == "FrameTop" then
                    y = offset * scaleFactor
                elseif anchorPosition == "FrameMiddle" then
                    y = .5 * anchorObject.h + offset * scaleFactor
                elseif anchorPosition == "FrameBottom" then
                    y = anchorObject.h + offset * scaleFactor
                else
                    y = 0
                end
            end
        end
    end
    
    if position == "Top" then
    elseif position == "Middle" then
        y = y - .5 * objHeight
    elseif position == "Bottom" then  
        y = y - objHeight
    end

    return y, objHeight
end

--Use this function to determine the vertical position of a single object anchored to a pane or another object.
function PageView:positionObjectY(anchorData, scaleFactor, vh)
    local y = 0
    local objHeight
    local yPositions = {}
    local anchorObject = anchorData.anchorTo   
    
    yPositions[anchorObject.name] = anchorObject.y
    
    y, objHeight = self:findObjectYPosition(y, anchorData, yPositions, scaleFactor, vh) 

    return y    
end

--anchorData must be in order from top to bottom.  Any objects that are dependent on the pane height must be placed in the table
--after all the non-dependent objects.  Any object placement that goes beyond the initial vh will cause the remainder of the calculations
--to use the newly calculated vh.
function PageView:anchorObjectsY( view, anchorData, scaleFactor, vh )
    local y = 0
    local pcty
    local vh1 = vh
    local object, anchorToObject, position, offset, objHeight, parent
    local yPositions = {}

    if anchorData ~= nil then
        for i, v in ipairs(anchorData) do
            object = v.object
            anchorObject = v.anchorTo
            position = v.position
            parent = v.parent
            
            --if object ~= nil and anchorObject ~= nil then   
            if object ~= nil then    
                y, objHeight = self:findObjectYPosition(y, v, yPositions, scaleFactor, vh)
--print("name", object.name, y, objHeight)                
                if position == "Top" or position == "Middle" then
                    if y + objHeight > vh1 then vh1 = y + objHeight; end
                elseif position == "Bottom" then -- the position is bottom. so the height of the object won't matter
                    if y > vh1 then vh1 = y; end
                end

                if parent ~= nil then
                    parent:modifyChildProperties(object.name, {pcty = y/vh})
                else
                    yPositions[object.name] = y
                end
            end
        end
    end

    return yPositions, vh1     
end

function PageView:addVhWhiteSpace(view, vh)
    if view.toAddVHWhitespace == true then
        local paneh = view.scrollPane.h
        local vhWhiteSpace = 10
        
        vh = vh + vhWhiteSpace  --Add a little white space.
     
        --If the vh is longer, than chopping off 10 pixels will be ok.  This helps with rounding errors.
        --The scrollbar will only turn on if the paneh is less than the vh, but not equal to or greater.
        if math.floor(vh - paneh) <= vhWhiteSpace and vh - paneh > 0 then  
            vh = paneh
        end 
    end
    
    return vh
end

function PageView:assignAnchorData(anchorTable)
    local anchorData = {}
    
    for idx=1, #anchorTable do
        anchorData[idx] = {object = anchorTable[idx][1], anchorTo = anchorTable[idx][2], anchorPosition = anchorTable[idx][3], position = anchorTable[idx][4], offset = anchorTable[idx][5]}
    end
    
    return anchorData
end

function PageView:invalidate(view)
    app.frame:setInvalidatedArea(view.x, view.y, view.w, view.h)
end

function PageView:drawBackgroundColor(view, gc )
    gc:setColorRGB( unpack(view.backgroundColor[1]) )
    gc:fillRect(view.x, view.y, view.w, view.h)
end

function PageView:updateView(view, layoutOnly)
    if app.frame.needsResize == false and view.needsResize == nil then
        self:resize(view, app.frame.x, app.frame.y, app.frame.w, app.frame.h, app.frame.scaleFactor)   --The layout will be done after the view state is initialized.
    elseif view.needsResize == true then
        self:resizeAndLayout(view)
    elseif layoutOnly ~= false and view.needsLayout == true then  
        self:layout(view)
    end
    
    if view.updateView then view:updateView() end -- in case your page needs to do something else after update view
end

function PageView:resizeAndLayout(view)
    self:resize(view, app.frame.x, app.frame.y, app.frame.w, app.frame.h, app.frame.scaleFactor)   --Perform the actual resize that was previously delayed.
    self:layout(view)
end

function PageView:layout(view)
    self:layoutScrollPane(view, view.w, view.h)
    self:layoutFooterPane(view)
    self:invalidate(view)
end

function PageView:layoutScrollPane(view, w, h)
    local xPositions, xPositions2, yPositions, yPositions2, vh, vh1, anchorDataX, anchorDataXCol2, anchorDataY, anchorDataYCol2
    local vh2 = 1
    local col1, col2 --= 1, 0		--Set the columns to 1 and 100%.
    local sf = nil		--Calculate the inner scale factor for column 1 for the current pane size
    
    if view.viewStyle == app.viewStyles.TWO_COLUMN or (view.w > view.h and view.w > 2.1 * app.HANDHELD_WIDTH and view.forceTwoColumn == true) then
        view.numberOfColumns = 2
        col1 = .5; col2 = .5        --Set the columns to 2 and 50% each.		  
    else
        view.numberOfColumns = 1
        col1 = 1; col2 = 0          --Set the columns to 1 and 100%.		  
    end
    
    view.scrollPane:setColumns(col1, col2)
    view.scrollPane:setScaleFactorMinimum(1, 1) --Minimum scale factor is 1.
  
    --Layout the objects onto the scroll pane.        
    anchorDataX, anchorDataY, anchorDataYCol2 = self:layoutXY(view, view.numberOfColumns)

    --Put the y positions of the scroll pane elements at scale factor of 1.  We only need to do this once.
    --Get the virtual height for a calculator layout.  This will tell us the vh that is needed for the original layout.
    if view.virtualHeights then
        vh1 = view.virtualHeights[app.controller.activePageID]
    else
        yPositions, vh1 = self:anchorObjectsY(view, anchorDataY, 1, app.HANDHELD_HEIGHT - app.frame.initHeaderHeight - app.frame.initFooterHeight)
        vh1 = self:addVhWhiteSpace(view, vh1)
    end
    
    if view.numberOfColumns == 2 then
        yPositions2, vh2 = self:anchorObjectsY(view, anchorDataYCol2, 1, app.HANDHELD_HEIGHT - app.frame.initHeaderHeight - app.frame.initFooterHeight)
        vh2 = self:addVhWhiteSpace(view, vh2)
    end
    
    vh = math.max(vh1, vh2)
 
    view.scrollPane:setVirtualSize(view.scrollPane.clientWidth, vh)   --Set virtual height to new virtual height that uses calculated values of scroll pane objects.

    if view.w == app.HANDHELD_WIDTH or view.viewStyle == app.viewStyles.LARGE then sf = view.scaleFactor end	--Force the inner scale factor for column 1 to be the same as the overall scale factor

    view.scrollPane:setInnerScaleFactor(sf)   --If sf==nil, then this call will use the vh to calculate the inner scale factor.

     --Recalculate the virtualHeight now that we have a different scale factor and set the vertical positions of each object.  Don't size and position the scroll pane objects now, since that will be done by resizeWidgets()
    yPositions, vh1 = self:anchorObjectsY(view, anchorDataY, view.scrollPane.innerScaleFactor1, view.scrollPane.h)
    vh1 = self:addVhWhiteSpace(view, vh1)

    if view.numberOfColumns == 2 then
        yPositions2, vh2 = self:anchorObjectsY(view, anchorDataYCol2, view.scrollPane.innerScaleFactor2, view.scrollPane.h)
        vh2 = self:addVhWhiteSpace(view, vh2)
    end
    vh = math.max(vh1, vh2)

--        vh = 174; vh1 = 174 
    view.scrollPane:setVirtualSize(view.scrollPane.clientWidth, vh)   --Set virtual height to new virtual height that uses calculated values of scroll pane objects.

    view.scrollPane:centerPane()	--Center the pane after calculating the new vh, but before setting the x positions

   --Set the horiztonal positions for each object that requires knowledge of the pane size.  Don't size and position scrollpane objects now, because resizeWidgets() will do that.
    xPositions = self:anchorObjectsX(anchorDataX, view.scrollPane.innerScaleFactor1, view.scrollPane.innerWidth1Centered)
    if view.numberOfColumns == 2 then
        xPositions2 = self:anchorObjectsX(anchorDataX, view.scrollPane.innerScaleFactor2, view.scrollPane.innerWidth2Centered)
    end
    
    self:calculateLayoutPercentsXY(view.scrollPane, xPositions, yPositions, view.scrollPane.innerScaleFactor1, view.scrollPane.innerWidth1Centered, vh1)
    if view.numberOfColumns == 2 then
        self:calculateLayoutPercentsXY(view.scrollPane, xPositions2, yPositions2, view.scrollPane.innerScaleFactor2, view.scrollPane.innerWidth2Centered, vh2)
    end
    
    self:setObjectsColumn(view)       --This needs to be looked at for a 2-column module.  Where do we need to place this line?  

    --Resize and position all widgets on scroll pane.
    view.scrollPane:resizeWidgets()
end

function PageView:layoutXY(view, numberOfColumns)
    local anchorDataX, anchorDataY, anchorDataYCol2

    anchorDataY = view:layoutY()
    if numberOfColumns == 2 then
        anchorDataYCol2 = view:layoutY()
    end
    
    if numberOfColumns == 2 then
        anchorDataX = view:layoutXTwoColumn()
    else
        anchorDataX = view:layoutXOneColumn()
    end
    
    return anchorDataX, anchorDataY, anchorDataY2
end

--Set column for each object
function PageView:setObjectsColumn(view)
end

function PageView:layoutFooterPane(view)
    local xPositions, xPositions2, yPositions, yPositions2, vh, vh1, anchorDataX, anchorDataXCol2, anchorDataY, anchorDataYCol

    if view.layoutFooter then
        anchorDataX, anchorDataY = view:layoutFooter()
    
        xPositions = self:anchorObjectsX(anchorDataX, view.scaleFactor, app.frame.footer.w)
        yPositions, vh1 = self:anchorObjectsY(view, anchorDataY, view.scaleFactor, app.frame.footer.h)
        
        self:calculateLayoutPercentsXY(app.frame.footer, xPositions, yPositions, view.scaleFactor, app.frame.footer.w, vh1)
    
        app.frame.footer:resizeWidgets()
    end
end

function PageView:invalidateFooter(view)
    local footerHeight = app.frame:getFooterHeight()
    app.frame:setInvalidatedArea(app.frame.x, app.frame.y + app.frame.h - footerHeight + 1, app.frame.w, footerHeight - 1)
end

function PageView:setupScrollPane(view)
    if view.scrollPane == nil then
        view.scrollPane = app.frame.widgetMgr:newWidget("SCROLL_PANE", view.pageID .."_scrollpane", {pctx = 0, pcty = 0, initHeight = 100, initWidth = 100} )
    end
end

function PageView:drawScrollPaneObjects(view, gc)
end

function PageView:getScrollPaneHeight()
    return app.frame.h - app.frame:getFooterHeight() - app.frame:getHeaderHeight()
end

function PageView:switchView(view)
    self.view = view
    self:resize(view, view.panex, view.paney, view.panew, view.paneh, app.frame.scaleFactor)
    app.frame:setInvalidatedArea(view.x, view.y, view.w, view.h)
end

function PageView:setupView(view)
    if view.needsViewSetup == true then
        gStartTime = timer.getMilliSecCounter()
        self:setupScrollPane(view)

        if view.setupView then view:setupView() end
    end
end

function PageView:enterKey(view)
    if view.enterKey then view:enterKey() end
end

function PageView:selectKey(view) self:enterKey(view) end

function PageView:escapeKey(view)
    if app.timer.timers[app.model.timerIDs.PARAGRAPHTIMER] then
        if view.tooltipState == app.model.tooltipStateIDs.DIRECTION then
            view.tooltipDirections.animatedPara:stopAnimation()
        else
            view.tooltipHint.animatedPara:stopAnimation()   
        end
    end
    
    --Stop any animations. if there is any
    if view.animationTimerIDs then
        for i, v in pairs(view.animationTimerIDs) do if app.timer.timers[i] then v:stopAnimation() end end
    end
    
    if view.escapeKey then view:escapeKey() end
end

function PageView:drawCheckMark(gc, x, y, w, h, scale)
    app.graphicsUtilities:drawFigure(app.graphicsUtilities.figureTypeIDs.CHECK_MARK, gc, x+.5*w-7*scale, y+.5*h-6*scale, 2*scale, app.graphicsUtilities.Color.black, app.graphicsUtilities.drawStyles.FILL_ONLY)
end

function PageView:setObjectVisibility(visibleTable, hideTable, activeTable, inactiveTable)
    if visibleTable then for i=1, #visibleTable do visibleTable[i]:setVisible(true) end end
    if hideTable then for i=1, #hideTable do hideTable[i]:setVisible(false) hideTable[i]:setActive(false) end end
    if activeTable then for i=1, #activeTable do activeTable[i]:setActive(true) end end
    if inactiveTable then for i=1, #inactiveTable do inactiveTable[i]:setActive(false) end end
end

function PageView:setMovieView(view)
    self.movieView = view
end

function PageView:playMovie(event, scene)
    local endEvent = self.movieView.sceneList[scene].endEvent
    local previousObject = self.movieView.sceneList[scene].prevObj
    local nextObject = self.movieView.sceneList[scene].nextObj
    local nextScene = self.movieView.sceneList[scene].nextScene
    local cleanupFunction = self.movieView.sceneList[scene].cleanupFn
    local nextState = self.movieView.sceneList[scene].nextState
    local nextSubState = self.movieView.sceneList[scene].nextSubState

    if scene == app.model.scenes.SCENE_START then
        app.frame.UIMgr:deactivateObjects(app.frame.activeViewID)   --deactivate objects during animation
        self.movieView.movieListener = nextObject:addListener(function(...) self:playMovie(...) end, nextScene)
        app.frame:enableUserInput(app.frame.allowUserInputCategories.ANIMATION, false)           --disable user input during animation except escapeKey
        nextObject:startAnimation()  --this will run asynchronously
    elseif scene == app.model.scenes.SCENE_END then
        if event == endEvent then
            previousObject:removeListener(self.movieView.movieListener, scene)
            app.frame.UIMgr:activateObjects(app.frame.activeViewID)      --reactivate objects after animation
            app.frame:enableUserInput(app.frame.allowUserInputCategories.ANIMATION, true)           --enable user input after animation
            
            if cleanupFunction then cleanupFunction() end

            if nextState ~= nil then self.movieView.page.nextState = nextState end
            if nextSubState ~= nil then self.movieView.page.nextSubState = nextSubState end
            if nextState ~= nil or nextSubState ~= nil then app.controller:dispatch(self.movieView.page.pageID) end
        end
    else
        previousObject:removeListener(self.movieView.movieListener, scene)
        self.movieView.movieListener = nextObject:addListener(function(...) self:playMovie(...) end, nextScene)
        if cleanupFunction then cleanupFunction() end
        nextObject:startAnimation()  --this will run asynchronously
    end
end

function PageView:setupImages(view)
    if view.imageWaitCursor == nil and view.useSmallHourglass == true then     --Only one copy will be loaded for the entire module.
        view.imageWaitCursor = app.frame.widgetMgr:newWidget("IMAGE", view.pageID.."_imageWaitCursor", _R.IMG.hourglass, {initSizeAndPosition = {15, 30, 0, 0}, visible = false} )
        view.scrollPane:addObject(view.imageWaitCursor)
    end
end

function PageView:attachKeyboard(view) app.frame:attachKeyboard( view.scrollPane ) end
function PageView:detachKeyboard(view) app.frame:detachKeyboard( view.scrollPane ) end

--##
-----------------------------------------------------------------
Controller = class() 

function Controller:init()
	self.pageLogic = nil
	self.pages = {} 
	self.activePageID = 1
	self.previousPageID = 0
	
	self.time_started = timer.getMilliSecCounter()
	
	self.tblPostMessages = {}   --This table contains posted messages that are executed on the next available timer tick.
end

function Controller:setupController()
    for k, v in pairs(app.model.timerIDs) do app.timer.timers[v] = false end    --Initialize the timers to false

    if ModuleController then self.moduleController = ModuleController() end    
end

--Setup to stay on current state or move to another state
function Controller:dispatch(pageID)
    local state, subState

    repeat
        self.pages[pageID].state = self.pages[pageID].nextState         --Move to the next state.
        self.pages[pageID].subState = self.pages[pageID].nextSubState         --Move to the next sub state.
        state = self.pages[pageID].state
        subState = self.pages[pageID].subState

        if state == app.model.statesList.LAUNCH then
            self:stateLaunch(pageID)
        elseif state == app.model.statesList.INIT then
            self:stateInit(pageID)
        elseif state == app.model.statesList.END then
            self:stateEnd(pageID)
        elseif state == app.model.statesList.TRANSITION then
            self:stateTransition()
        else
            app.model.stateFunctions[state][subState](self.pages[pageID])
        end
    until state == self.pages[pageID].nextState and subState == self.pages[pageID].nextSubState
end

function Controller:nextSubState(page)
    if self.moduleController and self.moduleController.nextSubState then self.moduleController:nextSubState(page) end

    if app.isPlatformSlow() then 
        --Give check button a chance to paint.
        app.controller:postMessage({function(...) self:goToNextSubState(page) end})
    else
        self:goToNextSubState(page)
    end    
end

function Controller:goToNextSubState(page)
    local nextSubState = app.model.nextSubStateTable[page.subState]
    if nextSubState ~= nil then page.nextSubState = nextSubState end

    app.controller:dispatch(page.pageID)
end

function Controller:handleTimer()
    self:handlePostMessages()

    for k,v in pairs(app.model.timerIDs) do
        if app.timer.timers[app.model.timerIDs[k]] == true then
           if app.model.timerFunctions[app.model.timerIDs[k]] then app.model.timerFunctions[app.model.timerIDs[k]]() end
        end
    end
        
    app.frame:handleTimer()
end

function Controller:handleTransitionTimer()
    local page = self.pages[self.activePageID]
    local view = app.frame.views[app.frame.activeViewID]
    
    self.delayTimeTick = self.delayTimeTick + 1

    if self.delayTimeTick == 1 then
        --do nothing
    elseif self.delayTimeTick >= self.delayTime then
        app.timer:stop( app.model.timerIDs.TRANSITIONTIMER )
        page.nextState = app.model.statesList.END
        self:dispatch(page.pageID)
    end
end


--These messages will be processed in order on the next timer tick.
--msg is an array with two elements.  The first element is the function.  The second is the vararg arguments in an array (if needed) in format {...}
function Controller:postMessage(msg)
    app.utilities:queueAdd(self.tblPostMessages, msg)
    app.frame:enableUserInput(app.frame.allowUserInputCategories.POST_MESSAGE, false)   --No user input will be accept while messages are pending.
end

function Controller:handlePostMessages()
    if #self.tblPostMessages ~= 0 then
        app.postMsgTickTimerCount = app.postMsgTickTimerCount + 1   --If we don't wait the extra 1/10 second tick, the iPad and the calculator do not update the screen.
        if app.postMsgTickTimerCount > 1 then
            local msg = app.utilities:queueRemove(self.tblPostMessages)
            if msg[2] ~= nil then 
                msg[1](unpack(msg[2]))
            else
                msg[1]()
            end   --Execute posted message   Looks like: fn(...)
            app.postMsgTickTimerCount = 0
        end
    end
    
    if #self.tblPostMessages == 0 then app.frame:enableUserInput(app.frame.allowUserInputCategories.POST_MESSAGE, true) end
end

function Controller:setNextState(pageID, nextState, nextSubState)
    self.pages[pageID].nextState = nextState
    self.pages[pageID].nextSubState = nextSubState
end

function Controller:stateLaunch(pageID)
    if self.moduleController and self.moduleController.stateLaunch then self.moduleController:stateLaunch(self.pages[pageID]) end
end

function Controller:stateInit(pageID)
    if self.moduleController and self.moduleController.stateInit then self.moduleController:stateInit(self.pages[pageID]) end
end

function Controller:stateEnd(pageID)
    if self.moduleController and self.moduleController.stateEnd then self.moduleController:stateEnd(self.pages[pageID]) end
end

function Controller:stateTransition()
    self.delayTimeTick = 0
    app.timer:start( app.model.timerIDs.TRANSITIONTIMER )  --The next state will be set by the transition timer handler.
end

function Controller:addPages()
    for k, v in pairs(app.model.pageList) do
        self:addPage(k, v[1], v[2], v[3], v[4])     --Example: 1, StoryProblemsPage, NoRemainderPageView, "STORY_PROBLEMS"
    end
end

function Controller:addPage(pageID, page, pageView, pageName)
    self.pages[pageID] = page(pageName)
    self.pages[pageID].pageID = pageID
end

--Call this function before switching pages to setup the transition and post a message to allow time for objects to paint between page switches.
function Controller:switchPages(pageID, startup)
    if self.moduleController and self.moduleController.switchPages then self.moduleController:switchPages(pageID) end

    if not startup and app.isPlatformSlow(pageID) == true then
        self.inTransition = true    --used by frame:paint() to delay painting of new page.
        app.frame.UIMgr:deactivateObjects(app.frame.activeViewID)  --Deactivate the objects on the current page so that the user can't accidentally click on them during transition.  Reactivate within page INIT.
        app.frame.footer:setVisible(false)
        app.frame.imageWaitCursor:setVisible(true)
        app.frame:disableMenuArrow()   --physical menu button on calculator is pressed, hide menu arrow
        app.frame.keyboard:setVisible(false)
        app.frame:setInvalidatedArea( 0, 0, app.frame.w, app.frame.h )  --This is necessary to invalidate the scrollpane view.
        self:postMessage({function(...) self:continueSwitchPages(pageID) end})    --Delayed execution of function.
    else
        self:continueSwitchPages(pageID)
    end
end
    
--This function is called after the transition and now the page will be switched.
function Controller:continueSwitchPages(pageID)
    if self.inTransition == true then
        app.frame.UIMgr:activateObjects(app.frame.activeViewID) --Re-activate
        self.inTransition = false
    end
    
    gStartTime = timer.getMilliSecCounter()

    local page = self.pages[pageID]
  
    self.previousPageID = self.activePageID
    self.activePageID = pageID
    
    app.frame:switchViews(pageID)

    self:dispatch(pageID)

    app.frame.imageWaitCursor:setVisible(false)
end

function Controller:begin()
    if self.moduleController and self.moduleController.begin then self.moduleController:begin() end 
end

--##APP
---------------------------------------------------------------
app.configure = function()
  app.platformConfig()
  app.setAppConstants()
  app.setTouchArea()      --Set the size of the touch area for finger or mouse
  app.setGlobals()
  app.defineCharacterSet() 
  
  app.timer = Timer()
  app.utilities = Utilities()
  app.graphicsUtilities = GraphicsUtilities()
  app.stringTools = StringTools()
  
  app.model = Model()
  app.controller = Controller()
  app.frame = Frame()
end

app.setAppConstants = function() 
    app.HANDHELD_WIDTH = 318
    app.HANDHELD_HEIGHT = 212
  
    app.viewStyles = app.enum({ "STANDARD", "LARGE", "TWO_COLUMN"})

    app.garbageCollectSpeed = 5    --5 for .1 clock and 20 for .025 clock 
    app.clockTickSpeed = .1       --.1 for 1/10 second clock.  .025 for 1/40 second clock.  (.025 seems to be too fast.  Keep at .1)
     
    app.SHOULD_DRAW_DEBUG_RECT = false
end

app.platformConfig = function()
    local ok, val = pcall(platform.getPlatformType)
   
    if ok then
        app.platformType = val     --This will be "ndlink" if not in native Nspire.
    else
        app.platformType = "NSpire"
    end
    
    if app.platformType == "NSpire" then
        app.scriptIsActivated = nil
        app.scriptHasFocus = false
    else
        app.scriptIsActivated = true
        app.scriptHasFocus = true
    end
    app.platformHW = platform.hw()      --7 is emulator on Windows, 3 is actual calculator
end

--Define characters such as double headed arrow
app.defineCharacterSet = function()
    if app.platformType == "NSpire" or app.platformType == "love2d" then app.charDoubleArrow = string.uchar(0x2195) else app.charDoubleArrow = string.uchar(0x21D5) end
    app.charBackspaceArrow = string.uchar(0x2190)
    app.charBullet = string.uchar(0x2022)
    app.charDegree = string.uchar(0x00B0)
    app.charExclamation = string.uchar(0x0021)--(0xFF01)
    app.div_sign = string.uchar(0x00F7)
    app.charRightArrow = string.uchar(0x25B6)
    app.charLeftArrow = string.uchar(0x25C0)
    app.charUpArrow = string.uchar(0x25B2)
    app.charDownArrow = string.uchar(0x25BC)
    app.charSuperscript_3 = string.uchar(0x00B3)
    app.charSuperscript_2 = string.uchar(0x00B2)
    app.charGrip = string.uchar(0x2261)
    app.charEllipsis = string.uchar(0x2026)
    app.multiplication_symbol = string.uchar(0x00D7)
    app.checkMark = string.uchar(0x2713)
    app.multiplicationSymbol = string.uchar(0x2022)
    app.filledCircle = string.uchar(0x25CF)
    app.filledTriangle = string.uchar(0x25B2)
    app.filledSquare = string.uchar(0x25A0) -- string.uchar(0x25FC)
    app.filledDiamond = string.uchar(0x25C6)
    app.emptyCircle = string.uchar(0x25CB)
    app.emptyTriangle = string.uchar(0x25B3)
    app.emptySquare = string.uchar(0x25A1)
    app.emptyDiamond = string.uchar(0x25C7)
end

app.enum = function(names)
  local t={}
  local enumID=1
  
  for _,k in ipairs(names) do
      t[k]= enumID
      enumID = enumID+1
  end

  return t
end

app.setGlobals = function()
    app.mouseDown = false       --Set to true in the on.mouseDown() event
    app.touchStart = false
    app.selectButtonDown = false    --Set to true only on calculator
    app.startupTime = 1000      --Set this time during on.construction() 
    app.postMsgTickTimerCount = 0
end

--The size of the touch area needs to be bigger when using a finger.		
app.setTouchArea = function()	
	--Some touch devices have both mouse pointer and touch screen.
	--Set a bigger touch area only when the touch device's screen is tapped
    if touch and touch.enabled() and app.touchStart == true then			
        app.MOUSE_XWIDTH = 25       --This many pixels is reasonable for touch area.		
        app.MOUSE_YHEIGHT = 25	
    else	
        app.MOUSE_XWIDTH = 2       --A smaller area for mouse pointer only.		
        app.MOUSE_YHEIGHT = 2		
    end	
end

--Call this function with b == true to show the cursor after a key press.  Hiding the cursor first, then showing it seems to make it work right.
app.showCursor = function(b)
    cursor.hide()
    if b then cursor.show() end
end

--Only check on web and any startup longer than 400ms will be considered slow. 150ms on a desktop computer, 616ms on Chromebook, 1022ms on old iPad
app.isPlatformSlow = function(pageID)
    if app.platformHW == 3 then
        return true
    elseif app.model.PLATFORM_IS_SLOW == true then
            return true
    elseif app.platformType == "ndlink" and app.startupTime > app.model.PAGE_MAX_LOAD_TIME_WEB then
        return true
    elseif pageID ~= nil then
        if app.frame.views[pageID].needsViewSetup and app.startupTime > app.model.PAGE_MAX_LOAD_TIME_DESKTOP then
            return true
        else
            return false
        end
    else
        return false
    end
end

--##
-------------------------------------------------------

function on.construction( userData )
    app.startTime = timer.getMilliSecCounter()

    app.configure()
	app.userData = userData

    app.timer:start(app.model.timerIDs.DEFAULTTIMER)

    app.controller:setupController()    
    app.controller:addPages()

    app.frame:setupFrame()
    app.frame:addViews()
    
    app.controller:begin()
end

function on.resize( w, h )
    app.frame:resize(w, h)
end

function on.paint(gc)
    app.frame:paint(gc)
    
    if app.model.COLLECTGARBAGE_ON_PAINT then collectgarbage() end -- force garbage collection on paint
end

function on.activate()
    cursor.set("pointer")
    app.showCursor( false )

    app.scriptIsActivated = true
    if app.timer.isReady and app.timer.started == false then
        timer.start(app.timer.timer_tick)
        app.timer.started = true
    end  
end

function on.deactivate()
    app.scriptIsActivated = false
    if app.timer.isReady and app.timer.started == true then
        timer.stop()       --We need to stop the timer so that other tabs don't slow down.
        app.timer.started = false
    end
end

function on.getFocus()
    app.scriptHasFocus = true
end

function on.loseFocus()
    app.scriptHasFocus = false
end

function on.timer()
    if app.scriptIsActivated == true then
        app.timer.timerCount = app.timer.timerCount + 1
        if app.timer.timerCount >= app.garbageCollectSpeed then
            app.timer.timerCount = 0
            -- print( "collect garbage", collectgarbage("count")*.001, "mb" )
            if app.model.SHOW_MEMORY then app.controller.memoryCounter = collectgarbage( "count" )
            else collectgarbage()        --Each timer event on the Nspire seems to cause a loss of a few bytes.  Cleaning up the garbages helps solve this.
            end
        end

        app.controller:handleTimer()
    end
end

function on.arrowLeft() app.frame:arrowLeft() end
function on.arrowRight() app.frame:arrowRight() end
function on.arrowUp() app.frame:arrowUp() end
function on.arrowDown() app.frame:arrowDown() end
function on.charIn(char) app.frame:charIn(char) end
function on.tabKey() app.frame:tabKey() end
function on.backtabKey() app.frame:backTabKey() end
function on.backspaceKey() app.frame:backspaceKey() end
function on.enterKey() app.frame:enterKey() end
function on.escapeKey() app.frame:escapeKey() end
function on.mouseMove(x,y)app.frame:mouseMove(x, y) end
function on.grabDown(x, y) app.frame:grabDown(x, y) end
function on.grabUp(x, y) app.frame:grabUp(x,y) end
function on.cut() app.frame:cut() end
function on.copy() app.frame:copy() end
function on.paste() app.frame:paste() end

function on.mouseDown(x,y)
    if app.touchStart == false and (app.mouseDown == true or app.selectButtonDown == true) then on.mouseUp(x, y) end      --If mouse was already down, then it looks like we missed the previous mouseUp, so do it now.

    --If x and y are zero, then the mouse pointer is hidden, so do nothing and wait for mouse up.
    if x == 0 and y == 0 then
        app.frame:onUserInput()
        app.selectButtonDown = true
    else
        app.mouseDown = true
        app.frame:mouseDown(x,y)
    end
end

function on.mouseUp(x,y)
    --Unfortunately, if you press the Select button fast enough, you can get (0,0) even if the mouse arrow is visible.  We just have to live with that.
    if x == 0 and y == 0 and app.selectButtonDown == true then     --Sometimes the MouseUp(0,0) is sent without ever having a mouse down so at least ignore that situation.
        app.frame:selectKey()  --If no x and y are zero, then the mouse pointer is hidden.  The select key on the calculator is the only time this will ever happen.
    else
        app.frame:mouseUp(x, y)
    end

    app.mouseDown = false   
    app.touchStart = false
    app.selectButtonDown = false
end
   
------------------------------------   
--These functions are not part of TI
------------------------------------
--Once the user taps the screen at any time, we permanently enable the keyboard.
function on.touchStart(x,y)
    app.mouseDown = true
    app.touchStart = true
    
    if app.model.HAS_KEYBOARD and app.frame.keyboard.enabled == false then
        app.frame.keyboard.enabled = true
        app.frame.keyboard.active = true 
    end     --This line is only executed once for the life of the module.
	
	app.setTouchArea() 

    on.mouseDown(x,y)
end

function on.shiftArrowRight() app.frame:shiftArrowRight() end
function on.shiftArrowLeft() app.frame:shiftArrowLeft() end
function on.homeKey() app.frame:homeKey() end
function on.endKey() app.frame:endKey() end
function on.deleteKey() app.frame:deleteKey() end

---------------------------------------------------------
Widget = class()

--name: each widget should be assigned a unique string name
function Widget:init(name)
    self.typeName = "widget"
    self.name = name
    self.x = 20; self.y = 20; self.w = 10; self.h = 10
    self.wWithFocus = self.w; self.hWithFocus = self.h
    self.initX, self.initY = 0, 0
    self.centerX, self.centerY = 0, 0
    self.scaleFactor = 1
    self.panex = 0; self.paney = 0; self.panew = 318; self.paneh = 212;
    self.initPctX = 0; self.initPctY = 0;
    self.pctx, self.pcty = self.initPctX, self.initPctY
    self.initWidth = 7; self.initHeight = 2;
    self.nonScaledWidth = self.initWidth; self.nonScaledHeight = self.initHeight
    self.nonScaledWidthWithFocus = self.nonScaledWidth; self.nonScaledHeightWithFocus = self.nonScaledHeight
    self.xGrabOffset = 0; self.yGrabOffset = 0;
    
    self.visible = true
    self.active = true
    self.hasFocus = false
    self.hasGrab = false
    self.mouseGrabbed = false
    self.tracking = false
    self.scrollY = 0
    self.tabSequence = {}       --Set by container
    self.backTabSequence = {}
    self.firstTabSequence = nil
    self.lastTabSequence = nil
    self.listeners = {}
    
    self.initFontSize = 10
    self.fontSize = self.initFontSize
    self.fontColor = {0, 0, 0}
    self.focusColor = {255, 0, 0}
    self.initFillColor = {242, 242, 235}    --whitegrey
    self.initFontFamily = "sansserif"
    self.fontFamily = self.initFontFamily
    self.initFontStyle = "r"
    self.fontStyle = self.initFontStyle
    self.text = ""
    self.mouse_xwidth, self.mouse_yheight = app.MOUSE_XWIDTH, app.MOUSE_YHEIGHT   --Used for increasing touch area
    self.boundingRectangle = false  --For debugging
    self.boundingRectangleColor = {0, 0, 255}

    self.stringTools = app.stringTools
    self.scaleFont = self.stringTools.scaleFont 
    
    self.acceptsFocus = false
    self.focusColor = {255, 0, 0}
    self.mouseHoverColor = {200, 200, 200}  --grey      
    self.mouseDownColor =  {132, 132, 132}  --dark grey     
    self.shouldHover = false

    self.propertiesFunctions = {active = function(...) return self:setActive(...) end, visible = function(...) return self:setVisible(...) end,
      hasFocus = function(...) return self:setFocus(...) end, scrollY = function(...) return self:setScrollY(...) end, fontColor = function(...) return self:setFontColor(...) end,
      fillColor = function(...) return self:setFillColor(...) end, text = function(...) return self:setText(...) end, initSizeAndPosition = function(params) return self:setInitSizeAndPosition(params[1], params[2], params[3], params[4]) end,
      label = function(...) return self:setLabel(...) end,  drawCallback = function(...) self:setDrawCallback(...) end, clickCallback = function(...) self:setClickCallback(...) end,
      initFontAttributes = function(params) return self:setInitFontAttributes(params[1], params[2], params[3]) end, maxInputWidth = function(...) return self:setMaxInputWidth(...) end,
      minInputWidth = function(...) return self:setMinInputWidth(...) end, initInputSizes = function(...) return self:setInitInputSizes(...) end, 
    }
end

function Widget:resize(panex, paney, panew, paneh, scaleFactor)
    self:setPane(panex, paney, panew, paneh, scaleFactor)     
    self:setSize(self.nonScaledWidth, self.nonScaledHeight)     
    self:setPosition(self.pctx, self.pcty)
end

function Widget:paint( gc )
    if self.visible then
        local x = self.x
        local y = self.y - self.scrollY

        gc:setColorRGB(unpack(self.fontColor))
        gc:setFont("sansserif", "r", self.fontSize)
        gc:drawString(self.text, x, y)
    end

    self:drawBoundingRectangle(gc)
end

function Widget:drawBoundingRectangle( gc )
    if self.boundingRectangle then
        gc:setPen("thin", "smooth")
        gc:setColorRGB(unpack(self.boundingRectangleColor))
        gc:drawRect(self.x, self.y - self.scrollY, self.w, self.h)
    end
end

function Widget:setInitSizeAndPosition(w, h, pctx, pcty) 
    self.initWidth = w; self.initHeight = h; self.initPctX = pctx; self.initPctY = pcty
    self.nonScaledWidth = self.initWidth; self.nonScaledHeight = self.initHeight
    self.pctx = self.initPctX; self.pcty = self.initPctY 
end

function Widget:setPane(panex, paney, panew, paneh, scaleFactor)
    self.panex = panex; self.paney = paney; self.panew = panew; self.paneh = paneh; self.scaleFactor = scaleFactor
end

function Widget:setSize(w, h)
    self:invalidate()

    self.nonScaledWidth = w; self.nonScaledHeight = h;
    self.w = self.nonScaledWidth * self.scaleFactor; self.h = self.nonScaledHeight * self.scaleFactor
    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    self.fontSize = self.stringTools:scaleFont(self.initFontSize, self.scaleFactor)

    self:invalidate()
end

function Widget:setPosition(pctx, pcty)
    self:invalidate()

    self.pctx = pctx; self.pcty = pcty
    self.x = self.panex + self.pctx*self.panew; self.y = self.paney + self.pcty*self.paneh;

    self:invalidate()
end

function Widget:invalidate()
    app.frame:setInvalidatedArea(self.x, self.y - self.scrollY, self.w, self.h)
end

function Widget:contains( x, y )
    local xExpanded = x - .5 * self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y - .5 * self.mouse_yheight

    local x_overlap = math.max(0, math.min(self.x+self.w, xExpanded + self.mouse_xwidth) - math.max(self.x, xExpanded))
    local y_overlap = math.max(0, math.min(self.paney+self.paneh, math.min(self.y+self.h-self.scrollY, yExpanded + self.mouse_yheight)) - math.max(self.paney, math.max(self.y-self.scrollY, yExpanded)))

    --If there is an intersecting rectangle, then this point is selected.
    if x_overlap * y_overlap > 0 then
        return 1
    end

    return 0
end

function Widget:calculateWidth( scaleFactor )
    return self.nonScaledWidth * scaleFactor
end

function Widget:calculateHeight( scaleFactor )
    return self.nonScaledHeight * scaleFactor
end

--Example: self.button1:modifyProperties( {active = true, visible = false} ) 
function Widget:modifyProperties(options)
    if options ~= nil then
        for i, v in pairs(options) do 
            if self.propertiesFunctions[i] ~= nil then self.propertiesFunctions[i](v)   --Call the function associated with this property.
            else self[i] = v
            end
        end
     end
end

--properties is a table containing the properties values that need to be changed
function Widget:modifyChildProperties(childName, properties)
    for i,v in pairs(self.children) do
        if v.name == childName then
            v:modifyProperties(properties)
        end
    end
end

function Widget:setInitFontAttributes(fontFamily, fontStyle, fontSize)
    self:invalidate()
    self.initFontFamily = fontFamily
    self.initFontStyle = fontStyle
    self.initFontSize = fontSize
    self:invalidate()
end

--b = true to set object visible, b = false to hide object.
function Widget:setVisible(b)
    self:invalidate()
    self.visible = b
end

function Widget:setActive(b)        
    self.active = b     
            
    if self.shouldHover == true then        
        if b == false then      
            self:UIMgrListener( app.model.events.EVENT_MOUSE_OUT )   --remove the hover color from the widget when the widget gets inactive       
        end     
    end     
end

function Widget:setFocus(b)
    self:invalidate()
    self.hasFocus = b
end

function Widget:setScrollY(y)
    self.scrollY = y
end

function Widget:setFontColor(color)
    self.fontColor = color
    self:invalidate()
end

function Widget:mouseDown( x, y )
    local retVal = false

    if self.active == true and self.visible == true then
        local b = self:contains(x, y)
        
        if b == 1 then
            self.tracking = true
            
            if self.hasGrab == true then 
                self.xGrabOffset = x - self.x + self.panex
                self.yGrabOffset = y - self.y + self.paney
            end
            
            self:notifyListeners(app.model.events.EVENT_MOUSE_DOWN, self, x, y)     --Listeners for this event are only notified if this object was under the mouse during mouseDown.

            retVal = true   --Event handled.
        end
    end
        
    return retVal, self   --Return whether the event was handled.    
end

function Widget:mouseUp(x, y)
    self.tracking = false
    self:notifyListeners(app.model.events.EVENT_MOUSE_UP, self, x, y)
    return true, self
end

function Widget:addListener( listener )
    local listenerID = #self.listeners + 1
    self.listeners[listenerID] = {}
    self.listeners[listenerID][1] = listener
    
    return listenerID
end

function Widget:removeListener( listenerID )
    self.listeners[listenerID] = {}
end

function Widget:notifyListeners( event, ... )
    for i=1, #self.listeners do
        if self.listeners[i][1] then
            self.listeners[i][1]( event, ... )
        end
    end
end

function Widget:UIMgrListener( event, x, y )
    if event == app.model.events.EVENT_MOUSE_MOVE then
        return self:mouseMove( x, y )
    elseif event == app.model.events.EVENT_MOUSE_OUT then    --mouse pointer is out of bounds
        return self:mouseOutHandler()
    elseif event == app.model.events.EVENT_MOUSE_OVER then   --mouse pointer is inside widget bounds
        return self:mouseOverHandler( x, y ) 
    elseif event == app.model.events.EVENT_MOUSE_DOWN then
        return self:mouseDown( x, y )
    elseif event == app.model.events.EVENT_MOUSE_UP then
        return self:mouseUp( x, y )
    end
end

function Widget:mouseMove( x, y )
    if self.visible == false or self.active == false then
        return false, nil      --mouse move events should not be handled when the widget is not visible or not active
    end
    
    if self.hasGrab == true and self.tracking == true then
      self:setPosition((x - self.xGrabOffset)/self.panew, (y - self.yGrabOffset)/self.paneh)
    end

    --returns true if mouse pointer is inside the widget bounding box; otherwise, false
    if self:contains(x, y) == 1 then
        self:notifyListeners(app.model.events.EVENT_MOUSE_MOVE, self, x, y)     --Listeners for this event are only notified if this object was under the mouse during mouseDown.
        return true, self
    else
        return false, self
    end
end

--change the button back to original color
function Widget:mouseOutHandler()
    if self.shouldHover == true and self.tracking ~= true then    --widget is not pressed
        local color = self.initFillColor 
        
        if (self.initFillColor and color[1] ~= self.fillColor[1] and color[2] ~= self.fillColor[2] and color[3] ~= self.fillColor[3]) or (color == nil and self.fillColor ~= nil) then
            self.fillColor = color
            self:invalidate()
        end
    end
end

--change the button color to hover color
function Widget:mouseOverHandler(x, y)
    if self.shouldHover == true and self.tracking ~= true then    --widget is not pressed
        local color = self.mouseHoverColor
        
        if (self.fillColor and color[1] ~= self.fillColor[1] and color[2] ~= self.fillColor[2] and color[3] ~= self.fillColor[3]) or self.fillColor == nil then
            self.fillColor = color
            self:invalidate()
        end
    end
end

function Widget:grabUp(x, y)
    if self.active == true and self.visible == true then 
        if self.hasGrab == true then
            if self:contains(x, y) > 1 then
                self.mouseGrabbed = true        --User has now pressed and released the mouse grab, so now the item is locked.  Set this to false upon any keyboard or mouse up/down event.
                return true
            end
        end
    end
        
    return false
end

function Widget:releaseGrab() 
    self.mouseGrabbed = false        
    self.tracking = false
end

function Widget:charIn(char) end
function Widget:backspaceKey() end
function Widget:arrowLeft() end
function Widget:arrowRight() end
function Widget:arrowUp() end
function Widget:arrowDown() end
function Widget:grabDown(x, y) end
function Widget:cut() end
function Widget:copy() end
function Widget:paste() end
function Widget:shiftArrowRight() end
function Widget:shiftArrowLeft() end
function Widget:homeKey() end
function Widget:endKey() end
function Widget:enterKey() end

function Widget:handleTimer() end
function Widget:calculateChildPositions(pctx, pcty) end

--------------------------------------------------------------
WidgetMgr = class()

function WidgetMgr:init()
  self.mouseDown = false
  self.mouseDownObject = nil
  self.widgetList = {}
  self.widgetTypes = {}
end

function WidgetMgr:register(name, newFunction) 
  self.widgetTypes[name] = newFunction
end

--Call this only after widget has been created.
function WidgetMgr:newWidget(widgetType, widget, ...)
    local widget = self.widgetTypes[widgetType](widget, ...)   --Excecute the new function
    
    return widget
end

--Adds a widget to the WidgetMgr so that the WidgetMgr is aware of it.  Widget must already exist as an object.
function WidgetMgr:addWidget(widget, options)
    assert(widget.name, "Invalid widget: "..tostring(widget.name))
    if options ~= nil then widget:modifyProperties(options) end
    self.widgetList[widget.name] = widget
end

function WidgetMgr:handleTimer()
  for i, v in pairs(self.widgetList) do
    v:handleTimer() 
  end
end

----------------------------------------------
GraphicsUtilities = class()

function GraphicsUtilities:init()
  self.Color = {
    black = {0x00, 0x00, 0x00},
    white = {0xFF, 0xFF, 0xFF},
    red = {0xFF, 0x00, 0x00},
    green = {0x00, 0xFF, 0x00},
    blue = {0x00, 0x00, 0xFF},
    blue2 =  {0x7D, 0x9E, 0xC0},
    red2 = {0xCD, 0x55, 0x55},
    pink = {255, 228, 225},
    yellow = {0xCC, 0xCC, 0},
    lightpurple = {0xE3, 0xCF, 0xFC},
    pastelyellow = {247, 247, 126},
    silvergrey = {227, 226, 218},
    whitegrey = {242, 242, 235},
    darkgrey = {200, 200, 200},
    darkblue = {55, 24, 214},
    pastelgreen = {203, 242, 206},
    pastelblue = {195, 244, 250},
    grey = {91, 91, 91},
    verydarkgrey = {31, 31, 31},
    tooltipgreen = {0x04, 0x78, 0x2E},   --brighter {0x07, 0xAD, 0x44}
    yellowish = { 255, 255, 153 },
    orangeish = { 255, 153, 51 },
    redish = { 255, 51, 51 },
    turquoise = { 56,114,113 },
    orange = {255, 165, 0},
    cyanish = { 0, 139, 169 },
    cyanish2 = { 0, 153, 153 },
    purpleish = { 204, 153, 255 },
    thistle ={216,191,216},
    maizeyellow = {0xFB, 0xEC, 0x5D},
    babyblue =  {0x7D, 0x9E, 0xC0},
    brightyellow = {0xFF, 0xFF, 0},
    purple = { 204, 0, 204 },
    harvestgold = { 230, 153, 0 },
    trueblue = { 0,102,204 }
   }
   
   self.figureTypeIDs = app.enum({ "RIGHT_ARROW", "LEFT_ARROW", "DOWN_ARROW", "UP_ARROW", "CHECK_MARK", "TICK_MARK", 
                        "SMALL_RIGHT_ARROW", "SMALL_LEFT_ARROW", "SMALL_DOWN_ARROW", "SMALL_UP_ARROW" })
   self.tickmarks = {
        [self.figureTypeIDs.RIGHT_ARROW] = {0,0, 2,2, 0,4, 0,0},
        [self.figureTypeIDs.LEFT_ARROW] = {2,0, 2,4, 0,2, 2,0}, 
        [self.figureTypeIDs.DOWN_ARROW] = {-2,0, 0,2, 0,2, 2,0},
        [self.figureTypeIDs.UP_ARROW] = {-2,2, 0,0, 0,0, 2,2},
        [self.figureTypeIDs.CHECK_MARK] = {0,4,2,6,7,1,6,0,2,4,1,3,0,4},
        [self.figureTypeIDs.TICK_MARK] = {0,1,2,3,0,5,1,6,3,4,5,6,6,5,4,3,6,1,5,0,3,2,1,0,0,1},
        [self.figureTypeIDs.SMALL_RIGHT_ARROW] = {0,0, 2,1, 0,2, 0,0},    
        [self.figureTypeIDs.SMALL_LEFT_ARROW] = {2,0, 2,2, 0,1, 2,0}, 
        [self.figureTypeIDs.SMALL_DOWN_ARROW] = {-1,0, 0,2, 0,2, 1,0},    
        [self.figureTypeIDs.SMALL_UP_ARROW] = {-1,2, 0,0, 0,0, 1,2},
   }
       
    self.drawStyles = app.enum({ "FILL_AND_OUTLINE", "FILL_ONLY", "OUTLINE_ONLY" })
end

function GraphicsUtilities:getColor(c)
  return self.Color(c)
end

-- style can be: "FILL_AND_OUTLINE", "FILL_ONLY", "OUTLINE_ONLY"; see self.drawStyles
-- figureType can be: "RIGHT_ARROW", "LEFT_ARROW", "DOWN_ARROW", "UP_ARROW", "CHECK_MARK", "TICK_MARK"; see self.figureTypeIDs
function GraphicsUtilities:drawFigure(figureType, gc, x, y, scale, color, style)
    if color == nil then color = self.Color.black end
    if style == nil then style = self.drawStyles.FILL_AND_OUTLINE end
    local tickmark, tickmarks = {}, {}

    gc:setColorRGB(unpack(color))
    gc:setPen("thin", "smooth")
  
    tickmarks = self.tickmarks[figureType]
  
    for i=1,table.getn(tickmarks) do
        tickmark[i]= scale * tickmarks[i]
        
        if math.floor(i/2)==i/2 then
            tickmark[i]=tickmark[i]+y
        else
            tickmark[i]=tickmark[i]+x
        end
    end

    if style == self.drawStyles.FILL_AND_OUTLINE or style == self.drawStyles.FILL_ONLY then
        gc:fillPolygon(tickmark)
    end
    
    if style == self.drawStyles.FILL_AND_OUTLINE or style == self.drawStyles.OUTLINE_ONLY then
        gc:setColorRGB(0,0,0)
        gc:drawPolyLine(tickmark)
    end
end

function GraphicsUtilities:addDebugRectangles(x, y, w, h, r, g, b, gc )
  if app.SHOULD_DRAW_DEBUG_RECT then
    gc:setColorRGB( r, g, b )
    gc:setPen( "medium", "smooth" )
    gc:drawRect( x, y, w, h )

    -- reset
    gc:setColorRGB( 0, 0, 0 )
    gc:setPen( "thin", "smooth" )
  end
end

function GraphicsUtilities:addDebugLine( x1, y1, x2, y2, r, g, b, gc )
  if app.SHOULD_DRAW_DEBUG_RECT then
    gc:setColorRGB( r, g, b )
    gc:setPen( "medium", "smooth" )
    gc:drawLine( x1, y1, x2, y2 )

    -- reset
    gc:setColorRGB( 0, 0, 0 )
    gc:setPen( "thin", "smooth" )
  end
end

function GraphicsUtilities:getRandomHexColor()
  local s = "0x"

  local charPool = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", }

  for a = 1, 6 do s = s..charPool[ math.random( 1, #charPool ) ] end

  return s
end

function GraphicsUtilities:getRandomRGBColor()
  return { math.random( 0, 255 ), math.random( 0, 255 ), math.random( 0, 255 ) }
end

---------------------------------------------------------
Utilities = class()

function Utilities:init()
end

function Utilities:queueAdd( tbl, d )
    table.insert(tbl, d)
end

function Utilities:queueRemove( tbl )
    d = table.remove( tbl, 1 )
    return d
end

function Utilities:push( tbl, d )
  table.insert( tbl, d )
end

function Utilities:pop( tbl )
  local d = tbl[#tbl]
  table.remove( tbl )
  return d
end

function Utilities:printTableAsLine( tbl )
    local str = ""
    for a = 1, #tbl do
        str = str .. tostring( tbl[a] )
    end
end

function Utilities:printCurrentMilliSecCounterWithCaption( caption )
    print( caption, timer.getMilliSecCounter())
end

function Utilities:joinTwoTables( t1, t2 )
    for k, v in ipairs( t2 ) do
        table.insert( t1, v )
    end
    
    return t1
end

-- single char to an object in a table
function Utilities:strToTable( str )
    local tbl = {}
    
    for a = 1, #str do
        if str:usub( a, a ) == "" then
            break
        end
        tbl[#tbl+1] = str:usub( a, a )
        
    end
    return tbl
end

-- obj1 and obj 2 are objects 
-- area extension would mean additional pixels for the area. {{{ obj1's xleft, xright }, { obj1's yleft, yright }}, {{ obj2's xleft, xright }, { obj2's yleft, yright }}}
function  Utilities:getAreaCovered( obj1, obj2, areaExtension )
    local hasAreaExtension = areaExtension ~= nil
    local areaExtensionObj1, areaExtensionObj2 = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
    
    if hasAreaExtension then
        if areaExtension[ 1 ] then
            if areaExtension[ 1 ][ 1 ] then
                if tonumber( areaExtension[ 1 ][ 1 ][ 1 ]) then areaExtensionObj1[ 1 ] = tonumber( areaExtension[ 1 ][ 1 ][ 1 ]) end
                if tonumber( areaExtension[ 1 ][ 1 ][ 2 ]) then areaExtensionObj1[ 2 ] = tonumber( areaExtension[ 1 ][ 1 ][ 2 ]) end
            end
            
            if areaExtension[ 1 ][ 2 ] then
                if tonumber( areaExtension[ 1 ][ 2 ][ 1 ]) then areaExtensionObj1[ 3 ] = tonumber( areaExtension[ 1 ][ 2 ][ 1 ]) end
                if tonumber( areaExtension[ 1 ][ 2 ][ 2 ]) then areaExtensionObj1[ 4 ] = tonumber( areaExtension[ 1 ][ 2 ][ 2 ])end
            end
        end
        
        if areaExtension[ 2 ] then
            if areaExtension[ 2 ][ 1 ] then
                if tonumber( areaExtension[ 2 ][ 1 ][ 1 ]) then areaExtensionObj2[ 1 ] = tonumber( areaExtension[ 2 ][ 1 ][ 1 ]) end
                if tonumber( areaExtension[ 2 ][ 1 ][ 2 ]) then areaExtensionObj2[ 2 ] = tonumber( areaExtension[ 2 ][ 1 ][ 2 ]) end
            end
            
            if areaExtension[ 2 ][ 2 ] then
                if tonumber( areaExtension[ 2 ][ 2 ][ 1 ]) then areaExtensionObj2[ 3 ] = tonumber( areaExtension[ 2 ][ 2 ][ 1 ]) end
                if tonumber( areaExtension[ 2 ][ 2 ][ 2 ]) then areaExtensionObj2[ 4 ] = tonumber( areaExtension[ 2 ][ 2 ][ 2 ])end
            end
        end    
    end
    
    -- obj1
    local obj1sf = obj1.scaleFactor
    local obj1xmin = obj1.x - ( areaExtensionObj1[ 1 ] * obj1sf )
    local obj1xmax = obj1.x + obj1.w + ( areaExtensionObj1[ 2 ] * obj1sf )
    local obj1ymin = obj1.y - ( areaExtensionObj1[ 3 ] * obj1sf )
    local obj1ymax = obj1.y + obj1.h + ( areaExtensionObj1[ 4 ] * obj1sf )
    
    -- obj2
    local obj2sf = obj2.scaleFactor
    local obj2xmin = obj2.x - ( areaExtensionObj2[ 1 ] * obj2sf )
    local obj2xmax = obj2.x + obj2.w + ( areaExtensionObj2[ 2 ] * obj2sf )
    local obj2ymin = obj2.y - ( areaExtensionObj2[ 3 ] * obj2sf )
    local obj2ymax = obj2.y + obj2.h + ( areaExtensionObj2[ 4 ] * obj2sf )
    
    local dx = math.min( obj1xmax, obj2xmax ) - math.max( obj1xmin, obj2xmin )
    local dy = math.min( obj1ymax, obj2ymax ) - math.max( obj1ymin, obj2ymin )
    
    if (dx>=0) and (dy>=0) then return dx * dy 
    else return 0
    end
end

--set default value of table t(and its table elements) to value using metatable
function Utilities:setDefaultTableValue(t, value)
    local mt = {__index = function() return value end}
    setmetatable(t, mt)
    
    for i,v in pairs(t) do
        if type(v) == "table" then
            return self:setDefault(v, value)     --tail call
        end
    end
end

---------------------------------------------------------
StringTools = class()

function StringTools:init()
    self.fontWidth = {}
    self.fontWidth["serif"] = {
    	["r"] = {
    		["7"] = {
    			["a"] = 5, ["b"] = 5, ["c"] = 5, ["d"] = 5, ["e"] = 5, ["f"] = 3, ["g"] = 5, ["h"] = 5, ["i"] = 2, ["j"] = 2, ["k"] = 5, ["l"] = 3, ["m"] = 8, ["n"] = 5, ["o"] = 5, ["p"] = 5, ["q"] = 5, ["r"] = 3, ["s"] = 5, ["t"] = 3, ["u"] = 5, ["v"] = 5, ["w"] = 7, ["x"] = 5, ["y"] = 5, ["z"] = 5, ["A"] = 6, ["B"] = 6, ["C"] = 7, ["D"] = 7, ["E"] = 6, ["F"] = 6, ["G"] = 7, ["H"] = 7, ["I"] = 3, ["J"] = 5, ["K"] = 6, ["L"] = 5, ["M"] = 8, ["N"] = 7, ["O"] = 7, ["P"] = 6, ["Q"] = 7, ["R"] = 7, ["S"] = 6, ["T"] = 6, ["U"] = 7, ["V"] = 6, ["W"] = 9, ["X"] = 6, ["Y"] = 6, ["Z"] = 6, ["1"] = 5, ["2"] = 5, ["3"] = 5, ["4"] = 5, ["5"] = 5, ["6"] = 5, ["7"] = 5, ["8"] = 5, ["9"] = 5, ["0"] = 5, ["`"] = 3, ["~"] = 5, ["!"] = 3, ["@"] = 9, ["#"] = 5, ["$"] = 5, ["%"] = 8, ["^"] = 4, ["&"] = 6, ["*"] = 4, ["("] = 3, [")"] = 3, ["-"] = 5, ["_"] = 5, ["+"] = 5, ["="] = 5, ["{"] = 3, ["["] = 3, ["]"] = 3, ["}"] = 3, ["|"] = 2, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 3, ["'"] = 2, ["<"] = 5, [">"] = 5, [","] = 3, ["."] = 3, ["?"] = 5, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 6, [string.uchar(0x21D5)] = 7, [string.uchar(0x21D5)] = 7, [app.charBackspaceArrow] = 9, [app.charDegree] = 4, [app.div_sign] = 5, [app.charSuperscript_3] = 3, [app.charSuperscript_2] = 3, [app.checkMark] = 7, [app.charDownArrow] = 9, [app.filledTriangle] = 9, ["◀"] = 6, [app.multiplicationSymbol] = 5, [app.filledCircle] = 5, [app.filledTriangle] = 9, [app.filledSquare] = 5, [app.filledDiamond] = 5, [app.emptyCircle] = 7, [app.emptyTriangle] = 9, [app.emptySquare] = 7, [app.emptyDiamond] = 7, 
    		},
    		["9"] = {
    			["a"] = 5, ["b"] = 6, ["c"] = 5, ["d"] = 6, ["e"] = 5, ["f"] = 4, ["g"] = 6, ["h"] = 6, ["i"] = 3, ["j"] = 3, ["k"] = 6, ["l"] = 3, ["m"] = 9, ["n"] = 6, ["o"] = 6, ["p"] = 6, ["q"] = 6, ["r"] = 4, ["s"] = 5, ["t"] = 3, ["u"] = 6, ["v"] = 6, ["w"] = 9, ["x"] = 6, ["y"] = 6, ["z"] = 5, ["A"] = 9, ["B"] = 8, ["C"] = 8, ["D"] = 9, ["E"] = 7, ["F"] = 7, ["G"] = 9, ["H"] = 9, ["I"] = 4, ["J"] = 5, ["K"] = 9, ["L"] = 7, ["M"] = 11, ["N"] = 9, ["O"] = 9, ["P"] = 7, ["Q"] = 9, ["R"] = 8, ["S"] = 7, ["T"] = 7, ["U"] = 9, ["V"] = 9, ["W"] = 11, ["X"] = 9, ["Y"] = 9, ["Z"] = 7, ["1"] = 6, ["2"] = 6, ["3"] = 6, ["4"] = 6, ["5"] = 6, ["6"] = 6, ["7"] = 6, ["8"] = 6, ["9"] = 6, ["0"] = 6, ["`"] = 4, ["~"] = 7, ["!"] = 4, ["@"] = 11, ["#"] = 6, ["$"] = 6, ["%"] = 10, ["^"] = 6, ["&"] = 9, ["*"] = 6, ["("] = 4, [")"] = 4, ["-"] = 7, ["_"] = 6, ["+"] = 7, ["="] = 7, ["{"] = 6, ["["] = 5, ["]"] = 5, ["}"] = 6, ["|"] = 2, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 5, ["'"] = 2, ["<"] = 7, [">"] = 7, [","] = 3, ["."] = 4, ["?"] = 5, ["/"] = 3, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 9, [string.uchar(0x21D5)] = 9, [app.charBackspaceArrow] = 12, [app.charDegree] = 5, [app.div_sign] = 7, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 9, [app.charDownArrow] = 12, [app.filledTriangle] = 12, ["◀"] = 8, [app.multiplicationSymbol] = 4, [app.filledCircle] = 7, [app.filledTriangle] = 12, [app.filledSquare] = 7, [app.filledDiamond] = 7, [app.emptyCircle] = 9, [app.emptyTriangle] = 12, [app.emptySquare] = 9, [app.emptyDiamond] = 9, 
    		},
    		["10"] = {
    			["a"] = 6, ["b"] = 7, ["c"] = 6, ["d"] = 7, ["e"] = 6, ["f"] = 4, ["g"] = 7, ["h"] = 7, ["i"] = 4, ["j"] = 4, ["k"] = 7, ["l"] = 4, ["m"] = 10, ["n"] = 7, ["o"] = 7, ["p"] = 7, ["q"] = 7, ["r"] = 4, ["s"] = 5, ["t"] = 4, ["u"] = 7, ["v"] = 7, ["w"] = 9, ["x"] = 7, ["y"] = 7, ["z"] = 6, ["A"] = 9, ["B"] = 9, ["C"] = 9, ["D"] = 9, ["E"] = 8, ["F"] = 7, ["G"] = 9, ["H"] = 9, ["I"] = 4, ["J"] = 5, ["K"] = 9, ["L"] = 8, ["M"] = 12, ["N"] = 9, ["O"] = 9, ["P"] = 7, ["Q"] = 9, ["R"] = 9, ["S"] = 7, ["T"] = 8, ["U"] = 9, ["V"] = 9, ["W"] = 12, ["X"] = 9, ["Y"] = 9, ["Z"] = 8, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 7, ["!"] = 4, ["@"] = 12, ["#"] = 7, ["$"] = 7, ["%"] = 11, ["^"] = 6, ["&"] = 10, ["*"] = 7, ["("] = 4, [")"] = 4, ["-"] = 8, ["_"] = 7, ["+"] = 8, ["="] = 8, ["{"] = 6, ["["] = 5, ["]"] = 5, ["}"] = 6, ["|"] = 3, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 5, ["'"] = 2, ["<"] = 8, [">"] = 8, [","] = 3, ["."] = 5, ["?"] = 6, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 10, [string.uchar(0x21D5)] = 10, [app.charBackspaceArrow] = 13, [app.charDegree] = 5, [app.div_sign] = 8, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 10, [app.charDownArrow] = 13, [app.filledTriangle] = 13, ["◀"] = 8, [app.multiplicationSymbol] = 5, [app.filledCircle] = 8, [app.filledTriangle] = 13, [app.filledSquare] = 8, [app.filledDiamond] = 8, [app.emptyCircle] = 10, [app.emptyTriangle] = 13, [app.emptySquare] = 10, [app.emptyDiamond] = 10, 
    		},
    		["11"] = {
    			["a"] = 7, ["b"] = 8, ["c"] = 7, ["d"] = 8, ["e"] = 7, ["f"] = 5, ["g"] = 8, ["h"] = 8, ["i"] = 4, ["j"] = 4, ["k"] = 8, ["l"] = 4, ["m"] = 12, ["n"] = 8, ["o"] = 8, ["p"] = 8, ["q"] = 8, ["r"] = 5, ["s"] = 6, ["t"] = 4, ["u"] = 8, ["v"] = 8, ["w"] = 11, ["x"] = 8, ["y"] = 8, ["z"] = 7, ["A"] = 11, ["B"] = 10, ["C"] = 10, ["D"] = 11, ["E"] = 9, ["F"] = 8, ["G"] = 11, ["H"] = 11, ["I"] = 5, ["J"] = 6, ["K"] = 11, ["L"] = 9, ["M"] = 13, ["N"] = 11, ["O"] = 11, ["P"] = 8, ["Q"] = 11, ["R"] = 10, ["S"] = 8, ["T"] = 9, ["U"] = 11, ["V"] = 11, ["W"] = 14, ["X"] = 11, ["Y"] = 11, ["Z"] = 9, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 8, ["!"] = 5, ["@"] = 14, ["#"] = 8, ["$"] = 8, ["%"] = 13, ["^"] = 7, ["&"] = 12, ["*"] = 8, ["("] = 5, [")"] = 5, ["-"] = 9, ["_"] = 8, ["+"] = 9, ["="] = 9, ["{"] = 7, ["["] = 6, ["]"] = 6, ["}"] = 7, ["|"] = 3, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 6, ["'"] = 3, ["<"] = 9, [">"] = 9, [","] = 4, ["."] = 5, ["?"] = 7, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 15, [app.charDegree] = 6, [app.div_sign] = 9, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 11, [app.charDownArrow] = 15, [app.filledTriangle] = 15, ["◀"] = 10, [app.multiplicationSymbol] = 5, [app.filledCircle] = 9, [app.filledTriangle] = 15, [app.filledSquare] = 9, [app.filledDiamond] = 9, [app.emptyCircle] = 12, [app.emptyTriangle] = 15, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["12"] = {
    			["a"] = 7, ["b"] = 8, ["c"] = 7, ["d"] = 8, ["e"] = 7, ["f"] = 5, ["g"] = 8, ["h"] = 8, ["i"] = 4, ["j"] = 4, ["k"] = 8, ["l"] = 4, ["m"] = 12, ["n"] = 8, ["o"] = 8, ["p"] = 8, ["q"] = 8, ["r"] = 5, ["s"] = 6, ["t"] = 4, ["u"] = 8, ["v"] = 8, ["w"] = 12, ["x"] = 8, ["y"] = 8, ["z"] = 7, ["A"] = 12, ["B"] = 11, ["C"] = 11, ["D"] = 12, ["E"] = 10, ["F"] = 9, ["G"] = 12, ["H"] = 12, ["I"] = 5, ["J"] = 6, ["K"] = 12, ["L"] = 10, ["M"] = 14, ["N"] = 12, ["O"] = 12, ["P"] = 9, ["Q"] = 12, ["R"] = 11, ["S"] = 9, ["T"] = 10, ["U"] = 12, ["V"] = 12, ["W"] = 15, ["X"] = 12, ["Y"] = 12, ["Z"] = 10, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 9, ["!"] = 5, ["@"] = 15, ["#"] = 8, ["$"] = 8, ["%"] = 13, ["^"] = 8, ["&"] = 12, ["*"] = 8, ["("] = 5, [")"] = 5, ["-"] = 10, ["_"] = 8, ["+"] = 10, ["="] = 10, ["{"] = 8, ["["] = 6, ["]"] = 6, ["}"] = 8, ["|"] = 3, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 7, ["'"] = 3, ["<"] = 10, [">"] = 10, [","] = 4, ["."] = 6, ["?"] = 7, ["/"] = 4, [" "] = 5, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 16, [app.charDegree] = 6, [app.div_sign] = 10, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 12, [app.charDownArrow] = 16, [app.filledTriangle] = 16, ["◀"] = 10, [app.multiplicationSymbol] = 6, [app.filledCircle] = 10, [app.filledTriangle] = 16, [app.filledSquare] = 10, [app.filledDiamond] = 10, [app.emptyCircle] = 12, [app.emptyTriangle] = 16, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["13"] = {
    			["a"] = 9, ["b"] = 11, ["c"] = 9, ["d"] = 11, ["e"] = 9, ["f"] = 7, ["g"] = 11, ["h"] = 11, ["i"] = 6, ["j"] = 6, ["k"] = 11, ["l"] = 6, ["m"] = 16, ["n"] = 11, ["o"] = 11, ["p"] = 11, ["q"] = 11, ["r"] = 7, ["s"] = 8, ["t"] = 6, ["u"] = 11, ["v"] = 11, ["w"] = 15, ["x"] = 11, ["y"] = 11, ["z"] = 9, ["A"] = 15, ["B"] = 14, ["C"] = 14, ["D"] = 15, ["E"] = 13, ["F"] = 12, ["G"] = 15, ["H"] = 15, ["I"] = 7, ["J"] = 8, ["K"] = 15, ["L"] = 13, ["M"] = 19, ["N"] = 15, ["O"] = 15, ["P"] = 12, ["Q"] = 15, ["R"] = 14, ["S"] = 12, ["T"] = 13, ["U"] = 15, ["V"] = 15, ["W"] = 20, ["X"] = 15, ["Y"] = 15, ["Z"] = 13, ["1"] = 11, ["2"] = 11, ["3"] = 11, ["4"] = 11, ["5"] = 11, ["6"] = 11, ["7"] = 11, ["8"] = 11, ["9"] = 11, ["0"] = 11, ["`"] = 7, ["~"] = 11, ["!"] = 7, ["@"] = 19, ["#"] = 11, ["$"] = 11, ["%"] = 18, ["^"] = 10, ["&"] = 16, ["*"] = 11, ["("] = 7, [")"] = 7, ["-"] = 13, ["_"] = 11, ["+"] = 13, ["="] = 13, ["{"] = 10, ["["] = 8, ["]"] = 8, ["}"] = 10, ["|"] = 4, ["\\"] = 6, [":"] = 6, [";"] = 6, ["\""] = 9, ["'"] = 4, ["<"] = 13, [">"] = 13, [","] = 5, ["."] = 8, ["?"] = 9, ["/"] = 6, [" "] = 6, [app.charRightArrow] = 13, [string.uchar(0x21D5)] = 16, [string.uchar(0x21D5)] = 16, [app.charBackspaceArrow] = 21, [app.charDegree] = 8, [app.div_sign] = 13, [app.charSuperscript_3] = 6, [app.charSuperscript_2] = 6, [app.checkMark] = 16, [app.charDownArrow] = 21, [app.filledTriangle] = 21, ["◀"] = 13, [app.multiplicationSymbol] = 7, [app.filledCircle] = 13, [app.filledTriangle] = 21, [app.filledSquare] = 13, [app.filledDiamond] = 13, [app.emptyCircle] = 16, [app.emptyTriangle] = 21, [app.emptySquare] = 16, [app.emptyDiamond] = 16, 
    		},
    		["24"] = {
    			["a"] = 14, ["b"] = 16, ["c"] = 14, ["d"] = 16, ["e"] = 14, ["f"] = 11, ["g"] = 16, ["h"] = 16, ["i"] = 9, ["j"] = 9, ["k"] = 16, ["l"] = 9, ["m"] = 25, ["n"] = 16, ["o"] = 16, ["p"] = 16, ["q"] = 16, ["r"] = 11, ["s"] = 12, ["t"] = 9, ["u"] = 16, ["v"] = 16, ["w"] = 23, ["x"] = 16, ["y"] = 16, ["z"] = 14, ["A"] = 23, ["B"] = 21, ["C"] = 21, ["D"] = 23, ["E"] = 20, ["F"] = 18, ["G"] = 23, ["H"] = 23, ["I"] = 11, ["J"] = 12, ["K"] = 23, ["L"] = 20, ["M"] = 28, ["N"] = 23, ["O"] = 23, ["P"] = 18, ["Q"] = 23, ["R"] = 21, ["S"] = 18, ["T"] = 20, ["U"] = 23, ["V"] = 23, ["W"] = 30, ["X"] = 23, ["Y"] = 23, ["Z"] = 20, ["1"] = 16, ["2"] = 16, ["3"] = 16, ["4"] = 16, ["5"] = 16, ["6"] = 16, ["7"] = 16, ["8"] = 16, ["9"] = 16, ["0"] = 16, ["`"] = 11, ["~"] = 17, ["!"] = 11, ["@"] = 29, ["#"] = 16, ["$"] = 16, ["%"] = 27, ["^"] = 15, ["&"] = 25, ["*"] = 16, ["("] = 11, [")"] = 11, ["-"] = 19, ["_"] = 16, ["+"] = 19, ["="] = 19, ["{"] = 15, ["["] = 12, ["]"] = 12, ["}"] = 15, ["|"] = 6, ["\\"] = 9, [":"] = 9, [";"] = 9, ["\""] = 13, ["'"] = 6, ["<"] = 19, [">"] = 19, [","] = 8, ["."] = 12, ["?"] = 14, ["/"] = 9, [" "] = 9, [app.charRightArrow] = 20, [string.uchar(0x21D5)] = 25, [string.uchar(0x21D5)] = 25, [app.charBackspaceArrow] = 32, [app.charDegree] = 13, [app.div_sign] = 19, [app.charSuperscript_3] = 10, [app.charSuperscript_2] = 10, [app.checkMark] = 24, [app.charDownArrow] = 32, [app.filledTriangle] = 32, ["◀"] = 20, [app.multiplicationSymbol] = 11, [app.filledCircle] = 19, [app.filledTriangle] = 32, [app.filledSquare] = 19, [app.filledDiamond] = 19, [app.emptyCircle] = 25, [app.emptyTriangle] = 32, [app.emptySquare] = 25, [app.emptyDiamond] = 25, 
    		},
    	},
    	["b"] = {
    		["7"] = {
    			["a"] = 5, ["b"] = 5, ["c"] = 5, ["d"] = 5, ["e"] = 5, ["f"] = 3, ["g"] = 5, ["h"] = 5, ["i"] = 2, ["j"] = 2, ["k"] = 5, ["l"] = 3, ["m"] = 8, ["n"] = 5, ["o"] = 5, ["p"] = 5, ["q"] = 5, ["r"] = 3, ["s"] = 5, ["t"] = 3, ["u"] = 5, ["v"] = 5, ["w"] = 7, ["x"] = 5, ["y"] = 5, ["z"] = 5, ["A"] = 6, ["B"] = 6, ["C"] = 7, ["D"] = 7, ["E"] = 6, ["F"] = 6, ["G"] = 7, ["H"] = 7, ["I"] = 3, ["J"] = 5, ["K"] = 6, ["L"] = 5, ["M"] = 8, ["N"] = 7, ["O"] = 7, ["P"] = 6, ["Q"] = 7, ["R"] = 7, ["S"] = 6, ["T"] = 6, ["U"] = 7, ["V"] = 6, ["W"] = 9, ["X"] = 6, ["Y"] = 6, ["Z"] = 6, ["1"] = 5, ["2"] = 5, ["3"] = 5, ["4"] = 5, ["5"] = 5, ["6"] = 5, ["7"] = 5, ["8"] = 5, ["9"] = 5, ["0"] = 5, ["`"] = 3, ["~"] = 5, ["!"] = 3, ["@"] = 9, ["#"] = 5, ["$"] = 5, ["%"] = 8, ["^"] = 4, ["&"] = 6, ["*"] = 4, ["("] = 3, [")"] = 3, ["-"] = 5, ["_"] = 5, ["+"] = 5, ["="] = 5, ["{"] = 3, ["["] = 3, ["]"] = 3, ["}"] = 3, ["|"] = 2, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 3, ["'"] = 2, ["<"] = 5, [">"] = 5, [","] = 3, ["."] = 3, ["?"] = 5, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 6, [string.uchar(0x21D5)] = 7, [string.uchar(0x21D5)] = 7, [app.charBackspaceArrow] = 9, [app.charDegree] = 4, [app.div_sign] = 5, [app.charSuperscript_3] = 3, [app.charSuperscript_2] = 3, [app.checkMark] = 7, [app.charDownArrow] = 9, [app.filledTriangle] = 9, ["◀"] = 6, [app.multiplicationSymbol] = 5, [app.filledCircle] = 5, [app.filledTriangle] = 9, [app.filledSquare] = 5, [app.filledDiamond] = 5, [app.emptyCircle] = 7, [app.emptyTriangle] = 9, [app.emptySquare] = 7, [app.emptyDiamond] = 7, 
    		},
    		["9"] = {
    			["a"] = 6, ["b"] = 7, ["c"] = 5, ["d"] = 7, ["e"] = 5, ["f"] = 4, ["g"] = 6, ["h"] = 7, ["i"] = 3, ["j"] = 4, ["k"] = 7, ["l"] = 3, ["m"] = 10, ["n"] = 7, ["o"] = 6, ["p"] = 7, ["q"] = 7, ["r"] = 5, ["s"] = 5, ["t"] = 4, ["u"] = 7, ["v"] = 6, ["w"] = 9, ["x"] = 6, ["y"] = 6, ["z"] = 5, ["A"] = 9, ["B"] = 8, ["C"] = 9, ["D"] = 9, ["E"] = 8, ["F"] = 7, ["G"] = 9, ["H"] = 9, ["I"] = 5, ["J"] = 6, ["K"] = 9, ["L"] = 8, ["M"] = 11, ["N"] = 9, ["O"] = 9, ["P"] = 7, ["Q"] = 9, ["R"] = 9, ["S"] = 7, ["T"] = 8, ["U"] = 9, ["V"] = 9, ["W"] = 12, ["X"] = 9, ["Y"] = 9, ["Z"] = 8, ["1"] = 6, ["2"] = 6, ["3"] = 6, ["4"] = 6, ["5"] = 6, ["6"] = 6, ["7"] = 6, ["8"] = 6, ["9"] = 6, ["0"] = 6, ["`"] = 4, ["~"] = 6, ["!"] = 4, ["@"] = 11, ["#"] = 6, ["$"] = 6, ["%"] = 12, ["^"] = 7, ["&"] = 10, ["*"] = 6, ["("] = 4, [")"] = 4, ["-"] = 7, ["_"] = 6, ["+"] = 7, ["="] = 7, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 3, ["\\"] = 3, [":"] = 4, [";"] = 4, ["\""] = 7, ["'"] = 3, ["<"] = 7, [">"] = 7, [","] = 3, ["."] = 5, ["?"] = 6, ["/"] = 3, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 9, [string.uchar(0x21D5)] = 9, [app.charBackspaceArrow] = 12, [app.charDegree] = 5, [app.div_sign] = 7, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 9, [app.charDownArrow] = 12, [app.filledTriangle] = 12, ["◀"] = 8, [app.multiplicationSymbol] = 4, [app.filledCircle] = 7, [app.filledTriangle] = 12, [app.filledSquare] = 7, [app.filledDiamond] = 7, [app.emptyCircle] = 9, [app.emptyTriangle] = 12, [app.emptySquare] = 9, [app.emptyDiamond] = 9, 
    		},
    		["10"] = {
    			["a"] = 7, ["b"] = 7, ["c"] = 6, ["d"] = 7, ["e"] = 6, ["f"] = 4, ["g"] = 7, ["h"] = 7, ["i"] = 4, ["j"] = 4, ["k"] = 7, ["l"] = 4, ["m"] = 11, ["n"] = 7, ["o"] = 7, ["p"] = 7, ["q"] = 7, ["r"] = 6, ["s"] = 5, ["t"] = 4, ["u"] = 7, ["v"] = 7, ["w"] = 9, ["x"] = 7, ["y"] = 7, ["z"] = 6, ["A"] = 9, ["B"] = 9, ["C"] = 9, ["D"] = 9, ["E"] = 9, ["F"] = 8, ["G"] = 10, ["H"] = 10, ["I"] = 5, ["J"] = 7, ["K"] = 10, ["L"] = 9, ["M"] = 12, ["N"] = 9, ["O"] = 10, ["P"] = 8, ["Q"] = 10, ["R"] = 9, ["S"] = 7, ["T"] = 9, ["U"] = 9, ["V"] = 9, ["W"] = 13, ["X"] = 9, ["Y"] = 9, ["Z"] = 9, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 7, ["!"] = 4, ["@"] = 12, ["#"] = 7, ["$"] = 7, ["%"] = 13, ["^"] = 8, ["&"] = 11, ["*"] = 7, ["("] = 4, [")"] = 4, ["-"] = 8, ["_"] = 7, ["+"] = 8, ["="] = 8, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 3, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 7, ["'"] = 4, ["<"] = 8, [">"] = 8, [","] = 3, ["."] = 5, ["?"] = 7, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 10, [string.uchar(0x21D5)] = 10, [app.charBackspaceArrow] = 13, [app.charDegree] = 5, [app.div_sign] = 8, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 10, [app.charDownArrow] = 13, [app.filledTriangle] = 13, ["◀"] = 8, [app.multiplicationSymbol] = 5, [app.filledCircle] = 8, [app.filledTriangle] = 13, [app.filledSquare] = 8, [app.filledDiamond] = 8, [app.emptyCircle] = 10, [app.emptyTriangle] = 13, [app.emptySquare] = 10, [app.emptyDiamond] = 10, 
    		},
    		["11"] = {
    			["a"] = 8, ["b"] = 8, ["c"] = 7, ["d"] = 8, ["e"] = 7, ["f"] = 5, ["g"] = 8, ["h"] = 8, ["i"] = 4, ["j"] = 5, ["k"] = 8, ["l"] = 4, ["m"] = 13, ["n"] = 8, ["o"] = 8, ["p"] = 8, ["q"] = 8, ["r"] = 7, ["s"] = 6, ["t"] = 5, ["u"] = 8, ["v"] = 8, ["w"] = 11, ["x"] = 8, ["y"] = 8, ["z"] = 7, ["A"] = 11, ["B"] = 10, ["C"] = 11, ["D"] = 11, ["E"] = 10, ["F"] = 9, ["G"] = 12, ["H"] = 12, ["I"] = 6, ["J"] = 8, ["K"] = 12, ["L"] = 10, ["M"] = 14, ["N"] = 11, ["O"] = 12, ["P"] = 9, ["Q"] = 12, ["R"] = 11, ["S"] = 8, ["T"] = 10, ["U"] = 11, ["V"] = 11, ["W"] = 15, ["X"] = 11, ["Y"] = 11, ["Z"] = 10, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 8, ["!"] = 5, ["@"] = 14, ["#"] = 8, ["$"] = 8, ["%"] = 15, ["^"] = 9, ["&"] = 13, ["*"] = 8, ["("] = 5, [")"] = 5, ["-"] = 9, ["_"] = 8, ["+"] = 9, ["="] = 9, ["{"] = 6, ["["] = 6, ["]"] = 6, ["}"] = 6, ["|"] = 3, ["\\"] = 4, [":"] = 5, [";"] = 5, ["\""] = 8, ["'"] = 4, ["<"] = 9, [">"] = 9, [","] = 4, ["."] = 6, ["?"] = 8, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 15, [app.charDegree] = 6, [app.div_sign] = 9, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 11, [app.charDownArrow] = 15, [app.filledTriangle] = 15, ["◀"] = 10, [app.multiplicationSymbol] = 5, [app.filledCircle] = 9, [app.filledTriangle] = 15, [app.filledSquare] = 9, [app.filledDiamond] = 9, [app.emptyCircle] = 12, [app.emptyTriangle] = 15, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["12"] = {
    			["a"] = 8, ["b"] = 9, ["c"] = 7, ["d"] = 9, ["e"] = 7, ["f"] = 5, ["g"] = 8, ["h"] = 9, ["i"] = 4, ["j"] = 5, ["k"] = 9, ["l"] = 4, ["m"] = 13, ["n"] = 9, ["o"] = 8, ["p"] = 9, ["q"] = 9, ["r"] = 7, ["s"] = 6, ["t"] = 5, ["u"] = 9, ["v"] = 8, ["w"] = 12, ["x"] = 8, ["y"] = 8, ["z"] = 7, ["A"] = 12, ["B"] = 11, ["C"] = 12, ["D"] = 12, ["E"] = 11, ["F"] = 10, ["G"] = 12, ["H"] = 12, ["I"] = 6, ["J"] = 8, ["K"] = 12, ["L"] = 11, ["M"] = 15, ["N"] = 12, ["O"] = 12, ["P"] = 10, ["Q"] = 12, ["R"] = 12, ["S"] = 9, ["T"] = 11, ["U"] = 12, ["V"] = 12, ["W"] = 16, ["X"] = 12, ["Y"] = 12, ["Z"] = 11, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 8, ["!"] = 5, ["@"] = 15, ["#"] = 8, ["$"] = 8, ["%"] = 16, ["^"] = 9, ["&"] = 13, ["*"] = 8, ["("] = 5, [")"] = 5, ["-"] = 10, ["_"] = 8, ["+"] = 10, ["="] = 10, ["{"] = 6, ["["] = 6, ["]"] = 6, ["}"] = 6, ["|"] = 4, ["\\"] = 4, [":"] = 5, [";"] = 5, ["\""] = 9, ["'"] = 4, ["<"] = 10, [">"] = 10, [","] = 4, ["."] = 6, ["?"] = 8, ["/"] = 4, [" "] = 5, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 16, [app.charDegree] = 6, [app.div_sign] = 10, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 12, [app.charDownArrow] = 16, [app.filledTriangle] = 16, ["◀"] = 10, [app.multiplicationSymbol] = 6, [app.filledCircle] = 10, [app.filledTriangle] = 16, [app.filledSquare] = 10, [app.filledDiamond] = 10, [app.emptyCircle] = 12, [app.emptyTriangle] = 16, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["13"] = {
    			["a"] = 11, ["b"] = 12, ["c"] = 9, ["d"] = 12, ["e"] = 9, ["f"] = 7, ["g"] = 11, ["h"] = 12, ["i"] = 6, ["j"] = 7, ["k"] = 12, ["l"] = 6, ["m"] = 18, ["n"] = 12, ["o"] = 11, ["p"] = 12, ["q"] = 12, ["r"] = 9, ["s"] = 8, ["t"] = 7, ["u"] = 12, ["v"] = 11, ["w"] = 15, ["x"] = 11, ["y"] = 11, ["z"] = 9, ["A"] = 15, ["B"] = 14, ["C"] = 15, ["D"] = 15, ["E"] = 14, ["F"] = 13, ["G"] = 16, ["H"] = 16, ["I"] = 8, ["J"] = 11, ["K"] = 16, ["L"] = 14, ["M"] = 20, ["N"] = 15, ["O"] = 16, ["P"] = 13, ["Q"] = 16, ["R"] = 15, ["S"] = 12, ["T"] = 14, ["U"] = 15, ["V"] = 15, ["W"] = 21, ["X"] = 15, ["Y"] = 15, ["Z"] = 14, ["1"] = 11, ["2"] = 11, ["3"] = 11, ["4"] = 11, ["5"] = 11, ["6"] = 11, ["7"] = 11, ["8"] = 11, ["9"] = 11, ["0"] = 11, ["`"] = 7, ["~"] = 11, ["!"] = 7, ["@"] = 20, ["#"] = 11, ["$"] = 11, ["%"] = 21, ["^"] = 12, ["&"] = 18, ["*"] = 11, ["("] = 7, [")"] = 7, ["-"] = 13, ["_"] = 11, ["+"] = 13, ["="] = 13, ["{"] = 8, ["["] = 8, ["]"] = 8, ["}"] = 8, ["|"] = 5, ["\\"] = 6, [":"] = 7, [";"] = 7, ["\""] = 12, ["'"] = 6, ["<"] = 13, [">"] = 13, [","] = 5, ["."] = 8, ["?"] = 11, ["/"] = 6, [" "] = 6, [app.charRightArrow] = 13, [string.uchar(0x21D5)] = 16, [string.uchar(0x21D5)] = 16, [app.charBackspaceArrow] = 21, [app.charDegree] = 8, [app.div_sign] = 13, [app.charSuperscript_3] = 6, [app.charSuperscript_2] = 6, [app.checkMark] = 16, [app.charDownArrow] = 21, [app.filledTriangle] = 21, ["◀"] = 13, [app.multiplicationSymbol] = 7, [app.filledCircle] = 13, [app.filledTriangle] = 21, [app.filledSquare] = 13, [app.filledDiamond] = 13, [app.emptyCircle] = 16, [app.emptyTriangle] = 21, [app.emptySquare] = 16, [app.emptyDiamond] = 16, 
    		},
    		["24"] = {
    			["a"] = 16, ["b"] = 18, ["c"] = 14, ["d"] = 18, ["e"] = 14, ["f"] = 11, ["g"] = 16, ["h"] = 18, ["i"] = 9, ["j"] = 11, ["k"] = 18, ["l"] = 9, ["m"] = 27, ["n"] = 18, ["o"] = 16, ["p"] = 18, ["q"] = 18, ["r"] = 14, ["s"] = 12, ["t"] = 11, ["u"] = 18, ["v"] = 16, ["w"] = 23, ["x"] = 16, ["y"] = 16, ["z"] = 14, ["A"] = 23, ["B"] = 21, ["C"] = 23, ["D"] = 23, ["E"] = 21, ["F"] = 20, ["G"] = 25, ["H"] = 25, ["I"] = 12, ["J"] = 16, ["K"] = 25, ["L"] = 21, ["M"] = 30, ["N"] = 23, ["O"] = 25, ["P"] = 20, ["Q"] = 25, ["R"] = 23, ["S"] = 18, ["T"] = 21, ["U"] = 23, ["V"] = 23, ["W"] = 32, ["X"] = 23, ["Y"] = 23, ["Z"] = 21, ["1"] = 16, ["2"] = 16, ["3"] = 16, ["4"] = 16, ["5"] = 16, ["6"] = 16, ["7"] = 16, ["8"] = 16, ["9"] = 16, ["0"] = 16, ["`"] = 11, ["~"] = 17, ["!"] = 11, ["@"] = 30, ["#"] = 16, ["$"] = 16, ["%"] = 32, ["^"] = 19, ["&"] = 27, ["*"] = 16, ["("] = 11, [")"] = 11, ["-"] = 20, ["_"] = 16, ["+"] = 20, ["="] = 20, ["{"] = 13, ["["] = 12, ["]"] = 12, ["}"] = 13, ["|"] = 7, ["\\"] = 9, [":"] = 11, [";"] = 11, ["\""] = 18, ["'"] = 9, ["<"] = 20, [">"] = 20, [","] = 8, ["."] = 12, ["?"] = 16, ["/"] = 9, [" "] = 9, [app.charRightArrow] = 20, [string.uchar(0x21D5)] = 25, [string.uchar(0x21D5)] = 25, [app.charBackspaceArrow] = 32, [app.charDegree] = 13, [app.div_sign] = 20, [app.charSuperscript_3] = 10, [app.charSuperscript_2] = 10, [app.checkMark] = 24, [app.charDownArrow] = 32, [app.filledTriangle] = 32, ["◀"] = 20, [app.multiplicationSymbol] = 11, [app.filledCircle] = 19, [app.filledTriangle] = 32, [app.filledSquare] = 19, [app.filledDiamond] = 19, [app.emptyCircle] = 25, [app.emptyTriangle] = 32, [app.emptySquare] = 25, [app.emptyDiamond] = 25, 
    		},
    	},
    }
    
    self.fontWidth["sansserif"] = {
    	["r"] = {
    		["7"] = {
    			["a"] = 5, ["b"] = 5, ["c"] = 5, ["d"] = 5, ["e"] = 5, ["f"] = 3, ["g"] = 5, ["h"] = 5, ["i"] = 2, ["j"] = 2, ["k"] = 5, ["l"] = 3, ["m"] = 8, ["n"] = 5, ["o"] = 5, ["p"] = 5, ["q"] = 5, ["r"] = 3, ["s"] = 5, ["t"] = 3, ["u"] = 5, ["v"] = 5, ["w"] = 7, ["x"] = 5, ["y"] = 5, ["z"] = 5, ["A"] = 6, ["B"] = 6, ["C"] = 7, ["D"] = 7, ["E"] = 6, ["F"] = 6, ["G"] = 7, ["H"] = 7, ["I"] = 3, ["J"] = 5, ["K"] = 6, ["L"] = 5, ["M"] = 8, ["N"] = 7, ["O"] = 7, ["P"] = 6, ["Q"] = 7, ["R"] = 7, ["S"] = 6, ["T"] = 6, ["U"] = 7, ["V"] = 6, ["W"] = 9, ["X"] = 6, ["Y"] = 6, ["Z"] = 6, ["1"] = 5, ["2"] = 5, ["3"] = 5, ["4"] = 5, ["5"] = 5, ["6"] = 5, ["7"] = 5, ["8"] = 5, ["9"] = 5, ["0"] = 5, ["`"] = 3, ["~"] = 5, ["!"] = 3, ["@"] = 9, ["#"] = 5, ["$"] = 5, ["%"] = 8, ["^"] = 4, ["&"] = 6, ["*"] = 4, ["("] = 3, [")"] = 3, ["-"] = 5, ["_"] = 5, ["+"] = 5, ["="] = 5, ["{"] = 3, ["["] = 3, ["]"] = 3, ["}"] = 3, ["|"] = 2, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 3, ["'"] = 2, ["<"] = 5, [">"] = 5, [","] = 3, ["."] = 3, ["?"] = 5, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 6, [string.uchar(0x21D5)] = 7, [string.uchar(0x21D5)] = 7, [app.charBackspaceArrow] = 9, [app.charDegree] = 4, [app.div_sign] = 5, [app.charSuperscript_3] = 3, [app.charSuperscript_2] = 3, [app.checkMark] = 7, [app.charDownArrow] = 9, [app.filledTriangle] = 9, ["◀"] = 6, [app.multiplicationSymbol] = 5, [app.filledCircle] = 5, [app.filledTriangle] = 9, [app.filledSquare] = 5, [app.filledDiamond] = 5, [app.emptyCircle] = 7, [app.emptyTriangle] = 9, [app.emptySquare] = 7, [app.emptyDiamond] = 7, 
    		},
    		["9"] = {
    			["a"] = 7, ["b"] = 7, ["c"] = 6, ["d"] = 7, ["e"] = 7, ["f"] = 3, ["g"] = 7, ["h"] = 7, ["i"] = 3, ["j"] = 3, ["k"] = 6, ["l"] = 3, ["m"] = 9, ["n"] = 7, ["o"] = 7, ["p"] = 7, ["q"] = 7, ["r"] = 4, ["s"] = 6, ["t"] = 3, ["u"] = 7, ["v"] = 6, ["w"] = 9, ["x"] = 6, ["y"] = 6, ["z"] = 6, ["A"] = 8, ["B"] = 8, ["C"] = 9, ["D"] = 9, ["E"] = 8, ["F"] = 7, ["G"] = 9, ["H"] = 9, ["I"] = 3, ["J"] = 6, ["K"] = 8, ["L"] = 7, ["M"] = 10, ["N"] = 9, ["O"] = 9, ["P"] = 8, ["Q"] = 9, ["R"] = 9, ["S"] = 8, ["T"] = 7, ["U"] = 9, ["V"] = 8, ["W"] = 11, ["X"] = 8, ["Y"] = 8, ["Z"] = 7, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 7, ["!"] = 3, ["@"] = 12, ["#"] = 7, ["$"] = 7, ["%"] = 11, ["^"] = 6, ["&"] = 8, ["*"] = 5, ["("] = 4, [")"] = 4, ["-"] = 7, ["_"] = 7, ["+"] = 7, ["="] = 7, ["{"] = 4, ["["] = 4, ["]"] = 4, ["}"] = 4, ["|"] = 3, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 4, ["'"] = 2, ["<"] = 7, [">"] = 7, [","] = 3, ["."] = 4, ["?"] = 7, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 9, [string.uchar(0x21D5)] = 9, [app.charBackspaceArrow] = 12, [app.charDegree] = 5, [app.div_sign] = 7, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 9, [app.charDownArrow] = 12, [app.filledTriangle] = 12, ["◀"] = 8, [app.multiplicationSymbol] = 6, [app.filledCircle] = 7, [app.filledTriangle] = 12, [app.filledSquare] = 7, [app.filledDiamond] = 7, [app.emptyCircle] = 9, [app.emptyTriangle] = 12, [app.emptySquare] = 9, [app.emptyDiamond] = 9, 
    		},
    		["10"] = {
    			["a"] = 7, ["b"] = 7, ["c"] = 7, ["d"] = 7, ["e"] = 7, ["f"] = 4, ["g"] = 7, ["h"] = 7, ["i"] = 3, ["j"] = 3, ["k"] = 7, ["l"] = 3, ["m"] = 11, ["n"] = 7, ["o"] = 7, ["p"] = 7, ["q"] = 7, ["r"] = 4, ["s"] = 7, ["t"] = 4, ["u"] = 7, ["v"] = 7, ["w"] = 9, ["x"] = 7, ["y"] = 7, ["z"] = 7, ["A"] = 9, ["B"] = 9, ["C"] = 9, ["D"] = 9, ["E"] = 9, ["F"] = 8, ["G"] = 10, ["H"] = 9, ["I"] = 4, ["J"] = 7, ["K"] = 9, ["L"] = 7, ["M"] = 11, ["N"] = 9, ["O"] = 10, ["P"] = 9, ["Q"] = 10, ["R"] = 9, ["S"] = 9, ["T"] = 8, ["U"] = 9, ["V"] = 9, ["W"] = 12, ["X"] = 9, ["Y"] = 9, ["Z"] = 8, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 8, ["!"] = 4, ["@"] = 13, ["#"] = 7, ["$"] = 7, ["%"] = 12, ["^"] = 6, ["&"] = 9, ["*"] = 5, ["("] = 4, [")"] = 4, ["-"] = 8, ["_"] = 7, ["+"] = 8, ["="] = 8, ["{"] = 4, ["["] = 4, ["]"] = 4, ["}"] = 4, ["|"] = 3, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 5, ["'"] = 2, ["<"] = 8, [">"] = 8, [","] = 4, ["."] = 5, ["?"] = 7, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 10, [string.uchar(0x21D5)] = 10, [app.charBackspaceArrow] = 13, [app.charDegree] = 5, [app.div_sign] = 8, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 10, [app.charDownArrow] = 13, [app.filledTriangle] = 13, ["◀"] = 8, [app.multiplicationSymbol] = 7, [app.filledCircle] = 8, [app.filledTriangle] = 13, [app.filledSquare] = 8, [app.filledDiamond] = 8, [app.emptyCircle] = 10, [app.emptyTriangle] = 13, [app.emptySquare] = 10, [app.emptyDiamond] = 10, 
    		},
    		["11"] = {
    			["a"] = 8, ["b"] = 8, ["c"] = 8, ["d"] = 8, ["e"] = 8, ["f"] = 4, ["g"] = 8, ["h"] = 8, ["i"] = 3, ["j"] = 3, ["k"] = 8, ["l"] = 3, ["m"] = 13, ["n"] = 8, ["o"] = 8, ["p"] = 8, ["q"] = 8, ["r"] = 5, ["s"] = 8, ["t"] = 4, ["u"] = 8, ["v"] = 8, ["w"] = 11, ["x"] = 8, ["y"] = 8, ["z"] = 8, ["A"] = 10, ["B"] = 10, ["C"] = 11, ["D"] = 11, ["E"] = 10, ["F"] = 9, ["G"] = 12, ["H"] = 11, ["I"] = 4, ["J"] = 8, ["K"] = 10, ["L"] = 8, ["M"] = 13, ["N"] = 11, ["O"] = 12, ["P"] = 10, ["Q"] = 12, ["R"] = 11, ["S"] = 10, ["T"] = 9, ["U"] = 11, ["V"] = 10, ["W"] = 14, ["X"] = 10, ["Y"] = 10, ["Z"] = 9, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 9, ["!"] = 4, ["@"] = 15, ["#"] = 8, ["$"] = 8, ["%"] = 13, ["^"] = 7, ["&"] = 10, ["*"] = 6, ["("] = 5, [")"] = 5, ["-"] = 9, ["_"] = 8, ["+"] = 9, ["="] = 9, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 4, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 5, ["'"] = 3, ["<"] = 9, [">"] = 9, [","] = 4, ["."] = 5, ["?"] = 8, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 11, [string.uchar(0x21D5)] = 11, [app.charBackspaceArrow] = 15, [app.charDegree] = 6, [app.div_sign] = 9, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 11, [app.charDownArrow] = 15, [app.filledTriangle] = 15, ["◀"] = 10, [app.multiplicationSymbol] = 8, [app.filledCircle] = 9, [app.filledTriangle] = 15, [app.filledSquare] = 9, [app.filledDiamond] = 9, [app.emptyCircle] = 11, [app.emptyTriangle] = 15, [app.emptySquare] = 11, [app.emptyDiamond] = 11, 
    		},
    		["12"] = {
    			["a"] = 9, ["b"] = 9, ["c"] = 8, ["d"] = 9, ["e"] = 9, ["f"] = 4, ["g"] = 9, ["h"] = 9, ["i"] = 4, ["j"] = 4, ["k"] = 8, ["l"] = 4, ["m"] = 13, ["n"] = 9, ["o"] = 9, ["p"] = 9, ["q"] = 9, ["r"] = 5, ["s"] = 8, ["t"] = 4, ["u"] = 9, ["v"] = 8, ["w"] = 12, ["x"] = 8, ["y"] = 8, ["z"] = 8, ["A"] = 11, ["B"] = 11, ["C"] = 12, ["D"] = 12, ["E"] = 11, ["F"] = 10, ["G"] = 12, ["H"] = 12, ["I"] = 4, ["J"] = 8, ["K"] = 11, ["L"] = 9, ["M"] = 13, ["N"] = 12, ["O"] = 12, ["P"] = 11, ["Q"] = 12, ["R"] = 12, ["S"] = 11, ["T"] = 10, ["U"] = 12, ["V"] = 11, ["W"] = 15, ["X"] = 11, ["Y"] = 11, ["Z"] = 10, ["1"] = 9, ["2"] = 9, ["3"] = 9, ["4"] = 9, ["5"] = 9, ["6"] = 9, ["7"] = 9, ["8"] = 9, ["9"] = 9, ["0"] = 9, ["`"] = 5, ["~"] = 9, ["!"] = 4, ["@"] = 16, ["#"] = 9, ["$"] = 9, ["%"] = 14, ["^"] = 8, ["&"] = 11, ["*"] = 6, ["("] = 5, [")"] = 5, ["-"] = 10, ["_"] = 9, ["+"] = 10, ["="] = 10, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 4, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 6, ["'"] = 3, ["<"] = 10, [">"] = 10, [","] = 4, ["."] = 6, ["?"] = 9, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 16, [app.charDegree] = 6, [app.div_sign] = 10, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 12, [app.charDownArrow] = 16, [app.filledTriangle] = 16, ["◀"] = 10, [app.multiplicationSymbol] = 8, [app.filledCircle] = 10, [app.filledTriangle] = 16, [app.filledSquare] = 10, [app.filledDiamond] = 10, [app.emptyCircle] = 12, [app.emptyTriangle] = 16, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["13"] = {
    			["a"] = 12, ["b"] = 12, ["c"] = 11, ["d"] = 12, ["e"] = 12, ["f"] = 6, ["g"] = 12, ["h"] = 12, ["i"] = 5, ["j"] = 5, ["k"] = 11, ["l"] = 5, ["m"] = 18, ["n"] = 12, ["o"] = 12, ["p"] = 12, ["q"] = 12, ["r"] = 7, ["s"] = 11, ["t"] = 6, ["u"] = 12, ["v"] = 11, ["w"] = 15, ["x"] = 11, ["y"] = 11, ["z"] = 11, ["A"] = 14, ["B"] = 14, ["C"] = 15, ["D"] = 15, ["E"] = 14, ["F"] = 13, ["G"] = 16, ["H"] = 15, ["I"] = 6, ["J"] = 11, ["K"] = 14, ["L"] = 12, ["M"] = 18, ["N"] = 15, ["O"] = 16, ["P"] = 14, ["Q"] = 16, ["R"] = 15, ["S"] = 14, ["T"] = 13, ["U"] = 15, ["V"] = 14, ["W"] = 20, ["X"] = 14, ["Y"] = 14, ["Z"] = 13, ["1"] = 12, ["2"] = 12, ["3"] = 12, ["4"] = 12, ["5"] = 12, ["6"] = 12, ["7"] = 12, ["8"] = 12, ["9"] = 12, ["0"] = 12, ["`"] = 7, ["~"] = 12, ["!"] = 6, ["@"] = 21, ["#"] = 12, ["$"] = 12, ["%"] = 19, ["^"] = 10, ["&"] = 14, ["*"] = 8, ["("] = 7, [")"] = 7, ["-"] = 13, ["_"] = 12, ["+"] = 13, ["="] = 13, ["{"] = 7, ["["] = 7, ["]"] = 7, ["}"] = 7, ["|"] = 5, ["\\"] = 6, [":"] = 6, [";"] = 6, ["\""] = 7, ["'"] = 4, ["<"] = 13, [">"] = 13, [","] = 6, ["."] = 8, ["?"] = 12, ["/"] = 6, [" "] = 6, [app.charRightArrow] = 13, [string.uchar(0x21D5)] = 16, [string.uchar(0x21D5)] = 16, [app.charBackspaceArrow] = 21, [app.charDegree] = 8, [app.div_sign] = 13, [app.charSuperscript_3] = 7, [app.charSuperscript_2] = 7, [app.checkMark] = 16, [app.charDownArrow] = 21, [app.filledTriangle] = 21, ["◀"] = 13, [app.multiplicationSymbol] = 11, [app.filledCircle] = 13, [app.filledTriangle] = 21, [app.filledSquare] = 13, [app.filledDiamond] = 13, [app.emptyCircle] = 16, [app.emptyTriangle] = 21, [app.emptySquare] = 16, [app.emptyDiamond] = 16, 
    		},
    		["24"] = {
    			["a"] = 18, ["b"] = 18, ["c"] = 16, ["d"] = 18, ["e"] = 18, ["f"] = 9, ["g"] = 18, ["h"] = 18, ["i"] = 7, ["j"] = 7, ["k"] = 16, ["l"] = 8, ["m"] = 27, ["n"] = 18, ["o"] = 18, ["p"] = 18, ["q"] = 18, ["r"] = 11, ["s"] = 16, ["t"] = 9, ["u"] = 18, ["v"] = 16, ["w"] = 23, ["x"] = 16, ["y"] = 16, ["z"] = 16, ["A"] = 21, ["B"] = 21, ["C"] = 23, ["D"] = 23, ["E"] = 21, ["F"] = 20, ["G"] = 25, ["H"] = 23, ["I"] = 9, ["J"] = 16, ["K"] = 21, ["L"] = 18, ["M"] = 27, ["N"] = 23, ["O"] = 25, ["P"] = 21, ["Q"] = 25, ["R"] = 23, ["S"] = 21, ["T"] = 20, ["U"] = 23, ["V"] = 21, ["W"] = 30, ["X"] = 21, ["Y"] = 21, ["Z"] = 20, ["1"] = 18, ["2"] = 18, ["3"] = 18, ["4"] = 18, ["5"] = 18, ["6"] = 18, ["7"] = 18, ["8"] = 18, ["9"] = 18, ["0"] = 18, ["`"] = 11, ["~"] = 19, ["!"] = 9, ["@"] = 32, ["#"] = 18, ["$"] = 18, ["%"] = 28, ["^"] = 15, ["&"] = 21, ["*"] = 12, ["("] = 11, [")"] = 11, ["-"] = 19, ["_"] = 18, ["+"] = 19, ["="] = 19, ["{"] = 11, ["["] = 10, ["]"] = 10, ["}"] = 11, ["|"] = 8, ["\\"] = 9, [":"] = 9, [";"] = 9, ["\""] = 11, ["'"] = 6, ["<"] = 19, [">"] = 19, [","] = 9, ["."] = 12, ["?"] = 18, ["/"] = 9, [" "] = 9, [app.charRightArrow] = 20, [string.uchar(0x21D5)] = 24, [string.uchar(0x21D5)] = 24, [app.charBackspaceArrow] = 32, [app.charDegree] = 13, [app.div_sign] = 19, [app.charSuperscript_3] = 11, [app.charSuperscript_2] = 11, [app.checkMark] = 24, [app.charDownArrow] = 32, [app.filledTriangle] = 32, ["◀"] = 20, [app.multiplicationSymbol] = 16, [app.filledCircle] = 19, [app.filledTriangle] = 32, [app.filledSquare] = 19, [app.filledDiamond] = 19, [app.emptyCircle] = 24, [app.emptyTriangle] = 32, [app.emptySquare] = 24, [app.emptyDiamond] = 24, 
    		},
    	},
    	["b"] = {
    		["7"] = {
    			["a"] = 5, ["b"] = 5, ["c"] = 5, ["d"] = 5, ["e"] = 5, ["f"] = 3, ["g"] = 5, ["h"] = 5, ["i"] = 2, ["j"] = 2, ["k"] = 5, ["l"] = 3, ["m"] = 8, ["n"] = 5, ["o"] = 5, ["p"] = 5, ["q"] = 5, ["r"] = 3, ["s"] = 5, ["t"] = 3, ["u"] = 5, ["v"] = 5, ["w"] = 7, ["x"] = 5, ["y"] = 5, ["z"] = 5, ["A"] = 6, ["B"] = 6, ["C"] = 7, ["D"] = 7, ["E"] = 6, ["F"] = 6, ["G"] = 7, ["H"] = 7, ["I"] = 3, ["J"] = 5, ["K"] = 6, ["L"] = 5, ["M"] = 8, ["N"] = 7, ["O"] = 7, ["P"] = 6, ["Q"] = 7, ["R"] = 7, ["S"] = 6, ["T"] = 6, ["U"] = 7, ["V"] = 6, ["W"] = 9, ["X"] = 6, ["Y"] = 6, ["Z"] = 6, ["1"] = 5, ["2"] = 5, ["3"] = 5, ["4"] = 5, ["5"] = 5, ["6"] = 5, ["7"] = 5, ["8"] = 5, ["9"] = 5, ["0"] = 5, ["`"] = 3, ["~"] = 5, ["!"] = 3, ["@"] = 9, ["#"] = 5, ["$"] = 5, ["%"] = 8, ["^"] = 4, ["&"] = 6, ["*"] = 4, ["("] = 3, [")"] = 3, ["-"] = 5, ["_"] = 5, ["+"] = 5, ["="] = 5, ["{"] = 3, ["["] = 3, ["]"] = 3, ["}"] = 3, ["|"] = 2, ["\\"] = 3, [":"] = 3, [";"] = 3, ["\""] = 3, ["'"] = 2, ["<"] = 5, [">"] = 5, [","] = 3, ["."] = 3, ["?"] = 5, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 6, [string.uchar(0x21D5)] = 7, [string.uchar(0x21D5)] = 7, [app.charBackspaceArrow] = 9, [app.charDegree] = 4, [app.div_sign] = 5, [app.charSuperscript_3] = 3, [app.charSuperscript_2] = 3, [app.checkMark] = 7, [app.charDownArrow] = 9, [app.filledTriangle] = 9, ["◀"] = 6, [app.multiplicationSymbol] = 5, [app.filledCircle] = 5, [app.filledTriangle] = 9, [app.filledSquare] = 5, [app.filledDiamond] = 5, [app.emptyCircle] = 7, [app.emptyTriangle] = 9, [app.emptySquare] = 7, [app.emptyDiamond] = 7, 
    		},
    		["9"] = {
    			["a"] = 7, ["b"] = 7, ["c"] = 7, ["d"] = 7, ["e"] = 7, ["f"] = 4, ["g"] = 7, ["h"] = 7, ["i"] = 3, ["j"] = 3, ["k"] = 7, ["l"] = 3, ["m"] = 11, ["n"] = 7, ["o"] = 7, ["p"] = 7, ["q"] = 7, ["r"] = 5, ["s"] = 7, ["t"] = 4, ["u"] = 7, ["v"] = 7, ["w"] = 9, ["x"] = 7, ["y"] = 7, ["z"] = 6, ["A"] = 9, ["B"] = 9, ["C"] = 9, ["D"] = 9, ["E"] = 8, ["F"] = 7, ["G"] = 9, ["H"] = 9, ["I"] = 3, ["J"] = 7, ["K"] = 9, ["L"] = 7, ["M"] = 10, ["N"] = 9, ["O"] = 9, ["P"] = 8, ["Q"] = 9, ["R"] = 9, ["S"] = 8, ["T"] = 7, ["U"] = 9, ["V"] = 8, ["W"] = 11, ["X"] = 8, ["Y"] = 8, ["Z"] = 7, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 7, ["!"] = 4, ["@"] = 12, ["#"] = 7, ["$"] = 7, ["%"] = 11, ["^"] = 7, ["&"] = 9, ["*"] = 5, ["("] = 4, [")"] = 4, ["-"] = 7, ["_"] = 7, ["+"] = 7, ["="] = 7, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 3, ["\\"] = 3, [":"] = 4, [";"] = 4, ["\""] = 6, ["'"] = 3, ["<"] = 7, [">"] = 7, [","] = 3, ["."] = 5, ["?"] = 7, ["/"] = 3, [" "] = 3, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 9, [string.uchar(0x21D5)] = 9, [app.charBackspaceArrow] = 12, [app.charDegree] = 5, [app.div_sign] = 7, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 9, [app.charDownArrow] = 12, [app.filledTriangle] = 12, ["◀"] = 8, [app.multiplicationSymbol] = 6, [app.filledCircle] = 7, [app.filledTriangle] = 12, [app.filledSquare] = 7, [app.filledDiamond] = 7, [app.emptyCircle] = 9, [app.emptyTriangle] = 12, [app.emptySquare] = 9, [app.emptyDiamond] = 9, 
    		},
    		["10"] = {
    			["a"] = 7, ["b"] = 8, ["c"] = 7, ["d"] = 8, ["e"] = 7, ["f"] = 4, ["g"] = 8, ["h"] = 8, ["i"] = 4, ["j"] = 4, ["k"] = 7, ["l"] = 4, ["m"] = 12, ["n"] = 8, ["o"] = 8, ["p"] = 8, ["q"] = 8, ["r"] = 5, ["s"] = 7, ["t"] = 4, ["u"] = 8, ["v"] = 7, ["w"] = 10, ["x"] = 7, ["y"] = 7, ["z"] = 7, ["A"] = 9, ["B"] = 9, ["C"] = 9, ["D"] = 9, ["E"] = 9, ["F"] = 8, ["G"] = 10, ["H"] = 9, ["I"] = 4, ["J"] = 7, ["K"] = 9, ["L"] = 8, ["M"] = 11, ["N"] = 9, ["O"] = 10, ["P"] = 9, ["Q"] = 10, ["R"] = 9, ["S"] = 9, ["T"] = 8, ["U"] = 9, ["V"] = 9, ["W"] = 12, ["X"] = 9, ["Y"] = 9, ["Z"] = 8, ["1"] = 7, ["2"] = 7, ["3"] = 7, ["4"] = 7, ["5"] = 7, ["6"] = 7, ["7"] = 7, ["8"] = 7, ["9"] = 7, ["0"] = 7, ["`"] = 4, ["~"] = 8, ["!"] = 4, ["@"] = 13, ["#"] = 7, ["$"] = 7, ["%"] = 12, ["^"] = 8, ["&"] = 9, ["*"] = 5, ["("] = 4, [")"] = 4, ["-"] = 8, ["_"] = 7, ["+"] = 8, ["="] = 8, ["{"] = 5, ["["] = 5, ["]"] = 5, ["}"] = 5, ["|"] = 4, ["\\"] = 4, [":"] = 4, [";"] = 4, ["\""] = 6, ["'"] = 3, ["<"] = 8, [">"] = 8, [","] = 4, ["."] = 5, ["?"] = 8, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 8, [string.uchar(0x21D5)] = 10, [string.uchar(0x21D5)] = 10, [app.charBackspaceArrow] = 13, [app.charDegree] = 6, [app.div_sign] = 8, [app.charSuperscript_3] = 4, [app.charSuperscript_2] = 4, [app.checkMark] = 10, [app.charDownArrow] = 13, [app.filledTriangle] = 13, ["◀"] = 8, [app.multiplicationSymbol] = 7, [app.filledCircle] = 8, [app.filledTriangle] = 13, [app.filledSquare] = 8, [app.filledDiamond] = 8, [app.emptyCircle] = 10, [app.emptyTriangle] = 13, [app.emptySquare] = 10, [app.emptyDiamond] = 10, 
    		},
    		["11"] = {
    			["a"] = 8, ["b"] = 9, ["c"] = 8, ["d"] = 9, ["e"] = 8, ["f"] = 5, ["g"] = 9, ["h"] = 9, ["i"] = 4, ["j"] = 4, ["k"] = 8, ["l"] = 4, ["m"] = 13, ["n"] = 9, ["o"] = 9, ["p"] = 9, ["q"] = 9, ["r"] = 6, ["s"] = 8, ["t"] = 5, ["u"] = 9, ["v"] = 8, ["w"] = 12, ["x"] = 8, ["y"] = 8, ["z"] = 8, ["A"] = 11, ["B"] = 11, ["C"] = 11, ["D"] = 11, ["E"] = 10, ["F"] = 9, ["G"] = 12, ["H"] = 11, ["I"] = 4, ["J"] = 8, ["K"] = 11, ["L"] = 9, ["M"] = 13, ["N"] = 11, ["O"] = 12, ["P"] = 10, ["Q"] = 12, ["R"] = 11, ["S"] = 10, ["T"] = 9, ["U"] = 11, ["V"] = 10, ["W"] = 14, ["X"] = 10, ["Y"] = 10, ["Z"] = 9, ["1"] = 8, ["2"] = 8, ["3"] = 8, ["4"] = 8, ["5"] = 8, ["6"] = 8, ["7"] = 8, ["8"] = 8, ["9"] = 8, ["0"] = 8, ["`"] = 5, ["~"] = 9, ["!"] = 5, ["@"] = 15, ["#"] = 8, ["$"] = 8, ["%"] = 13, ["^"] = 9, ["&"] = 11, ["*"] = 6, ["("] = 5, [")"] = 5, ["-"] = 9, ["_"] = 8, ["+"] = 9, ["="] = 9, ["{"] = 6, ["["] = 6, ["]"] = 6, ["}"] = 6, ["|"] = 4, ["\\"] = 4, [":"] = 5, [";"] = 5, ["\""] = 7, ["'"] = 4, ["<"] = 9, [">"] = 9, [","] = 4, ["."] = 6, ["?"] = 9, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 11, [string.uchar(0x21D5)] = 11, [app.charBackspaceArrow] = 15, [app.charDegree] = 6, [app.div_sign] = 9, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 11, [app.charDownArrow] = 15, [app.filledTriangle] = 15, ["◀"] = 10, [app.multiplicationSymbol] = 8, [app.filledCircle] = 9, [app.filledTriangle] = 15, [app.filledSquare] = 9, [app.filledDiamond] = 9, [app.emptyCircle] = 11, [app.emptyTriangle] = 15, [app.emptySquare] = 11, [app.emptyDiamond] = 11, 
    		},
    		["12"] = {
    			["a"] = 9, ["b"] = 10, ["c"] = 9, ["d"] = 10, ["e"] = 9, ["f"] = 5, ["g"] = 10, ["h"] = 10, ["i"] = 4, ["j"] = 4, ["k"] = 9, ["l"] = 4, ["m"] = 14, ["n"] = 10, ["o"] = 10, ["p"] = 10, ["q"] = 10, ["r"] = 6, ["s"] = 9, ["t"] = 5, ["u"] = 10, ["v"] = 9, ["w"] = 12, ["x"] = 9, ["y"] = 9, ["z"] = 8, ["A"] = 12, ["B"] = 12, ["C"] = 12, ["D"] = 12, ["E"] = 11, ["F"] = 10, ["G"] = 12, ["H"] = 12, ["I"] = 4, ["J"] = 9, ["K"] = 12, ["L"] = 10, ["M"] = 13, ["N"] = 12, ["O"] = 12, ["P"] = 11, ["Q"] = 12, ["R"] = 12, ["S"] = 11, ["T"] = 10, ["U"] = 12, ["V"] = 11, ["W"] = 15, ["X"] = 11, ["Y"] = 11, ["Z"] = 10, ["1"] = 9, ["2"] = 9, ["3"] = 9, ["4"] = 9, ["5"] = 9, ["6"] = 9, ["7"] = 9, ["8"] = 9, ["9"] = 9, ["0"] = 9, ["`"] = 5, ["~"] = 9, ["!"] = 5, ["@"] = 16, ["#"] = 9, ["$"] = 9, ["%"] = 14, ["^"] = 9, ["&"] = 12, ["*"] = 6, ["("] = 5, [")"] = 5, ["-"] = 10, ["_"] = 9, ["+"] = 10, ["="] = 10, ["{"] = 6, ["["] = 6, ["]"] = 6, ["}"] = 6, ["|"] = 4, ["\\"] = 4, [":"] = 5, [";"] = 5, ["\""] = 8, ["'"] = 4, ["<"] = 10, [">"] = 10, [","] = 4, ["."] = 6, ["?"] = 10, ["/"] = 4, [" "] = 4, [app.charRightArrow] = 10, [string.uchar(0x21D5)] = 12, [string.uchar(0x21D5)] = 12, [app.charBackspaceArrow] = 16, [app.charDegree] = 7, [app.div_sign] = 10, [app.charSuperscript_3] = 5, [app.charSuperscript_2] = 5, [app.checkMark] = 12, [app.charDownArrow] = 16, [app.filledTriangle] = 16, ["◀"] = 10, [app.multiplicationSymbol] = 9, [app.filledCircle] = 10, [app.filledTriangle] = 16, [app.filledSquare] = 10, [app.filledDiamond] = 10, [app.emptyCircle] = 12, [app.emptyTriangle] = 16, [app.emptySquare] = 12, [app.emptyDiamond] = 12, 
    		},
    		["13"] = {
    			["a"] = 12, ["b"] = 13, ["c"] = 12, ["d"] = 13, ["e"] = 12, ["f"] = 7, ["g"] = 13, ["h"] = 13, ["i"] = 6, ["j"] = 6, ["k"] = 12, ["l"] = 6, ["m"] = 19, ["n"] = 13, ["o"] = 13, ["p"] = 13, ["q"] = 13, ["r"] = 8, ["s"] = 12, ["t"] = 7, ["u"] = 13, ["v"] = 12, ["w"] = 16, ["x"] = 12, ["y"] = 12, ["z"] = 11, ["A"] = 15, ["B"] = 15, ["C"] = 15, ["D"] = 15, ["E"] = 14, ["F"] = 13, ["G"] = 16, ["H"] = 15, ["I"] = 6, ["J"] = 12, ["K"] = 15, ["L"] = 13, ["M"] = 18, ["N"] = 15, ["O"] = 16, ["P"] = 14, ["Q"] = 16, ["R"] = 15, ["S"] = 14, ["T"] = 13, ["U"] = 15, ["V"] = 14, ["W"] = 20, ["X"] = 14, ["Y"] = 14, ["Z"] = 13, ["1"] = 12, ["2"] = 12, ["3"] = 12, ["4"] = 12, ["5"] = 12, ["6"] = 12, ["7"] = 12, ["8"] = 12, ["9"] = 12, ["0"] = 12, ["`"] = 7, ["~"] = 12, ["!"] = 7, ["@"] = 20, ["#"] = 12, ["$"] = 12, ["%"] = 19, ["^"] = 12, ["&"] = 15, ["*"] = 8, ["("] = 7, [")"] = 7, ["-"] = 13, ["_"] = 12, ["+"] = 13, ["="] = 13, ["{"] = 8, ["["] = 8, ["]"] = 8, ["}"] = 8, ["|"] = 6, ["\\"] = 6, [":"] = 7, [";"] = 7, ["\""] = 10, ["'"] = 5, ["<"] = 13, [">"] = 13, [","] = 6, ["."] = 8, ["?"] = 13, ["/"] = 6, [" "] = 6, [app.charRightArrow] = 13, [string.uchar(0x21D5)] = 16, [string.uchar(0x21D5)] = 16, [app.charBackspaceArrow] = 21, [app.charDegree] = 9, [app.div_sign] = 13, [app.charSuperscript_3] = 7, [app.charSuperscript_2] = 7, [app.checkMark] = 16, [app.charDownArrow] = 21, [app.filledTriangle] = 21, ["◀"] = 13, [app.multiplicationSymbol] = 11, [app.filledCircle] = 13, [app.filledTriangle] = 21, [app.filledSquare] = 13, [app.filledDiamond] = 13, [app.emptyCircle] = 16, [app.emptyTriangle] = 21, [app.emptySquare] = 16, [app.emptyDiamond] = 16, 
    		},
    		["24"] = {
    			["a"] = 18, ["b"] = 20, ["c"] = 18, ["d"] = 20, ["e"] = 18, ["f"] = 11, ["g"] = 20, ["h"] = 20, ["i"] = 9, ["j"] = 9, ["k"] = 18, ["l"] = 9, ["m"] = 28, ["n"] = 20, ["o"] = 20, ["p"] = 20, ["q"] = 20, ["r"] = 12, ["s"] = 18, ["t"] = 11, ["u"] = 20, ["v"] = 18, ["w"] = 25, ["x"] = 18, ["y"] = 18, ["z"] = 16, ["A"] = 23, ["B"] = 23, ["C"] = 23, ["D"] = 23, ["E"] = 21, ["F"] = 20, ["G"] = 25, ["H"] = 23, ["I"] = 9, ["J"] = 18, ["K"] = 23, ["L"] = 20, ["M"] = 27, ["N"] = 23, ["O"] = 25, ["P"] = 21, ["Q"] = 25, ["R"] = 23, ["S"] = 21, ["T"] = 20, ["U"] = 23, ["V"] = 21, ["W"] = 30, ["X"] = 21, ["Y"] = 21, ["Z"] = 20, ["1"] = 18, ["2"] = 18, ["3"] = 18, ["4"] = 18, ["5"] = 18, ["6"] = 18, ["7"] = 18, ["8"] = 18, ["9"] = 18, ["0"] = 18, ["`"] = 11, ["~"] = 19, ["!"] = 11, ["@"] = 31, ["#"] = 18, ["$"] = 18, ["%"] = 28, ["^"] = 19, ["&"] = 23, ["*"] = 12, ["("] = 11, [")"] = 11, ["-"] = 19, ["_"] = 18, ["+"] = 19, ["="] = 19, ["{"] = 12, ["["] = 12, ["]"] = 12, ["}"] = 12, ["|"] = 9, ["\\"] = 9, [":"] = 11, [";"] = 11, ["\""] = 15, ["'"] = 8, ["<"] = 19, [">"] = 19, [","] = 9, ["."] = 12, ["?"] = 20, ["/"] = 9, [" "] = 9, [app.charRightArrow] = 20, [string.uchar(0x21D5)] = 24, [string.uchar(0x21D5)] = 24, [app.charBackspaceArrow] = 32, [app.charDegree] = 14, [app.div_sign] = 19, [app.charSuperscript_3] = 11, [app.charSuperscript_2] = 11, [app.checkMark] = 24, [app.charDownArrow] = 32, [app.filledTriangle] = 32, ["◀"] = 20, [app.multiplicationSymbol] = 17, [app.filledCircle] = 19, [app.filledTriangle] = 32, [app.filledSquare] = 19, [app.filledDiamond] = 19, [app.emptyCircle] = 24, [app.emptyTriangle] = 32, [app.emptySquare] = 24, [app.emptyDiamond] = 24, 
    		},
    	},
    }
    
    self.fontHeight = {["7"] = 13, ["9"] = 17, ["10"] = 19, ["11"] = 21, ["12"] = 21, ["13"] = 29, ["24"] = 44}
    
    self.webTopPct = { ["-"] = 0.55 }
    
    self.fontYOffset = { 
        ["7"] = {
            [app.filledCircle] = -1, [app.filledTriangle] = -1, [app.filledSquare] = -1, [app.emptyTriangle] = -1
        },
        ["9"] = {
            [app.filledCircle] = -2, [app.filledTriangle] = -2, [app.filledSquare] = -2, [app.emptyTriangle] = -2
        },
        ["10"] = {
            [app.filledCircle] = -2, [app.filledTriangle] = -1, [app.filledSquare] = -2, [app.emptyTriangle] = -1
        },
        ["11"] = {
            [app.filledCircle] = -2, [app.filledTriangle] = -2, [app.filledSquare] = -3, [app.filledDiamond] = -1, [app.emptyTriangle] = -2
        },
        ["12"] = {
            [app.filledCircle] = -1, [app.filledTriangle] = -1, [app.filledSquare] = -3, [app.emptyTriangle] = -1
        },
        ["13"] = {
            [app.filledCircle] = -8, [app.filledTriangle] = -1, [app.filledSquare] = -4, [app.filledDiamond] = -5, [app.emptyTriangle] = -1
        },
        ["24"] = {
            --[app.filledCircle] = -4, [app.filledTriangle] = -2, [app.filledSquare] = -4, [app.filledDiamond] = -14, [app.emptyTriangle] = -2
            [app.filledCircle] = -16, [app.filledTriangle] = -2, [app.filledSquare] = -4, [app.filledDiamond] = -14, [app.emptyTriangle] = -2
        }
    }

end

function StringTools:scaleFont(fontSize, scaleFactor)
    fontSize = fontSize * scaleFactor
    fontSize = fontSize >= 7 and fontSize or 7
    fontSize = fontSize <= 255 and fontSize or 255

    return fontSize
end

--Removes leading and trailing white space
function StringTools:trim(s)
    if s then return (s:gsub("^%s*(.-)%s*$", "%1")) else return nil end
end

--Removes external and internal whitespace
function StringTools:removeWhiteSpace(s)
    local stemp1 = ""
    local exp = ""

    --Get rid of all internal and external white space
    for j=1, string.len(s) do
        stemp1 = string.sub(s, j, j)
        if stemp1 ~= " " then
            exp = exp..stemp1
        end
    end

    return exp
end

--Returns either the original string and "", or two strings.
function StringTools:splitInTwo(s, m)
    local idx, lside, rside

    if s == nil then return s end

    lside = s
    rside = ""
    idx = string.find(s, m, 1, true)    --Find the split character.  start at first char and turn off regexp
    if idx ~= nil then
        lside = string.sub(s, 1, idx - 1)
        rside = string.sub(s, idx + 1)  --Returns empty string if no more characters
    end

    return lside, rside
end

--Splits a string into three parts.  The left Marker must be left of the right Marker.
function StringTools:splitInThree(s, leftMarker, rightMarker)
    local leftSide, middle, rightSide = "", "", ""
    local idx1, idx2

    if s == nil then return s, "", "" end

    idx1 = string.find(s, leftMarker, 1, true)     --No special characters.
    if idx1 == nil then
        leftSide = s
    else
        --The right marker must be further right than the left marker
        idx2 = string.find(s, rightMarker, idx1+1, true)     --No special characters.
        if idx2 == nil then
            if idx1 > 1 then
                leftSide = string.sub(s, 1, idx1-1)
            else
                if string.len(s) ~= 1 then
                    rightSide = string.sub(s, 2)
                end
            end
        else
            --Both markers are found
            if idx1 > 1 then
                leftSide = string.sub(s, 1, idx1-1)
            end
            if idx2 < string.len(s) then
                rightSide = string.sub(s, idx2+1)
            end
            if idx2 - idx1 > 1 then
                middle = string.sub(s, idx1+1, idx2-1)
            end
        end
    end
    return leftSide, middle, rightSide
end

--Use the fake gc to calculate the center on the pane.
function StringTools:centerString(width, s, fontFamily, fontStyle, fontSize)
    local w, h
    w, h = platform.withGC(function(...) w, h = self:getStringWidthHeight(...) return w,h end, s, fontFamily, fontStyle, fontSize)
    return (width - w) / 2
end

--Use the fake gc to get the width of the string.
function StringTools:getStringWidth(s, fontFamily, fontStyle, fontSize)
    local w, h
    w, h = platform.withGC(function(...) w,h = self:getStringWidthHeight(...) return w,h end, s, fontFamily, fontStyle, fontSize)
    return w
end

--Use the fake gc to get the height of the string.
function StringTools:getStringHeight(s, fontFamily, fontStyle, fontSize)
    local w, h
    w, h = platform.withGC(function(...) w,h = self:getStringWidthHeight(...) return w,h end, s, fontFamily, fontStyle, fontSize)
    return h
end

--Using fake gc from platform.withGC().
function StringTools:getStringWidthHeight(s, fontFamily, fontStyle, fontSize, gc)
    local f, i, w, h
    local totalWidth = 0

    local oldfontFamily, oldfontStyle, oldfontSize = gc:setFont(fontFamily, fontStyle, fontSize)

    --Height
    --_, h = self:getCharacterWidthHeight(string.sub(s, 1, 1), fontFamily, fontStyle, fontSize, gc)
    _, h = self:getCharacterWidthHeight(s, fontFamily, fontStyle, fontSize, gc)

    --Width
    if platform.hw() == 3 then      --3 is actual calculator

        for i=1, #tostring(s) do
            local uniChar = string.usub(s, i, i)
            w, _ = self:getCharacterWidthHeight(uniChar, fontFamily, fontStyle, fontSize, gc)
            if w == nil then w = gc:getStringWidth(uniChar) end      --character is not found in font size table, so this gets a reasonable width
            totalWidth = totalWidth + w
            if string.usub(s, i+1, i+1) == "" then break end
        end

    else
        totalWidth = gc:getStringWidth(s)
    end
    
    if oldfontSize ~= nil and oldfontSize >=6 and oldfontSize <=255 then gc:setFont(oldfontFamily, oldfontStyle, oldfontSize) end

    return totalWidth, h
end

--Call the function to get the extra white space factor for string height.  Nspire will use 1.  The browser version with ndlink will return a scaled value.
function StringTools:getStringHeightWhitespaceFactor()
    if app.platformType == "NSpire" then
        return 1
    else
        return platform:getStringHeightWhitespace()
    end
end

--Uses fake gc to return the character width
function StringTools:getCharacterWidth(c, fontFamily, fontStyle, fontSize)
    local w, h
    w, h = platform.withGC(function(...) w,h = self:getCharacterWidthHeight(...) return w,h end, c, fontFamily, fontStyle, fontSize)
    return w
end

--Uses fake gc to return the character height
function StringTools:getCharacterHeight(c, fontFamily, fontStyle, fontSize)
    local w, h
    w, h = platform.withGC(function(...) w,h = self:getCharacterWidthHeight(...) return w,h end, c, fontFamily, fontStyle, fontSize)
    return h
end

--Returns the width and height of a character
--Uses the fake gc for non-calculator platforms; uses the table of character width values for calculator platform
--c should be a single character
function StringTools:getCharacterWidthHeight(c, fontFamily, fontStyle, fontSize, gc)
    local w, h

    local oldfontFamily, oldfontStyle, oldfontSize = gc:setFont(fontFamily, fontStyle, fontSize)

    if platform.hw() == 3 then      --3 is actual calculator
        if fontSize <= 8 then
            fontSize = 7
        elseif fontSize > 12 and fontSize < 17 then
            fontSize = 13
        elseif fontSize > 16 then
            fontSize = 24
        end

        w = self.fontWidth[fontFamily][fontStyle][tostring(fontSize)][c]
        h = self.fontHeight[tostring(fontSize)]
    else
        w = gc:getStringWidth(c)
        h = gc:getStringHeight(c)
    end
    
    gc:setFont(oldfontFamily, oldfontStyle, oldfontSize)

    return w, h
end

--Loops through the string to find the index of the unicode character
--s = string; c = character to be found, should be a single character only; startIdx = index where to begin the search; plain = true for plain search
--Find = true if string.find should be used
function StringTools:ufind(s, c, startIdx, plain, regularFind)
    local i, j, stemp
    local firstIdx, lastIdx = -1, -1
    local char1, nextChar

    if regularFind then return string.find(s, c, startIdx, plain) end

    for i=startIdx, #s do
        stemp = string.usub(s, i, i)

        if stemp == c then
            return i
        end
    end

    return nil
end

-- In the string abcdefg, passing in an index of 5 will start at f, then search backwards.  If the pattern "b" is found, then returned index will be 2.
function StringTools:reverseFind(s, pattern, index, plain)
    local idx

    idx = string.find(string.reverse(s), pattern, (#s - index + 1), plain)

    if idx == nil then
        return nil
    else
        return #s - idx + 1
    end
end

function StringTools:getTopPercentageOfCharacter( char )
    if app.platformType == "NSpire" then
        return 0.5
    else
        return self.webTopPct[char]
    end
end

--returns the number of characters in a string
--use as replacement for string.len() or #string to count a unicode character as one character
function StringTools:getNumOfChars(str)
    local i, c
    local charTbl = {}
    
    for i=1, #str do
        c = string.usub(str, i, i)
        
        if c ~= "" and c ~= nil then table.insert(charTbl, c) end
    end
    
    return #charTbl
end

-------------------------------------------------------------
Timer = class()

function Timer:init()
    math.randomseed(timer.getMilliSecCounter()) --Initialize the random seed for math.random() functions.
    self.timer_tick = app.clockTickSpeed         -- (.1 = 100ms = 1/10 of a second).  (1 = 1000ms = 1 second)  (.025 = 25ms = 1/40 of a second.)  
    self.timers = {false, false, false}
    self.timerCount = 0             --Increments each on.timer() event.
    --timer.start(self.timer_tick)  --Do not start the timer until the tab is activated.
    self.started = false
    self.isReady = true        --Set this to true once user initiates something.
end

function Timer:start(timerID)
  self.timers[timerID] = true
end

--Only stop the entire timer if all timers have been stopped.
function Timer:stop(timerID)
    self.timers[timerID] = false
end

function Timer:getMilliSecCounter()
    return timer.getMilliSecCounter()
end

function Timer:performWithDelay( func, ms, loop )
    self.timerPerformWithDelayStart = timer.getMilliSecCounter()
    self.timerPerformWithDelayDuration = ms
    self.timerPerformWithDelayFunc = func
    self.timerPerformWithDelayLoop = loop -- if loop is -1, it will be infinite
    self.timerPerformWithDelayLoopCount = 0
    app.timer:start( app.model.timerIDs.DEFAULTTIMER )
end

function Timer:stopPerformWithDelay()
    self.timerPerformWithDelayStart = nil
    self.timerPerformWithDelayDuration = nil
    self.timerPerformWithDelayFunc = nil
    self.timerPerformWithDelayLoop = 0 -- if loop is -1, it will be infinite
    self.timerPerformWithDelayLoopCount = 0
    app.timer:stop( app.model.timerIDs.DEFAULTTIMER )
end

-------------------------------------------------
Menu = class(Widget)

function Menu:init()
    self.typeName = "menu"
  
    self.menu = nil
    self.selectedItem = 0
    self.totalItems = 0
    self.selectedItem2 = 0
    self.totalItems2 = 0
    self.menuLevel = 0      --1 means top level menu was selected, 2 means sub menu was selected
    self.menu2on = false
    self.itemChosen = ""
    self.visible = false
    self.closing = false        --Set to true when in the process of being hidden
    self.m1 = ""
    self.m2 = ""
    self.timer_count = 0
    self.timer_count_on = false
    self.submenuWidth, self.submenuHeight = {}, {}       --width and height of the submenu based on the top menu item selected
    self.callbackFunction = nil
    self.mainMenuWidth, self.mainMenuHeight = 1, 1      --width and height of the top level menu
    self.initMainMenuWidth, self.initMainMenuHeight = 1, 1      --initial width and height of the top level menu
    self.itemHeight = 1     --initial height of each menu item
    self.initItemHeight = 1     --height of each menu item

    self.stringTools = app.stringTools
    self.initFontSize = 10
    self.fontSize = self.initFontSize
    self.fontColor = {0, 0, 0}
    self.fontFamily = "sansserif"
    self.fontStyle = "r"
    self.mouse_xwidth, self.mouse_yheight = app.MOUSE_XWIDTH, app.MOUSE_YHEIGHT   --Used for increasing touch area
    
    self.submenuOffsets = {} -- contains offset up for the submenu
	self.feedbacks = {}
	self.showCheckMarks = false    --Green check marks on submenu
	self.boundingRectangle = false
    self.boundingRectangleColor = app.graphicsUtilities.Color.blue
end

--panew,paneh are pane sizes.  pctx,pcty are percentages of pane size.  w,h do not really affect the size of the menu.
function Menu:resize(panex, paney, panew, paneh, pctx, pcty, w, h, scaleFactor)
    local submenuWidth = 0
    if self.menu2on == true then submenuWidth = self.submenuWidth[self.selectedItem] + 2; end
    
    self.scaleFactor = scaleFactor
    self.panex = panex self.paney = paney self.panew = panew self.paneh = paneh
    self.x = pctx*panew; self.y = pcty*paneh 
    self.fontSize = self.stringTools:scaleFont(self.initFontSize, scaleFactor)
    self.mainMenuWidth = self.initMainMenuWidth * scaleFactor; self.mainMenuHeight = self.initMainMenuHeight * scaleFactor
    self.itemHeight = self.initItemHeight * scaleFactor

    self.w = (self.initWidth + submenuWidth) * self.scaleFactor
    self.h = self:calculateHeight(self.scaleFactor)
	
	self:resizeFeedbacks()
end

function Menu:paint(gc)
    if self.visible == true then
	
        self:drawTopLevelMenuShadow(gc)
        self:drawMainMenu(gc)

        if self.selectedItem ~= 0 then
		
            self:drawSelectedMainMenuItem(gc)

            if self.menu2on == true then
                local startY = self.y + (self.selectedItem-1)*self.itemHeight+2 
                local endY = startY + self.submenuHeight[self.selectedItem]*self.scaleFactor
                local offset = 0
                
                if self.paneh < endY then
                    offset = endY - self.paneh + 2 * self.scaleFactor -- for the shadow
                end
                            
				self:drawSubMenuShadow( gc, offset )
				self:drawSubMenuRect( gc, offset )
				self:drawSubMenuItems( gc, offset )

				if self.selectedItem2 ~= 0 then
				   self:drawSelectedSubMenuItem( gc, offset )
				end

				self:drawFeedbacks(gc)
           end
        end
        
        self:drawBoundingRectangle( gc )
    end
end

function Menu:drawMainMenu(gc)
	gc:setPen("thin", "smooth")
	gc:setColorRGB(255,255,255)
	gc:fillRect(self.x, self.y, self.mainMenuWidth, self.mainMenuHeight)
	gc:setColorRGB(0,0,0)
	gc:drawRect(self.x, self.y, self.mainMenuWidth, self.mainMenuHeight)

	gc:setColorRGB(unpack(app.graphicsUtilities.Color.black))
	gc:setFont("sansserif", "r", self.fontSize)
	
	for i=1,self.totalItems do
		gc:drawString(self.menu[i][1], self.x+3, self.y+(i-1)*self.itemHeight)
		gc:drawString(app.charRightArrow, self.x + self.mainMenuWidth - gc:getStringWidth(app.charRightArrow) - 2*self.scaleFactor, self.y+(i-1)*self.itemHeight)
	end
end

function Menu:drawSelectedMainMenuItem(gc)
	gc:setColorRGB(30, 144, 255)        --light blue
	gc:fillRect(self.x, self.y+(self.selectedItem-1)*self.itemHeight, self.mainMenuWidth, self.itemHeight)
	gc:setColorRGB(unpack(app.graphicsUtilities.Color.white))
	gc:drawString(self.menu[self.selectedItem][1], self.x+3, self.y+(self.selectedItem-1)*self.itemHeight)
	gc:drawString(app.charRightArrow, self.x + self.mainMenuWidth - gc:getStringWidth(app.charRightArrow) - 2*self.scaleFactor, self.y+(self.selectedItem-1)*self.itemHeight)
end

function Menu:drawSubMenuRect(gc, offset)
	local wOffset = self.submenuOffsets[self.selectedItem]
	local w = (self.submenuWidth[self.selectedItem] + wOffset) * self.scaleFactor
	local h = self.submenuHeight[self.selectedItem] * self.scaleFactor
	
	gc:setPen("thin", "smooth")
	gc:setColorRGB(255,255,255)
	gc:fillRect(self.x+self.mainMenuWidth-1, ( self.y+(self.selectedItem-1)*self.itemHeight+2 ) - offset, w, h)
	
	gc:setColorRGB(0,0,0)
	gc:drawRect(self.x+self.mainMenuWidth-1, ( self.y+(self.selectedItem-1)*self.itemHeight+2 ) - offset, w, h)
end

function Menu:drawSubMenuItems(gc, offset)
	gc:setColorRGB(0,0,0)
	gc:setFont("sansserif", "r", self.fontSize)

	for i=1,self.totalItems2 do
	   if self.selectedItem ~= 0 then
		   gc:drawString((app.model.menuItems[self.selectedItem][i+1])[1], self.x+self.mainMenuWidth+2, self.y+(i-1+self.selectedItem-1)*self.itemHeight+2 - offset )
	   else
		   gc:drawString((app.model.menuItems[1][i+1])[1], self.x+self.mainMenuWidth+2, self.y+(i-1+self.selectedItem-1)*self.itemHeight+2 - offset )
	   end
	end
end

function Menu:drawSelectedSubMenuItem(gc, offset)
	local wOffset = self.submenuOffsets[self.selectedItem]
	
	gc:setColorRGB(unpack(app.graphicsUtilities.Color.blue))
	gc:fillRect(self.x+self.mainMenuWidth-1, self.y+(self.selectedItem2-1+self.selectedItem-1)*self.itemHeight+1 - offset, (self.submenuWidth[self.selectedItem] + wOffset) * self.scaleFactor, self.itemHeight+1)
	gc:setColorRGB(unpack(app.graphicsUtilities.Color.white))
	gc:drawString((app.model.menuItems[self.selectedItem][self.selectedItem2+1])[1], self.x+self.mainMenuWidth+2, self.y+(self.selectedItem2-1+self.selectedItem-1)*self.itemHeight+2 - offset)
end

function Menu:drawFeedbacks(gc)
	for j=1, #self.feedbacks[self.selectedItem] do
		self.feedbacks[self.selectedItem][j]:paint(gc)
	end
end

function Menu:drawTopLevelMenuShadow(gc)
    local pt1X = self.x
    local pt1Y = self.y + self.mainMenuHeight
    local pt2X = self.x + 2*self.scaleFactor
    local pt2Y = self.y + self.mainMenuHeight + 2*self.scaleFactor
    local pt3X = self.x + self.mainMenuWidth + 2*self.scaleFactor
    local pt3Y = self.y + self.mainMenuHeight + 2*self.scaleFactor
    local pt4X = self.x + self.mainMenuWidth + 2*self.scaleFactor
    local pt4Y = self.y + 2*self.scaleFactor
    local pt5X = self.x + self.mainMenuWidth
    local pt5Y = self.y
        
    gc:setColorRGB(132, 132, 132)   --light grey
    gc:fillPolygon({pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y, pt4X, pt4Y, pt5X, pt5Y})
end

function Menu:drawSubMenuShadow( gc, offset )
	local submenuOffset = self.submenuOffsets[self.selectedItem]
	local submenuWidth = (self.submenuWidth[self.selectedItem] + submenuOffset) * self.scaleFactor
    local pt1X = self.x + self.mainMenuWidth - 1
    local pt1Y = self.y + (self.selectedItem-1)*self.itemHeight + 2 + self.itemHeight*self.totalItems2 - offset
    local pt2X = self.x + self.mainMenuWidth - 1 + 2*self.scaleFactor
    local pt2Y = self.y + (self.selectedItem-1)*self.itemHeight + 2 + self.itemHeight*self.totalItems2 + 2*self.scaleFactor  - offset
    local pt3X = self.x + self.mainMenuWidth - 1 + submenuWidth + 2*self.scaleFactor
    local pt3Y = self.y + (self.selectedItem-1)*self.itemHeight + 2 + self.itemHeight*self.totalItems2 + 2*self.scaleFactor  - offset
    local pt4X = self.x + self.mainMenuWidth - 1 + submenuWidth + 2*self.scaleFactor
    local pt4Y = self.y + (self.selectedItem-1)*self.itemHeight + 2 + 2*self.scaleFactor - offset
    local pt5X = self.x + self.mainMenuWidth - 1 + submenuWidth
    local pt5Y = self.y + (self.selectedItem-1)*self.itemHeight + 2  - offset
    
    gc:setColorRGB(132, 132, 132)   --light grey
    gc:fillPolygon({pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y, pt4X, pt4Y, pt5X, pt5Y})
end

function Menu:resizeFeedbacks()
	local xFeedback, yFeedback
	local feedbackWidth, feedbackHeight = 0, 0
	local strWidth
	
	if self.feedbacks[1] then 
		feedbackWidth, feedbackHeight = self.feedbacks[1][1]:calculateWidth( self.scaleFactor ), self.feedbacks[1][1]:calculateHeight( self.scaleFactor ) 
	end
	
	for i=1, self.totalItems do
		for j=1, #self.menu[i]-1 do
			strWidth = self.stringTools:getStringWidth(self.menu[i][j+1][1], "sansserif", "r", self.fontSize)
			xFeedback = (self.mainMenuWidth + strWidth)/self.panew
			yFeedback = ( (i-1+j-1)*self.itemHeight + .5*self.itemHeight - .5*feedbackHeight)/self.paneh
			
			self.feedbacks[i][j]:resize(self.x, self.y, self.panew, self.paneh, self.scaleFactor)
			self.feedbacks[i][j]:setPosition(xFeedback, yFeedback)
		end
	end
end

function Menu:contains(x, y)
    local xExpanded = x - .5*self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y                         -- No adjustment for vertical part of menu - .5*mouse_yheight

    local x_overlap = math.max(0, math.min(self.x+self.mainMenuWidth, xExpanded + self.mouse_xwidth) - math.max(self.x, xExpanded))
    local y_overlap = math.max(0, math.min(self.y+self.mainMenuHeight, yExpanded + self.mouse_yheight) - math.max(self.y, yExpanded))

    --If there is an intersecting rectangle, then this point is selected.
    if x_overlap * y_overlap > 0 then
        for i=1, self.totalItems do
            y_overlap = math.max(0, math.min(self.y+self.itemHeight*i, yExpanded + self.mouse_yheight) - math.max(self.y, yExpanded))
            if x_overlap * y_overlap > 0 then
                return 1, i     --Main menu, item
            end
        end
    elseif self.menu2on == true then
        if self.selectedItem > 0 then
            local startY = self.y + (self.selectedItem-1)*self.itemHeight+2
            local endY = startY + self.submenuHeight[self.selectedItem]*self.scaleFactor
            local offset = 0
			local submenuOffset = self.submenuOffsets[self.selectedItem]
			local submenuWidth = (self.submenuWidth[self.selectedItem] + submenuOffset) * self.scaleFactor
            
            if self.paneh < endY then
                offset = endY - self.paneh + 2 * self.scaleFactor -- for the shadow
            end
                            
            x_overlap = math.max(0, math.min(self.x + self.mainMenuWidth - 1 + submenuWidth, xExpanded + self.mouse_xwidth) - math.max(self.x + self.mainMenuWidth - 1, xExpanded))
            y_overlap = math.max(0, math.min(self.y + (self.selectedItem-1)*self.itemHeight + self.itemHeight*self.totalItems2 - offset, yExpanded + self.mouse_yheight) - math.max(self.y + (self.selectedItem-1)*self.itemHeight - offset, yExpanded))
            if x_overlap * y_overlap > 0 then
                for i=1, self.totalItems2 do
                    y_overlap = math.max(0, math.min(self.y + (self.selectedItem-1)*self.itemHeight + self.itemHeight*i - offset, yExpanded + self.mouse_yheight) - math.max(self.y + (self.selectedItem-1)*self.itemHeight - offset, yExpanded))
                    if x_overlap * y_overlap > 0 then
                        return 2, i     --Main menu, item
                    end
                end
            end
        end
    end

    return 0, 0    --Mouse not on menu
end

--b = true to set object visible, b = false to hide object.
function Menu:setVisible(b)
    self:invalidate()
    self.visible = b
end

function Menu:invalidate()
    if self.submenuHeight[self.selectedItem] and self.h < self.submenuHeight[self.selectedItem] * self.scaleFactor then
        local offset = self.submenuHeight[self.selectedItem] * self.scaleFactor - self.h
        app.frame:setInvalidatedArea(self.x, self.y - offset, self.w, self.submenuHeight[self.selectedItem] * self.scaleFactor)
    else
        app.frame:setInvalidatedArea(self.x, self.y, self.w, self.h)
    end
end

function Menu:drawBoundingRectangle( gc )
    if self.boundingRectangle then
        gc:setPen("thin", "smooth")
        gc:setColorRGB(unpack(self.boundingRectangleColor))
        
        if self.submenuHeight[self.selectedItem] then
            if self.h < self.submenuHeight[self.selectedItem] * self.scaleFactor then
                local offset = self.submenuHeight[self.selectedItem] * self.scaleFactor - self.h
                 gc:drawRect(self.x, self.y - offset, self.w, self.submenuHeight[self.selectedItem] * self.scaleFactor)
            else
                 gc:drawRect(self.x, self.y, self.w, self.h)
            end
        else
            gc:drawRect(self.x, self.y, self.w, self.h)
        end
    end
end

function Menu:register(menu)
    self.menu = menu
    self.totalItems = #self.menu
    self.selectedItem = 1
    self.initItemHeight = self.stringTools:getStringHeight(self.menu[1][1], "sansserif", "r", self.fontSize)      --assuming the menu items have the same fontStyle, fontFamily and fontSize
    self.itemHeight = self.initItemHeight
	
	self:setupSubmenuOffsets()
	self:setupFeedbacks()
    self:setupMainMenuWidthAndHeight()   
    self:setupSubmenuWidthAndHeight()  
    self:setupInitWidthAndInitHeight()
end

function Menu:setupInitWidthAndInitHeight()
    self.initWidth = self.initMainMenuWidth + 2; self.initHeight = self.initMainMenuHeight + 2
    self.w = self.initWidth; self.h = self.initHeight
end

function Menu:setupMainMenuWidthAndHeight()
    local i
    local longestWidth, w = 0, 0
    
    for i=1, self.totalItems do
        w = self.stringTools:getStringWidth(self.menu[i][1].."  ", "sansserif", "r", self.fontSize)
        if w > longestWidth then
            longestWidth = w
        end
    end
    
    self.initMainMenuWidth = longestWidth + self.stringTools:getCharacterWidth(app.charRightArrow, "sansserif", "r", self.fontSize)
    self.mainMenuWidth = self.initMainMenuWidth
    self.initMainMenuHeight = self.itemHeight * self.totalItems
    self.mainMenuHeight = self.initMainMenuHeight
end

function Menu:setupSubmenuWidthAndHeight()
    local i, j
    local longestWidth, w = 0, 0
 
    for i=1, self.totalItems do
        for j=1, #self.menu[i] do
            if self.menu[i][j][1] ~= nil then w = self.stringTools:getStringWidth(self.menu[i][j][1].."  ", "sansserif", "r", self.fontSize) end
            if w > longestWidth then
                longestWidth = w
            end
        end
        
        self.submenuWidth[i] = longestWidth 	
        self.submenuHeight[i] = self.itemHeight * (#self.menu[i] - 1)
        longestWidth = 0
        w = 0
    end
end

function Menu:setupFeedbacks()
	for i=1, #self.menu do
		self.feedbacks[i] = {}
		
		for j=1, #self.menu[i]-1 do
            self.feedbacks[i][j] = app.frame.widgetMgr:newWidget("FEEDBACK", "menuFeedback"..i, {initSizeAndPosition = {20, 20, 0, 0}, visible = false } )
			self.feedbacks[i][j]:setStyle("CheckMark")
			self.feedbacks[i][j]:setLocalScale(1, 1)
		end
	end
end

function Menu:setupSubmenuOffsets()
	for i=1, self.totalItems do
		self.submenuOffsets[i] = 0
	end
end

function Menu:handleTimer()
    if self.timer_count_on == true then
        self.timer_count = self.timer_count + 1
        if self.timer_count > 1 then
            self.timer_count_on = false
            self.timer_count = 0
            self:openSubMenu() 
            app.timer:stop(app.model.timerIDs.MENUTIMER)
        end
    end
  
 end

function Menu:show(selectedItem)
    self:setVisible(true)
    self.closing = false
    self.menu2on = false
    self.selectedItem = selectedItem
    self.selectedItem2 = 0
    self.timer_count_on = 0
    self.timer_count_on = true
    
    toolpalette.register(nil)   --if we are showing our custom menu, the unregister the calculator menu.
end
 
function Menu:hide()
    if self.visible == true then
        self:setVisible(false)
        self.closing = false
        self.menu2on = false
        
        toolpalette.register(app.model.menuItems)  --If we are hiding our custom menu, then renable the calculator menu.
        self.callbackFunction()         --post menu process only when closing menu.
    end
end

function Menu:arrowLeft()
    if self.visible == true then
        self:escapeKey()
        
        return true     --Event handled
    end
    
    return false    --Event not handled
end

function Menu:arrowRight()
    if self.visible == true then
        self:openSubMenu()
    
        if self.menu2on == true and self.selectedItem2 == 0 then
            self.selectedItem2 = 1
            self:invalidate()
        end

        return true     --Event handled
    end
        
    return false    --Event not handled
end

function Menu:arrowUp()
    if self.visible == true then
        if self.menu2on == true then
            if self.selectedItem2 > 1 then
                self.selectedItem2 = self.selectedItem2 - 1
                self:invalidate()
            end
        else
            if self.selectedItem > 1 then
                self.selectedItem = self.selectedItem - 1
                self:invalidate()
            end
        end
        
        return true     --Event handled
    end
    
    return false    --Event not handled
end

function Menu:arrowDown()
    if self.visible == true then
        if self.menu2on == true then
            if self.selectedItem2 < self.totalItems2 then
                self.selectedItem2 = self.selectedItem2 + 1
                self:invalidate()
            end
        else
            if self.selectedItem < self.totalItems then
                self.selectedItem = self.selectedItem + 1
                self:invalidate()
            end
        end
        
        return true     --Event handled
    end
    
    return false    --Event not handled
end

function Menu:selectKey()
    self:enterKey()
end

function Menu:enterKey()
    if self.menu2on == false then
        if self.selectedItem ~= 0 then
			local submenuOffset = self.submenuOffsets[self.selectedItem] + 2
			local submenuWidth = (self.initWidth + self.submenuWidth[self.selectedItem] + submenuOffset) * self.scaleFactor
			
            self.menu2on = true
            self.totalItems2 = #self.menu[self.selectedItem] - 1
            self.selectedItem2 = 1
            self.w = submenuWidth
            self.h = (self.initHeight + self.submenuHeight[self.selectedItem] + 2)*self.scaleFactor
        else
            self.totalItems2 = #self.menu[1] - 1
        end
        
        self:invalidate()
    else
        if self.selectedItem > 0 and self.selectedItem2 > 0 then
            if app.platformType == "ndlink" then                --Do this on web only to avoid too much delay in showing the menu on the calculator.
                app.controller:postMessage({function(...) self:hide() end})         --Give the submenu a chance to paint 
            else
                self:hide()
            end

            local fn = (app.model.menuItems[self.selectedItem][self.selectedItem2+1])[2]       --The second item is the function that is called for the selected menu item.
            fn(self.menu[self.selectedItem][1], (app.model.menuItems[self.selectedItem][self.selectedItem2+1])[1])  --Direct execute
        end
    end
end

function Menu:escapeKey()
    if self.menu2on == true then
        self.menu2on = false
        self.selectedItem2 = 0
        self:invalidate()
    else
        self:hide()    --Hide the menu
    end
    
end

function Menu:mouseDown(x, y)
    local menu, item

    if self.visible == true then
        menu, item = self:contains(x, y)
        
        if menu == 2 and item > 0 then
            self.selectedItem2 = item
            self:invalidate()
        end
        
        return true
    end
   
   return false           
end

function Menu:mouseUp(x, y)
    local item, ret

    if self.visible == true then
        self.menuLevel, item = self:contains(x, y)

        if self.menuLevel == 1 then
            self.menu2on = false
            self.selectedItem2 = 0

            if item > 0 then
                self.selectedItem = item
                self:openSubMenu()       --Open up submenu
            else
                self.selectedItem = 0
            end
        elseif self.menuLevel == 2 then
            if item > 0 then
                self.selectedItem2 = item
                self:enterKey()       --Select the item from the sub menu.
            end
        else
            self:hide()    --Hide the menu
        end
        
        return true     --Event handled
    end

    return false
end

function Menu:mouseMove(x, y)
    local menu, item
    if self.visible == true then
        menu, item = self:contains(x, y)
        if menu == 1 then
            if item > 0 then
                if self.menu2on == false or item ~= self.selectedItem then
                    self.menuLevel = menu
                    self.selectedItem = item
                    self.selectedItem2 = 0
                    self.menu2on = false
                    self.timer_count_on = 0
                    self.timer_count_on = true
                    app.timer:start(app.model.timerIDs.MENUTIMER)
                end
            end
            
            self:invalidate()
            
            return "menu1"
        elseif menu == 2 then
            if item > 0 then
                self.menuLevel = menu
                self.selectedItem2 = item
                
                self:invalidate()
                return "menu2"
            end
        else
            if self.selectedItem2 > 0 then  --We fell off the menu
                self.selectedItem2 = 0
                
                self:invalidate()
                return "none"
            end
        end
        
    end

    return ""
end

function Menu:charIn( char )
    if app.model.SUBMENU_X_DEBUG == true and string.lower( char ) == "x" and self.selectedItem and self.selectedItem2 then -- if the user pressed x
        local isSelectedItemAbout = app.model.menuItems[self.selectedItem] and app.model.menuItems[self.selectedItem][ 1 ] == "About" -- check if the main menu is on About
        local isSelectedSubMenuItemAbout = isSelectedItemAbout and app.model.menuItems[self.selectedItem][self.selectedItem2+1][ 1 ] == "About" -- check if the sub menu is on About
        
        if isSelectedSubMenuItemAbout then
            app.model.SHOW_MEMORY = not app.model.SHOW_MEMORY
            
            -- force invalidation of the whole area
            app.frame:setInvalidatedArea( 0, 0, app.frame.w, app.frame.h )
            self:invalidate()
            
            return true
        end
    end
    
    return false
end

function Menu:openSubMenu()
    if self.visible == true then
        if self.selectedItem > 0 then
            if self.menu2on == false then self.menu2on = true end 
            self:invalidate()
            
			local submenuOffset = self.submenuOffsets[self.selectedItem] + 2
			local submenuWidth = (self.initWidth + self.submenuWidth[self.selectedItem] + submenuOffset) * self.scaleFactor
			
            self.totalItems2 = #self.menu[self.selectedItem] - 1
            self.w = submenuWidth
            self.h = self:calculateHeight(self.scaleFactor)
           
            self:invalidate()
        end
    end
end

function Menu:calculateHeight(scaleFactor)
    local shadowOffset = 2
    local startY = self.y + (self.selectedItem-1) * self.itemHeight + shadowOffset
    
    local subMenuHeight = 0
    if self.selectedItem ~= 0 then subMenuHeight = self.submenuHeight[self.selectedItem] end
    
    local endY = startY + subMenuHeight * scaleFactor
    local offset = 0
    local h
    
    if self.paneh < endY then
        offset = endY - self.paneh + shadowOffset * scaleFactor
    end
    
    local submenuStartY = startY - offset
    local submenuEndY = submenuStartY + (subMenuHeight + shadowOffset) * scaleFactor
    local mainMenuEndY = self.y + self.initHeight * scaleFactor
    local heightDiff = submenuEndY - mainMenuEndY
    
    if heightDiff > 0 then
        h = self.initHeight * scaleFactor + heightDiff
    else
        h = self.initHeight * scaleFactor
    end
    
    return h
end

function Menu:setPostMenuFunction(func)
    self.callbackFunction = func
end

function Menu:setActive(b)      
    self.active = b     
    if b == false then self.hasFocus = false end    --Not allowed to have focus if not active.
    
    if self.shouldHover == true then        
        if b == false then      
            self:UIMgrListener( app.model.events.EVENT_MOUSE_OUT )   --remove the hover color from the widget when the widget gets inactive       
        end     
    end     
end

function Menu:showFeedbackForSelectedProblem( problemNum )
	local selectedItem, selectedItem2 = self:getFeedbackIdx( problemNum )
	
	if selectedItem and selectedItem2 then
		self.feedbacks[selectedItem][selectedItem2]:setVisible(true)
		self.submenuOffsets[selectedItem] = 4
	end
end

function Menu:getFeedbackIdx( problemNum )
	local selectedItem, selectedItem2
	local problemCtr = 0
	
	for i=1, #self.menu do
		for j=1, #self.menu[i]-1 do
			problemCtr = problemCtr + 1
			
			if problemCtr == problemNum then
				return i, j
			end
		end
	end
	
	return selectedItem, selectedItem2
end

function Menu:UIMgrListener( event, x, y )
    if event == app.model.events.EVENT_MOUSE_MOVE then
        return self:mouseMove( x, y )
    elseif event == app.model.events.EVENT_MOUSE_OUT then    --mouse pointer is out of bounds
        return self:mouseOutHandler()
    elseif event == app.model.events.EVENT_MOUSE_OVER then   --mouse pointer is inside widget bounds
        return self:mouseOverHandler( x, y ) 
    elseif event == app.model.events.EVENT_MOUSE_DOWN then
        return self:mouseDown( x, y )
    elseif event == app.model.events.EVENT_MOUSE_UP then
        return self:mouseUp( x, y )
    end
end

--------------------------------------------------------------------
UIMgr = class()

function UIMgr:init(menu)
    self.menu = menu
    self.scrollPane = nil
    self.activeViewID = 0
    self.listeners = {}
    self.mouseOverWidget = nil
    self.deactivatedObjList = {}    --holds the list of objects that are deactivated by ViewID
    self:reset()
end

function UIMgr:paint(gc)
    for i,UIObject in pairs(self.UIObjects[self.activeViewID]) do
        UIObject:paint(gc)
    end
end

function UIMgr:reset()
    self.currentObject = {}
    self.UIObjects = {}    --Textboxes, Buttons, etc. for each page.
    self.tabSequence = {} 
    self.backTabSequence = {}
    self.mouseDownObject = nil  --This is set to the object that mouseDown lands on.  Reset to nil on mouseUp
    self.grabbedObject = nil    --Set to the mouseDownObject if the user used the grab feature of the calculator.
end

function UIMgr:setActiveViewID(viewID)
    if self.activeViewID ~= nil and self.currentObject[self.activeViewID] ~= nil then self.currentObject[self.activeViewID]:setFocus(false) end --Turn off the focus on the previous page (it might have been the menu button in the frame).
    self.activeViewID = viewID
    if self.currentObject[self.activeViewID] ~= nil then self.currentObject[self.activeViewID]:setFocus(true) end   --Turn of the focus on the current page (it might be the menu button in the frame).
end

function UIMgr:setScrollPane(sp)
    self.scrollPane = sp
end

--Adds an object to the UIMgr so that it becomes part of the tab chain.
function UIMgr:addTabObject(UIObject, viewID)
    if self.UIObjects[viewID] == nil then self.UIObjects[viewID] = {} end
    self.UIObjects[viewID][UIObject.name] = UIObject   --Name was set on init() of object and must be unique per page.
end

--list is the list of tab objects
function UIMgr:addPageTabObjects(viewID, list)
    for i=1, #list do
        self:addTabObject(list[i], viewID)
    end
end

function UIMgr:setTabSequence(UIObject, viewID, ts, bts)
    if self.tabSequence[viewID] == nil then self.tabSequence[viewID] = {} end 
    if self.backTabSequence[viewID] == nil then self.backTabSequence[viewID] = {} end 

    self.tabSequence[viewID][UIObject.name] = ts
    self.backTabSequence[viewID][UIObject.name] = bts
end

--sequenceTbl is the ordered list of tab objects
function UIMgr:setPageTabSequence(viewID, sequenceTbl)
    local totalObjects = #sequenceTbl

    local UIObject, ts, bts
    local firstObject = sequenceTbl[1]
    local lastObject = sequenceTbl[ totalObjects ]
    
    if totalObjects == 1  then
        self:setTabSequence(firstObject, viewID, firstObject.name, lastObject.name)
    elseif totalObjects == 2 then
        self:setTabSequence(firstObject, viewID, lastObject.name, lastObject.name)
        self:setTabSequence(lastObject, viewID, firstObject.name, firstObject.name )
    else
        --set the first object's tab sequence
        self:setTabSequence(firstObject, viewID, sequenceTbl[2].name, lastObject.name)
        
        --loop through objects in the table except the last object
        for i=2, totalObjects - 1 do
            UIObject = sequenceTbl[ i ]
            ts = sequenceTbl[ i + 1 ]
            bts = sequenceTbl[ i - 1 ]

            self:setTabSequence(UIObject, viewID, ts.name, bts.name)
        end
        
        --set the last object's tab sequence
         self:setTabSequence( lastObject, viewID, firstObject.name, sequenceTbl[ totalObjects - 1 ].name )
    end
end

--name is the unique name of the instantiated object.
function UIMgr:switchFocus(name)
    assert( self.UIObjects[self.activeViewID], "UIMgr:switchFocus -> this object does not exist on this viewID: "..tostring(self.activeViewID).." "..name )
    assert( self.UIObjects[self.activeViewID][name], "UIMgr:switchFocus -> this object does not exist on this viewID "..tostring(self.activeViewID).." "..name )

    local previousObject = self.currentObject[self.activeViewID] -- XX this is the current object but will be treated as previous object right here
    local UIObject = self.UIObjects[self.activeViewID][name] -- XX this will be the current object
    
    if UIObject.acceptsFocus ~= true then -- the object should be able to accept focus before you can switch focus to it.
        return
    end
 
    if UIObject.visible == false or UIObject.active == false then  --Can't set focus to this item, so try to find something available.
       UIObject = self:findNextTabStop()    --If all objects are deactivated, this will return nil
    end

    if UIObject ~= nil then
        if UIObject.visible == true and UIObject.active == true and UIObject.acceptsFocus == true then
            -- we don't need to unset the focus if the focus will just go to the same object, just different child
            
            if UIObject ~= previousObject then -- if the previous object is not the same as the will-be-current object, then set the focus of the previous object to false
				if self.currentObject[self.activeViewID] ~= nil then self.currentObject[self.activeViewID]:setFocus(false) end        --currentObject is nil until this func is called
			end
			
            self.currentObject[self.activeViewID] = UIObject
            self.currentObject[self.activeViewID]:setFocus(true) 	
 
            --Hide the keyboard unless this object is a textbox.
            if app.frame.keyboard.visible == true and ( app.frame.keyboard.attachedToScrollPane == nil or app.frame.keyboard.scrollPane ~= self.scrollPane )    -- do this if keyboard is visible and keyboard is not attached to any scrollpane
                and app.frame.keyboard.lockVisibility ~= true then --Locked means don't mess with the visibility state of the keyboard. 
                
                --See if this widget is associated with the soft keyboard.
                local found = false
                for i = 1, #app.model.keyboardInputs do
                    if UIObject.typeName == app.model.keyboardInputs[i] then
                        found = true
                        break
                    end
                end

                if found == false then app.frame.keyboard:setVisible(false) end    --If this object is not a keyboardInput object, then hide the soft keyboard.
            end
        else
            self.currentObject[self.activeViewID]:setFocus(false)  --Ooops, can't meet the focus request, so set focus and current object to nothing 
        end
    end
end

function UIMgr:charIn(char)
    self.currentObject[self.activeViewID]:charIn(char)
end

function UIMgr:arrowLeft()
    local currentObject = self.currentObject[self.activeViewID]
    
    local didArrowLeft = currentObject:arrowLeft()
    
    if didArrowLeft ~= true then
        self:backTabKey()
    end
end

function UIMgr:arrowRight()
    local currentObject = self.currentObject[self.activeViewID]
    
    local didArrowRight = currentObject:arrowRight()
    
    if didArrowRight ~= true then
        self:tabKey()
    end
end

function UIMgr:arrowUp()
    return self.currentObject[self.activeViewID]:arrowUp()
end

function UIMgr:arrowDown()
    return self.currentObject[self.activeViewID]:arrowDown()
end

function UIMgr:mouseDown(x, y)
    local x1, y1, w1, h1
    
    self.mouseDownObject = nil  --Assume initially that no UI object is under the mousedown.
    
    --add a return when UIMgr handles a mouse down event
    return self:notifyListeners(self.activeViewID, app.model.events.EVENT_MOUSE_DOWN, x, y)
end

--The mouse up responds to whatever object it was on when it mousedown was called.
--page is the current page that was given focus on the mousedown event.
function UIMgr:mouseUp(x, y)
    local x1, y1, w1, h1
    local handled = false

    if self.mouseDownObject then
        local UIObject = self.mouseDownObject
        handled = UIObject:mouseUp(x,y)   --Use the same object that the mousedown started on.
        self.mouseDownObject = nil          --No more mousedown object.
    end
    
    return handled
end

--x, y are acutal pixels.
function UIMgr:mouseMove(x, y)
    if self.menu.visible == true then
        local ret = self.menu:mouseMove(x,y)
        if ret ~= "" then             --If the mouse was over the menu or just fell off then repaint.
            if ret ~= "none" then       --If the mouse is still over the menu, then we're done. 
                return
            end
        end
    end

    self:notifyListeners(self.activeViewID, app.model.events.EVENT_MOUSE_MOVE, x, y)
end

function UIMgr:grabUp(x, y)
    if self.grabbedObject and self.grabbedObject.hasGrab then              --If we try to grab another object, then release the first object.
        self.grabbedObject:releaseGrab()   
        self.grabbedObject = nil     
    end
    self.grabbedObject = self.mouseDownObject   --Whatever the mouseDown was on will be the object (or nil) that was grabbed.
    if self.grabbedObject and self.grabbedObject.hasGrab then
        self.grabbedObject:grabUp(x, y)
    end
end

function UIMgr:releaseGrab()
    if self.grabbedObject and self.grabbedObject.hasGrab then
        self.grabbedObject:releaseGrab()
        self.grabbedObject = nil
    end
end

function UIMgr:backspaceKey()
    self.currentObject[self.activeViewID]:backspaceKey()
end

function UIMgr:cut()
    self.currentObject[self.activeViewID]:cut()
end

function UIMgr:copy()
    self.currentObject[self.activeViewID]:copy()
end

function UIMgr:paste()
    self.currentObject[self.activeViewID]:paste()
end

function UIMgr:shiftArrowRight()
    self.currentObject[self.activeViewID]:shiftArrowRight()
end

function UIMgr:shiftArrowLeft()
    self.currentObject[self.activeViewID]:shiftArrowLeft()
end

function UIMgr:homeKey()
    self.currentObject[self.activeViewID]:homeKey()
end

function UIMgr:endKey()
    self.currentObject[self.activeViewID]:endKey()
end

function UIMgr:deleteKey()
    self.currentObject[ self.activeViewID ]:deleteKey()
end

function UIMgr:enterKey()
    if self.currentObject[self.activeViewID] == nil then self:switchFocus(app.frame.views[self.activeViewID].initFocus) end --Nothing currently has focus.

    return self.currentObject[ self.activeViewID ]:enterKey()
end

function UIMgr:tabKey()
    local nextObject
    if self.currentObject[self.activeViewID] == nil then self:switchFocus(app.frame.views[self.activeViewID].initFocus) end --Nothing currently has focus.
    nextObject = self:findNextTabStop()
    self:switchFocus(nextObject.name)
    if self.scrollPane ~= nil then self.scrollPane:scrollIntoView(nextObject.name) end
end

--Go through the UI Objects until either we find a visible and active object or until we get back to original UIObject
function UIMgr:findNextTabStop()
    local UIObject = self.currentObject[self.activeViewID]
    local nextObject = UIObject
    local counter = 0
    local UIObjectFocusDone

    --Handle UI objects with multiple focus
    if UIObject ~= nil then
        if UIObject.hasMultipleFocus == true then
            if UIObject.visible == true and UIObject.active == true and UIObject.acceptsFocus == true then
                UIObjectFocusDone = UIObject:moveFocusForward()   --move focus inside this UIObject
            
                if UIObjectFocusDone == false then      --focus traversal for this UIObject is not yet done, we cannot move to the next tab sequence so return the same UIObject
                    return UIObject
                end
            end
        end
    
        nextObject = UIObject
        repeat
            nextObject = self.UIObjects[self.activeViewID][self.tabSequence[self.activeViewID][nextObject.name]] --get next position by name
            counter = counter + 1
        until nextObject == nil or counter > 100 or nextObject == UIObject or (nextObject.visible == true and nextObject.active == true and nextObject.acceptsFocus == true )
    
        if nextObject == nil then nextObject = UIObject end     --If there was a failure, just keep things as they were.
    
        if nextObject.hasMultipleFocus == true then  
            if nextObject.visible == true and nextObject.active == true then 
                nextObject:setFocusToFirstObj()      --make sure that the next focus will go first to the first object of a multiple focus object
            end
        end
    end
    
    return nextObject    --Return the next object.
end

--Go through the UI Objects until either we find a visible and active object or until we get back to original UIObject
function UIMgr:findPreviousTabStop()
    local UIObject = self.currentObject[self.activeViewID]
    local nextObject = UIObject
    local counter = 0
    local UIObjectFocusDone
    
    if UIObject ~= nil then
        --Handle UI objects with multiple focus
        if UIObject.hasMultipleFocus == true then
            if UIObject.visible == true and UIObject.active == true and UIObject.acceptsFocus == true then
                UIObjectFocusDone = UIObject:moveFocusBackward()    --move focus inside this UIObject
                
                if UIObjectFocusDone == false then      --focus traversal for this UIObject is not yet done, we cannot move to the next tab sequence so return the same UIObject
                    return UIObject
                end
            end
        end
            
        nextObject = UIObject
        repeat
            nextObject = self.UIObjects[self.activeViewID][self.backTabSequence[self.activeViewID][nextObject.name]] --get next position by name
            counter = counter + 1
        until nextObject == nil or counter > 100 or nextObject == UIObject or (nextObject.visible == true and nextObject.active == true and nextObject.acceptsFocus == true)
    
        if nextObject == nil then nextObject = UIObject end     --If there was a failure, just keep things as they were.
        
        if nextObject.hasMultipleFocus == true then   
            if nextObject.visible == true and nextObject.active == true and UIObject.acceptsFocus == true then 
                nextObject:setFocusToLastObj()      --make sure that the next focus will go first to the last object of a multiple focus object
            end
        end
    end
    
    return nextObject    --Return the next object.
end

function UIMgr:backTabKey()
    local nextObject
    nextObject = self:findPreviousTabStop()
    self:switchFocus(nextObject.name)
    if self.scrollPane ~= nil then 
        self.scrollPane:scrollIntoView(nextObject.name)    
    end
end

--Activate the list of objects passed
function UIMgr:activateObjects(viewID)
    if self.deactivatedObjList[viewID] ~= nil then
        for j=1, #self.deactivatedObjList[viewID] do
            for i,UIObject in pairs(self.UIObjects[viewID]) do
                if self.deactivatedObjList[viewID][j].visible == true and self.deactivatedObjList[viewID][j].name == UIObject.name then
                    UIObject:setActive(true)
                end
            end
        end
    
        if viewID == self.activeViewID then self:switchFocus(app.frame.views[viewID].initFocus) end     --Set focus to desired object.
        
        self.deactivatedObjList[viewID] = nil
    end
end

--Turns the active objects to inactive
--Returns the array of objects deactivated
function UIMgr:deactivateObjects(viewID)
    local objects = {}

    for i,UIObject in pairs(self.UIObjects[viewID]) do
        if UIObject.visible == true and UIObject.active == true then
            UIObject:setActive(false)
            UIObject:setFocus( false )
            table.insert(objects, UIObject)
        end
    end

    self.deactivatedObjList[viewID] = objects
end

function UIMgr:getFocusObject()
    return self.currentObject[self.activeViewID]
end

function UIMgr:addListener( viewID, listener )
    if self.listeners[viewID] == nil then self.listeners[viewID] = {} end
    
    local listenerID = #self.listeners[viewID] + 1
    self.listeners[viewID][listenerID] = {}
    self.listeners[viewID][listenerID][1] = listener
    
    return listenerID
end

function UIMgr:removeListener( viewID, listenerID )
    self.listeners[viewID][listenerID] = {}
end

function UIMgr:notifyListeners( viewID, event, ... )
    local ret
    local ret1
    local widget = select( 1, ... )
    
    --Notify listeners on this page.
    if self.listeners[viewID] then 
        for i=1, #self.listeners[viewID] do
            ret = self:notifyListener(viewID, i, event, ...)
            if ret == true then break end
        end
    end
    
    --Notify frame listeners.
    if ret ~= true and self.listeners[0] then
        for i=1, #self.listeners[0] do
            ret = self:notifyListener(0, i, event, ...)
            if ret == true then break end
        end
    end
    
    --we need to add a return if a listener from UIMgr handled something.
    return ret
end

function UIMgr:notifyListener( viewID, i, event, ... )
    local ret = false
    
    if self.listeners[viewID][i][1] then
        local listener = self.listeners[viewID][i][1]
        
        if event == app.model.events.EVENT_MOUSE_MOVE then
            -- this code will not change color of button if mouseDownObject is not nil
            if self.mouseDownObject ~= nil then
                local x, y = select( 1, ... )
                ret = self.mouseDownObject:mouseMove( x, y )
            else
                ret, widget = listener( event, ... )
                
                ret = self:afterMouseMove( ret, widget, ... )
            end
            
            -- This code will still highlight the object under the mouse while dragging the mouseDownObject
            --[[if self.mouseDownObject ~= nil then
                local x, y = select( 1, ... )
                ret = self.mouseDownObject:mouseMove( x, y )
            end
            
            ret, widget = listener( event, ... )
            
            
            ret = self:afterMouseMove( ret, widget, ... )]]
            
        elseif event == app.model.events.EVENT_MOUSE_DOWN then
            ret, widget = listener( event, ... )
            ret = self:afterMouseDown( ret, widget )
        end
    end
    
    return ret
end

function UIMgr:afterMouseDown(ret, widget)
    if ret == true then
        self:switchFocus(widget.name)
        self.mouseDownObject = widget     --A UI object was under the mouse.
    end    
    
    return ret
end

--... = x, y
function UIMgr:afterMouseMove( ret, widget, ... )
    if ret == true then         --mouse pointer is over a widget
        previousMouseOverWidget = self.mouseOverWidget
        self.mouseOverWidget = widget
    else            
        previousMouseOverWidget = self.mouseOverWidget
        self.mouseOverWidget = nil
    end   

    local x, y = select( 1, ... )

    --mouse out
    if previousMouseOverWidget then
        previousMouseOverWidget:UIMgrListener(app.model.events.EVENT_MOUSE_OUT, x, y)
    end
    
    --mouse enter
    if self.mouseOverWidget then
        self.mouseOverWidget:UIMgrListener(app.model.events.EVENT_MOUSE_OVER, x, y)
    end
    
    return ret
end

function UIMgr:getObjectUsingName( objectName )
    if self.UIObjects[self.activeViewID][objectName] then
        return self.UIObjects[self.activeViewID][objectName]
    else
        assert( false, "UIMgr:getObjectUsingName -> this object does not exist on this viewID" )
    end
end

-- sidesOffset would mean additional pixels for the area. {{{ obj1's xleft, xright }, { obj1's yleft, yright }}, {{ obj2's xleft, xright }, { obj2's yleft, yright }}}
function UIMgr:hasCollided( obj1, obj2, sidesOffset, areaExtension )
    if not obj1 then return false end
    if not obj2 then return false end
    
    local sidesOffset = sidesOffset or 0
    local hasAreaExtension = areaExtension ~= nil
    local areaExtensionObj1, areaExtensionObj2 = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
    
    if hasAreaExtension then
        if areaExtension[ 1 ] then
            if areaExtension[ 1 ][ 1 ] then
                if tonumber( areaExtension[ 1 ][ 1 ][ 1 ]) then areaExtensionObj1[ 1 ] = tonumber( areaExtension[ 1 ][ 1 ][ 1 ]) end
                if tonumber( areaExtension[ 1 ][ 1 ][ 2 ]) then areaExtensionObj1[ 2 ] = tonumber( areaExtension[ 1 ][ 1 ][ 2 ]) end
            end
            
            if areaExtension[ 1 ][ 2 ] then
                if tonumber( areaExtension[ 1 ][ 2 ][ 1 ]) then areaExtensionObj1[ 3 ] = tonumber( areaExtension[ 1 ][ 2 ][ 1 ]) end
                if tonumber( areaExtension[ 1 ][ 2 ][ 2 ]) then areaExtensionObj1[ 4 ] = tonumber( areaExtension[ 1 ][ 2 ][ 2 ])end
            end
        end
        
        if areaExtension[ 2 ] then
            if areaExtension[ 2 ][ 1 ] then
                if tonumber( areaExtension[ 2 ][ 1 ][ 1 ]) then areaExtensionObj2[ 1 ] = tonumber( areaExtension[ 2 ][ 1 ][ 1 ]) end
                if tonumber( areaExtension[ 2 ][ 1 ][ 2 ]) then areaExtensionObj2[ 2 ] = tonumber( areaExtension[ 2 ][ 1 ][ 2 ]) end
            end
            
            if areaExtension[ 2 ][ 2 ] then
                if tonumber( areaExtension[ 2 ][ 2 ][ 1 ]) then areaExtensionObj2[ 3 ] = tonumber( areaExtension[ 2 ][ 2 ][ 1 ]) end
                if tonumber( areaExtension[ 2 ][ 2 ][ 2 ]) then areaExtensionObj2[ 4 ] = tonumber( areaExtension[ 2 ][ 2 ][ 2 ])end
            end
        end    
    end
    
    -- obj1
    local obj1sf = obj1.scaleFactor
    local obj1xmin = obj1.x - ( areaExtensionObj1[ 1 ] * obj1sf )
    local obj1xmax = obj1.x + obj1.w + ( areaExtensionObj1[ 2 ] * obj1sf )
    local obj1ymin = obj1.y - ( areaExtensionObj1[ 3 ] * obj1sf )
    local obj1ymax = obj1.y + obj1.h + ( areaExtensionObj1[ 4 ] * obj1sf )
    
    -- obj2
    local obj2sf = obj2.scaleFactor
    local obj2xmin = obj2.x - ( areaExtensionObj2[ 1 ] * obj2sf )
    local obj2xmax = obj2.x + obj2.w + ( areaExtensionObj2[ 2 ] * obj2sf )
    local obj2ymin = obj2.y - ( areaExtensionObj2[ 3 ] * obj2sf )
    local obj2ymax = obj2.y + obj2.h + ( areaExtensionObj2[ 4 ] * obj2sf )
    
    local left  = obj1xmin + sidesOffset <= obj2xmin + sidesOffset and obj1xmax - sidesOffset >= obj2xmin + sidesOffset
    local right = obj1xmin + sidesOffset >= obj2xmin + sidesOffset and obj1xmin + sidesOffset <= obj2xmax - sidesOffset
    local up    = obj1ymin + sidesOffset <= obj2ymin + sidesOffset and obj1ymax - sidesOffset >= obj2ymin + sidesOffset
    local down  = obj1ymin + sidesOffset >= obj2ymin + sidesOffset and obj1ymin + sidesOffset <= obj2ymax - sidesOffset
    
    return ( left or right ) and ( up or down )
end

--##WIDGETS
---------------------------------------------------------
Image = class(Widget)

function Image:init( name )
  Widget.init(self, name)
  self.typeName = "image"
  
  self.image = nil
  self.rotation = 0
  self.rotationSet = 0
end

function Image:paint( gc )
    if self.visible == true then
        gc:drawImage( self.image, self.x, self.y - self.scrollY )
        
        if self.boundingRectangle then self:paintBoundingRectangle( gc ) end
        
    end
end

function Image:paintBoundingRectangle( gc )
    gc:setColorRGB( 255, 0, 0 ) 
    gc:drawRect( self.x, self.y - self.scrollY, self.w, self.h )
end

function Image:setInitSizeAndPosition(w, h, pctx, pcty)
  Widget.setInitSizeAndPosition(self, w, h, pctx, pcty)
    
  self.image = self.image:copy( self.nonScaledWidth, self.nonScaledHeight )
end

function Image:setSize(w, h)
  Widget.setSize(self, w, h)
  assert(self.image, "Image is nil: "..tostring(self.name))
  
  self.image = self.image:copy( self.w, self.h )
end

function Image:loadImage( resourceImage )
    self.image = image.new( resourceImage )
    assert(self.image, "Image is nil: "..tostring(self.name).." with resourceImage: "..tostring(resourceImage))
    
    self.initWidth = self.image:width()
    self.initHeight = self.image:height()
end

function Image:rotate( angle )
    if not angle then angle = 0 end
    
    self.rotation = self.rotation + angle   
    self.image = self.image:rotate( angle )
    
    self:setSize( self.image:width() / self.scaleFactor, self.image:height() / self.scaleFactor )
    
end

function Image:calculateBoundingBox( scaleFactor )
    local rectangleWidth = self.initWidth * scaleFactor
    local rectangleHeight = self.initHeight * scaleFactor
    local newHeightUp = 0
    local newHeightLow = 0
    local newWidthLeft = 0
    local newWidthRight = 0
    local outerWidth = 0
    local outerHeight = 0
    
    newWidthLeft = rectangleWidth * math.abs( math.cos( math.rad( self.rotation )))
    newHeightLow = rectangleWidth * math.abs( math.sin( math.rad( self.rotation )))
    newHeightUp = rectangleHeight * math.abs( math.cos( math.rad( self.rotation )))
    newWidthRight = rectangleHeight * math.abs( math.sin( math.rad( self.rotation )))
    
    outerWidth = math.floor( newWidthLeft + newWidthRight )
    outerHeight = math.floor( newHeightUp + newHeightLow )
    
    return outerWidth, outerHeight
end

function Image:calculateWidth( scaleFactor )
    local width, height = self:calculateBoundingBox( scaleFactor )

    return width
end

function Image:calculateHeight( scaleFactor )
    local width, height = self:calculateBoundingBox( scaleFactor )
    
    return height
end

-- set rotation of image to user-specific value
function Image:setRotation( rotation )
    if not rotation then rotation = 0 end
    
    self.image = self.image:rotate( self.rotation * -1 ) -- rotate the image back to 0 position
    
    self.rotation = rotation -- set rotation to user value
    self.image = self.image:rotate( self.rotation ) -- rotate image to user value
    
    self:setSize( self.image:width() / self.scaleFactor, self.image:height() / self.scaleFactor )
end

function Image:getImage()
    return self.image
end

-----------------------------------------------------------------
Circle = class(Widget)

function Circle:init(name)
    Widget.init(self, name)
    self.typeName = "circle"
    
    --Custom properties
    self.fillColor = self.initFillColor    --whitegrey
    self.borderColor = {0, 0, 0}
    self.fontColor = {0, 0, 0}
    self.fill = true
    self.drawBorder = true
    
end

function Circle:paint( gc )
    if self.visible then
        local x = self.x
        local y = self.y - self.scrollY

        self:paintCircle( x, y, gc )
        
        gc:setColorRGB(unpack(self.fontColor))
        gc:setFont("sansserif", "r", self.fontSize)
        gc:drawString(self.text, x, y)
        
        self:drawBoundingRectangle(gc)
    end
end

function Circle:paintCircle( x, y, gc )
    if self.fill == true then
        gc:setColorRGB(unpack(self.fillColor))
        gc:fillArc(x, y, self.w - 1, self.h - 1, 0, 360)      --The -1 is because fillRect doesn't count the first line as part of the height.
    end

    if self.drawBorder == true and self.hasFocus == false then
        gc:setPen("thin", "smooth")
        gc:setColorRGB(unpack(self.borderColor))
        gc:drawArc(x, y, self.w - 1, self.h - 1, 0, 360)      --The -1 is because fillRect doesn't count the first line as part of the height.
    end
    
    if self.hasFocus == true then
        gc:setColorRGB(unpack(self.focusColor))
        gc:setPen("thin", "dashed")
        gc:drawArc(x, y, self.w - 1, self.h - 1, 0, 360)      --The -1 is because fillRect doesn't count the first line as part of the height.
    end
end

function Circle:showBorder(b)
    self:invalidate()
    self.drawBorder = b
end

function Circle:setFillColor(color)
    self.fillColor = color
    self:invalidate()
end

---------------------------------------------------------
Rectangle = class(Widget)

function Rectangle:init(name)
    Widget.init(self, name)
    self.typeName = "rectangle"
    
    --Custom properties
    self.fillColor = self.initFillColor    --whitegrey
    self.borderColor = {0, 0, 0}
    self.fontColor = {0, 0, 0}
    self.fill = true
    self.drawBorder = true
    self.text = ""
    self.alignID = app.enum({ "X_LEFT", "X_CENTER", "X_RIGHT", "Y_TOP", "Y_CENTER", "Y_BOTTOM"})
    self.textAlignment = { self.alignID.X_CENTER, self.alignID.Y_CENTER }
    self.borderType = "smooth"
    self.paragraph = nil
    self.hasParagraph = false
    self.isParagraphVisible = false
end

function Rectangle:setPane( panex, paney, panew, paneh, scaleFactor )
    Widget.setPane( self, panex, paney, panew, paneh, scaleFactor )
    
    if self.paragraph then self.paragraph:setPane( panex, paney, panew, paneh, scaleFactor ) end
end

function Rectangle:setPosition( pctx, pcty )
    Widget.setPosition( self, pctx, pcty )
    
    local pctxTbl, pctyTbl = self:computeTextAndButtonPosition( pctx, pcty )
    if self.paragraph then 
        self.paragraph:setPosition( pctxTbl[self.paragraph.name], pctyTbl[self.paragraph.name] )
    end
end

function Rectangle:setSize( nsw, nsh )
    Widget.setSize( self, nsw, nsh )
    
    if self.paragraph then self.paragraph:setSize( self.paragraph.nonScaledWidth, self.paragraph.nonScaledHeight ) end

    self:notifyListeners( app.model.events.EVENT_SIZE_CHANGE, self )
end

function Rectangle:paint( gc )
    if self.visible then
        local x = self.x
        local y = self.y - self.scrollY

        self:paintRectangle( x, y, gc )
        self:paintText( x, y, gc )
        
        if self.hasParagraph == true and self.isParagraphVisible == true then
            self.paragraph:paint( gc )
        end
        
        self:drawBoundingRectangle(gc)
    end
end

function Rectangle:paintRectangle( x, y, gc )
    if self.fill == true then
        gc:setColorRGB(unpack(self.fillColor))
        
        if self.drawBorder == true then
            gc:fillRect(x, y, self.w, self.h)
        else
            gc:fillRect(x - 1, y - 1, self.w + 1, self.h + 1)
        end
    end

    if self.drawBorder == true and self.hasFocus == false then
        gc:setPen("thin", self.borderType )
        gc:setColorRGB(unpack(self.borderColor))
        gc:drawRect(x, y, self.w, self.h)   
    end
    
    if self.hasFocus == true then
        gc:setColorRGB(unpack(self.focusColor))
        gc:setPen("thin", "dashed")
        gc:drawRect(x, y, self.w, self.h)
    end
end

function Rectangle:paintText( x, y, gc )
    gc:setColorRGB(unpack(self.fontColor))
    gc:setFont("sansserif", "r", self.fontSize)
    
    local xpos = x
    local ypos = y
    
    if self.textAlignment[1] == self.alignID.X_CENTER then
        xpos = x + self.w * 0.5 - gc:getStringWidth( self.text ) * 0.5
    elseif self.textAlignment[1] == self.alignID.X_RIGHT then
        xpos = x + self.w - gc:getStringWidth( self.text )
    end
    
    if self.textAlignment[2] == self.alignID.Y_CENTER then
        ypos = y + self.h * 0.5 - gc:getStringHeight( self.text ) * 0.5
    elseif self.textAlignment[2] == self.alignID.Y_BOTTOM then
        ypos = y + self.h - gc:getStringHeight( self.text )
    end
    
    gc:drawString( self.text, xpos, ypos )
end

function Rectangle:showBorder(b)
    self:invalidate()
    self.drawBorder = b
end

--change the base color of the button
function Rectangle:setFillColor(color)
    self.fillColor = color
    self:invalidate()
end

function Rectangle:handleTimer() end

-- alignx and aligny are values from 
function Rectangle:setTextAlignment( alignx, aligny )
    self.textAlignment = { alignx, aligny }
end

function Rectangle:setPositionToInit()
    self:setPosition( self.initPctX, self.initPctY )
end

function Rectangle:setBorderType( borderType )
    self.borderType = borderType
    self:invalidate()
end

function Rectangle:setBorderColor( borderColor )
    self.borderColor = borderColor
    self:invalidate()
end

function Rectangle:setParagraph( s )
    if s then
        self.hasParagraph = true
        self.paragraph:setText({ s })
    else
        self.hasParagraph = false
    end
end

function Rectangle:showParagraph( b )
    self.isParagraphVisible = b
end

function Rectangle:computeTextAndButtonPosition(pctx, pcty)
    local pctxTbl, pctyTbl = {}, {}
    
    if self.paragraph then
        local nsw = self.paragraph:calculateWidth( self.paragraph.scaleFactor ) / self.paragraph.panew
        local nsh = self.paragraph:calculateHeight( self.paragraph.scaleFactor ) / self.paragraph.paneh
        pctxTbl[ self.paragraph.name ] = pctx + (( self.w * 0.5 ) / self.panew ) - ( nsw * 0.5 )
        pctyTbl[ self.paragraph.name ] = pcty + (( self.h * 0.5 ) / self.paneh ) - ( nsh * 0.5 )
    end
    
    return pctxTbl, pctyTbl
end

function Rectangle:addParagraph()
    self.paragraph = Paragraph( self.name .. "-fraction" )
    self.paragraph.fontStyle = "r"
    self.paragraph.fontFamily = "sansserif"
    self.paragraph.active = false
    self.paragraph.drawStyle = "vertical"
end

function Rectangle:setVisible( b )
    Widget.setVisible( self, b )
    if self.paragraph then self.paragraph:setVisible( b ) end
end

function Rectangle:setActive( b )
    self.active = b
    if self.paragraph then self.paragraph.active = b end
end

function Rectangle:setScrollY(y)
    Widget.setScrollY(self, y)
    
    if self.paragraph then self.paragraph:setScrollY(y) end
end

function Rectangle:handleTimer()
    if app.timer.timers[app.model.timerIDs.PARAGRAPHTIMER] == true and self.visible then
      self.animatedPara:handleTimer()
    end
end

---------------------------------------------------------
RoundedRectangle = class(Rectangle)

function RoundedRectangle:init(name)
    Rectangle.init(self, name)
    self.typeName = "roundedRectangle"
    
    --Custom properties
    self.curve = 1
    self.curvePct = .28
    self:setCurve( self.curvePct )
    self.fillColor = self.initFillColor    --whitegrey
    self.borderColor = {0, 0, 0}
    self.borderStyle = "smooth"    --"smooth", "dashed"
    self.fontColor = {0, 0, 0}
    self.fill = true
end

function RoundedRectangle:paint( gc )
    if self.visible then
        local x = self.x
        local y = self.y - self.scrollY

        self:paintRoundedRectangle( x, y, gc )
        
        gc:setColorRGB(unpack(self.fontColor))
        gc:setFont("sansserif", "r", self.fontSize)
        gc:drawString(self.text, x, y)
        
        self:drawBoundingRectangle(gc)
    end
end

function RoundedRectangle:paintRoundedRectangle( x, y, gc )
    local width = self.w
    local height = self.h 
    local curve = self.curve
    
    if self.fill == true then
      gc:setPen("thin", "smooth")
      gc:setColorRGB(unpack(self.fillColor))
         
      --x, y, w, h - Fill a cross
      gc:fillRect(x+curve, y, width-2*curve, height)      
      gc:drawRect(x+curve, y, width-2*curve, height)      --drawRect 1 pixel higher and wider than fillRect
      gc:fillRect(x, y+curve, width, height-2*curve - 1)      --horizontal rectangle
      gc:drawRect(x, y+curve, width, height-2*curve - 1)      --drawRect 1 pixel higher and wider than fillRect

      --x1, y1, r1, r2 (keep the same), start angle, number of degrees to trun (NSpire docs say end angle, but it's actually turn angle).
      gc:fillArc(x, y, 2*curve+1, 2*curve+1, 90, 360) --upper left
      gc:fillArc(x+width-2*curve, y, 2*curve, 2*curve, 0, 360)          --upper right
      gc:fillArc(x+width-2*curve, y+height-2*curve, 2*curve, 2*curve, 0, -360)      --bottom right
      gc:fillArc(x, y+height-2*curve, 2*curve, 2*curve, 90, 360)
    end
    
    gc:setPen("thin", self.borderStyle) 
    gc:setColorRGB(unpack(self.borderColor))
    
    --x1, y1, r1, r2 (keep the same), start angle, number of degrees to trun. - Draw the border
    gc:drawArc(x, y, 2*curve, 2*curve, 90, 90)  --top left
    gc:drawArc(x+width-2*curve, y, 2*curve, 2*curve, 0, 90) --top right
    gc:drawArc(x+width-2*curve, y+height - 2*curve, 2*curve, 2*curve, 0, -90)  
    gc:drawArc(x, y+height - 2*curve, 2*curve, 2*curve, 270, -90)
    
    --x1, y1, x2, y2 - Draw the border
    gc:drawLine(x+curve, y, x+width-curve, y)  --top
    gc:drawLine(x+width, y+curve, x+width, y+height-curve)  --right side
    gc:drawLine(x+width-curve, y+height, x+curve, y+height)  --bottom
    gc:drawLine(x, y+height-curve, x, y+curve)  --left side
end

function RoundedRectangle:setSize(w, h)
    Rectangle.setSize(self, w, h)
    
    if self.w < 2 then self.w = 2 end; if self.h < 2 then self.h = 2 end    

    self:setCurve( self.curvePct )
end

function RoundedRectangle:setCurve( curvePct )
    local minSide = math.min(self.w, self.h)
    self.curve = math.floor(curvePct * minSide)
end

---------------------------------------------------------------------
OctagonRectangle = class(Rectangle)

function OctagonRectangle:init(name)
    Rectangle.init(self, name)
    self.typeName = "octagonRectangle"

    self.innerGap = 0;  --Number of pixels between focus rectangle and rounded rectangle.
end

function OctagonRectangle:paint( gc )
    if self.visible then
        self:drawOctagon(gc)
    end
end

function OctagonRectangle:paint( gc )
    local sf = self.scaleFactor
    local cut = 2  --Number of pixels to cut from corner for diagonal
    local getInnerGap = function( multiplier ) return multiplier * self.innerGap * self.scaleFactor end
    local y = self.y - self.scrollY
    
    local pt1X, pt1Y = self.x + getInnerGap( 1 ) + cut*sf,          y + getInnerGap( 1 )  --line
    local pt2X, pt2Y = self.x + self.w-1 - getInnerGap( 1 ) - cut*sf, y + getInnerGap( 1 )  --diagonal
    local pt3X, pt3Y = self.x + self.w-1 - getInnerGap( 1 ), y + getInnerGap( 1 ) + cut*sf -- line, right side
    local pt4X, pt4Y = self.x + self.w-1 - getInnerGap( 1 ), y + self.h - getInnerGap( 1 ) - cut*sf -- diagonal, lower right
    local pt5X, pt5Y = self.x + self.w-1 - getInnerGap( 1 ) - cut*sf, y + self.h-1 - getInnerGap( 1 )-- line
    local pt6X, pt6Y = self.x + getInnerGap( 1 ) + cut*sf,          y + self.h-1 - getInnerGap( 1) -- diagonal, lower left
    local pt7X, pt7Y = self.x + getInnerGap( 1 ),          y + self.h-1 - getInnerGap( 1 ) - cut*sf -- line
    local pt8X, pt8Y = self.x + getInnerGap( 1 ),          y + getInnerGap( 1 ) + cut*sf -- diagonal, upper left
    
    local tblx, tbly = { pt1X, pt2X, pt3X, pt4X, pt5X, pt6X, pt7X, pt8X, pt1X }, { pt1Y, pt2Y, pt3Y, pt4Y, pt5Y, pt6Y, pt7Y, pt8Y, pt1Y }
    
    gc:setPen("thin", self.borderStyle) 
    gc:setColorRGB(unpack(self.fillColor))
    gc:fillPolygon( { pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y, pt4X, pt4Y, pt5X, pt5Y, pt6X, pt6Y, pt7X, pt7Y, pt8X, pt8Y, pt1X, pt1Y })
    gc:setColorRGB(unpack(self.borderColor))
    
    gc:drawLine( tblx[1], tbly[1], tblx[2], tbly[2] )
    gc:drawLine( tblx[2], tbly[2], tblx[3], tbly[3] )
    gc:drawLine( tblx[3], tbly[3], tblx[4], tbly[4] )
    gc:drawLine( tblx[4], tbly[4], tblx[5], tbly[5] )
    gc:drawLine( tblx[5], tbly[5], tblx[6], tbly[6] )
    gc:drawLine( tblx[6], tbly[6], tblx[7], tbly[7] )
    gc:drawLine( tblx[7], tbly[7], tblx[8], tbly[8] )
    gc:drawLine( tblx[8], tbly[8], tblx[9], tbly[9] )
end

---------------------------------------------------------------------
Button = class(Widget)

function Button:init(name)
    Widget.init(self, name)
    self.typeName = "button"

    self.innerGap = 0;  --Number of pixels between focus rectangle and rounded rectangle.
    self.innerWidth = 1;  self.innerHeight = 1  --Nonscaled width and height of widget without focus rectangle.
    self.sizeIncludesFocus = true          --Set to false to size the button without consideration of a focus rectangle.
    self.drawFunction = nil
    self.label = ""
    self.fillColor = self.initFillColor
    self.initBorderColor = {0, 0, 0}
    self.borderColor = self.initBorderColor
    self.labelOffset = 1
    self.styleIDs = app.enum({ "RECTANGLE", "ROUNDED_RECTANGLE", "OCTAGON", "CIRCLE" })
    self.style = self.styleIDs.OCTAGON    --1 = rectangle, 2,3 = rounded rectangle, 3 = octagon rectangle on calculator
    self.octagonStyle = false        --true allows octagon style    
    self:setStyle(self.style)    
    self.rectangle.borderColor = self.borderColor
         
    self.acceptsFocus = true
    self.shouldHover = true
end

--x,y is the pane location.  self.x and self.y are offset within the pane.
function Button:paint(gc)
    if self.visible == true then
      local x = self.x
      local y = self.y - self.scrollY
      local yRect = self.rectangle.y - self.scrollY

      self.rectangle.fillColor = self.fillColor
      self.rectangle:paint(gc)

      --Label
      if self.drawFunction == nil then
        self:drawText(gc, self.rectangle.x, yRect, self.rectangle.w, self.rectangle.h) 
      else
        self.drawFunction(gc, self.rectangle.x, yRect, self.rectangle.w, self.rectangle.h, self.scaleFactor) --Call a function to draw onto the button.
      end

      self:drawBoundingRectangle(gc)
    end
end

function Button:drawText(gc, x, y, w, h)
    gc:setColorRGB(unpack(self.fontColor))
    gc:setFont("sansserif", "r", self.fontSize)
    local labelW, labelH = gc:getStringWidth(self.label), gc:getStringHeight(self.label)   
    gc:drawString(self.label, x + .5 * (w - labelW), y + .5 * (h - labelH) - self.labelOffset * self.scaleFactor)    
end

function Button:setInitSizeAndPosition(w, h, pctx, pcty)
    Widget.setInitSizeAndPosition(self, w, h, pctx, pcty)

    self.rectangle:setInitSizeAndPosition(w - 2*self.innerGap, h - 2*self.innerGap, pctx, pcty)
end

function Button:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)
    
    self.rectangle:setPane(panex, paney, panew, paneh, scaleFactor)
end

function Button:setSize(w, h)
  Widget.setSize(self, w, h)

  self.innerWidth = self.nonScaledWidth - 2*self.innerGap; self.innerHeight = self.nonScaledHeight - 2*self.innerGap
  if self.innerWidth < 0 then self.innerWidth = 0 end;  if self.innerHeight < 0 then self.innerHeight = 0 end

  if self.sizeIncludesFocus then
    self.rectangle:setSize(self.innerWidth, self.innerHeight)
  else
    self.rectangle:setSize(self.nonScaledWidth, self.nonScaledHeight)    --Rectangle goes out to the edge of the bounding box.
  end
  
  self:invalidate()
end

--Set position based on percentage of the container pane.
function Button:setPosition(pctx, pcty)
  Widget.setPosition(self, pctx, pcty)

  --Inform internal objects that pane size has changed.  (Cannot just use resize() here because resize uses existing values and we have new values).
  if self.sizeIncludesFocus then
    self.rectangle:setPosition(self.pctx + (self.innerGap*self.scaleFactor)/self.panew, self.pcty + (self.innerGap*self.scaleFactor)/self.paneh)   --Add 2 pixels to rectangle to account for focus rectangle.
  else
    self.rectangle:setPosition(self.pctx, self.pcty)   --Rectangle is positioned same as bounding rectangle.
  end
end

function Button:setLabel(label)
    self.label = label
end

function Button:setScrollY(y)
    Widget.setScrollY(self, y)
    
    self.rectangle:setScrollY(y)
end

--Sets a function that will draw onto the button.
function Button:setDrawCallback(drawFunction)
    self.drawFunction = drawFunction
end

function Button:mouseDown( x, y )
    local ret, widget = Widget.mouseDown(self, x, y)
    
    if self.tracking == true then self:setFillColor(self.mouseDownColor) end   
    
    return ret, widget  
end

function Button:mouseUp(x, y)
    if self.active == true and self.visible == true and self.tracking == true then
        self:setFillColor(self.initFillColor)
        self:notifyListeners(app.model.events.EVENT_MOUSE_UP, self, x, y)     --Listeners for this event are only notified if this object is visible, active and received a mouse down/move event.
    end

    self.tracking = false
end

function Button:enterKey()
    if self.active == true and self.visible == true then
        self:setFillColor(self.mouseDownColor)
        self:notifyListeners(app.model.events.EVENT_ENTER_KEY, self, x, y)     --Listeners for this event are only notified if this object is visible and active.
    end
end

function Button:setFocus(b)
    Widget.setFocus(self, b)
    
    if b == true then
        self.rectangle.borderStyle = "dashed"
        self.rectangle.borderColor = self.focusColor
        self:notifyListeners(app.model.events.EVENT_GOT_FOCUS, self, x, y)
    else
        self.rectangle.borderStyle = "smooth"
        self.borderColor = self.initBorderColor
        self.rectangle.borderColor = self.borderColor
        self:notifyListeners(app.model.events.EVENT_LOST_FOCUS, self, x, y)
    end
    
    self:invalidate()
end

--change the base color of the button
function Button:setBorderColor(color)
    self.initBorderColor = color
    self.borderColor = self.initBorderColor
    if not self.hasFocus then self.rectangle.borderColor = self.initBorderColor end
     
    self:invalidate()
end

--change the base color of the button
function Button:setFillColor(color)
    self.fillColor = color
    self:invalidate()
end

--style can be: "RECTANGLE", "ROUNDED_RECTANGLE", "OCTAGON", "CIRCLE"; see self.styleIDs
function Button:setStyle(style)
    self:invalidate()
       
    self.style = style
  
    if self.style == self.styleIDs.CIRCLE then
        self.rectangle = Circle(self.name.."Rect")
    elseif self.style == self.styleIDs.OCTAGON and app.platformHW == 3 then      --Only use Octagon style on actual calculator
        self.rectangle = OctagonRectangle(self.name.."Rect")
    elseif self.style == self.styleIDs.OCTAGON or self.style == self.styleIDs.ROUNDED_RECTANGLE then
        self.rectangle = RoundedRectangle(self.name.."Rect")
    else
        self.rectangle = Rectangle(self.name.."Rect")
    end

    self:invalidate()
end

function Button:charIn( char )
    self:notifyListeners( app.model.events.EVENT_CHAR_IN, char )
end

-------------------------------------------------------------
TextBox = class(Widget)

function TextBox:init(name)
    Widget.init(self, name)
    self.typeName = "textbox"
    
    self:setUpLabels()
    self:setUpEditBox()
    self:setUpBottomLine()
    
    self.visibleText = SimpleString(self.name.."_visibleText")

    self.maxChar = 100      --Default max characters
    self.cursorpos = 0      --also the start of the gap buffer
    self.cursorStartXPos = 0
    self.prefilled = false  --true if textbox is has prefilled text.  This will be deleted after first character entered.
    self.preFillColor = {255, 0, 0}
    self.showTextboxCursor = false      --for showing the blinking cursor
    self.enableTextboxCursor = true		--even if showTextboxCursor is true, if this is set to false, the cursor will not show
    self.autocomplete = nil      --text will autocomplete to second term if first term is entered
    self.autocompleteDone = false   --tells whether or not autocomplete is done
    self.pen = "thin"
    self.timer_count = 0
    self.processCallback = nil      --Allow container to pre-process input.
    self.enterKeyCallback = nil     --Allow container to handle the ENTER key.
    self.getStringHeightWhitespaceFactor = self.stringTools.getStringHeightWhitespaceFactor
    self.drawFocus = true   --Focus rect
    self.blinkSpeed = 8        --8 for .1 clock and 32 for .025 clock
    
    --private
    self.isVinculumActive = false
    self.vinculumStartX = 0
    self.vinculumEndX = 0
    self.vinculumIdxStart = -1
    self.vinculumIdxEnd = 0
    self.vinculumUICallback = nil
    self.vinculumToRemoveBox = false
    self.vinculumBoxIsShown = false
    self.minWidth = 10
    self.maxWidth = 0
    self.toResizeFont = false
    self.allowScroll = false
    self.isDynamicWidth = true
    self.forceLowercase = false
    self.usePlurality = false   --autocomplete feature will be based on the plurality of the value entered by the user
    self.acceptsFocus = true
    self.overrideChar = false       --if true and maxChar is 1, existing text will be overridden by the new character without backspacing
    self.charXPos = {}      --for insertion point
    self.charXPos[1] = 0        --set the first char position to 0; it means no characters entered yet
    self.selectedTextStartX, self.selectedTextEndX = 0, 0
    self.selectedText = ""
    self.selectionStartIdx = 1
    self.enableCut = false
    self.enableCopy = false
    self.enablePaste = false
    self.selectionColor = {0, 178, 238}     --light blue
    
    self.gapBuffer = {}     --will contain all characters in the whole text
    self.visibleStartIdx, self.visibleEndIdx = 0, 0        --visible text start and end index
    self.charCounter = 0        --counts the number of characters in the whole text
    self.spaceIdx = 0       --used in autocomplete
    self.mouseDragged = false
    self.cursorSideIDs = app.enum({ "LEFT", "RIGHT" })
    self.trim = app.stringTools.trim
    self.scaleFactorChanged = false        --true if scaleFactor is changed e.g. calculator view to computer view
    self.takeMouseEvents = true
    
    self.cursorColor = self.visibleText.fontColor
end

function TextBox:paint(gc)
    if self.visible == true then
        --Label
        self.label:paint(gc)
        self.label2:paint(gc)
        
        --rectangle boxes
        self.editBox:paint(gc)
        
        -- bottom line
        self.bottomLine:paint(gc)
        
        --text selection
        self:drawTextSelection(gc)
        
        --Text
        self:drawVisibleText(gc)
        
        --cursor
        self:drawCursor(gc)
        
        --vinculum
        self:drawVinculumLineAndBox(gc)
    end
    
    self:drawBoundingRectangle(gc)
end

function TextBox:drawTextSelection(gc, x, y)
    local x, y = self.editBox.x+2*self.scaleFactor, self.editBox.y+2*self.scaleFactor - self.scrollY
    local startX, endX = self.selectedTextStartX, self.selectedTextEndX
    local w, h = math.max(0, math.abs(endX - startX)), self.editBox.h-4*self.scaleFactor
   
    if endX < startX then     --selection is from right to left
        startX = math.max( x, endX )
        w = math.max(0, math.abs(self.selectedTextStartX - startX))
    end
   
    if self.maxSelectedTextWidth == true then       --selection moves to hidden characters
        local visibleTextWidth = self.visibleText:calculateWidth(self.scaleFactor)
        w = math.min(visibleTextWidth, self.selectedTextWidth)
    end
     
    if self.hasFocus == true and w > 0 then
        gc:setColorRGB(unpack(self.selectionColor))
        gc:fillRect(startX, y, w, h) 
    end
end

function TextBox:drawVisibleText(gc)
    if self.visibleText.text ~= "" then 
        if self.vinculumBoxIsShown == true and self.cursorpos < self.charCounter then
            --vinculum box is inserted in the visible text; divide the visible text to two parts
            local visibleText1 = string.usub(self.visibleText.text, 1, self.cursorpos)
            local visibleText2 = string.usub(self.visibleText.text, self.cursorpos+1, #self.visibleText.text)
            local boxWidth = 10*self.scaleFactor + 1
            
            gc:drawString(visibleText1, self.visibleText.x, self.visibleText.y - self.scrollY)
            gc:drawString(visibleText2, self.cursorStartXPos + boxWidth, self.visibleText.y - self.scrollY)
        else
            self.visibleText:paint(gc)
        end
    end
end

function TextBox:drawCursor(gc)
    if self.enableTextboxCursor == true and self.showTextboxCursor == true and self.hasFocus == true then
        if self.tracking == false then      --show the blinking cursor when text selection is not currently happening
            gc:setPen(self.pen, "smooth")
            gc:setColorRGB(unpack(self.cursorColor))

            gc:drawLine(self.cursorStartXPos, self.cursorStartYPos - self.scrollY, self.cursorStartXPos, self.cursorEndYPos - self.scrollY)
        end
    end
end

function TextBox:drawVinculumLineAndBox(gc)
    local y, h = self.editBox.y - self.scrollY, self.editBox.h
    local stringHeight = gc:getStringHeight( "0" )
    local yLine = y + h * 0.5 - stringHeight * 0.4
    
    gc:setColorRGB(unpack(self.visibleText.fontColor))
        
    -- vinculum line with box
    if self.vinculumBoxIsShown == true then
        local boxWidth, boxHeight = 10*self.scaleFactor, stringHeight * 0.85
        local yOffset = 3*self.scaleFactor
        local xLine = self.cursorStartXPos - 2*self.scaleFactor
        
        gc:setPen(self.pen, "smooth")
        gc:drawLine( xLine, yLine, xLine + boxWidth, yLine )
        
        gc:setPen(self.pen, "dashed")
        gc:drawRect( xLine, yLine + yOffset, boxWidth, boxHeight - yOffset )
    end
    
    gc:setPen(self.pen, "smooth")
    
    -- start vinculum line
    if self.visibleText.text ~= "" and self.vinculumIdxStart > -1 then
        if self.vinculumIdxStart ~= self.vinculumIdxEnd then
            gc:drawLine( self.vinculumStartX, yLine, self.vinculumEndX, yLine)
        end
    end
end

function TextBox:setUpLabels()
    self.label = SimpleString(self.name.."_label1")
    self.label:setVisible(false)
    self.label.fontStyle = "b"
    
    self.label2 = SimpleString(self.name.."_label2")
    self.label2:setVisible(false)
    self.label2.fontStyle = "b"
    
    self.labelPositionIDs = app.enum({"LEFT", "TOP", "TOPLEFT", "RIGHT"})
    self.labelPosition = self.labelPositionIDs.LEFT
end

function TextBox:setUpEditBox()
    self.editBox = Rectangle(self.name.."_editBox")
    self.editBox.initFillColor = app.graphicsUtilities.Color.white
    self.editBox.fillColor = self.editBox.initFillColor
    self.editBox.borderColor = app.graphicsUtilities.Color.darkgrey
end

function TextBox:setUpBottomLine()
    self.bottomLine = Rectangle(self.name.."_bottomLine")
    self.bottomLine.initFillColor = app.graphicsUtilities.Color.black
    self.bottomLine.fillColor = self.bottomLine.initFillColor
    self.bottomLine.borderColor = app.graphicsUtilities.Color.black
    self.bottomLine:setVisible(false)       --by default, this is hidden; Call TextBox:useBottomLine() to make this visible
end

--w, h is for the box only
function TextBox:setInitSizeAndPosition(w, h, pctx, pcty)
    self.initWidth = w; self.initHeight = h; self.initPctX = pctx; self.initPctY = pcty
    self.nonScaledWidth = self.initWidth; self.nonScaledHeight = self.initHeight
    self.pctx = self.initPctX; self.pcty = self.initPctY
    
    self.editBox:setInitSizeAndPosition(w, h, pctx, pcty)
    self.bottomLine:setInitSizeAndPosition(w, h, pctx, pcty)
end

function TextBox:setPane(panex, paney, panew, paneh, scaleFactor)
    if self.scaleFactor ~= scaleFactor then self.scaleFactorChanged = true else self.scaleFactorChanged = false end
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)
    
    self.label:setPane(panex, paney, panew, paneh, scaleFactor)
    self.label2:setPane(panex, paney, panew, paneh, scaleFactor)
    self.editBox:setPane(panex, paney, panew, paneh, scaleFactor)
    self.bottomLine:setPane(panex, paney, panew, paneh, scaleFactor)
    self.visibleText:setPane(panex, paney, panew, paneh, scaleFactor)
end

--w, h are ignored because the whole width and height of the textbox will be computed based on the label and box sizes
--use setInitBoxSize() to set the size of the box only
function TextBox:setSize(w, h)
    self:invalidate()

    self.label:setSize(w, h)
    self.label2:setSize(w, h)
    if self.scaleFactor > 2 then self.pen = "medium" else self.pen = "thin" end
  
    self.editBox.nonScaledWidth, self.editBox.nonScaledHeight = self.editBox.initWidth, self.editBox.initHeight
    self.bottomLine.nonScaledWidth, self.bottomLine.nonScaledHeight = self.bottomLine.initWidth, self.bottomLine.initHeight
    
    local maxWidth = math.max( self.bottomLine.nonScaledWidth, self.editBox.nonScaledWidth )
    if self.maxWidth < maxWidth then self.maxWidth = maxWidth end         --if maxWidth is not set properly, make sure maxWidth gets the editBox nonScaledWidth
  
    self:updateEditBoxSizeAndVisibleText()
    self:updateBottomLineSizeAndVisibleText()
end

function TextBox:updateEditBoxSizeAndVisibleText()
    --local oldNonScaledWidth, oldNonScaledHeight = self.nonScaledWidth, self.nonScaledHeight
    local oldWidth, oldHeight = self.w, self.h

    self:invalidate()

    w, h = self:updateSizeAndVisibleText()

    self.editBox:setSize(w, self.editBox.nonScaledHeight)  

    --self.nonScaledWidth = self:calculateWidth(1); self.nonScaledHeight = self:calculateHeight(1)
    self.w = self:calculateWidth(self.scaleFactor); self.h = self:calculateHeight(self.scaleFactor)

    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    --notify listeners only if the size is changed; and the change is not caused by changing scale factor only
    --if (oldNonScaledWidth ~= self.nonScaledWidth or oldNonScaledHeight ~= self.nonScaledHeight) and self.scaleFactorChanged == false then
    if (oldWidth ~= self.w or oldHeight ~= self.h) and self.scaleFactorChanged == false then
        self:notifyListeners( app.model.events.EVENT_SIZE_CHANGE, self )
    end

    self.scaleFactorChanged = false
    
    self:invalidate()
end

function TextBox:updateBottomLineSizeAndVisibleText()
    --local oldNonScaledWidth, oldNonScaledHeight = self.nonScaledWidth, self.nonScaledHeight
    local oldWidth, oldHeight = self.w, self.h

    self:invalidate()

    w, h = self:updateSizeAndVisibleText()

    self.bottomLine:setSize(w, self.bottomLine.nonScaledHeight)  

    --self.nonScaledWidth = self:calculateWidth(1); self.nonScaledHeight = self:calculateHeight(1)
    self.w = self:calculateWidth(self.scaleFactor); self.h = self:calculateHeight(self.scaleFactor)

    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    --notify listeners only if the size is changed; and the change is not caused by changing scale factor only
    --if (oldNonScaledWidth ~= self.nonScaledWidth or oldNonScaledHeight ~= self.nonScaledHeight) and self.scaleFactorChanged == false then
    if (oldWidth ~= self.w or oldHeight ~= self.h) and self.scaleFactorChanged == false then
        self:notifyListeners( app.model.events.EVENT_SIZE_CHANGE, self )
    end

    self.scaleFactorChanged = false
    
    self:invalidate()
end

function TextBox:setPosition(pctx, pcty)
    local textStartX
    local pctxTbl, pctyTbl
    local hiddenTextLastIdx = self.visibleStartIdx - 1
 
    pctxTbl, pctyTbl = self:computeLabelAndBoxPosition(pctx, pcty)
    self.label:setPosition(pctxTbl[self.label.name], pctyTbl[self.label.name])
    self.label2:setPosition(pctxTbl[self.label2.name], pctyTbl[self.label2.name])
    self.editBox:setPosition(pctxTbl[self.editBox.name], pctyTbl[self.editBox.name])
    self.bottomLine:setPosition(pctxTbl[self.bottomLine.name], pctyTbl[self.bottomLine.name])

    Widget.setPosition(self, math.min(pctxTbl[self.label.name], pctxTbl[self.editBox.name], pctxTbl[self.bottomLine.name]), math.min(pctyTbl[self.label.name], pctyTbl[self.editBox.name], pctyTbl[self.bottomLine.name]))
    
    self:computeVisibleTextPosition()
    self:updateVinculum()
    self:updateCharXPosTbl()
    self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)
    
    if self.hasGrab == true then            --highlight is enabled
        textStartX = self:getTextStartX()
        
        if #self.charXPos > 1 then 
          self.selectedTextStartX = textStartX + self.charXPos[math.max( 1, math.min(self.selectionStartIdx+1-hiddenTextLastIdx, #self.charXPos) )] 
        else
          self.selectedTextStartX = textStartX
        end
        
        if self.vinculumBoxIsShown == true then self.selectedTextStartX = self.selectedTextStartX + 2*self.scaleFactor end
        
        self.selectedTextEndX = self.cursorStartXPos
        self.selectedTextWidth = self.stringTools:getStringWidth(self.selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
    end
end

function TextBox:computeLabelAndBoxPosition(pctx, pcty)
    local boxWidth, boxHeight = self.editBox.nonScaledWidth * self.scaleFactor, self.editBox.nonScaledHeight * self.scaleFactor
    local labelWidth, labelHeight = self.label:calculateWidth(self.scaleFactor), self.label:calculateHeight(self.scaleFactor)
    local pctxTbl, pctyTbl = {}, {}
    local labelPctx, labelPcty = pctx, pcty
    local label2Pctx, label2Pcty = pctx, pcty
    local editBoxPctx, editBoxPcty = pctx, pcty
    local bottomLinePctx, bottomLinePcty = pctx, pcty
   
    if self.labelPosition == self.labelPositionIDs.TOP then
        labelPctx, labelPcty = pctx + .5*(self.w - labelWidth)/self.panew, pcty
        editBoxPcty = pcty + (labelHeight+1)/self.paneh
        bottomLinePcty = pcty + (labelHeight+1)/self.paneh
    elseif self.labelPosition == self.labelPositionIDs.TOPLEFT then
        labelPctx, labelPcty = pctx, pcty
        editBoxPcty = pcty + (labelHeight+1)/self.paneh
        bottomLinePcty = pcty + (labelHeight+1)/self.paneh
    elseif self.labelPosition == self.labelPositionIDs.RIGHT then
        labelPctx, labelPcty = pctx + boxWidth/self.panew, pcty + (.5*boxHeight - .5*labelHeight)/self.paneh
    else
        local strw = 0
        
        if self.label2.text ~= "" then
            labelPctx, labelPcty = pctx, pcty - 2 / self.paneh
            label2Pctx, label2Pcty = pctx, pcty + 0.75 * labelHeight / self.paneh
            strw = math.max(labelWidth, self.label2:calculateWidth(self.scaleFactor))
            heightOfLabels = labelHeight + 0.75 * labelHeight
            
            if heightOfLabels > boxHeight then
                editBoxPcty = pcty + ( 0.5 * heightOfLabels - 0.5 * boxHeight ) / self.paneh
                bottomLinePcty = pcty + ( 0.5 * heightOfLabels - 0.5 * boxHeight ) / self.paneh
            else
                editBoxPcty = pcty
                bottomLinePcty = pcty
                labelPcty = pcty + ( boxHeight * 0.5 - labelHeight * 0.5 ) / self.paneh
                label2Pcty = labelPcty + labelHeight * 0.75 / self.paneh
            end
            
        else
            labelPctx = pctx
            strw = labelWidth
            
            if labelHeight > boxHeight then
                labelPcty = pcty
                editBoxPcty = pcty + ( 0.5 * labelHeight - 0.5 * boxHeight) / self.paneh
                bottomLinePcty = pcty + ( 0.5 * labelHeight - 0.5 * boxHeight) / self.paneh
            else
                editBoxPcty = pcty
                bottomLinePcty = pcty
                labelPcty = pcty + ( 0.5 * boxHeight - 0.5 * labelHeight) / self.paneh
            end
        end
        
        editBoxPctx = pctx + strw/self.panew
    end
    
    bottomLinePcty = editBoxPcty + ( boxHeight - ( self.bottomLine.nonScaledHeight * self.scaleFactor )) / self.paneh
    bottomLinePctx = editBoxPctx
    
    pctxTbl[self.label.name], pctyTbl[self.label.name] = labelPctx, labelPcty
    pctxTbl[self.label2.name], pctyTbl[self.label2.name] = label2Pctx, label2Pcty
    pctxTbl[self.editBox.name], pctyTbl[self.editBox.name] = editBoxPctx, editBoxPcty
    pctxTbl[self.bottomLine.name], pctyTbl[self.bottomLine.name] = bottomLinePctx, bottomLinePcty
    
    return pctxTbl, pctyTbl
end

function TextBox:computeVisibleTextPosition()
    local visibleTextHeight = self.stringTools:getStringHeight("0", self.visibleText.fontFamily, self.visibleText.fontStyle, self.visibleText.initFontSize*self.scaleFactor)
    local textCenteredY = .5*self.editBox.nonScaledHeight*self.scaleFactor - .5*visibleTextHeight

    self.visibleText:setPosition(self.editBox.pctx + 3*self.scaleFactor/self.panew, self.editBox.pcty + textCenteredY/self.paneh)
end

--update the table of x positions of the characters
function TextBox:updateCharXPosTbl()
    local i, str
    local substrings = {}
    self.charXPos = {}
    
    --put each character in a table; to handle even unicode characters        
    for i=1, #self.visibleText.text do
        local sub = string.usub(self.visibleText.text, i, i)
        
        if sub == "" then 
            break 
        else
            substrings[i] = sub
        end
    end
    
    str = ""
    self.charXPos[1] = 0        --starts at 0
    
    for i=1, #substrings do
        str = str..substrings[i]
        self.charXPos[i+1] = self.stringTools:getStringWidth(str, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
    end
end

--move the cursor position at the end of the new character typed in
--charIdx - the index of the character(in the visible text) to the left of the cursor
function TextBox:moveCursorToCharEnd(charIdx)
    local textStartX = self:getTextStartX()
    local strWidth = 0
    local editBoxY, editBoxH = self.editBox.y, self.editBox.h
    local strHeight = self.stringTools:getStringHeight("0", self.visibleText.fontFamily, self.visibleText.fontStyle, self.visibleText.initFontSize*self.scaleFactor)
    local vinculumIdxStart = self.vinculumIdxStart

    if charIdx ~= nil then
        strWidth = self.charXPos[ math.min(charIdx+1, #self.charXPos) ]         --charXPos[1] is to the left of the first visible char
        self.cursorStartXPos = textStartX + strWidth
    end

    charIdx = charIdx + self.visibleStartIdx - 1        --index of the character including the hidden characters

    if self.isVinculumActive then
        if ( self.vinculumIdxEnd - self.vinculumIdxStart ) == 0 then
            self.cursorStartXPos = textStartX + strWidth + 2*self.scaleFactor
        end
        
        if (charIdx >= vinculumIdxStart and charIdx <= self.vinculumIdxEnd) or self.vinculumBoxIsShown == true then
            self.cursorStartYPos, self.cursorEndYPos = editBoxY + editBoxH * 0.5 - strHeight * 0.4 + 3*self.scaleFactor, editBoxY + editBoxH * 0.5 + strHeight * 0.45
        else
            self.cursorStartYPos, self.cursorEndYPos = editBoxY + 2*self.scaleFactor, editBoxY + editBoxH - 2*self.scaleFactor
        end
    else
        if self.charCounter > 0 and (charIdx >= vinculumIdxStart and charIdx < self.vinculumIdxEnd) then
            self.cursorStartYPos, self.cursorEndYPos = editBoxY + editBoxH * 0.5 - strHeight * 0.4 + 3*self.scaleFactor, editBoxY + editBoxH * 0.5 + strHeight * 0.45
        else
            self.cursorStartYPos, self.cursorEndYPos = editBoxY + 2*self.scaleFactor, editBoxY + editBoxH - 2*self.scaleFactor
        end
    end
    
    self.showTextboxCursor = true
end

--position should be: labelPositionIDs = app.enum({"LEFT", "TOP", "TOPLEFT", "RIGHT"})
function TextBox:setLabelPosition(position)
    self.labelPosition = position
    self:setPosition(self.pctx, self.pcty)
end

function TextBox:clear()
    self:setText("")
end

--clears the text and resets the box w and h to initial values
function TextBox:clearAndReset()
    self.editBox:setSize(self.editBox.initWidth, self.editBox.initHeight)
    self.bottomLine:setSize(self.bottomLine.initWidth, self.bottomLine.initHeight)
    self:clear()
end

function TextBox:contains(x, y)
    local x_overlap, y_overlap = 0, 0
    local xExpanded = x - .5 * self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y - .5 * self.mouse_yheight
    local xBox, yBox = self.editBox.x, self.editBox.y
    local y1 = yBox - self.scrollY

    x_overlap = math.max(0, math.min(xBox+self.editBox.w, xExpanded + self.mouse_xwidth) - math.max(xBox, xExpanded))
    y_overlap = math.max(0, math.min(self.paney+self.paneh, math.min(y1+self.editBox.h, yExpanded + self.mouse_yheight)) - math.max(self.paney, math.max(y1, yExpanded)))

    --If there is an intersecting rectangle, then this point is selected.
    if x_overlap * y_overlap > 0 then
        return 1
    end
    
    return 0
end

function TextBox:setLabel(label, label2)
    self.label:setText(label)
    self.label:setVisible(true) 
    if label2 ~= "" and label2 ~= nil then self.label2:setText(label2); self.label2:setVisible(true) end

    self:setSize(self.editBox.nonScaledWidth, self.editBox.nonScaledHeight)
    self:setSize(self.bottomLine.nonScaledWidth, self.bottomLine.nonScaledHeight)
    self:setPosition(self.pctx, self.pcty)
end

function TextBox:setFocus(b)
    self:invalidate()

    if self.drawFocus == true then self.editBox:setFocus(b) end
    
    if b == true then
        self.hasFocus = true
         
        self.showTextboxCursor = true       --turn on caret
      
        if self.cursorStartXPos ~= nil then 
            self.selectedTextStartX = self.cursorStartXPos
            self.selectedTextEndX = self.cursorStartXPos
        end

        self:showEllipsis()
        local hiddenTextLastIdx = self.visibleStartIdx - 1
        
        if self.prefilled then
            self:moveCursorToFirst()
        else
            self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)
        end
                
        self:notifyListeners( app.model.events.EVENT_GOT_FOCUS, self )
    else
        self.hasFocus = false
        self.selectedTextStartX = self.cursorStartXPos
        self.selectedTextEndX = self.cursorStartXPos
        self.maxSelectedTextWidth = false
        self.selectionStartIdx = self.cursorpos

        self:showEllipsis()
        self:notifyListeners( app.model.events.EVENT_LOST_FOCUS, self )
    end
end

--b is true/false to show/hide ellipsis
function TextBox:showEllipsis()
    if self.charCounter > 0 then
        self:updateEditBoxSizeAndVisibleText()         --ellipsis will be added here
        self:updateCharXPosTbl()
    end
end

function TextBox:setScrollY(y)
    Widget.setScrollY(self, y)
    
    self.label:setScrollY(y)
    self.label2:setScrollY(y)
    self.editBox:setScrollY(y)
    self.bottomLine:setScrollY(y)
    self.visibleText:setScrollY(y)
end

function TextBox:charIn(char)
    if self.active == true and self.visible == true and self.hasFocus == true and self.autocompleteDone == false then       
        self:addChar(char)
         
        self:notifyListeners( app.model.events.EVENT_CHAR_IN, self )
    end
end

--adds the passed in char to the end of the text
function TextBox:addChar(char)
    local changed = false
    local addChar = true
 
    if self.prefilled == true then
        self:clear()    --Remove the prefilled text.
        self:showPrefilledText(false)
    end
    
    if tonumber(char) == nil then
       if self.forceLowercase then char = string.lower(char) end
    end

    --Check to see if the character is the small (on the keyboard) negative sign.
    if char == "−" then
         char = "-"        --Substitute the big (on the keyboard) minus sign.  If you don't do this, string comparisons won't work.
    end

    if self.processCallback ~= nil then char = self.processCallback(char) end       --Pre-process the character.

    if char ~= nil then
        if char ~= "" then
            local numOfCharInput = app.stringTools:getNumOfChars(char)
            
            if (self.maxChar == 1 and self.overrideChar == true) or (self:trim(self.visibleText.text) == "" and numOfCharInput == 1) then 
                self.gapBuffer[1] = char
                self.visibleStartIdx, self.visibleEndIdx = 1, 1
                self.charCounter = 1
                self.cursorpos = 1
                self.spaceIdx = 0
                changed = true
            elseif self.charCounter < self.maxChar then
                local numOfAllowedChar = math.min( self.maxChar - self.charCounter, numOfCharInput )    --number of characters allowed to be added
                if numOfAllowedChar > 0 then char = char:usub(1, numOfAllowedChar) end
              
                if self.allowScroll == false then
                    addChar = self:shouldAddChar(char)      --check if there is enough space in the editBox for the new character
                end

                if addChar == true then   
                    self:insertToGapBuffer(self.cursorpos + 1, char)
                    self.charCounter = math.min( self.charCounter + numOfCharInput, self.maxChar )
    
                    if self.visibleStartIdx == 0 then
                        self.visibleStartIdx = 1
                        self.visibleEndIdx = 1
                    else
                        self.visibleEndIdx = math.min( self.visibleEndIdx + numOfCharInput, self.maxChar )
                    end
                    
                    self.cursorpos = math.min( self.cursorpos + numOfCharInput, self.maxChar )
                   
                    changed = true
                end
            end
        end
        
        if changed == true then
            --Perform autocomplete feature when needed
            self:autoCompleteText(char)
            self:updateEditBoxSizeAndVisibleText()       --update size and visible text
            
            self:updateVinculum()
            self:updateCharXPosTbl()
            local hiddenTextLastIdx = self.visibleStartIdx - 1
            self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)
        end
        
        self.selectionStartIdx = self.cursorpos
        self.selectedTextStartX = self.cursorStartXPos
        self.selectedTextEndX = self.cursorStartXPos
        self.maxSelectedTextWidth = false
       
        self:invalidate()
    end
end

function TextBox:shouldAddChar(char)
    local addChar = false
    local visibleText = ""
    
    if self.visibleStartIdx > 0 and self.visibleEndIdx > 0 then
        visibleText = table.concat( self.gapBuffer, "", self.visibleStartIdx, self.visibleEndIdx )..char
    else
        visibleText = char
    end
    
    local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
    local currentTextWidth = getStringWidth( visibleText, self.visibleText.initFontSize )
    local offset = 7 * self.scaleFactor     --gap from left side of box to text start plus cursor width
    currentTextWidth = math.floor( (currentTextWidth + offset)/self.scaleFactor )
   
    if currentTextWidth <= self.maxWidth then
        addChar = true
    end
    
    return addChar
end

function TextBox:insertToGapBuffer(cursorpos, char)
    local a, idx, lastIdx
    local gapBufferOtherHalf = {}
    local numOfCharInput = app.stringTools:getNumOfChars(char)
    local newCursorPos = cursorpos + numOfCharInput
    
    if self.gapBuffer[cursorpos] ~= nil and self.gapBuffer[cursorpos] ~= "" then
        for i=cursorpos, self.maxChar do
            if self.gapBuffer[i] ~= nil and self.gapBuffer[i] ~= "" then
                table.insert(gapBufferOtherHalf, self.gapBuffer[i])
            end
        end
    end
 
    idx = cursorpos - 1
    lastIdx = idx
    for i=1, numOfCharInput do
       if lastIdx >= self.maxChar then break; end
       lastIdx = idx + i
       self.gapBuffer[lastIdx] = char:usub(i, i) 
    end

    a = newCursorPos
    for i=1, #gapBufferOtherHalf do
        if a > self.maxChar then break; end
        self.gapBuffer[a] = gapBufferOtherHalf[i]
        a = a + 1
    end
end

function TextBox:deleteCharFromGapBuffer(cursorpos)
    local a
    local gapBufferOtherHalf = {}
    
    for i=cursorpos+1, self.charCounter do
        if self.gapBuffer[i] ~= nil and self.gapBuffer[i] ~= "" then
            table.insert(gapBufferOtherHalf, self.gapBuffer[i])
        end
    end
    
    a = math.max( 1, cursorpos )
    for i=1, #gapBufferOtherHalf do
        self.gapBuffer[a] = gapBufferOtherHalf[i]
        a = a + 1
    end
    
    --the remaining buffer should be nil
    for i = a, self.charCounter do
        self.gapBuffer[i] = nil
    end
end

function TextBox:backspaceKey() -- removes characters at the left side of the cursor
    if self.active == true and self.visible == true and self.hasFocus == true then     
        self:invalidate()
        self:removeCharFromCursorPos( self.cursorSideIDs.LEFT )
    end
end

--remove a character from the current cursor position
--returns removed character
function TextBox:removeCharFromCursorPos( p_cursorSide )
    local removedChar = ""
    local cursorpos = self.cursorpos
    if p_cursorSide == nil then p_cursorSide = self.cursorSideIDs.LEFT end -- if parameter p_cursorSide is nil, assign "left" on it to do backspace.
    
    if self.charCounter > 0 then
        if self.vinculumBoxIsShown == true then     --hide the vinculum box first before backspacing on the remaining characters
            self:setVinculumActive(false) 
            self:updateVinculum()
            local hiddenTextLastIdx = self.visibleStartIdx - 1
            self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)    --update cursor x and y positions
        else
            local charIdxToRemove = cursorpos
            local newCursorPos = cursorpos - 1

            if p_cursorSide == self.cursorSideIDs.RIGHT then 
                charIdxToRemove = cursorpos + 1 -- need to remove the character on the right side of the cursor
                newCursorPos = cursorpos -- the cursor position stays
            end

            removedChar = self.gapBuffer[charIdxToRemove]
            if removedChar == nil then removedChar = "" end

            if removedChar ~= "" then
                self:deleteCharFromGapBuffer( charIdxToRemove )
                cursorpos = math.max( newCursorPos, 0 )
                self.visibleEndIdx = self.visibleEndIdx - 1
                self:updateEditBoxSizeAndVisibleText()
                self.charCounter = self.charCounter - 1
                if self.cursorpos <= self.vinculumIdxEnd then self.vinculumIdxEnd = self.vinculumIdxEnd - 1 end     --character removed has vinculum line
                self:setVinculumActive(false)
                self:updateVinculum()
                self:updateCharXPosTbl()
                local hiddenTextLastIdx = self.visibleStartIdx - 1
                self:moveCursorToCharEnd(cursorpos - hiddenTextLastIdx)
                
                self.cursorpos = cursorpos
                self.selectionStartIdx = self.cursorpos
                self.selectedTextStartX = self.cursorStartXPos
                self.selectedTextEndX = self.cursorStartXPos
                self.maxSelectedTextWidth = false
                self.autocompleteDone = false
            end
            
            if removedChar == " " then self.spaceIdx = 0 end
        end
    else
        if self.vinculumBoxIsShown == true then 
            self:setVinculumActive(false)
            local hiddenTextLastIdx = self.visibleStartIdx - 1
            self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)    --update cursor x and y positions
        end
    end
    
    if p_cursorSide == self.cursorSideIDs.RIGHT then self:notifyListeners( app.model.events.EVENT_DELETE, self )
    elseif p_cursorSide == self.cursorSideIDs.LEFT then self:notifyListeners( app.model.events.EVENT_BACKSPACE, self )
    end
  
    return removedChar
end

--returns the character index(of the visible text) to the left of the current cursor position based from the passed in value of cursorStartXPos
--used during text selection
--offsetX - start x position of the text from the box border
--cursorStartXPos - the current x position of the cursor
function TextBox:getCharIdxFromCursor(offsetX, cursorStartXPos)
    if cursorStartXPos > offsetX + self.charXPos[#self.charXPos] then return #self.charXPos - 1 end
    
    local m = 0
    local char1Pos, char2Pos
    
    for i=1, #self.charXPos do
        char1Pos = offsetX + self.charXPos[i]
        char2Pos = offsetX + self.charXPos[ math.min(i+1, #self.charXPos) ]
        
        if cursorStartXPos == char1Pos then
            m = i
            break
        elseif cursorStartXPos > char1Pos and cursorStartXPos < char2Pos then
            if math.abs(cursorStartXPos - char1Pos) < math.abs(char2Pos - cursorStartXPos) then
                m = i
                break
            else
                m = math.min(i+1, #self.charXPos)
                break
            end
        end
    end
    
    return math.max(0, m - 1)
end

function TextBox:enterKey() 
    if self.active == true then
        if self.enterKeyCallback ~= nil then char = self.enterKeyCallback() end     --Allow container to handle the enter key.
    end
end

function TextBox:mouseDown(x, y)
    local retVal = false
    
    if self.active == true and self.visible == true and self.takeMouseEvents == true then 
        local b = self:contains(x, y)
       
        if b == 1 then
            self.tracking = true
            
            if self.hasGrab == true then
                self.xGrabOffset = x - self.x + self.panex
                self.yGrabOffset = y - self.y + self.paney
            end
            
            if self.hasFocus == true then
                self:updateCursorStartPos(x)        --only update the cursor position if the textbox already has focus; user may have clicked on a character 
                self.selectedTextStartX = self.cursorStartXPos
                self.selectedTextEndX = self.cursorStartXPos
                self.selectionStartIdx = self.cursorpos
                self.maxSelectedTextWidth = false
            end
        
            self.xMouseDown, self.yMouseDown = x, y      --keep a copy of the mouse down x and y
            
            self:notifyListeners(app.model.events.EVENT_MOUSE_DOWN, self, x, y)     --Listeners for this event are only notified if this object was under the mouse during mouseDown.

            retVal = true   --Event handled.
        end
        
    end
        
    return retVal, self   --Return whether the event was handled.      
end

function TextBox:mouseUp(x, y)
    if self.active == true and self.visible == true and self.tracking == true and self.prefilled == false then      --when the text is a prefilled text, the cursor should not be able to traverse the text
        self:invalidate() 

        local textStartX = self:getTextStartX()
        local cursorX = x
        if self.mouseDragged == true then cursorX = self.selectedTextEndX end
        local charIdx = self:getCharIdxFromCursor(textStartX, cursorX)

        self:moveCursorToCharEnd(charIdx)       --update cursor position
        
        if self.visibleStartIdx > 1 then
            self.cursorpos = charIdx + (self.visibleStartIdx - 1)
        else
            self.cursorpos = charIdx
        end
        
        --update selected text
        local startIdx, endIdx = self.selectionStartIdx+1, self.cursorpos
  
        if self.selectionStartIdx > self.cursorpos then 
            startIdx, endIdx = self.cursorpos+1, self.selectionStartIdx
        end
        
        self.selectedText = table.concat(self.gapBuffer, "", startIdx, endIdx)    
        self.selectedTextWidth = self.stringTools:getStringWidth(self.selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor) 

        self:invalidate() 
        
        
    end
    
    self:notifyListeners(app.model.events.EVENT_MOUSE_UP, self, x, y)     --Listeners for this event are only notified if this object was under the mouse during mouseDown.
    self.tracking = false
    
    return true
end

function TextBox:mouseMove(x, y)
    --for now, the textbox is not draggable to give way to selecting text
    --Widget.mouseMove( self, x, y )
    
    if self.visible == false or self.active == false then
        return false, nil      --mouse move events should not be handled when the widget is not visible or not active
    end

    --web: mouseMove() is always called in between mouseDown() and mouseUp() even if the mouse pointer did not move; to identify this, we check the value of x and y 
    if self.xMouseDown == x and self.yMouseDown == y then return false, nil end
    self.mouseDragged = false

    if self.hasGrab == true and self.tracking == true and self.visibleText.text ~= "" then
        local textStartX = self:getTextStartX()
        local visibleTextWidth = self.visibleText:calculateWidth(self.scaleFactor)
        local charIdx = self:getCharIdxFromCursor(textStartX, x)       --get the character index(start position of a character) to the left of the current mouse pointer position
        local visibleTextEndX = textStartX+visibleTextWidth
        local selectedText
        
        self.mouseDragged = true

        if self.selectedTextStartX <= x then        --increment the charIdx only when the selection goes from left to right
            charIdx = charIdx+1     --charIdx starts at zero(start of text); since this will be used as index to charXPos table, we need to add one
        end
        charIdx = math.max( 1, charIdx )
        
        self.selectedTextEndX = math.min(visibleTextEndX, textStartX+self.charXPos[ math.min(charIdx, #self.charXPos) ])    
        self:setVinculumActive(false)       --deactivate vinculum during text selection
        
        if self.visibleEndIdx < self.charCounter and x > visibleTextEndX and self.cursorpos < self.charCounter then     --the selection is past the visible text to the right
            self:updateVisibleTextToTheRight()
            selectedText = table.concat(self.gapBuffer, "", self.selectionStartIdx+1, self.cursorpos)
            self.maxSelectedTextWidth = true
            self.selectedTextWidth = self.stringTools:getStringWidth(selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
            
            local startIdx = string.find(self.visibleText.text, selectedText, 1, true)
                            
            if startIdx == nil and #selectedText > 0 then       --the selected text is no longer found in the visible text, this means that the visible text has updated
                self.selectedTextStartX = textStartX 
            elseif startIdx ~= nil then
                self.selectedTextStartX = textStartX + self.charXPos[startIdx]
            end 
        elseif (self.visibleStartIdx > 1 or self.visibleEndIdx < self.charCounter) and x < textStartX then          --the selection is past the visible text to the left
            local cursorpos = math.max(1, self.cursorpos)       --will be used as index to table so it cannot accept zero value
            self.maxSelectedTextWidth = true
            self:updateVisibleTextToTheLeft()
            selectedText = table.concat(self.gapBuffer, "", cursorpos, self.selectionStartIdx)
            self.selectedTextWidth = self.stringTools:getStringWidth(selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor) 
            local startIdx = string.find(self.visibleText.text, selectedText, 1, true)
                                        
            if startIdx ~= nil then
                self.selectedTextStartX = textStartX + self.stringTools:getStringWidth(selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
            end 
        else
            self.maxSelectedTextWidth = false
        end

        self:invalidate()
    end
     
    --returns true if mouse pointer is inside the widget bounding box; otherwise, false
    if self:contains(x, y) == 1 then
        return true, self
    else
        return false, self
    end
end

--x is the mouse pointer x position
function TextBox:updateCursorStartPos(x)
    local textStartX = self:getTextStartX()
    
    if x >= textStartX and self.visibleText.text ~= "" then
        local charIdx = self:getCharIdxFromCursor(textStartX, x)
     
        self:moveCursorToCharEnd(charIdx)
       
        if self.visibleStartIdx > 1 then
            self.cursorpos = charIdx + (self.visibleStartIdx - 1)
        else
            self.cursorpos = charIdx
        end
        
        self.showTextboxCursor = true
    end
    
end

--Changes the value of text if the user enters a shortcut set in self.autocomplete
--E.g. self.autocomplete = {"f", "feet"}; user enters "f", text will be set automatically to "feet"
function TextBox:autoCompleteText(char)
    local num = ""
    local text = char
    local found = false
 
    if self.active == true and self.hasFocus == true then 
        if self.autocomplete ~= nil then
            if char == " " then self.spaceIdx = self.cursorpos; return end
         
            if self.spaceIdx > 0 then
                num = table.concat(self.gapBuffer, "", 1, self.spaceIdx-1)
                text = table.concat(self.gapBuffer, "", self.spaceIdx+1, self.charCounter)
            end  
          
            for i=1,#self.autocomplete do
                if string.lower(text) == self.autocomplete[i][1] and #self.gapBuffer == #self.autocomplete[i][1] then -- we need to check if the gap buffer has exact number of the chars on the autocomplete testing to make sure that there's nothing else on the textbox.
                    if self.usePlurality then
                        if self.autocomplete[i][3] ~= nil and tonumber(num) == nil then        --value is not a number, use the plural form
                            text = self.autocomplete[i][3]
                            found = true
                        elseif self.autocomplete[i][3] ~= nil and tonumber(num) > 1 then       --value is > 1, use the plural form
                            text = self.autocomplete[i][3]
                            found = true
                        else
                            text = self.autocomplete[i][2]     --singular form
                            found = true
                        end
                    else
                        text = self.autocomplete[i][2]
                        found = true
                    end
                    
                    self.autocompleteDone = true
                    if found == true then break end
                end
            end
                
            if found == true then 
                local a = 1
                local startIdx = self.spaceIdx
            
                if startIdx == 0 then          --no space found; use the current cursor
                    startIdx = self.cursorpos - 1
                end
            
                for i=startIdx+1, self.maxChar do
                    local c = string.usub(text, a, a)
                    
                    if c == nil or c == "" then 
                        c = ""
                    else
                        a = a + 1 
                    end
                    
                    self.gapBuffer[i] = c
                end
                
                self.charCounter = startIdx + a - 1
                if self.allowScroll == true then self.visibleStartIdx = self.charCounter else self.visibleStartIdx = 1 end
                self.visibleEndIdx = self.charCounter
                self.cursorpos = self.charCounter
            end
        end
    end
end

--Show/Hide the blinking caret for textbox that has focus and active
function TextBox:handleTimer()
    if self.active == true and self.hasFocus == true then
        self.timer_count = self.timer_count + 1
        if self.timer_count > self.blinkSpeed then
            self.timer_count = 0
            self.showTextboxCursor = not(self.showTextboxCursor)
            self:invalidate()
        end
    end
end

--Pre-process a typed character.
function TextBox:setProcessCallback(fn)
    self.processCallback = fn
end

--Process an ENTER key.
function TextBox:setEnterKeyCallback(cf)
    self.enterKeyCallback = cf
end

function TextBox:setVinculumActive( b )
    self.isVinculumActive = b
    self.vinculumBoxIsShown = b
    
    self:invalidate()
    
    if self.isVinculumActive then
        self.vinculumStartX = self.visibleText.x
        self.vinculumEndX = self.vinculumStartX
        self.vinculumIdxStart = self.cursorpos  
        self.vinculumIdxEnd = self.cursorpos   
        self.vinculumToRemoveBox = false
        
        if ( self.vinculumIdxEnd - self.vinculumIdxStart ) == 0 and self.charCounter < self.maxChar and self.vinculumToRemoveBox == false then
            self.vinculumBoxIsShown = true
        end
    end
  
    self:invalidate()
end

function TextBox:updateVinculum()
    local strIdxWidth = self.charCounter
    
    self.vinculumBoxIsShown = false

    if self.isVinculumActive then
    
        if self.vinculumIdxStart >= strIdxWidth then
            -- reset everything.
            self.vinculumStartX = self.visibleText.x
            self.vinculumEndX = self.vinculumStartX
            self.vinculumIdxStart = strIdxWidth
            self.vinculumIdxEnd = strIdxWidth
        else
            self.vinculumIdxEnd = self.cursorpos
        end
        
        if ( self.vinculumIdxEnd - self.vinculumIdxStart ) ~= 0 and self.vinculumBoxIsShown == true then
            self.vinculumToRemoveBox = true
        elseif ( self.vinculumIdxEnd - self.vinculumIdxStart ) == 0 and self.vinculumToRemoveBox then
            if self.vinculumUICallback ~= nil then self.vinculumUICallback() end
        end
        
        if ( self.vinculumIdxEnd - self.vinculumIdxStart ) == 0 and self.charCounter < self.maxChar and self.vinculumToRemoveBox == false then
            self.vinculumBoxIsShown = true
        end
    else
        if strIdxWidth == 0 then
            self.vinculumIdxStart = strIdxWidth
            self.vinculumIdxEnd = strIdxWidth
        elseif strIdxWidth <= self.vinculumIdxStart then
            self.vinculumIdxStart = -1
            self.vinculumIdxEnd = 0
        end
    end
   
    self:computeVinculumStartAndEndX()
end

function TextBox:computeVinculumStartAndEndX()
    if self.vinculumIdxStart > -1 then
        local getStringWidth = function( str ) return self.stringTools:getStringWidth( str, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor ) end
        local vinculumIdxStart, vinculumIdxEnd = self.vinculumIdxStart+1, math.min(self.vinculumIdxEnd, self.visibleEndIdx)
        
        if self.visibleStartIdx > 1 and vinculumIdxStart <= self.visibleStartIdx then        --there are hidden characters and vinculum start is now hidden because the text is scrolled to the right
            vinculumIdxStart = math.max(vinculumIdxStart, self.visibleStartIdx) 
        end
        self.strVinculum = table.concat(self.gapBuffer, "", vinculumIdxStart, vinculumIdxEnd)
        
        self.strNoVinculum = ""
        if self.vinculumIdxStart > 0 and vinculumIdxStart > self.visibleStartIdx then   --get text with no vinculum because it is still visible
            self.strNoVinculum = table.concat(self.gapBuffer, "", math.max(1, self.visibleStartIdx), vinculumIdxStart-1) 
        end
        
        self.vinculumStartX = self.visibleText.x + getStringWidth( self.strNoVinculum )
        self.vinculumEndX = self.vinculumStartX + getStringWidth( self.strVinculum )   
    end
end

function TextBox:updateSizeAndVisibleText()
    local newWidth, newHeight = self.editBox.nonScaledWidth, self.editBox.nonScaledHeight
    local visibleText = ""
    local maxWidth = self.maxWidth
  
    if self.visibleStartIdx > 0 and self.visibleEndIdx > 0 then
        visibleText = table.concat( self.gapBuffer, "", self.visibleStartIdx, self.visibleEndIdx )
    end

    if self.charCounter > 0 then
        local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
        local currentTextWidth = getStringWidth( visibleText, self.visibleText.initFontSize )
        local offset = 7 * self.scaleFactor     --gap from left side of box to text start plus cursor width
        newWidth = math.max(( currentTextWidth + offset ), self.minWidth * self.scaleFactor  )
        newWidth = newWidth / self.scaleFactor
        if self.isDynamicWidth == false then maxWidth = self.editBox.nonScaledWidth end

        if maxWidth > 0 then
            if self.vinculumBoxIsShown == true then newWidth = newWidth + 11 end        --vinculum box width is 11
            visibleText = self:adjustVisibleText(self.hasFocus, newWidth, visibleText, maxWidth)
        
            newWidth = (getStringWidth(visibleText, self.visibleText.initFontSize) + offset)/self.scaleFactor   --recompute the width of the textbox
            newWidth = math.min(maxWidth, newWidth)        --make sure the width does not go over the max width
            newWidth = math.max(self.minWidth, newWidth)        --make sure the width does not go shorter than the min width
            
            self.visibleText:setText(visibleText)       --will also set the size of the SimpleString
        end
    end
    
    if self.isDynamicWidth == false then
        newWidth, newHeight = self.editBox.nonScaledWidth, self.editBox.nonScaledHeight         --size should not change when box is not dynamic
    end
    
    return newWidth, newHeight
end

function TextBox:resizeFont(newWidth, visibleText)
    if self.toResizeFont == true then
      local fontSize = self.visibleText.initFontSize
      local shouldResize = true
      local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
      local offset = 7 * self.scaleFactor     --gap from left side of box to text start plus cursor width
      
      while shouldResize do
        fontSize = fontSize - 1
        if fontSize < 7 then fontSize = 7 end       --7 is the smallest possible font size on calculator
        if newWidth * self.scaleFactor > getStringWidth( visibleText, fontSize ) + offset or fontSize >= 7 then
          self.visibleText.initFontSize = fontSize
          shouldResize = false
        end
      end
    end
end

function TextBox:adjustVisibleText(hasFocus, newWidth, visibleText, maxWidth)
    if hasFocus == false then   --no focus, show ellipsis when needed
        visibleText = self:adjustVisibleTextWithoutFocus(newWidth, visibleText, maxWidth)
    else
        visibleText = self:adjustVisibleTextWithFocus(newWidth, visibleText, maxWidth)
    end
    
    return visibleText
end

function TextBox:adjustVisibleTextWithFocus(newWidth, visibleText, maxWidth)
    if maxWidth < newWidth then           --visible text is longer than maxWidth
        --resize font
        self:resizeFont(newWidth, visibleText)
        
        --fit the visible text in the box
        if self.allowScroll == true then
            if self.cursorpos >= self.visibleEndIdx then
                self:adjustVisibleTextStart(maxWidth)
            else
                self:adjustVisibleTextEnd(maxWidth)
            end
            
            visibleText = table.concat( self.gapBuffer, "", self.visibleStartIdx, self.visibleEndIdx )
        end
    else
        --show hidden characters that will fit in the textbox
       -- if self.allowScroll == true then
            if self.gapBuffer[self.visibleEndIdx+1] ~= nil and self.gapBuffer[self.visibleEndIdx+1] ~= "" then
                self:adjustVisibleTextEnd(maxWidth)
            else
                self:adjustVisibleTextStart(maxWidth)
            end
            
            visibleText = table.concat( self.gapBuffer, "", self.visibleStartIdx, self.visibleEndIdx )
       -- end
    end
    
    return visibleText
end

function TextBox:adjustVisibleTextWithoutFocus(newWidth, visibleText, maxWidth)
    local charToAdd = ""
    local charCounter = self.charCounter

    if maxWidth < newWidth then           --visible text is longer than maxWidth
        --resize font
        self:resizeFont(newWidth, visibleText)
    end
 
    if self.allowScroll == true then
        local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
        local offset = 7 * self.scaleFactor     --gap from left side of box to text start plus cursor width
        if self.gapBuffer[charCounter] == nil or self.gapBuffer[charCounter] == "" then charCounter = charCounter - 1 end
        visibleText = table.concat(self.gapBuffer, "", 1, charCounter) 
        if maxWidth * self.scaleFactor < getStringWidth( visibleText, self.visibleText.initFontSize ) + offset then charToAdd = app.charEllipsis end
                    
        for a = 1, charCounter do
          if maxWidth * self.scaleFactor > getStringWidth( charToAdd..visibleText:usub(a,#visibleText), self.visibleText.initFontSize ) + offset then
            visibleText = visibleText:usub(a,#visibleText)
            break
          end
        end    
       
        visibleText = charToAdd..visibleText      --add ellipsis when part of the text is hidden
     end
    
    return visibleText
end

function TextBox:adjustVisibleTextStart(maxWidth)
    local i
    local vs = self.visibleStartIdx
    local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
    local visibleText = ""
    local vinculumBoxWidth = 0
    if self.vinculumBoxIsShown == true then vinculumBoxWidth = 10 * self.scaleFactor + 1 end
    local offset = 7 * self.scaleFactor + vinculumBoxWidth    --gap from left side of box to text start plus cursor width + vinculumBoxWidth

    for i = self.visibleEndIdx, 1, -1 do
        visibleText = self.gapBuffer[i]..visibleText
        
        if getStringWidth( visibleText, self.visibleText.initFontSize ) + offset <= maxWidth * self.scaleFactor then
            vs = i
        else
            break
        end
    end
    
    self.visibleStartIdx = vs
end

function TextBox:adjustVisibleTextEnd(maxWidth)
    local i
    local ve = self.visibleEndIdx
    local getStringWidth = function( string, fontSize ) return self.stringTools:getStringWidth( string, "sansserif", "r", fontSize * self.scaleFactor) end -- get string width using string tools
    local visibleText = ""
    local vinculumBoxWidth = 0
    if self.vinculumBoxIsShown == true then vinculumBoxWidth = 10 * self.scaleFactor + 1 end
    local offset = 7 * self.scaleFactor + vinculumBoxWidth      --gap from left side of box to text start plus cursor width + vinculumBoxWidth
    
    for i = self.visibleStartIdx, self.charCounter do
        if self.gapBuffer[i] ~= nil and self.gapBuffer[i] ~= "" then
            visibleText = visibleText..self.gapBuffer[i]
            
            if getStringWidth( visibleText, self.visibleText.initFontSize ) + offset <= maxWidth * self.scaleFactor then
                ve = i
            end 
        else
            break                       
        end
    end
    
    self.visibleEndIdx = ve
    
    --we've reached the end of the text but there is still available space, check if there are hidden characters on the left side
    if self.gapBuffer[self.charCounter+1] == nil or self.gapBuffer[self.charCounter+1] == "" then
        visibleText = table.concat(self.gapBuffer, "", self.visibleStartIdx, ve)
        if getStringWidth( visibleText, self.visibleText.initFontSize ) + offset < maxWidth * self.scaleFactor then
            self:adjustVisibleTextStart(maxWidth)
        end
    end
end

--use only for setting the whole text directly when the textbox doesn't have focus
--!!!use TextBox:addChar() if only one character will be added to the end of the text
function TextBox:setText( text )
    local textStartX = self:getTextStartX()
    local newGapBuffer = {}
    local i
    local lastIdx = math.min(#text, self.maxChar)       --number of characters should not exceed the maxChar allowed
    
    for i=1, lastIdx do
        newGapBuffer[i] = string.usub(text, i, i)
    end
    
    self.gapBuffer = newGapBuffer
    self.visibleStartIdx = 1
    self.visibleEndIdx = lastIdx
    self.charCounter = lastIdx
    self.cursorpos = self.visibleEndIdx
    
    if self.charCounter == 0 then
        self.visibleText.text = ""
        self.editBox:setSize(self.editBox.nonScaledWidth, self.editBox.nonScaledHeight) 
        self.bottomLine:setSize(self.bottomLine.nonScaledWidth, self.bottomLine.nonScaledHeight) 
    else
        self:updateEditBoxSizeAndVisibleText()
    end

    self:updateCharXPosTbl()   

    self.cursorStartXPos = textStartX + self.visibleText:calculateWidth(self.scaleFactor)
    self.selectedTextStartX = self.cursorStartXPos
    self.selectedTextEndX = self.cursorStartXPos
    self.selectionStartIdx = self.cursorpos
    self.maxSelectedTextWidth = false
end

function TextBox:changeTextboxColor( tblTextboxColorRGB )
    self.editBox.fillColor = tblTextboxColorRGB
    self:invalidate()
end

function TextBox:arrowRight() 
    if self.visible == true and self.active == true and self.hasFocus == true and self.prefilled == false then
        self:updateVisibleTextToTheRight()
        self.selectionStartIdx = self.cursorpos
        self:setVinculumActive(false)
        self:updateVinculum()
        
        --remove selection only if the selection is not ongoing
        if self.tracking == false then
            self.selectedTextStartX = self.cursorStartXPos
            self.selectedTextEndX = self.cursorStartXPos
            self.maxSelectedTextWidth = false
        end
        
        --if self.vinculumBoxIsShown == true then self:setVinculumActive(false) end
        local hiddenTextLastIdx = self.visibleStartIdx - 1
        self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)    --update cursor x and y positions
        
        self:notifyListeners( app.model.events.EVENT_ARROW_RIGHT, self )
        
        self:invalidate()
        
        return true
    end
    
    return false
end

function TextBox:arrowLeft() 
    if self.visible == true and self.active == true and self.hasFocus == true and self.prefilled == false then
        self:updateVisibleTextToTheLeft()
        self.selectionStartIdx = self.cursorpos
        self:setVinculumActive(false)
        self:updateVinculum()
        
        --remove selection only if the selection is not ongoing
        if self.tracking == false then
            self.selectedTextStartX = self.cursorStartXPos
            self.selectedTextEndX = self.cursorStartXPos
            self.maxSelectedTextWidth = false
        end
        
        --if self.vinculumBoxIsShown == true then self:setVinculumActive(false) end
        local hiddenTextLastIdx = self.visibleStartIdx - 1
        self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)    --update cursor x and y positions
        
        self:notifyListeners( app.model.events.EVENT_ARROW_LEFT, self )
        
        self:invalidate()
        
        return true
    end
    
    return false
end

--when the cursor moves to the right, the visible text gets updated
function TextBox:updateVisibleTextToTheRight()
    if self.cursorpos < self.charCounter then 
        if self.cursorpos > self.visibleEndIdx - 1 then           --update the visible text to the right only when the cursor reaches the end of the visible text
            self.visibleEndIdx = self.visibleEndIdx + 1 
            self.cursorpos = math.min(self.cursorpos + 1, self.charCounter)
            self:updateEditBoxSizeAndVisibleText()
            self:updateCharXPosTbl()
        else
            self.cursorpos = math.min(self.cursorpos + 1, self.charCounter)
        end
        
        local hiddenTextLastIdx = self.visibleStartIdx - 1
        self:moveCursorToCharEnd(self.cursorpos - hiddenTextLastIdx)
    end
end

function TextBox:updateVisibleTextToTheLeft()
    if self.cursorpos > 0 then 
        if self.cursorpos < self.visibleStartIdx then           --update the visible text to the left only when the cursor reaches the start of the visible text
            self.visibleStartIdx = self.visibleStartIdx - 1 
            self.cursorpos = math.max(0, self.cursorpos - 1)
            self:updateEditBoxSizeAndVisibleText()
            self:updateCharXPosTbl()
        else
            self.cursorpos = math.max(0, self.cursorpos - 1)
        end
        
        local hiddenTextLastIdx = self.visibleStartIdx - 1
        self:moveCursorToCharEnd( self.cursorpos - hiddenTextLastIdx )
    end
end

function TextBox:getTextStartX()
    local textStartX = self.visibleText.x 
    
    return textStartX
end

--cut, copy, paste - true/false to enable/disable
function TextBox:setToolpaletteValues(cut, copy, paste)
    toolpalette.enableCut(cut)
    toolpalette.enableCopy(copy)
    toolpalette.enablePaste(paste)
end

function TextBox:cut()
    if self.active == true and self.visible == true and self.hasFocus == true then
        clipboard.addText(self.selectedText)
        local oldText = self:getText()
        local newText = ""
        local selectionIsToTheLeft = self.selectedTextStartX > self.selectedTextEndX
        local oldSelectionStartIdx = self.selectionStartIdx
        local oldCharCounter = self.charCounter
    
        newText = string.gsub(oldText, self.selectedText, "", 1)      --limit to one substitution of pattern occurrence
        self.selectedTextStartX = self.cursorStartXPos
        self.selectedTextEndX = self.cursorStartXPos
        self:setText(newText)
    
        if selectionIsToTheLeft == true then
            local numOfRemovedChars = oldCharCounter - self.charCounter
            self.cursorpos = oldSelectionStartIdx - numOfRemovedChars
        else
            self.cursorpos = math.min(oldSelectionStartIdx, self.charCounter)
        end
    
        self.selectionStartIdx = self.cursorpos 
        self:moveCursorToCharEnd(self.cursorpos)
   end
end

function TextBox:copy()
    if self.active == true and self.visible == true and self.hasFocus == true then
        clipboard.addText(self.selectedText)
    end
end

function TextBox:paste()
    if self.active == true and self.visible == true and self.hasFocus == true then 
        local str = clipboard.getText()
        
        if self.prefilled == true then
            self:clear()    --Remove the prefilled text.
            self:showPrefilledText(false)
        end
    
        if str ~= nil and str ~= "" and self.charCounter < self.maxChar then
            local newText = ""
            local selectionStartIdx, cursorpos = self.selectionStartIdx, self.cursorpos
            local numOfPastedChars = self.stringTools:getNumOfChars(str)
            local oldVisibleStartIdx = self.visibleStartIdx
       
            if self.selectedTextStartX ~= self.selectedTextEndX then        --there is a highlighted text
                local prefix, postfix = "", ""
                
                if cursorpos < selectionStartIdx then selectionStartIdx, cursorpos = cursorpos, selectionStartIdx end
                
                if selectionStartIdx > 0 then
                    prefix = table.concat(self.gapBuffer, "", 1, selectionStartIdx)
                end
                
                if cursorpos < self.charCounter then
                    postfix = table.concat(self.gapBuffer, "", cursorpos+1, self.charCounter)
                end
                
                newText = prefix..str..postfix
                cursorpos = selectionStartIdx
            else
                if cursorpos == 0 then
                    newText = str..self:getText()
                else
                    newText = table.concat(self.gapBuffer, "", 1, cursorpos)..str..table.concat(self.gapBuffer, "", cursorpos+1, self.charCounter)
                end
            end
            
            self:setText(newText)           --cursorpos here is always at the end of the whole text
            self.cursorpos = math.min(cursorpos + numOfPastedChars, self.charCounter)       --supposed cursorpos
           
            --make sure that the cursor position is showing in the visible text
            if self.cursorpos < self.visibleEndIdx then
                self.visibleStartIdx = oldVisibleStartIdx
                self.visibleEndIdx = self.cursorpos
                self:updateEditBoxSizeAndVisibleText()
                self:updateCharXPosTbl()
            end
            
            self.selectionStartIdx = self.cursorpos 
            self:moveCursorToCharEnd( self.cursorpos - (self.visibleStartIdx - 1) )
        
            self:invalidate()
        end
   end
end

--for web
function TextBox:shiftArrowRight()
    if self.active == true and self.visible == true and self.hasFocus == true then 
        if self.visibleText.text ~= "" then
            local selectedText
            local textStartX = self:getTextStartX()
            local visibleTextWidth = self.visibleText:calculateWidth(self.scaleFactor)
            local charIdx = self.cursorpos - (self.visibleStartIdx - 1)       --get the character index(start position of a character) to the left of the current mouse pointer position
    
            if self.visibleStartIdx > 1 or self.visibleEndIdx < self.charCounter then       --there are hidden characters
                if charIdx == #self.visibleText.text and self.cursorpos < self.charCounter then     --the selection is past the visible text to the right
                    self:updateVisibleTextToTheRight()
                    self.maxSelectedTextWidth = true
                    selectedText = table.concat(self.gapBuffer, "", self.selectionStartIdx+1, self.cursorpos)
                    self.selectedTextWidth = self.stringTools:getStringWidth(selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
                    local startIdx = string.find(self.visibleText.text, selectedText, 1, true)
                    
                    if startIdx == nil and #selectedText > 0 then       --the selected text is no longer found in the visible text, this means that the visible text has updated
                        self.selectedTextStartX = textStartX 
                    elseif startIdx ~= nil then
                        self.selectedTextStartX = textStartX + self.charXPos[startIdx]
                    end
                else
                    self.maxSelectedTextWidth = false
                    charIdx = math.min(charIdx + 2, #self.charXPos)
                    self.selectedTextEndX = textStartX+self.charXPos[ charIdx ]
                    self.cursorpos = math.min(self.cursorpos + 1, self.charCounter)
                    self:moveCursorToCharEnd(charIdx - 1)
                end
            else
                charIdx = math.min(charIdx + 2, #self.charXPos)
                self.selectedTextEndX = textStartX+self.charXPos[ charIdx ]
                self.cursorpos = math.min(self.cursorpos + 1, self.charCounter)
                self:moveCursorToCharEnd(charIdx - 1)
            end
        
            --update selected text
            local startIdx, endIdx = self.selectionStartIdx+1, self.cursorpos
            self.selectedText = table.concat(self.gapBuffer, "", startIdx, endIdx)
            self:invalidate()
        end
   end
end

--for web
function TextBox:shiftArrowLeft()
    if self.active == true and self.visible == true and self.hasFocus == true then 
        if self.visibleText.text ~= "" then
            local selectedText
            local textStartX = self:getTextStartX()
            local visibleTextWidth = self.visibleText:calculateWidth(self.scaleFactor)
            local charIdx = self.cursorpos - (self.visibleStartIdx - 1)       --get the character index(start position of a character) to the left of the current mouse pointer position
           
            if self.visibleStartIdx > 1 or self.visibleEndIdx < self.charCounter then       --there are hidden characters
                if charIdx == 0 then          --the selection is past the visible text to the left
                    self.maxSelectedTextWidth = true
                    self:updateVisibleTextToTheLeft()
                    selectedText = table.concat(self.gapBuffer, "", self.cursorpos, self.selectionStartIdx)
                    self.selectedTextWidth = self.stringTools:getStringWidth(selectedText, "sansserif", "r", self.visibleText.initFontSize*self.scaleFactor)
                else
                    self.maxSelectedTextWidth = false
                    charIdx = math.max(1, charIdx)
                    self.selectedTextEndX = textStartX+self.charXPos[ charIdx ]
                    self.cursorpos = math.max(0, self.cursorpos - 1)
                    self:moveCursorToCharEnd(charIdx - 1)
                end
            else
                charIdx = math.max(1, charIdx)
                self.selectedTextEndX = textStartX+self.charXPos[ charIdx ]
                self.cursorpos = math.max(0, self.cursorpos - 1)
                self:moveCursorToCharEnd(self.cursorpos)
            end
            
            --update selected text
            local startIdx, endIdx = self.cursorpos+1, self.selectionStartIdx
            self.selectedText = table.concat(self.gapBuffer, "", startIdx, endIdx)
            self:invalidate()
        end
   end
end

--for web
function TextBox:homeKey()
    if self.active == true and self.visible == true and self.hasFocus == true then  
        self:moveCursorToFirst()
    end
end

--for web
function TextBox:endKey()
    if self.active == true and self.visible == true and self.hasFocus == true then  
        local textStartX = self:getTextStartX()
        
        self.cursorStartXPos = textStartX + self.visibleText:calculateWidth(self.scaleFactor)
        self.cursorpos = self.charCounter
        
        --there are hidden characters
        if self.visibleStartIdx > 1 or self.visibleEndIdx < self.charCounter then
            self.visibleStartIdx = self.cursorpos
            self.visibleEndIdx = self.cursorpos
            self:updateEditBoxSizeAndVisibleText()
            self:updateCharXPosTbl()
        end
        
        self:moveCursorToCharEnd(self.cursorpos)
        
        self:invalidate()
    end
end

--returns the whole text including hidden characters
function TextBox:getText()
    return table.concat(self.gapBuffer, "", 1, self.charCounter)
end

--set label font attributes
function TextBox:setInitFontAttributes(fontFamily, fontStyle, fontSize)
    Widget.setInitFontAttributes(self, fontFamily, fontStyle, fontSize)
    
    self.label:setInitFontAttributes(fontFamily, fontStyle, fontSize)
    self.label2:setInitFontAttributes(fontFamily, fontStyle, fontSize)
end

--set visible text font size
function TextBox:setTextFontSize(fontSize)
    self.visibleText.initFontSize = fontSize
end

function TextBox:showPrefilledText(b)
    self.prefilled = b
    
    if b == true then
        self.visibleText.fontColor = self.preFillColor
    else
        self.visibleText.fontColor = self.fontColor
    end
end

--returns the pctx and pcty of the label and box based from the passed in pctx and pcty
function TextBox:calculateChildPositions( pctx, pcty )
    local childPctxTbl, childPctyTbl = {}, {}
    childPctxTbl, childPctyTbl = self:computeLabelAndBoxPosition(pctx, pcty)
    
    return childPctxTbl, childPctyTbl
end

--w, h are the box sizes
function TextBox:setInitBoxSize(w, h)
    self.editBox.initWidth, self.editBox.initHeight = w, h
end

--w, h are the box sizes
function TextBox:setInitBottomLineSize(w, h)
    self.bottomLine.initWidth, self.bottomLine.initHeight = w, h
end

function TextBox:calculateWidth(scaleFactor)
    local w
    local maxNonScaledLabelWidth = math.max(self.label:calculateWidth(scaleFactor), self.label2:calculateWidth(scaleFactor))
    
    if self.labelPosition == self.labelPositionIDs.TOP or self.labelPosition == self.labelPositionIDs.TOPLEFT then
        w = math.max(maxNonScaledLabelWidth, self.editBox.nonScaledWidth * scaleFactor, self.bottomLine.nonScaledWidth * scaleFactor)
    else
        w = maxNonScaledLabelWidth + math.max( self.editBox.nonScaledWidth, self.bottomLine.nonScaledWidth ) * scaleFactor
    end
    
    return w
end

function TextBox:calculateHeight(scaleFactor)
    local h
    local label1Height = self.label:calculateHeight(scaleFactor)
    local label2Height = 0
    if self.label2.text ~= "" then label2Height = .75 * self.label2:calculateHeight(scaleFactor) end
    
    if self.labelPosition == self.labelPositionIDs.TOP or self.labelPosition == self.labelPositionIDs.TOPLEFT then
        h = label1Height + label2Height + self.editBox.nonScaledHeight * scaleFactor
    else
        h = math.max(label1Height + label2Height, self.editBox.nonScaledHeight * scaleFactor)
    end
    
    return h
end

function TextBox:deleteKey() -- delete key removes character to the right of cursor
    if self.active == true and self.visible == true and self.hasFocus == true and self.prefilled == false then     
        self:invalidate()
        self:removeCharFromCursorPos( self.cursorSideIDs.RIGHT )
    end
end

function TextBox:getEditBox() 
    return self.editBox
end

function TextBox:getBottomLine() 
    return self.bottomLine
end

function TextBox:setShowTextboxCursor( b )
    self.showTextboxCursor = b
    self:invalidate()
end

function TextBox:moveCursorToFirst()
    self.cursorStartXPos = self:getTextStartX()
    self.cursorpos = 0
    
    --there are hidden characters
    if self.visibleStartIdx > 1 or self.visibleEndIdx < self.charCounter then
        self.visibleStartIdx = 1
        self.visibleEndIdx = 1
        self:updateEditBoxSizeAndVisibleText()
        self:updateCharXPosTbl()
    end
    
    self:moveCursorToCharEnd(self.cursorpos)
    
    self:invalidate()
end

--b is true/false
function TextBox:setAutocompleteDone( b ) self.autocompleteDone = b end

--b is true/false
function TextBox:setUsePlurality( b ) self.usePlurality = b end

function TextBox:useBottomLine( b ) self.bottomLine:setVisible( b ) end
function TextBox:useEditBox( b ) self.editBox:setVisible( b ) end
function TextBox:canTakeMouseEvents( b ) self.takeMouseEvents = b end

---------------------------------------------------------
SimpleString = class(Widget)

function SimpleString:init(name)
    Widget.init(self, name)
    self.typeName = "simpleString"
    
    self.fontColor = {0, 0, 0}
    self.initFillColor = nil      
    self.focusFillColor = {135, 206, 235}       --background color for string when string accepts focus
    self.fillColor = self.initFillColor
    self.stringTools = app.stringTools
    self.pctxJustify = 0; self.pctyJustify = 0
    self.initPctx = self.pctx; self.initPcty = self.pcty
    self.justify = "Left"     --"Left", "Center", "Right"
    self.acceptsFocus = false
    self.hasUnderline = false
    --self.boundingRectangle = true
end

function SimpleString:paint(gc)
    local x = self.x
    local y = self.y - self.scrollY
    local fillColor

    if self.visible == true then
        if self.fillColor ~= nil then
            gc:setColorRGB( unpack(self.fillColor) )
            gc:fillRect( x, y, self.w, self.h)
        end
            
        if self.hasFocus == true then   
            if self.fillColor ~= nil then fillColor = self.fillColor
            else fillColor = self.focusFillColor
            end

            gc:setColorRGB( unpack(fillColor) )
            gc:fillRect( x, y, self.w, self.h)
        
            gc:setColorRGB(unpack(self.focusColor))
            gc:setPen("thin", "dashed")
            gc:drawRect(x, y, self.w, self.h)
        end
        
        gc:setFont(self.fontFamily, self.fontStyle, self.fontSize)
        gc:setColorRGB(unpack(self.fontColor)) 
        gc:drawString(self.text, x, y)
        
        if self.hasUnderline == true then
            gc:setPen("thin", "smooth")
            local lineOffset = 3 * self.scaleFactor
            gc:drawLine( x, y + self:calculateHeight( self.scaleFactor ) - lineOffset, x + self:calculateWidth( self.scaleFactor ), y + self:calculateHeight( self.scaleFactor ) - lineOffset)
        end
        
        self:drawBoundingRectangle(gc)
  end 
end

--w, h are ignored since sizing is based on the font.
function SimpleString:setSize(w, h)
    self:invalidate()

    local w, h = self:calculateWidth(1), self:calculateHeight(1)        --Size is based on the font
    
    self.nonScaledWidth = w; self.nonScaledHeight = h;
    self.w = self.nonScaledWidth * self.scaleFactor; self.h = self.nonScaledHeight * self.scaleFactor
    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    self.fontSize = self.stringTools:scaleFont(self.initFontSize, self.scaleFactor)

    self:invalidate()
end

function SimpleString:setPosition(pctx, pcty)
    self.initPctx = pctx; self.initPcty = pcty

    Widget.setPosition(self, pctx + self.pctxJustify, pcty)
end

function SimpleString:mouseDown( x, y )
    local ret, widget = Widget.mouseDown(self, x, y)
    
    if self.tracking == true and self.acceptsFocus == true then self.fillColor = self.mouseDownColor; self:invalidate() end   
    
    return ret, widget  
end

function SimpleString:mouseUp(x, y)
    if self.active == true and self.visible == true and self.tracking == true then
        if self.clickFunction then
            self.clickFunction()
        end
        
        self.fillColor = self.initFillColor 
        self:invalidate() 
    end

    self.tracking = false
end

function SimpleString:setText(text)
    self.text = text
    
    self:setSize(w, h)

    if self.justify == "Center" then
        self.pctxJustify = -.5 * self.nonScaledWidth * self.scaleFactor / self.panew
    elseif self.justify == "Right" then
        self.pctxJustify = -self.nonScaledWidth * self.scaleFactor / self.panew
    else  
        self.pctxJustify = 0
    end
         
    self:setPosition(self.initPctx, self.initPcty)    
end   

function SimpleString:calculateWidth(scaleFactor)
   return self.stringTools:getStringWidth(self.text, self.fontFamily, self.fontStyle, self:scaleFont(self.initFontSize, scaleFactor))
end

function SimpleString:calculateHeight(scaleFactor)
    return self.stringTools:getStringHeight(self.text, self.fontFamily, self.fontStyle, self:scaleFont(self.initFontSize, scaleFactor))
end

function SimpleString:addUnderline( b )
    self.hasUnderline = b
end

---------------------------------------------------------
Figure = class(Widget)

function Figure:init(name)
    Widget.init(self, name)
    self.typeName = "figure"
    
    self.style = app.graphicsUtilities.drawStyles.FILL_AND_OUTLINE  
    self.color = app.graphicsUtilities.Color.green
    self.initNonScaledWidth = 7; self.initNonScaledHeight = 6
    self.nonScaledWidth = self.initNonScaledWidth; self.nonScaledHeight = self.initNonScaledHeight  
    self.initPoints =  {0,4, 2,6, 7,1, 6,0, 2,4, 1,3, 0,4}  --Check Mark
    self.points = self.initPoints
    self.localScaleW = 2; self.localScaleH = 2     --Scale by this much, independent of the client.
    self.outlineColor = app.graphicsUtilities.Color.black
end

function Figure:paint(gc)
    if self.visible == true then
        self:drawFigure(gc)
        self:drawBoundingRectangle(gc)
    end
end

function Figure:drawFigure(gc)
    gc:setPen("thin", "smooth")

    if self.style == app.graphicsUtilities.drawStyles.FILL_AND_OUTLINE or self.style == app.graphicsUtilities.drawStyles.FILL_ONLY then
        gc:setColorRGB(unpack(self.color))
        gc:fillPolygon(self.points)
    end
  
    if self.style == app.graphicsUtilities.drawStyles.FILL_AND_OUTLINE or self.style == app.graphicsUtilities.drawStyles.OUTLINE_ONLY then
        gc:setColorRGB(unpack( self.outlineColor ))
        gc:drawPolyLine(self.points)
    end
end

--w and h are ignored.
function Figure:setSize(w, h)
    self:invalidate()

    self.nonScaledWidth = self.initNonScaledWidth * self.localScaleW; self.nonScaledHeight = self.initNonScaledHeight * self.localScaleH
    self.w = self.nonScaledWidth * self.scaleFactor; self.h = self.nonScaledHeight * self.scaleFactor
    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    self:positionAndSizePoints()

    self:invalidate()
end

function Figure:setPosition(pctx, pcty)
    Widget.setPosition(self, pctx, pcty)
  
    self:positionAndSizePoints()
end

function Figure:setScrollY(y)
    Widget.setScrollY(self, y)
    
    self:positionAndSizePoints()
end

function Figure:positionAndSizePoints()
    local points = self.initPoints
    self.points = {}
    
    for i=1,table.getn(points) do
        if math.floor(i/2)==i/2 then
            self.points[i] = self.y - self.scrollY + points[i] * self.localScaleH * self.scaleFactor
        else
            self.points[i] = self.x + points[i] * self.localScaleW * self.scaleFactor
        end
    end
end

function Figure:calculateWidth( scaleFactor )
    return self.initNonScaledWidth * self.localScaleW * scaleFactor
end

function Figure:calculateHeight( scaleFactor )
    return self.initNonScaledHeight * self.localScaleH * scaleFactor
end

function Figure:setLocalScale( w, h )
    if w then
        self.localScaleW = w
    end
    
    if h then
        self.localScaleH = h
    end
end

---------------------------------------------------------
FigureCheckMark = class(Figure)

function FigureCheckMark:init(name)
    Figure.init(self, name)
    self.typeName = "figureCheckMark"
    self.color = app.graphicsUtilities.Color.green; self.initNonScaledWidth = 7; self.initNonScaledHeight = 6  
    self.initPoints =  {0,4, 2,6, 7,1, 6,0, 2,4, 1,3, 0,4}
end

-----------------------------------------------------------
FigureCrossMark = class(Figure)

function FigureCrossMark:init(name)
    Figure.init(self, name)
    self.typeName = "figureCrossMark"
    self.color = app.graphicsUtilities.Color.red; self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = {0,1, 2,3, 0,5, 1,6, 3,4, 5,6, 6,5, 4,3, 6,1, 5,0, 3,2, 1,0, 0,1}
end

-----------------------------------------------------------
FigureRightArrow = class(Figure)

function FigureRightArrow:init(name)
    Figure.init(self, name)
    self.typeName = "figureRightArrow"
    self.color = app.graphicsUtilities.Color.black; self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = {0,0, 5,2, 0,4, 0,0}
end

-----------------------------------------------------------
FigureLeftArrow = class(Figure)

function FigureLeftArrow:init(name)
    Figure.init(self, name); self.typeName = "figureLeftArrow"
    self.color = app.graphicsUtilities.Color.black; self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = {5,0, 5,4, 0,2, 5,0}
end

-----------------------------------------------------------
FigureDownArrow = class(Figure)

function FigureDownArrow:init(name)
    Figure.init(self, name); self.typeName = "figureDownArrow"
    self.color = app.graphicsUtilities.Color.black; self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = {-2, 0, 0,2, 0,2, 2,0}
end

-----------------------------------------------------------
FigureUpArrow = class(Figure)

function FigureUpArrow:init(name)
    Figure.init(self, name); self.typeName = "figureUpArrow"
    self.color = app.graphicsUtilities.Color.black;  self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = {-2,2, 0,0, 0,0, 2,2}
end

-----------------------------------------------------------
FigureDiamond = class(Figure)

function FigureDiamond:init(name)
    Figure.init(self, name); self.typeName = "figureDiamond"
    self.color = app.graphicsUtilities.Color.black;  self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = { 3, 0, 0, 3, 3, 6, 6, 3, 3, 0 }
end

-----------------------------------------------------------
FigureSquare = class(Figure)

function FigureSquare:init(name)
    Figure.init(self, name); self.typeName = "figureSquare"
    self.color = app.graphicsUtilities.Color.black;  self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = { 0, 0, 0, 6, 6, 6, 6, 0, 0, 0 }
end

-----------------------------------------------------------

FigureTriangle = class(Figure)

function FigureTriangle:init(name)
    Figure.init(self, name); self.typeName = "figureTriangle"
    self.color = app.graphicsUtilities.Color.black;  self.initNonScaledWidth = 6; self.initNonScaledHeight = 6  
    self.initPoints = { 3, 0, 0, 6, 6, 6, 3, 0 }
end

----------------------------------------------------------------
Feedback = class(Widget)

function Feedback:init(name)
    Widget.init(self, name)
    self.typeName = "feedback"
    
    self.figureCheckMark = FigureCheckMark(self.name.."_FigureCheckMark")
    self.figureCrossMark = FigureCrossMark(self.name.."_FigureCrossMark")
    self.style = "CheckMark"        --CheckMark, CrossMark
    self.figure = self.figureCheckMark
    self.maxNonScaledWidth = self.figureCheckMark.nonScaledWidth; self.maxNonScaledHeight = self.figureCheckMark.nonScaledHeight     
end

function Feedback:setStyle(style)
    self.style = style
  
    if self.style == "CrossMark" then
        self.figure = self.figureCrossMark
    else
        self.figure = self.figureCheckMark
    end
    
    self:setSize(self.nonScaledWidth, self.nonScaledHeight)
end

function Feedback:paint(gc)
    if self.visible then
        self.figure:paint(gc)
        self:drawBoundingRectangle(gc)
    end
end

function Feedback:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)
    
    self.figureCheckMark:setPane(panex, paney, panew, paneh, scaleFactor)
    self.figureCrossMark:setPane(panex, paney, panew, paneh, scaleFactor)
end

--w and h are ignored.
function Feedback:setSize(w, h)
    self:invalidate()
    
    self.figureCheckMark:setSize(w, h)
    self.figureCrossMark:setSize(w, h)
    
    if self.style == "CrossMark" then
        self.nonScaledWidth = self.figureCrossMark.nonScaledWidth; self.nonScaledHeight = self.figureCrossMark.nonScaledHeight
    else
        self.nonScaledWidth = self.figureCheckMark.nonScaledWidth; self.nonScaledHeight = self.figureCheckMark.nonScaledHeight
    end        
     
    self.maxNonScaledWidth = math.max(self.figureCheckMark.nonScaledWidth, self.figureCrossMark.nonScaledWidth)   --Bigger of the check mark or cross mark
    self.maxNonScaledHeight = math.max(self.figureCheckMark.nonScaledHeight, self.figureCrossMark.nonScaledHeight)     
    self.w = self.nonScaledWidth * self.scaleFactor; self.h = self.nonScaledHeight * self.scaleFactor
    if self.w < 1 then self.w = 1 end; if self.h < 1 then self.h = 1 end;

    self:notifyListeners( app.model.events.EVENT_SIZE_CHANGE, self )

    self:invalidate()
end

function Feedback:setPosition(pctx, pcty)
    Widget.setPosition(self, pctx, pcty)

    self.figureCheckMark:setPosition(pctx, pcty)
    self.figureCrossMark:setPosition(pctx, pcty)
end

function Feedback:calculateWidth( scaleFactor )
    return self.figure.initNonScaledWidth * self.figure.localScaleW * scaleFactor
end

function Feedback:calculateHeight( scaleFactor )
    return self.figure.initNonScaledHeight * self.figure.localScaleH * scaleFactor
end

function Feedback:setScrollY(y)
    Widget.setScrollY(self, y)
    
    self.figureCheckMark:setScrollY(y)
    self.figureCrossMark:setScrollY(y)
end

function Feedback:setLocalScale( w, h )
    self:setLocalScaleCheckMark( w, h )
    self:setLocalScaleCrossMark( w, h )
end

function Feedback:setLocalScaleCheckMark( w, h )
    self.figureCheckMark:setLocalScale( w, h )
end

function Feedback:setLocalScaleCrossMark( w, h )
    self.figureCrossMark:setLocalScale( w, h )
end

-----------------------------------------------------------
Keyboard = class(Widget)

function Keyboard:init(name)
    Widget.init(self, name)
    self.typeName = "keyboard"
  
    self.xpositions = {.025, .2}
    self.ypositions = {.05, .65, .65}     --Keyboard can either be at the top of bottom.

    self.yPosition = 3      --Storage for container for which index to use for placing the keyboard
    self.initWidth = 300;   self.initHeight = 65   --Storage for container.
    self.initPctX = self.xpositions[1];    self.initPctY = self.ypositions[self.yPosition]       --Storage for container.
    self.nonScaledWidth = self.initWidth; self.nonScaledHeight = self.initHeight
    self.pctx = self.initPctX;  self.pcty = self.initPctY   

    self.ySize = self.initHeight
    self.enabled = false
    self.active = false
    self.visible = false
    self.lockVisibility = false     --Set to true to override typical handling of keyboard visibility.
    self.scrollBarListenerID = nil

    self.roundedRectangle = RoundedRectangle(self.name.."Rect")
    self.roundedRectangle.fillColor = app.graphicsUtilities.Color.white
    self.roundedRectangle.curvePct = 0.1
    self.spacing = 0                    --0 for ysize < 80, .05 for ysize >= 80
    self.lastKeyPressed = ""
    self.keysIndex = 1
    self.dynamicKeys = {}        --This is the index for which key can be changed.
    self.buttonName = "KeyboardButton"
    if KeyboardLayout then self.keysLayout = KeyboardLayout() end
    if self.keysLayout then self:setKeyboardLayout(self.keysLayout) end
    
    self.controlRoundedRectangle = RoundedRectangle(self.name.."ControlRect")
    self.controlRoundedRectangle.fillColor = app.graphicsUtilities.Color.white
    
    self.btnContainerInitWidth = 44;   self.btnContainerInitHeight = 20   --Storage for container.
    
    self.showDragIcon = true        --for showing app.charGrip
    self.timerCount = 0
    self.lastKeyPressed = ""
    self.mouseOverWidget = nil
    self.copyPasteToolbar = CopyPasteToolbar(self.name.."CopyPasteToolbar")
    self.textbox = nil
    
    assert(_R.IMG.clipboardicon, "clipboardImage does not exist.")
    self.clipboardImage = image.new( _R.IMG.clipboardicon )
    self.clipboardImage = self.clipboardImage:copy( 20, 20 )
end

--x,y is the pane location.  self.x and self.y are offset within the pane.
function Keyboard:paint(gc)
  if self.visible == true and self.active == true then
    local x = self.panex + self.x
    local y = self.paney + self.y - self.scrollY

    self.roundedRectangle:paint(gc)
--THIS CAN BE MADE FASTER BY REMOVING THE TRIM
    for i,v in ipairs(self.keys[self.keysIndex]) do
--      if app.stringTools.trim(self[self.buttonName..tostring(i+self.keysCounter[self.keysIndex])].label) ~= "" then
--      print("button paint", self[self.buttonName..tostring(i+self.keysCounter[self.keysIndex])].label, self.keysIndex)
        self[self.buttonName..tostring(i+self.keysCounter[self.keysIndex])]:paint(gc)
--      end
    end
    
    if self.showDragIcon == true then
        gc:setColorRGB(unpack(app.graphicsUtilities.Color.black))
        gc:drawString(app.charGrip, self.x + self.w + self.keysLayout.grabIconXY[self.keysIndex][1] * self.scaleFactor, self.y + self.keysLayout.grabIconXY[self.keysIndex][2] * self.scaleFactor)
    end
    
    --toolbar
    self.copyPasteToolbar:paint(gc)
  end
end

function Keyboard:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)

    self.roundedRectangle:setPane(panex, paney, panew, paneh, scaleFactor)
    self.controlRoundedRectangle:setPane(panex, paney, panew, paneh, scaleFactor)
    self.copyPasteToolbar:setPane(panex, paney, panew, paneh, scaleFactor)
end

function Keyboard:setSize(w, h)
    Widget.setSize(self, w, h)

    self.roundedRectangle:setSize(self.w/self.scaleFactor, self.h/self.scaleFactor)
    self.controlRoundedRectangle:setSize( self.btnContainerInitWidth, self.btnContainerInitHeight )
    self.clipboardImage = self.clipboardImage:copy( 20 * self.scaleFactor, 20 * self.scaleFactor )
    self:setButtonPanes()
    self.copyPasteToolbar:setSize( self.copyPasteToolbar.nonScaledWidth, self.copyPasteToolbar.nonScaledHeight )
end

--Set position based on percentage of the container pane.
function Keyboard:setPosition(pctx, pcty)
    Widget.setPosition(self, pctx, pcty)

    self.roundedRectangle:setPosition(self.pctx, self.pcty)
    local curveDiff = 0 -- curve pixels?
    self.controlRoundedRectangle:setPosition( self.pctx + (self.w - ( self.btnContainerInitWidth + curveDiff ) * self.scaleFactor) / self.panew, self.pcty - ( self.btnContainerInitHeight * self.scaleFactor ) / self.paneh )
    self:setButtonPanes()
    self.copyPasteToolbar:setPosition( self.copyPasteToolbar.pctx, self.copyPasteToolbar.pcty )
end

function Keyboard:setButtonPanes()
    --Key percentages will be based on the keyboard size, not the pane size.
    if self.keys then
        for j=1, #self.keys do
            for i,v in ipairs(self.keys[j]) do
                local btn = self[self.buttonName..tostring(i+self.keysCounter[j])]
                btn:resize(self.x, self.y, self.w, self.h, self.scaleFactor)
            end
        end
    end
end

function Keyboard:setDynamicKey(keyNames)
    local button, label, x, w, h
    
    for i=1,#self.dynamicKeys do
        button = self.buttonName..tostring(self.dynamicKeys[i])
        self[button].label = " "..keyNames[i].." "
        label = keyNames[i]
        w = self.stringTools:getStringWidth(keyNames[i], "sansserif", "r", self.initFontSize) + 5
        h = self.keys[1][ self.dynamicKeys[i] ][5]
        x = self.keys[1][self.dynamicKeys[i]-1][2] + (self.keys[1][self.dynamicKeys[i]-1][4]*self.scaleFactor/(self.nonScaledWidth*self.scaleFactor)) + .02 
        y = self.keys[1][ self.dynamicKeys[i] ][3]+self.spacing
        
        self.keys[1][ self.dynamicKeys[i] ][1] = label
        self.keys[1][ self.dynamicKeys[i] ][2] = x
        self.keys[1][ self.dynamicKeys[i] ][4] = w
        self[button]:setSize(w, h)
        self[button]:setPosition(x + .01, y)
    end
end

function Keyboard:setKeyboardLayout(keysLayout)
    self.keys = keysLayout.keys
    self.keysCounter = {}    
    
    local count = 0
    for i = 1, #self.keys do
        self.keysCounter[i] = count
        if i < #self.keys then count = count + #self.keys[i+1] end  
    end
    
    local button
    for j = 1, #self.keys do
        for i,v in ipairs(self.keys[j]) do
            button = self.buttonName..tostring(i+self.keysCounter[j])
            self[button] = Button(button)
            self[button].sizeIncludesFocus = false
            if app.platformType == "ndlink" then
                self[button]:setStyle(self[button].styleIDs.CIRCLE)    --Primitive circle for performance.
            else
                self[button]:setStyle(self[button].styleIDs.CIRCLE)    --4 - circle, 3 - Rounded Rectangle or Octagon.
            end
            self[button]:setInitSizeAndPosition(v[4], v[5], v[2]+.01, v[3]+self.spacing)
            self[button].label = v[1]
            
            if v[1] == "clipboardIcon" then
                self[button]:setDrawCallback( function( gc, x, y, w, h, sf )
                    gc:drawImage( self.clipboardImage, x + w * 0.5 - self.clipboardImage:width() * 0.5  - 1 * sf, y + h * 0.5 - self.clipboardImage:height() * 0.5 - 1 * sf )
                end )
            end
            
            if v[6] == "Close" then self[button].fontColor = app.graphicsUtilities.Color.red end
        end
    end
end

--Returns true if the keyboard area is clicked.
function Keyboard:mouseDown(x, y)
    if self.active == true and self.visible == true then
        local b, button, keyPressed = 0, "", ""
        
        b = self:contains(x, y)
    
        if b == 1 then
            local didTouchKey = false -- flag, change to true if touched a key.
    
            for i,v in ipairs(self.keys[self.keysIndex]) do
                button = self.buttonName..tostring(i+self.keysCounter[self.keysIndex])
                b = self[button]:contains(x, y)
                
                if b == 1 then
                    self[button]:mouseDown( x, y )
                    self.buttonPressed = button
                    didTouchKey = true -- user touched key.
                    self.lastKeyPressed = v[1]
                    keyPressed = v[1]
                    
                    if v[1] == app.charDoubleArrow then
                        if self.yPosition == 3 then  self.yPosition = 1    else   self.yPosition = 3   end
                        self:setPosition(self.xpositions[1], self.ypositions[self.yPosition])
                        self:setButtonPositions()
                    elseif v[1] == "123" then
                        self.keysIndex = 1
                        self.ySize = self.initHeight
                        self.spacing = 0
                        self:resize(self.panew, self.paneh, self.scaleFactor)
                    elseif v[1] == "abc" then
                        self.keysIndex = 2
                        self.ySize = self.initHeight
                        self.spacing = 0
                        self:resize(self.panew, self.paneh, self.scaleFactor)
                    else
                        if v[1] == app.charBackspaceArrow then
                            self.textbox:backspaceKey()
                        elseif v[6] == "Close" then
                            self.lastKeyPressed = v[6]
                            keyPressed = "Close"
                        elseif v[1] == "Enter" then
                            keyPressed = "Enter"
                            app.frame:enterKey()
                        elseif v[1] == "Tab" then
                            keyPressed = "Tab"
                        elseif v[1] == "clipboardIcon" then
                            keyPressed = "clipboardIcon"
                            self:clickMoreOptions()
                        end
                    end
                    break
                else
                    --self.lastKeyPressed = ""
                end
            end
            
            -- allow drag if user did not touch any key on the keyboard
            if not didTouchKey then
                self.tracking = true
                if self.hasGrab == true then
                    self.xGrabOffset = x - self.x + self.panex
                    self.yGrabOffset = y - self.y + self.paney
                end
            else
                self.timerCount = 0
                self.timerOn = true     --If user touched a key, then wait only briefly for the mouse up.
            end
            
            return true, keyPressed     --Event handled and return additional information
        elseif self.copyPasteToolbar.visible == true then
            return self.copyPasteToolbar:mouseDown(x, y)
        end
    end
    
    return false  --Event not handled.
end

function Keyboard:mouseUp(x, y)
    if self.active == true and self.visible == true and self.lastKeyPressed ~= "" then
        self.timerOn = false
        self:processKeypressed(self.lastKeyPressed)
        self.lastKeyPressed = ""
        if self.buttonPressed then self[self.buttonPressed]:mouseUp() end
    end
    
    self.copyPasteToolbar:mouseUp(x, y)
    self.tracking = false

    return
end

function Keyboard:processKeypressed(keyPressed)
    if keyPressed == "Close" then
        self:setActive(false)
        self:setVisible(false)
    elseif keyPressed == "Space" then
        self.textbox:charIn(" ")
    elseif keyPressed ~= app.charBackspaceArrow and keyPressed ~= "Tab" and keyPressed ~= "Enter" and keyPressed ~= app.charBackspaceArrow and keyPressed ~= "clipboardIcon" then
        self.textbox:charIn(keyPressed)
    end
    
end

function Keyboard:mouseMove(x, y)
    if self.hasGrab == true and self.tracking == true then
        local x1 = x - self.xGrabOffset; local y1 = y - self.yGrabOffset
        
        if x1 < 0 then x1 = 0; self.xGrabOffset = x - self.x + self.panex end
        if y1 < 0 then y1 = 0; self.yGrabOffset = y - self.y + self.paney end
        if x1 + self.w > self.panew then x1 = self.panew - self.w; self.xGrabOffset = x - self.x + self.panex end
        if y1 + self.h > self.paneh then y1 = self.paneh - self.h; self.yGrabOffset = y - self.y + self.paney end
        
        self:setPosition(x1/self.panew, y1/self.paneh)
        
    end
end

-- x, y should be the target position of the top left of keyboard
function Keyboard:isInsidePane( x, y )
    -- this function checks if the keyboard is inside or outside the pane
    local topButtonHeight = self.btnContainerInitHeight * self.scaleFactor-- height of container of the button
    
    if not self.isBtnVisible then topButtonHeight = 0 end
    
    local isInsidePaneWidth = ( x >= -1 and x + self.w <= self.panew ) or ( self.x >= -1 and self.x + self.w <= self.panew )  -- flag for x
    local isInsidePaneHeight = ( y - topButtonHeight >= 0 and y + self.h <= self.paneh )  -- flag for y
    
    return isInsidePaneWidth, isInsidePaneHeight -- true if whole keyboard is inside the pane

end

function Keyboard:calculateHeight( scaleFactor )
    return self.nonScaledHeight * scaleFactor
end

function Keyboard:drawMoveMark(gc, x, y, w, h, scale)
    app.graphicsUtilities:drawFigure(app.graphicsUtilities.figureTypeIDs.TICK_MARK, gc, x+.2*w, y+.2*h, 2*scale, app.graphicsUtilities.Color.black, app.graphicsUtilities.drawStyles.OUTLINE_ONLY) 
end

function Keyboard:drawXMark(gc, x, y, w, h, scale)
    app.graphicsUtilities:drawFigure(app.graphicsUtilities.figureTypeIDs.TICK_MARK, gc, x+.2*w, y+.2*h, 2*scale, app.graphicsUtilities.Color.black, app.graphicsUtilities.drawStyles.OUTLINE_ONLY) 
end

--This is a listener on TextBox events.
--Activate the soft keyboard if the user clicks or taps into the edit box.     
function Keyboard:textBoxListener(event, tb, ...)
    if event == app.model.events.EVENT_MOUSE_DOWN and self.enabled == true then
        self:setActive(true)
        self:setVisible(true)
        self:setTextbox(tb)
    elseif event == app.model.events.EVENT_GOT_FOCUS and self.enabled == true then
        self:setTextbox(tb)
        self.copyPasteToolbar:setTextbox(tb)    --to position the copy paste toolbar above the textbox with focus
    end
end

function Keyboard:setTextbox(tb)
    self.textbox = tb
end

--vertical ellipsis button is clicked from soft keyboard
function Keyboard:clickMoreOptions()
    self.copyPasteToolbar:setVisible( not self.copyPasteToolbar.visible )
end

function Keyboard:contains(x, y)
    if self.attachedToScrollPane then
        return Widget.contains( self, x, y )
    else
        local xExpanded = x - .5*self.mouse_xwidth            --Expand the location where the screen was touched.
        local yExpanded = y - .5*self.mouse_yheight
    
        local x_overlap = math.max(0, math.min(self.panex+self.x+self.w, xExpanded + self.mouse_xwidth) - math.max(self.panex+self.x, xExpanded))
        local y_overlap = math.max(0, math.min(self.paney+self.y+self.h, yExpanded + self.mouse_yheight) - math.max(self.paney+self.y, yExpanded))
    
        --If there is an intersecting rectangle, then this point is selected.
        if x_overlap * y_overlap > 0 then
            return 1
        end
    
        return 0
    end
end

function Keyboard:handleTimer()
    if self.timerOn == true then
        self.timerCount = self.timerCount + 1
        if self.timerCount > 5 then     --Allow only .5 seconds for mouse up on keyboard in case we missed hardware mouseup.
            self:mouseUp(0, 0)  
        end
    end
end

--------------------------------------------------------------
CopyPasteToolbar = class(Widget)

function CopyPasteToolbar:init(name)
	Widget.init(self, name)
	self.typeName = "toolbar"
	
    self.initWidth = 138;   self.initHeight = 24   --Storage for container.
    self.initPctX = .39;    self.initPctY = .15      --Storage for container.
    self.nonScaledWidth = self.initWidth; self.nonScaledHeight = self.initHeight
    self.pctx = self.initPctX;  self.pcty = self.initPctY   

    self.visible = false
    self.scrollBarListenerID = nil
    
    self.textbox = nil      --This will be set by the textbox that is given focus.
    self.roundedRectangle = RoundedRectangle(self.name.."Rect")
    self.roundedRectangle.fillColor = app.graphicsUtilities.Color.white
    self.roundedRectangle.curvePct = 0.1
    self.roundedRectangle:setInitSizeAndPosition(self.nonScaledWidth, self.nonScaledHeight, self.pctx, self.pcty)      
    self.nonScaledPointerWidth, self.nonScaledPointerHeight = 10, 7
    self.pointerWidth, self.pointerHeight = self.nonScaledPointerWidth, self.nonScaledPointerHeight
    self.lastKeyPressed = ""
    
    self:setupButtons()
end

--x,y is the pane location.  self.x and self.y are offset within the pane.
function CopyPasteToolbar:paint(gc)
	if self.visible == true and self.active == true then
		local x = self.panex + self.x
		local y = self.paney + self.y - self.scrollY
		local i

		self.roundedRectangle:paint(gc)
        
        --tip
        gc:setColorRGB(255, 255, 255)                      -- inverted triangle
        gc:fillPolygon(self.tipPolyPts)
        
        gc:setColorRGB(0, 0, 0)        --border of triangle
        gc:drawLine(self.tipPolyPts[1] + 1*self.scaleFactor, self.tipPolyPts[2] + 2*self.scaleFactor, self.tipPolyPts[3], self.tipPolyPts[4] - 1*self.scaleFactor)        --left line
        gc:drawLine(self.tipPolyPts[3], self.tipPolyPts[4] - 1*self.scaleFactor, self.tipPolyPts[5] - 1*self.scaleFactor, self.tipPolyPts[6] + 2*self.scaleFactor)     --right line
        
        --buttons
        for i=1, #self.toolbarButtons do
            self.toolbarButtons[i]:paint(gc)
        end
	end
end

function CopyPasteToolbar:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)

    self.roundedRectangle:setPane(panex, paney, panew, paneh, scaleFactor)
    
    for i=1, #self.toolbarButtons do
        self.toolbarButtons[i]:setPane(panex, paney, panew, paneh, scaleFactor)
    end
end

function CopyPasteToolbar:setSize(w, h)
	Widget.setSize(self, w, h)

    self.roundedRectangle:setSize(self.nonScaledWidth, self.nonScaledHeight)
    
    for i=1, #self.toolbarButtons do
        self.toolbarButtons[i]:setSize(self.toolbarButtons[i].nonScaledWidth, self.toolbarButtons[i].nonScaledHeight)
    end
end

--Set position based on percentage of the container pane.
function CopyPasteToolbar:setPosition(pctx, pcty)
	Widget.setPosition(self, pctx, pcty)
    if self.textbox ~= nil then self:setToolbarPositions() end
end

function CopyPasteToolbar:setToolbarPositions()
    self.pointerWidth = self.nonScaledPointerWidth * self.scaleFactor
    self.pointerHeight = self.nonScaledPointerHeight * self.scaleFactor

    local editBox = self.textbox
    if self.textbox.editBox ~= nil then editBox = self.textbox.editBox end
        
    --rectangle       
    local innerX = editBox.x
    local toolbarRectanglePctx = (innerX + .5*editBox.w - .5*self.roundedRectangle.w)/self.textbox.panew
    local toolbarRectanglePcty = self.textbox.pcty - (self.roundedRectangle.h + self.pointerHeight + 3*self.scaleFactor)/self.textbox.paneh
    self.roundedRectangle:setPosition(toolbarRectanglePctx, toolbarRectanglePcty)   
    
    --tip
    local pointerX = innerX + .5*editBox.w - .5*self.pointerWidth
    local py = self.roundedRectangle.y
    local rectH = self.roundedRectangle.h
    self.tipPolyPts = {pointerX - 1*self.scaleFactor, py + rectH - 3*self.scaleFactor, pointerX + .5*self.pointerWidth, py + rectH + self.pointerHeight + 1*self.scaleFactor, pointerX + self.pointerWidth + 1*self.scaleFactor, py + rectH - 3*self.scaleFactor}
    
    --buttons
    local buttonPctx = toolbarRectanglePctx + 4*self.scaleFactor/self.panew
    local buttonPcty = toolbarRectanglePcty + 4*self.scaleFactor/self.paneh
    local spacing = 0*self.scaleFactor
    local i
    
    for i=1, #self.toolbarButtons do
        self.toolbarButtons[i]:setPosition(buttonPctx, buttonPcty)
        buttonPctx = self.toolbarButtons[i].pctx + (self.toolbarButtons[i].w - spacing)/self.panew
    end
end

function CopyPasteToolbar:setScrollY(y)
    Widget.setScrollY(self, y)
    
    self.roundedRectangle:setScrollY(y)
    
    for i=1, #self.toolbarButtons do
        self.toolbarButtons[i]:setScrollY(y)
    end
    
    local tipPolyPts = {self.tipPolyPts[1], self.tipPolyPts[2] - self.scrollY, self.tipPolyPts[3], self.tipPolyPts[4] - self.scrollY, self.tipPolyPts[5], self.tipPolyPts[6] - self.scrollY}
    self.tipPolyPts = {}
    self.tipPolyPts = tipPolyPts
end

--Returns true if the keyboard area is clicked.
function CopyPasteToolbar:mouseDown(x, y)
    if self.active == true and self.visible == true then
        local b, keyPressed = 0, ""
        
        b = self.roundedRectangle:contains(x, y)
    
        if b == 1 then
            local i
            
            for i=1, #self.toolbarButtons do
                local button = self.toolbarButtons[i]
                
                if button:contains(x, y) == 1 then
                    self.lastKeyPressed = button.name            --Save what key was pressed for use by another routine.
                    break
                end
            end
            
            return true    --Event handled 
        end
    end
    
    return false  --Event not handled.
end

function CopyPasteToolbar:contains(x, y)
    local xExpanded = x - .5*self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y - .5*self.mouse_yheight

    local x_overlap = math.max(0, math.min(self.panex+self.x+self.w, xExpanded + self.mouse_xwidth) - math.max(self.panex+self.x, xExpanded))
    local y_overlap = math.max(0, math.min(self.paney+self.y+self.h, yExpanded + self.mouse_yheight) - math.max(self.paney+self.y, yExpanded))

    --If there is an intersecting rectangle, then this point is selected.
    if x_overlap * y_overlap > 0 then
        return 1
    end

    return 0
end

function CopyPasteToolbar:mouseUp(x, y)
    if self.active == true and self.visible == true then
        if self.lastKeyPressed == self.copyButton.name then
            app.frame:copy()
        elseif self.lastKeyPressed == self.cutButton.name then
            app.frame:cut()
        elseif self.lastKeyPressed == self.pasteButton.name then
            app.frame:paste()
        elseif self.lastKeyPressed == self.leftArrowButton.name then
            app.frame:arrowLeft()
        elseif self.lastKeyPressed == self.rightArrowButton.name then
            app.frame:arrowRight()
        elseif self.lastKeyPressed == self.closeButton.name then
            self:setVisible(false)
        end
        
        self.lastKeyPressed = ""
    end
    
    self.tracking = false

    return
end

function CopyPasteToolbar:setupButtons()
    self.copyButton = Button(self.name.."copyButton")
    self.copyButton:setInitSizeAndPosition(26, 16, .4, .16)
    self.copyButton.initFontSize = 8
    self.copyButton:setLabel("copy")
    self.copyButton:addListener(function( event, ...) return self.textbox:copy(event, ...) end) 
    
    self.cutButton = Button(self.name.."cutButton")
    self.cutButton:setInitSizeAndPosition(22, 16, .49, .16)
    self.cutButton.initFontSize = 8
    self.cutButton:setLabel("cut")
    
    self.pasteButton = Button(self.name.."pasteButton")
    self.pasteButton:setInitSizeAndPosition(30, 16, .56, .16)
    self.pasteButton.initFontSize = 8
    self.pasteButton:setLabel("paste")
    
    self.rightArrowButton = Button(self.name.."rightArrowButton")
    self.rightArrowButton:setInitSizeAndPosition(18, 16, .56, .16)
    self.rightArrowButton.initFontSize = 8
    self.rightArrowButton:setLabel(app.charRightArrow)
    
    self.leftArrowButton = Button(self.name.."leftArrowButton")
    self.leftArrowButton:setInitSizeAndPosition(18, 16, .56, .16)
    self.leftArrowButton.initFontSize = 8
    self.leftArrowButton:setLabel(app.charLeftArrow)
    
    self.closeButton = Button(self.name.."closeButton")
    self.closeButton:setInitSizeAndPosition(16, 16, .56, .16)
    self.closeButton.initFontSize = 8
    self.closeButton.fontColor = {255, 0, 0}     --red
    self.closeButton:setLabel("X")
    
    self.toolbarButtons = {}
    self.toolbarButtons[1] = self.copyButton
    self.toolbarButtons[2] = self.cutButton
    self.toolbarButtons[3] = self.pasteButton
    self.toolbarButtons[4] = self.leftArrowButton
    self.toolbarButtons[5] = self.rightArrowButton
    self.toolbarButtons[6] = self.closeButton
end

function CopyPasteToolbar:setTextbox(tb)
    self.textbox = tb
    self:setPosition(self.pctx, self.pcty)      --reposition the toolbar near the new textbox
end

----------------------------------------------------------
ScrollBar = class(Widget)

function ScrollBar:init(name)
  Widget.init(self, name)
  self.typeName = "scrollbar"
    
    self.scrollBoxYPosition = 1   --starting y position of the moving grey area in the scroll bar
    self.scrollBoxHeight = 1
    self.virtualHeight = 1   --Number of pixels for the virtual window
    self.rectXPosition = 1; self.rectYPosition = 1; self.rectWidth = 1; self.rectHeight = 1
    self.upButton = Button("upButton")
    self.upButton.sizeIncludesFocus = false --We don't use the focus rectangle.
    self.upButton:setStyle(self.upButton.styleIDs.RECTANGLE)
    self.upButton:setInitSizeAndPosition(self.w, self.w, 0, 0)
    self.downButton = Button("downButton")
    self.downButton.sizeIncludesFocus = false --We don't use the focus rectangle.
    self.downButton:setStyle(self.downButton.styleIDs.RECTANGLE)
    self.upButton:setInitSizeAndPosition(self.w, self.w, 0, (self.h-self.w)/self.h)

    self.areaSelected = 0
    self.scrollDistance = 20        --Jump this many pixels each time up or down button is clicked.
    self.scrollBoxGrabbed = false
    self.prevMouseY = 0
    self.listeners = {}
end

--Draw the scroll bar
function ScrollBar:paint(gc)

    if self.visible == true then
        --Draw the up button
        self.upButton:setDrawCallback(function() app.graphicsUtilities:drawFigure(app.graphicsUtilities.figureTypeIDs.UP_ARROW, gc, self.upButton.x + (self.upButton.w * 0.5), self.upButton.y+4*self.scaleFactor, 2*self.scaleFactor, app.graphicsUtilities.Color.blue, app.graphicsUtilities.drawStyles.OUTLINE_ONLY) end)
        self.upButton:paint(gc)
        
        --Draw the down button
        self.downButton:setDrawCallback(function() app.graphicsUtilities:drawFigure(app.graphicsUtilities.figureTypeIDs.DOWN_ARROW, gc, self.downButton.x + (self.downButton.w * 0.5), self.downButton.y + 4*self.scaleFactor, 2*self.scaleFactor, app.graphicsUtilities.Color.blue, app.graphicsUtilities.drawStyles.OUTLINE_ONLY) end)
        self.downButton:paint(gc)
    
        --Draw the scroll bar rectangle
        gc:setColorRGB(unpack(app.graphicsUtilities.Color.whitegrey))
        gc:fillRect(self.rectXPosition, self.rectYPosition, self.rectWidth,  self.rectHeight)
        
        --Draw grey scroll box/thumb
        gc:setColorRGB(unpack(app.graphicsUtilities.Color.grey))
        gc:fillRect(self.rectXPosition, self.scrollBoxYPosition, self.rectWidth, self.scrollBoxHeight)

        --Draw the scroll bar rectangle
        gc:setPen("thin", "smooth")
        gc:setColorRGB(unpack(app.graphicsUtilities.Color.verydarkgrey))
        gc:drawRect(self.rectXPosition, self.rectYPosition, self.rectWidth - 1, self.rectHeight - 1)    -- -1 accounts for the way NSpire counts rect of height 1 really takes 2 pixels.
    end
end

function ScrollBar:setInitSizeAndPosition(w, h, pctx, pcty)
  Widget.setInitSizeAndPosition(self, w, h, pctx, pcty)
 
    self.upButton:setInitSizeAndPosition(w, h, pctx, pcty)
    self.downButton:setInitSizeAndPosition(w, h, pctx, pcty)
end

function ScrollBar:setVirtualHeight(vh)
    self.virtualHeight = vh
    if self.virtualHeight < 1 then self.virtualHeight = 1 end
   
    self:setSize(self.nonScaledWidth, self.nonScaledHeight) --recalculate items related to virtual height
    self:setPosition(self.pctx, self.pcty)
end

function ScrollBar:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)

    self.upButton:setPane(panex, paney, panew, paneh, scaleFactor)
    self.downButton:setPane(panex, paney, panew, paneh, scaleFactor)
end

function ScrollBar:setSize(w, h)
    Widget.setSize(self, w, h)

    self.upButton:setSize(self.nonScaledWidth, self.nonScaledWidth)
    self.downButton:setSize(self.nonScaledWidth, self.nonScaledWidth)

    self.rectWidth = self.w
    self.rectHeight = self.h - ( 2 * self.upButton.h )          --If the height of the scroll pane is 24, minus the 24 for the two buttons, then the rectHeight is 0.
    if self.rectHeight <= 0 then self.rectHeight = 1 end        --But a drawRectangle() would actually draw 3 pixels.  If self.h is 27, then rectHeight is 3, so drawRectangle should be 3 - 1.

    if self.virtualHeight > self.h then
        self.scrollBarRange = self.virtualHeight - self.h      --Scrollbar range is difference of virtual height and the viewport height
    else 
        self.virtualHeight = self.h     --The virtual height is never less than the actual height.
        self.scrollBarRange = 0
    end

    self.scrollBoxHeight = (self.h/self.virtualHeight)*self.rectHeight      --viewport height divided by virtual window height times the scroll bar height
    if self.scrollBoxHeight < 1 then self.scrollBoxHeight = 1 end
    if self.scrollY >= self.scrollBarRange then self.scrollY = self.scrollBarRange; self:notifyListeners(app.model.events.EVENT_SCROLL) end
end

--Set position based on percentage of the container pane.
function ScrollBar:setPosition(pctx, pcty)
    Widget.setPosition(self, pctx, pcty)

    --Internal objects must now have the pane size, object size and position set.    (You can't just call self.upButton:resize() here because we are using new values)
    self.upButton:setPosition(self.pctx, self.pcty)
    self.downButton:setPosition(self.pctx, self.pcty + (self.upButton.h + self.rectHeight)/self.paneh)
    
    -- place in the middle of the buttons
    self.rectXPosition = self.x 
    self.rectYPosition = self.y + self.upButton.h  
    self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
end

--Returns 1 if area clicked is within boundaries of up button or scroll bar area above the scroll box, 2 if within boundaries of down button or scroll bar area below the scroll box
--Returns 3 if the area clicked is within the boundaries of the scroll box/thumb, zero otherwise
function ScrollBar:contains(x, y)
    local xExpanded = x - .5*self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y - .5*self.mouse_yheight
    local buttonX = self.upButton.x 
    local upButtonY = self.upButton.y 
    local downButtonY = self.downButton.y

        --Check for button boundaries
    local x_overlap_button = math.max(0, math.min(buttonX + self.w, xExpanded + self.mouse_xwidth) - math.max(buttonX, xExpanded))
    local y_overlap_upButton = math.max(0, math.min(upButtonY + self.w, yExpanded + self.mouse_yheight) - math.max(upButtonY, yExpanded))
    local y_overlap_downButton = math.max(0, math.min(downButtonY + self.w, yExpanded + self.mouse_yheight) - math.max(downButtonY, yExpanded))

    --Check for scroll bar boundaries.  For y positions, take the bottom boundary minus the top boundary and see if the mouse y is between.
    local x_overlap_scrollRect = math.max(0, math.min(self.rectXPosition + self.rectWidth, xExpanded + self.mouse_xwidth) - math.max(self.rectXPosition, xExpanded))
    local y_overlap_scrollBox = math.max(0, math.min(self.scrollBoxYPosition + self.scrollBoxHeight, yExpanded + self.mouse_yheight) - math.max(self.scrollBoxYPosition, yExpanded))
    local y_overlap_upScrollRect = math.max(0, math.min(self.scrollBoxYPosition, yExpanded + self.mouse_yheight) - math.max(self.rectYPosition, yExpanded))
    local y_overlap_downScrollRect = math.max(0, math.min(self.rectYPosition + self.rectHeight, yExpanded + self.mouse_yheight) - math.max(self.scrollBoxYPosition+self.scrollBoxHeight, yExpanded))
    
    --If there is an intersecting rectangle, then this point is selected.
    if x_overlap_button * y_overlap_upButton > 0 then
        return 1
    elseif x_overlap_button * y_overlap_downButton > 0 then
        return 2
    elseif x_overlap_scrollRect * y_overlap_scrollBox > 0 then
        return 3
    elseif x_overlap_scrollRect * y_overlap_upScrollRect > 0 then
        return 1
    elseif x_overlap_scrollRect * y_overlap_downScrollRect > 0 then
        return 2
    end

    return 0
end

--Save the button clicked and check whether the scroll box is clicked
function ScrollBar:mouseDown(x, y)
    local retVal = false

    if self.active == true and self.visible == true then
        self.areaSelected = self:contains(x, y)
    
        if self.areaSelected > 0 then
            self.tracking = true
            
            if self.hasGrab == true then
                self.xGrabOffset = x - self.x + self.panex
                self.yGrabOffset = y - self.y + self.paney
            end
            
            if self.areaSelected == 3 then self.scrollBoxGrabbed = true; self.prevMouseY = y end
    
            retVal = true   --Event handled.
        end
    end
            
    return retVal, self.areaSelected        --Event handled or not, area selected.
end

--Call the appropriate function for button selected
function ScrollBar:mouseUp()
    self.tracking = false

    if self.active == true and self.visible == true then
        if self.scrollBoxGrabbed == true then
            self:invalidate()
            self.scrollBoxGrabbed = false
        end

        if self.areaSelected == 1 then
            self:upButtonClick()
        elseif self.areaSelected == 2 then
            self:downButtonClick()
        end

        return self.areaSelected     --if self.areaSelected > 0 then event handled
    end
    
    return 0        --Event not handled
end

--Update the position of the scroll box when it is being dragged
function ScrollBar:mouseMove(x, y)
    Widget.mouseMove( self, x, y )
    
    if self.scrollBoxGrabbed == true then
        self:invalidate()

        if self.prevMouseY < y then
            self.scrollBoxYPosition = math.min(self.scrollBoxYPosition + math.abs(self.prevMouseY-y), self.rectYPosition + self.rectHeight - self.scrollBoxHeight)
        else
            self.scrollBoxYPosition = math.max(self.scrollBoxYPosition - (self.prevMouseY-y), self.rectYPosition)
        end
        self.scrollY = self.virtualHeight*(self.scrollBoxYPosition -  self.rectYPosition)/self.rectHeight
        self.prevMouseY = y
        self:notifyListeners(app.model.events.EVENT_SCROLL) 
    end
end

function ScrollBar:grabUp(x, y) 
    if self.active == true and self.visible == true then
        if self.hasGrab == true then
            if self:contains(x, y) > 0 then
                self.mouseGrabbed = true        --User has now pressed and released the mouse grab, so now the item is locked.  Set this to false upon any keyboard or mouse up/down event.
                return true
            end
        end
    end
        
    return false
end

function ScrollBar:releaseGrab()
    if self.mouseGrabbed then           --Release only if it was previously grabbed.
        self.mouseGrabbed = false
        self.scrollBoxGrabbed = false
        self.tracking = false
    end
end

function ScrollBar:arrowUp()
    if self.active == true and self.visible == true then
        self:upButtonClick()
        return true     --Event handled
    end

    return false    --Event not handled
end

function ScrollBar:arrowDown()
    if self.active == true and self.visible == true then
        self:downButtonClick()
        return true     --Event handled
    end

    return false    --Event not handled
end

--Move the objects in the scroll pane upwards
function ScrollBar:upButtonClick()
    self:invalidate()
    self.scrollY = self.scrollY - self.scrollDistance*self.scaleFactor
    if self.scrollY <= 0 then self.scrollY = 0 end
    self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
    self:notifyListeners(app.model.events.EVENT_SCROLL) 
end

--Move the objects in the scroll pane downwards
function ScrollBar:downButtonClick()
    self:invalidate()
    if self.scrollY + self.scrollDistance*self.scaleFactor > self.scrollBarRange then   --Don't go too far, but handle the extra pixels.
        self.scrollY = self.scrollBarRange
    else
        self.scrollY = self.scrollY + self.scrollDistance*self.scaleFactor
    end
    self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
    self:notifyListeners(app.model.events.EVENT_SCROLL) 
end

--Adjust the scrollY to move the object into view based from the percentage indicated and move the scroll box y position
function ScrollBar:scrollIntoView(pct, objectYPosition)
    --Only scroll if there scrollbar is visible
    if self.active == true and self.visible == true then
        if pct == 0 then                --if scroll to top, do not add 10 pixels
            self.scrollY = objectYPosition
        else
            self.scrollY = objectYPosition - self.h*pct + 10*self.scaleFactor     --10 pixels is added so that the bottom of the object is not exactly on to the bottom of the scroll pane.

            if self.scrollY > self.scrollBarRange then
                self.scrollY = self.scrollBarRange
            end
        end

        self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
        self:notifyListeners(app.model.events.EVENT_SCROLL) 
        self:invalidate()
    end
end

--Move the object to viewport; this will be used when percentage is not indicated
function ScrollBar:moveObjectToView(objectYPosition, objectHeight)
    local paneYBottom = self.paney + self.h   --position of last pixel of scroll pane.
    local objectYBottom = objectYPosition + objectHeight - self.scrollY  --position of last pixel of object
    local paneYTop = self.paney
    local objectYTop = objectYPosition - self.scrollY

    --Only scroll if there scrollbar is visible
    if self.visible == true then
        if objectYBottom > paneYBottom then 
            self.scrollY = objectYPosition - paneYBottom + objectHeight + 10*self.scaleFactor     --10 pixels is added so that the bottom of the object is not exactly on to the bottom of the scroll pane.
            if self.scrollY > self.virtualHeight - self.h then self.scrollY = self.virtualHeight - self.h end
            self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
        elseif objectYTop < paneYTop then
            self.scrollY = objectYPosition - self.h - 10*self.scaleFactor       --10 pixels for spacing.
            if self.scrollY < 0 then self.scrollY = 0 end   -- 0 is as far as we can go.
            self.scrollBoxYPosition = self.rectYPosition + (self.scrollY/self.virtualHeight)*self.rectHeight
        end
        
        self:notifyListeners(app.model.events.EVENT_SCROLL)
    end
end

--listener is a callback function.  
function ScrollBar:addListener(listener)
    local listenerID = #self.listeners + 1
    self.listeners[listenerID] = {}
    self.listeners[listenerID][1] = listener
    
    return listenerID  --The caller uses this handle as the ID for later removal of the listener
end

function ScrollBar:removeListener(listenerID)
    self.listeners[listenerID][tag] = nil
end

function ScrollBar:notifyListeners(event)
    for i=1, #self.listeners do
        self.listeners[i][1](event)
    end
end

---------------------------------------------------------
ScrollPane = class(Widget)

--callback is function that paints inside the scroll pane.
function ScrollPane:init(name)
    Widget.init(self, name)
    self.typeName = "scrollpane"
    
    self.innerWidth1 = 1; self.innerWidth2 = 1    --Column Widths
    self.x1Centered = self.x  --left position of scroll pane for drawing objects when centered within pane.
    self.innerWidth1Centered = self.w
    self.x2Centered = self.x  --left position of column 2 of scroll pane for drawing objects when centered within pane.
    self.innerWidth2Centered = self.w
    self.virtualWidth = 0;  self.virtualHeight = 0;       --Number of pixels for the virtual window(the whole length of the area being clipped)
    self.clientWidth = 1   --The width of the scroll pane minus the width of the scroll bar
    self.innerScaleFactor1 = 1
    self.innerScaleFactor2 = 1    --scale factor for second column
    self.column1Pct = 1; self.column2Pct = 0  --Should total 100%
    self.columnCount = 1            --Set to 2 for 2 column.
    self.minInnerScaleFactor1 = 1; self.minInnerScaleFactor2 = 1
    self.allowClip = true

    self.scrollBar = ScrollBar()
    self.scrollBar:setInitSizeAndPosition(12, 1, .95, 0)      --w, h, x, y
    self.scrollBarListenerID = self.scrollBar:addListener(function(...) return self:scrollBarListener(...) end)
    
    self.objects = {}        --objects inside the scroll pane
    self.objectColumns = {} --Column containing object
    self.paintCallback = nil
    
    self.drawPaneBorder = false
    self.drawCenteredBorder = false
    self.drawVirtualHeight = false
    self.drawDebugInfo = false

    self.zOrder = {}
end

function ScrollPane:resize(panex, paney, panew, paneh, scaleFactor)
    Widget.resize(self, panex, paney, panew, paneh, scaleFactor)

    self.scrollBar:setInitSizeAndPosition(self.scrollBar.initWidth, self.h, (self.w - self.scrollBar.w + 1)/self.w, 0)    --Place scrollbar at right edge of scroll pane.
    self.scrollBar:setSize(self.scrollBar.nonScaledWidth, self.nonScaledHeight)  --Yes, you must call setSize() again with the new size
    self.scrollBar:resize(self.x, self.y, self.w, self.h, self.scaleFactor)
end

function ScrollPane:resizeWidgets()
    self:setWidgetPanes()
    self:setWidgetSizes()
    self:setWidgetPositions()
end

--Draw the scroll bar and set the clipRect as scroll pane
function ScrollPane:paint(gc)
    if self.visible == true then 
        if self.allowClip == true then gc:clipRect("set", self.x, self.y, self.w, self.h) end
       
        -- paint with zOrder
        for a = 1, #self.zOrder do
            self.objects[self.zOrder[a]]:paint( gc )
        end

        if self.paintCallback ~= nil then self.paintCallback(gc) end     --Call the client painting routine to draw onto our scrollPane.

        if self.drawDebugInfo == true then    
            gc:setFont("sansserif", "r", 10)
            gc:drawString("Scale Factor = "..tostring(math.floor(self.scaleFactor*10)/10), self.x1Centered+10, self.y+15)
            gc:drawString("Inner Scale Factor = "..tostring(math.floor(self.innerScaleFactor1*10)/10), self.x1Centered+10, self.y+55)
            gc:drawString("Pane Width = "..tostring(math.floor(self.innerWidth1*10)/10), self.x1Centered+180, self.y+15)
            gc:drawString("Pane Width Centered = "..tostring(math.floor(self.innerWidth1Centered*10)/10), self.x1Centered+180, self.y+25)
            gc:drawString("Pane Height = "..tostring(math.floor(self.h*10)/10), self.x1Centered+180, self.y+38)
            gc:drawString("w/hw = "..tostring(math.floor(self.innerWidth1/318*10)/10), self.x1Centered+180, self.y+55)
            gc:drawString("h/vh = "..tostring(math.floor(self.h/self.virtualHeight*10)/10), self.x1Centered+180, self.y+70)
            gc:drawString("iw/h = "..tostring(math.floor(self.innerWidth1/self.h*10)/10), self.x1Centered+180, self.y+85)
            gc:drawString("vh = "..tostring(math.floor(self.virtualHeight*10)/10), self.x1Centered+180, self.y+self.virtualHeight - 20 - self.scrollBar.scrollY)
            gc:drawString("vh = "..tostring(math.floor(.5*self.virtualHeight*10)/10), self.x1Centered+180, self.y+.5*self.virtualHeight - self.scrollBar.scrollY)
        end
        
        --Scrollpane
        if self.drawPaneBorder == true then
            gc:setColorRGB(255, 0, 0)
            gc:drawRect(self.x, self.y, self.w - 1, self.h - 1)  --  -1 is necessary because rectangle height of 1 is actually 2 lines.  
            gc:drawString("ScrollPane", self.x+10, self.y + self.h - self.stringTools:getStringHeight("ScrollPane", "sansserif", "r", 10))
        end
        
        --Centered area
        if self.drawCenteredBorder == true then
            gc:setColorRGB(0, 0, 255)
            gc:drawRect(self.x1Centered, self.y, self.innerWidth1Centered - 1, self.h - 1) --  -1 is necessary because rectangle height of 1 is actually 2 lines.  
            gc:drawLine(self.x1Centered + .5*self.innerWidth1Centered, self.y, self.x1Centered + .5*self.innerWidth1Centered, self.y + self.h)
            gc:drawLine(self.x1Centered + .25*self.innerWidth1Centered, self.y, self.x1Centered + .25*self.innerWidth1Centered, self.y + self.h)
            gc:drawString("Centered Bounding Box", self.x1Centered+100, self.y + self.h - self.stringTools:getStringHeight("ScrollPane", "sansserif", "r", 10))

            if self.columnCount == 2 then
                gc:setColorRGB(255, 0, 255)
                gc:drawRect(self.x2Centered, self.y, self.innerWidth2Centered - 1, self.h - 1) --  -1 is necessary because rectangle height of 1 is actually 2 lines.  
                gc:drawLine(self.x2Centered + .5*self.innerWidth2Centered, self.y, self.x2Centered + .5*self.innerWidth2Centered, self.y + self.h)
                gc:drawLine(self.x2Centered + .25*self.innerWidth2Centered, self.y, self.x2Centered + .25*self.innerWidth2Centered, self.y + self.h)
                gc:drawString("Centered Bounding Box", self.x2Centered+100, self.y + self.h - self.stringTools:getStringHeight("ScrollPane", "sansserif", "r", 10))
            end
        end
        
        --virtual height
        if self.drawVirtualHeight == true then
            gc:setColorRGB(0, 255, 0)
            gc:drawLine(self.x, self.y + self.virtualHeight, self.x + self.innerWidth1 - 1, self.y + self.virtualHeight)
            gc:drawString("Virtual Height = "..tostring(self.virtualHeight), self.x+100, self.y + self.virtualHeight - self.stringTools:getStringHeight("ScrollPane", "sansserif", "r", 10))
        end
        
        self.scrollBar:paint(gc)            --Draw the scrollbar
    
        if self.allowClip == true then gc:clipRect("reset") end
    end
end

function ScrollPane:setInitSizeAndPosition(w, h, pctx, pcty)
    if w < 1 then w = 1 end; if h < 1 then h = 1 end
    Widget.setInitSizeAndPosition(self, w, h, pctx, pcty)
end

function ScrollPane:setPane(panex, paney, panew, paneh, scaleFactor)
    Widget.setPane(self, panex, paney, panew, paneh, scaleFactor)
end

function ScrollPane:setSize(w, h)
    Widget.setSize(self, w, h)
    
    self.scrollBar:setPane(self.x, self.y, self.w, self.h, self.scaleFactor)    --We now to need to recalculate the new scroll bar size for use with calculating self.clientWidth.
    self.scrollBar:setSize(self.scrollBar.nonScaledWidth, self.scrollBar.nonScaledWidth)    

    self.clientWidth = self.w - self.scrollBar.w    --This is the width that the client may actually draw into.
    self.innerWidth1 = self.column1Pct * self.clientWidth; self.innerWidth2 = self.column2Pct * self.clientWidth   --Split columns 1 and 2 by percentage.
    self.innerWidth1Centered = self.innerWidth1; self.innerWidth2Centered = self.innerWidth2

end

function ScrollPane:setWidgetPanes()
    for k, v in pairs(self.objects) do 
        if self.objectColumns[v.name] == 2 then
            v:setPane(self.x2Centered, self.y, self.innerWidth2Centered, self.virtualHeight, self.innerScaleFactor2)       
        else
            v:setPane(self.x1Centered, self.y, self.innerWidth1Centered, self.virtualHeight, self.innerScaleFactor1)       
        end        
    end
end

function ScrollPane:setWidgetSizes()
    for k, v in pairs(self.objects) do
        v:setSize(v.nonScaledWidth, v.nonScaledHeight)   
    end
end

function ScrollPane:setWidgetPositions()
    for k, v in pairs(self.objects) do 
        v:setPosition(v.pctx, v.pcty) 
    end
end

--Sets the virtual width and height of the scrollpane.  This will activate the scroll bar as necessary.
function ScrollPane:setVirtualSize(virtualWidth, virtualHeight)
    self.virtualHeight = virtualHeight; self.virtualWidth = virtualWidth        --These values don't scale.
    self.scrollBar:setVirtualHeight(self.virtualHeight)

    if self.scrollBar.active == true and self.h < self.virtualHeight then
        self.scrollBar:setVisible(true)       --Turn on scrollbar if the virtual height is more than what is available in the scroll pane.
    else
        self.scrollBar:setVisible(false)
    end
end

--Sets the scroll pane column percents.  Set pctColumn2 = 0 to create a 1 column pane.
function ScrollPane:setColumns(pctColumn1, pctColumn2)
    self.column1Pct = pctColumn1
    self.innerWidth1 = self.column1Pct * self.clientWidth 
    self.innerWidth1Centered = self.innerWidth1

    self.column2Pct = pctColumn2
    self.innerWidth2 = self.column2Pct * self.clientWidth
    self.innerWidth2Centered = self.innerWidth2

    if pctColumn2 ~= 0 then
        self.columnCount = 2
    else
        self.columnCount = 1
    end
end

--Adds an object to the scroll pane
function ScrollPane:addObject(object, column)
    self.objects[object.name] = object
    self.zOrder[#self.zOrder+1] = object.name -- sets the zOrder for the object added
    if column == nil then column = 1 end        --Default to column 1 of scroll pane.
    self.objectColumns[object.name] = column
    object.scrollPane = self
end

--Sets the column where the object should be positioned
function ScrollPane:setObjectColumn(object, column)
    self.objectColumns[object.name] = column
end

--Move the scroll pane object into view, pct is the percentage of viewport where the object should appear
--0 will move the object to the top of the viewport, 1 will move the object to the end of the viewport
function ScrollPane:scrollIntoView(objectName, pct)
    if objectName == "TOP" then
        self.scrollBar:scrollIntoView(pct or 0, 0)
    elseif objectName == "END" then
        self.scrollBar:scrollIntoView(pct or 0, self.virtualHeight)
    elseif self.objects[objectName] ~= nil then
        local objectYPosition = self.objects[objectName].y + self.objects[objectName].h
        
        if pct ~= nil  then
            self.scrollBar:scrollIntoView(pct, self.objects[objectName].y)
        elseif objectYPosition > self.h or self.objects[objectName].y - self.scrollBar.scrollY < self.y then   --check whether the object is outside of the scrollpane
            self.scrollBar:moveObjectToView(self.objects[objectName].y, self.objects[objectName].h)
        end
    end
end

--Don't allow the inner scale factor to drop below this amount
--min1 is for column1, min2 is for column2 
function ScrollPane:setScaleFactorMinimum(min1, min2)
    self.minInnerScaleFactor1 = math.max(min1, 1)
    self.minInnerScaleFactor2 = math.max(min2, 1)
end

--Centers horizontally if the horiztonal scaleFactor is largest.
function ScrollPane:centerPane()
    local extraPixels = 0
    
    self.x1Centered = self.x
    self.innerWidth1Centered = self.innerWidth1
    self.x2Centered = self.x + self.innerWidth1
    self.innerWidth2Centered = self.innerWidth2

    --If the width inner scale factor is greater than the height inner scale factor, then there will be extra horizontal spaces, so center.
  if self.innerWidth1 > app.HANDHELD_WIDTH and self.innerWidth1/app.HANDHELD_WIDTH > self.h/self.virtualHeight then
        extraPixels = self.innerWidth1 - self.innerScaleFactor1 * app.HANDHELD_WIDTH  --HANDHELD_WIDTH / HANDHELD_HEIGHT * self.h  --self.innerScaleFactor1 * HANDHELD_WIDTH 
        self.x1Centered = self.x + extraPixels / 2
        self.innerWidth1Centered = self.innerWidth1 - extraPixels
        self.innerWidth1Centered = math.min(self.innerWidth1Centered, self.innerWidth1)     --Don't allow width to grow wider than what is available.    
  end

  if self.columnCount == 2 then
      if self.innerWidth2 > app.HANDHELD_WIDTH and self.innerWidth2/app.HANDHELD_WIDTH > self.h/self.virtualHeight then
            extraPixels = self.innerWidth2 - self.innerScaleFactor2 * app.HANDHELD_WIDTH
            self.x2Centered = self.x + self.innerWidth1 + extraPixels / 2
            self.innerWidth2Centered = self.innerWidth2 - extraPixels
            self.innerWidth2Centered = math.min(self.innerWidth2Centered, self.innerWidth2)     --Don't allow width to grow wider than what is available.    
        end
    end    

    if self.x1Centered < 0 then self.x1Centered = 0 end
    if self.innerWidth1Centered < 1 then self.innerWidth1Centered = 1 end
    if self.x2Centered < 0 then self.x2Centered = 0 end
    if self.innerWidth2Centered < 1 then self.innerWidth2Centered = 1 end
end

--The scale factor is calculated as a percentage of the initial designed-for width and height, scaling to match the original design, just bigger.
--self.scrollPane.innerScaleFactor = math.min(w/HANDHELD_WIDTH, h/HANDHELD_HEIGHT)  --Only scale 50% because of two-pane layout.
--w is clientWidth, h is pixel height, vh is virtual height
--Pass in: if nothing is passed in, then the values will be calculated.  Otherwise, the values will be set.
function ScrollPane:setInnerScaleFactor(innerScaleFactor1, innerScaleFactor2)
  if innerScaleFactor1 == nil then
    self.innerScaleFactor1 = math.min(self.innerWidth1/app.HANDHELD_WIDTH, self.h/self.virtualHeight)   --Try to squeeze it all onto the viewable area.
    self.innerScaleFactor1 = self.innerScaleFactor1 * .95   --need a little buffer
  else
    self.innerScaleFactor1 = innerScaleFactor1
  end
  self.innerScaleFactor1 = math.max(self.innerScaleFactor1, self.minInnerScaleFactor1)      --A scale factor of 1 is as small as we get.  If the original innerScaleFactor was less than the set minimum, the scroll bar will appear. 

  if innerScaleFactor2 == nil then
    self.innerScaleFactor2 = math.min(self.innerWidth2/app.HANDHELD_WIDTH, self.h/self.virtualHeight)   --Try to squeeze it all onto the viewable area.
    self.innerScaleFactor2 = self.innerScaleFactor2 * .95   --need a little buffer
  else
    self.innerScaleFactor2 = innerScaleFactor2
  end
  self.innerScaleFactor2 = math.max(self.innerScaleFactor2, self.minInnerScaleFactor2)      --A scale factor of 1 is as small as we get.  If the original innerScaleFactor was less than the set minimum, the scroll bar will appear.
end

function ScrollPane:contains(x, y)
    local xExpanded = x - .5*self.mouse_xwidth            --Expand the location where the screen was touched.
    local yExpanded = y - .5*self.mouse_yheight
    local scrollY = 0
        
    if self.scrollPane ~= nil then  scrollY = self.scrollPane.scrollBar.scrollY  end
    
    local x_overlap = math.max(0, math.min(self.x+self.w, xExpanded + self.mouse_xwidth) - math.max(self.x, xExpanded))
    local y_overlap = math.max(0, math.min(self.y+self.h-scrollY, yExpanded + self.mouse_yheight) - math.max(self.y-scrollY, yExpanded))
    
    if x_overlap * y_overlap > 0 then  return 1  end    --If there is an intersecting rectangle, then this point is selected.
    
    return 0
end

function ScrollPane:mouseDown(x, y)
    local retVal = false

    if self.active == true and self.visible == true then
        retVal = self.scrollBar:mouseDown(x, y)
        
        if retVal ~= true then
            for k, v in pairs(self.objects) do 
                retVal = v:mouseDown(x, y) 
                if retVal == true then break end
            end
        end
        
        if retVal ~= true then
            local b = self:contains(x, y)
            
            if b == 1 then
                self.tracking = true
                if self.hasGrab == true then            --Only allow changing of position if self.hasGrab is true
                    self.xGrabOffset = x - self.x + self.panex
                    self.yGrabOffset = y - self.y + self.paney
                end
                
                retVal = true --Event handled
            end
        end
    end
    
    return retVal 
end

function ScrollPane:mouseUp(x, y)
    if self.active == true and self.visible == true then
        local scrollBarArea = self.scrollBar:mouseUp(x, y)

        for k, v in pairs(self.objects) do 
            v:mouseUp(x, y) 
        end
        
        if self.tracking == true then
            if self.clickFunction then
                self.clickFunction()
            end
            self.tracking = false
        end
    end
end

function ScrollPane:mouseMove(x, y)
    if self.active == true and self.visible == true then
        self.scrollBar:mouseMove(x,y)
        
        for k, v in pairs(self.objects) do 
            v:mouseMove(x, y) 
        end

        if self.hasGrab == true and self.tracking == true then
            local pctx = math.max(0, (x - self.xGrabOffset)/self.panew)     --Limit left side to 0
            local pcty = math.max(0, (y - self.yGrabOffset)/self.paneh)
            self:setPosition(pctx, pcty)
            self:centerPane()
            
            --Scrollbar
            self.scrollBar:setPane(self.x, self.y, self.w, self.h, self.scaleFactor)
            self.scrollBar:setPosition(self.scrollBar.pctx, self.scrollBar.pcty)
            
            --Widgets
            self:setWidgetPanes()
            self:setWidgetPositions()
        end
    end
end

function ScrollPane:arrowUp()
    if self.active == true and self.visible == true then
        self.scrollBar:arrowUp()
    end
end

function ScrollPane:arrowDown()
    if self.active == true and self.visible == true then
        self.scrollBar:arrowDown()
    end
end

--The scroll position has changed, so notify all the widgets.
function ScrollPane:scrollBarListener(event)
    if event == app.model.events.EVENT_SCROLL then
        self:invalidate()
        for k, v in pairs(self.objects) do 
            v:setScrollY(self.scrollBar.scrollY) 
        end
    end
end

function ScrollPane:setZOrder( objectName, idx )
    local currentIdx = 0
    for a = 1, #self.zOrder do -- Find the object first. Check if it exists.
        if self.zOrder[a] == objectName then 
            currentIdx = a 
            break 
        end
    end
    
    if currentIdx > 0 then -- Object exists. Re-assign zOrder index
        table.remove( self.zOrder, currentIdx ) -- remove this from table
        if idx <= #self.zOrder and idx > 0 then 
            table.insert( self.zOrder, idx, objectName ) -- add in between tables
        elseif idx > #self.zOrder then
            table.insert( self.zOrder, objectName ) -- add to top
        else
            table.insert( self.zOrder, 1, objectName ) -- add to bottom
        end
    end
end

function ScrollPane:getZOrder( objectName )
    local currentIdx = 0

    for a = 1, #self.zOrder do
        if self.zOrder[a] == objectName then 
            currentIdx = a 
            break 
        end
    end
    
    return currentIdx   
end

-------------------------------------------------
Footer = class(Widget)

--callback is function that paints inside the scroll pane.
function Footer:init(name)
    Widget.init(self, name)
    self.typeName = "footerpane"
    
    self.objects = {}
    
    self.progressBarVisible = false
    self.progressPct = 0
end    

function Footer:resizeWidgets()
    self:setWidgetPanes()
    self:setWidgetSizes()
    self:setWidgetPositions()
end

function Footer:paint(gc)
    if self.visible then
        self:paintProgressBar(gc)

        for k, v in pairs(self.objects) do
            v:paint(gc) 
        end
        
        --DEBUG: memory usage
        gc:setFont( "sansserif", "r", 8 )  
        if app.model.showMemoryUsage then gc:drawString( tostring(collectgarbage("count")*.001).."mb "..tostring(app.frame.invalidateDirty), self.x + 100, self.y - 20 ) end
    end
end
    
function Footer:paintProgressBar(gc)
    if self.progressBarVisible == true then
        gc:setColorRGB(unpack(app.graphicsUtilities.Color.green))
        gc:fillRect(self.x, self.y + 1, self.progressPct * self.w, self.h)
    end
end

function Footer:addObject(object)
    self.objects[object.name] = object
    object.scrollPane = nil
end

function Footer:setWidgetPanes()
    for k, v in pairs(self.objects) do 
        v:setPane(self.x, self.y, self.w, self.h, self.scaleFactor)       
    end
end

function Footer:setWidgetSizes()
    for k, v in pairs(self.objects) do 
        v:setSize(v.nonScaledWidth, v.nonScaledHeight)       
    end
end

function Footer:setWidgetPositions()
    for k, v in pairs(self.objects) do 
        v:setPosition(v.pctx, v.pcty) 
    end
end

--Pass in Percent as decimal
function Footer:setProgressBar(pct)
    self.progressPct = pct
    self:invalidate() 
end

function Footer:setProgressBarVisible(b)
    self:invalidate()
    self.progressBarVisible = b
end

function Footer:invalidate()
    app.frame:setInvalidatedArea(self.x, self.y, self.w, self.h)
end

---------------------------------------------------------------------
Line = class(Widget)

function Line:init(name)
    Widget.init(self, name)
    self.typeName = "line"
    
    --Custom properties
    self.fontColor = {0, 0, 0}
end

function Line:paint( gc )
    if self.visible then
        local x = self.x
        local y = self.y - self.scrollY
        
        gc:setColorRGB(unpack(self.fontColor))
		gc:setPen("thin", "smooth")
		
        gc:drawLine(x, y, x + self.w, y)
        
        self:drawBoundingRectangle(gc)
    end
end

-------------------------------------
--##FRAMEWORK END

------------------------------------------------------------
--##FRAMEWORK - CUSTOM

----------------------------------------------------------
Rationals = class()

function Rationals:init()
  self.trim = app.stringTools.trim
  self.splitInTwo = app.stringTools.splitInTwo
  self.removeWhiteSpace = app.stringTools.removeWhiteSpace
  self.reverseFind = app.stringTools.reverseFind
end

--Returns the simplest format of a decimal number (remove leading zeros, trailings zeros, leading + symbol and optional decimal point)
function Rationals:simplifyDecimal(s)
    local idx, val
    local isNegative = false

    if s == nil or tonumber(s) == nil then return s end

    s = self:trim(s)        --Remove leading and trailing whitespace.

    if s == "" then return s end        --If s is now nil empty, then return s.

    idx = string.find(s, "%a")          --Find the first letter.
    if idx ~= nil then return s end                 --If there is a letter, then this is not a number.

    --If the number is zero, then return it as "0"
    val = tonumber(s)
    if val == 0 or val == -0 then return "0" end

    if s:sub(1,1) == "-" then           --If the first character is a negative sign, the remove it temporarily.
        s = s:sub(2)
        isNegative = true
    elseif s:sub(1,1) == "+" then        --Remove a leading + sign since it is optional.
        s = s:sub(2)
    end

    idx = string.find(s, "[^0]")       --Find the first non-zero character.
    if idx == nil then                  --If there is no character that's not a zero, then the number is 0.
        return "0"
    end

    s = s:sub(idx)        --Get all characters from the first non-zero character and to the right, so now we've removed all leading zeros up to the decimal point.
    idx = string.find(s, "%.")   --Locate the decimal point
    if idx == nil then
        s = s.."."  --Append a decimal point so that the next reverse search won't accidentally find a zero in a number like 40.
    end
    s = s:reverse()
    idx = string.find(s, "[^0]")  --Find the first non-zero character counting in from the right.
    s = s:sub(idx)        --Get all characters from the first non-zero character and to the right, so now we've removed all trailing zeros after the decimal point.
    s = s:reverse()

    if s:sub(-1, -1) == "." then
        s = s:sub(1, -2)        --Remove the decimal point if it's the last character
    end

    if isNegative == true then
        s = "-"..s
    end

    return s
end

--allowReducing is true if equivalent fractions are allowed.
function Rationals:simplifyRational(s, allowReducing)
    local numerator, denominator, gcd, n, d, retString

    if s == nil then return s end

    s = self:trim(s)
    if s == "" then return s end

    numerator, denominator = self:splitInTwo(s, "/")    --If this is a fraction, then get the numerator and denominator.
    --if numerator == "-" then numerator = "-1" end           --If only the negative sign is available, then make it -1.
    if denominator == "" then denominator = "1" end     --If this is a whole number, turn it into a fraction.

    n = tonumber(numerator)
    d = tonumber(denominator)

    if n == nil or d == nil then return s end       --If some failure happens, then return the original string.

    --Only do GCD and simplify fraction if both numbers are integers.
    if allowReducing == true and math.floor(n) == n and math.floor(d) == d then
        gcd = self:GCD(n, d)
        n = n / gcd
        d = d / gcd
    end

    numerator = tostring(n)                             --tostring() makes a decimal look like 0.5.
    denominator = tostring(d)

    numerator = self:simplifyDecimal(numerator)         --Convert value such as +02.00 to just 2
    denominator = self:simplifyDecimal(denominator)

    if denominator == "1" then
        retString = numerator
    else
        retString = numerator.."/"..denominator
    end

    return retString
end

--Find the place value of the decimal value.  Returns 0 for ones, 1 for tenths, etc.
function Rationals:findDecimalPlaceValue(s)
    local idx

    if s == nil then return -1 end

    s = self:trim(s)        --Remove leading and trailing whitespace.

    if s == "" then return -1 end        --If s is now nil empty, then return s.

    idx = string.find(s, "%.")   --Locate the decimal point
    if idx == nil then
        return 0                --No decimal point, so place value is the 10^0
    else
        return string.len(s) - idx     --Return the place value.  1 = tenths, 2, hundredths, ...
    end
end

--Find the greatest common divisor
function Rationals:GCD(a, b)
   if b == 0 then 
      return a      --If the divisor is zero, meaning that there is no remainder, then we're done.
   end
   
   return self:GCD(b, a%b)      --Recursion.  Call self with denominator and modulo of numerator divided by denominator.  E.g.  3/6.  a%b=3, then 6/3.  a%b=0, so return 3,0, so finally return 3.
end

--Find the lowest common multiple
function Rationals:LCM(a, b)
   
   return (a*b) / self:GCD(a, b)      --Multiply the two values together to get a common multiple, then divide by the the GCD to get the lowest common multiple
end

--str is a string with decimal values
--converts decimal value to fraction, whole number is returned as whole number
function Rationals:toFraction(str, allowReducing)
    local numOfDp, decimalPointIdx 
    local decimalValue, wholeNum, numerator, denominator
    local i, fractionPart, retString
    
    if allowReducing == nil then allowReducing = false end       --default
    
    str = self:simplifyDecimal(str)
    numOfDp = self:findDecimalPlaceValue(str)
    decimalPointIdx = string.find(str, ".", 1, true)
    
    if decimalPointIdx == nil then      --no decimal places
        return str 
    elseif decimalPointIdx == 1 then
        wholeNum = ""
        decimalValue = string.sub(str, 2, #str)
        numerator = decimalValue
    else
        wholeNum = string.sub(str, 1, decimalPointIdx-1)
        if wholeNum == "0" then wholeNum = "" end
        
        decimalValue = string.sub(str, decimalPointIdx+1, #str)
        
        if #decimalValue == numOfDp then
            numerator = decimalValue
        elseif #decimalValue < numOfDp then
            numerator = decimalValue
            
            for i=1, numOfDp-#decimalValue do
                numerator = numerator.."0"
            end
        end
    end  
    
    denominator = 1
    
    for i=1, numOfDp do
        denominator = denominator.."0"
    end     
    
    fractionPart = numerator.."/"..denominator
    fractionPart = self:simplifyRational(fractionPart, allowReducing)
    retString = wholeNum.." "..fractionPart
    
    return retString
end

--s is a mixed number.  Converts 5 1/2 to 11/2
function Rationals:convertToImproper(s)
    s = app.rationals:trim(s)
    
    local wholeNum, fraction = app.stringTools:splitInTwo(s, " ")
    wholeNum = app.rationals:trim(wholeNum)
    fraction = app.rationals:trim(fraction)
    
    local numerator, denominator = app.stringTools:splitInTwo(fraction, "/")
    local isNegative = false
    local improperNum
    
    if tonumber(wholeNum) < 0 then
        isNegative = true
    end
    
    improperNum = tonumber(denominator) * math.abs( tonumber(wholeNum) ) + tonumber(numerator)
    
    if isNegative == true then
        return "-"..improperNum.."/"..denominator
    else
        return improperNum.."/"..denominator
    end
end

--s is string to convert, allowReducing = true means to reduce fractions, simplestForm = true means to simplify 0 1/2 to 1/2.  makeProper means 5/2 = 2 1/2.  makeMixed means 1/2 = 0 1/2.
function Rationals:simplifyMixed(s, allowReducing, simplestForm, makeProper, makeMixed)
    local idx, idx2, num, n, d, w, w2, r, f
    local retString = nil   --Set this to a value
  
    --Parse the string into a whole, fraction or mixed.
    local whole, fraction = self:parseForNumber(s)  

    --Place the negative sign onto the numerator only and simplify the fraction as necessary.
    if fraction ~= "" then
        numerator, denominator = self:splitInTwo(fraction, "/")  
        if string.sub(numerator, 1, 1) == "-" and string.sub(denominator, 1, 1) == "-" then
            numerator = string.sub(numerator, 2)
            denominator = string.sub(denominator, 2)
            if simplestForm == true then
                fraction = self:simplifyDecimal(numerator).."/"..self:simplifyDecimal(denominator)
            else
                fraction = numerator.."/"..denominator
            end
        elseif string.sub(numerator, 1, 1) == "-" then
            numerator = string.sub(numerator, 2)
            if simplestForm == true then
                fraction = "-"..self:simplifyDecimal(numerator).."/"..self:simplifyDecimal(denominator)
            else
                fraction = "-"..numerator.."/"..denominator
            end
        elseif string.sub(denominator, 1, 1) == "-" then
            denominator = string.sub(denominator, 2)
            if simplestForm == true then
                fraction = "-"..self:simplifyDecimal(numerator).."/"..self:simplifyDecimal(denominator)
            else
                fraction = "-"..numerator.."/"..denominator
            end
        else
            if simplestForm == true then
                fraction = self:simplifyDecimal(numerator).."/"..self:simplifyDecimal(denominator)
            else
                fraction = numerator.."/"..denominator
            end
        end

        --Simplify the fraction as required. 
        if allowReducing == true then
            fraction = self:reduceFraction(fraction)
        end
    end

    if fraction ~= "" then
        --If the fraction ended up with no /, then the input was invalid.
        if string.find(fraction, "/", 1, true) == nil then
          retString = ""
        else
             if makeProper == true then
                numerator, denominator = self:splitInTwo(fraction, "/")    --If this is a fraction, then get the numerator and denominator.
                
                n = tonumber(numerator)
                d = tonumber(denominator)
                w = tonumber(whole)
       
                if whole == "-" or whole == "." or whole == "+" or (w == nil and whole ~= "") or n == nil or d == nil then
                    retString = ""
                else
                    --If the fraction portion is an improper fraction, the convert to mixed and add to existing whole number
                    if math.abs(n) >= d then
                        w2 = math.floor(math.abs(n) / d)
                        r = math.abs(n) % d       --The remainder becomes the numerator of the proper fraction.
                 
                        if whole == "" then
                            if string.sub(numerator, 1, 1) == "-" then
                                whole = "-"..tostring(w2)
                            else
                                whole = tostring(w2)
                            end
                        else
                            if string.sub(whole, 1, 1) == "-" then
                                whole = "-"..tostring(math.abs(w) + math.abs(w2))
                            else
                                whole = tostring(w + w2)
                            end
                        end
                        fraction = tostring(r).."/"..denominator
                    end
                end
            end
        end
    end

    --If the fraction has a negative sign, then the entire value is negative.
    if fraction ~= "" then
        if string.sub(fraction, 1, 1) == "-" then
            if whole ~= "" then
                if string.sub(whole, 1, 1) == "-" then
                    whole = whole
                    fraction = string.sub(fraction, 2)
                else
                    if whole == "-0" then
                        whole = whole
                        fraction = fraction
                    else
                        whole = "-"..whole
                        fraction = string.sub(fraction, 2)
                    end
                end            
            elseif whole == "-0" then
                whole = whole
                fraction = fraction
            end
        end
    end
  
    if whole ~= "" then
        if whole == "-" or tonumber(whole) == nil then
            retString = ""
        end
    end
 
    --If retString has not yet been set, then everything is valid.
    if retString == nil then
        if simplestForm == true then
            if fraction == "" then
                retString = self:simplifyDecimal(whole)
            else
                numerator, denominator = self:splitInTwo(fraction, "/")    
                if (whole == "0" or whole == "-0") then
                    if numerator == "0" or numerator == "-0" then
                        retString = "0"
                    elseif whole == "0" then
                        retString = fraction
                    elseif whole == "-0" then
                        retString = "-"..fraction
                    end
                elseif numerator == "0" or numerator == "-0" then
                    if whole == "" then
                        retString = "0"
                    else
                        retString = self:simplifyDecimal(whole)
                    end
                else
                    if whole == "" then
                        retString = fraction
                    else
                        retString = self:simplifyDecimal(whole).." "..fraction
                    end
                end
            end
        else
            if fraction == "" then
                retString = whole
            elseif whole == "" then
                retString = fraction
            else
                retString = whole.." "..fraction
            end
        end

        if makeMixed == true then
            if fraction == "" then
                fraction = "0/1"
            end
            if whole == "" then
                whole = "0"
            end
            retString = whole.." "..fraction
        end
    end    
        
    return retString, whole, fraction
end

--Takes a string parses a whole number and fraction part.  If there is no whole, then "" is returned. If there is no fraction, then "" is returned.
function Rationals:parseForNumber(s)
    local idx, idx2, idx3, num, fraction, whole
  
    --Remove leading and trailing whitespace.
    s = self:trim(s)

    --The string is a whole number if there is no fraction bar.
    idx = string.find(s, "/", 1, true)
    if idx == nil then
        fraction = ""
        whole = s
    else
        idx2 = app.stringTools:reverseFind(s, " ", idx - 1, true)       --The first whitespace going to the left represents the left marker for the numerator of the fraction.
        if idx2 == nil then
            fraction = s
            whole = ""
        else
            fraction = string.sub(s, idx2)    --The fraction part is everything to the right of the whitespace.
            idx3 = app.stringTools:reverseFind(s, " ", idx2 - 1, true)       --The second whitespace going to the left represents the left marker for the whole number, unless it is a negative sign.
            if idx3 == nil then
                if self:trim(string.sub(s, 1, idx2)) == "-" then        --If there is no second whitespace, but the second chunk is only a negative sign, then attach tne neg. to the fraction.
                    fraction = "-"..fraction
                    whole = ""
                else
                    if string.sub(self:trim(fraction), 1, 1) == "/" then        --Attach the negative sign to the fraction.
                        fraction = s      --The second white space marks the numerator
                        whole = ""
                    else
                        fraction = string.sub(s, idx2)      --The second white space marks the whole number.
                        whole = string.sub(s, 1, idx2 - 1)
                    end
                end
            else
                if string.sub(s, 1, idx3 - 1) == "-" then      
                    if string.sub(self:trim(fraction), 1, 1) == "/" then        --Attach the negative sign to the fraction.
                        fraction = s
                        whole = ""
                    else
                        fraction = fraction
                        whole = string.sub(s, 1, idx2 - 1)
                    end
                else
                    if string.sub(self:trim(fraction), 1, 1) == "/" then        --Attach the negative sign to the fraction.
                        fraction = string.sub(s, idx3, idx2 - 1)..fraction  --Everything to the right is the fraction
                        whole = string.sub(s, 1, idx3 - 1)  --Everything to the left is the whole
                    else
                        whole = string.sub(s, 1, idx3)  --Everything to the left is the whole
                    end                    
                end
            end
        end
    end
    
    return self:removeWhiteSpace(whole), self:removeWhiteSpace(fraction)
end

--Reduce a fraction to simplest terms, but keep in fraction form.
function Rationals:reduceFraction(s)
    local numerator, denominator, gcd, n, d, retString

    if s == nil then return s end

    s = self:trim(s)
    
    if s == "" then return s end

    numerator, denominator = self:splitInTwo(s, "/")    --If this is a fraction, then get the numerator and denominator.

    n = tonumber(numerator)
    d = tonumber(denominator)

    if n == nil or d == nil then return s end       --If some failure happens, then return the original string.

    --Only do GCD and simplify fraction if both numbers are integers.
    if math.floor(n) == n and math.floor(d) == d then
        gcd = self:GCD(n, d)
        n = n / gcd
        d = d / gcd
    end

    numerator = tostring(n)                             --tostring() makes a decimal look like 0.5.
    denominator = tostring(d)

    retString = numerator.."/"..denominator

    return retString
end

--Determines if a value is an Integer
function Rationals:isInteger(x)
  if math.abs(self:cleanupMath(x)) % 1 == 0 then
    return true
  else
    return false
  end
end

--Takes a numeric value and gets rid of the tiny junk at the end of the number.
--Clips to the 1/10000 place.
function Rationals:cleanupMath(x)
  return math.floor((x*10000+.5))/10000
end

-- get factors of numbers
function Rationals:getFactors( n )
    local tbl = {}
    
    local n = math.abs( tonumber( n ))
    for a = 0, n do
        if self:cleanupMath( n % a ) == 0 then
            table.insert( tbl, a)
        end
    end

    return tbl
end

function Rationals:multiply( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:multiply() -> Pass correct values!" ) end
    
    return self:cleanupMath( a*b )
end

function Rationals:divide( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:divide() -> Pass correct values!" ) end
    
    return self:cleanupMath( a/b )
end

function Rationals:add( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:add() -> Pass correct values!" ) end
    
    return self:cleanupMath( a+b )
end

function Rationals:raise( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:raise() -> Pass correct values!" ) end
    
    return self:cleanupMath( a^b )
end

function Rationals:subtract( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:subtract() -> Pass correct values!" ) end
    
    return self:cleanupMath( a-b )
end

function Rationals:mod( a, b )
    local a, b = tonumber( a ), tonumber( b )
    
    if not a or not b then assert( false, "Rationals:mod() -> Pass correct values!" ) end
    
    return self:cleanupMath( a%b )
end

--returns the sum of the number's digits
function Rationals:computeChecksum(n)
    local checksum = 0
    
    while n > 0 do
        checksum = checksum + self:mod(n, 10)
        n = math.floor( self:divide(n, 10) )
    end
    
    return checksum
end

--x0, y0 are center of circle in pixels, radius is length of radius, degrees is angle.  0 degrees is on the right side.  90 degrees is at the top.  Returns cartesian degrees.
function Rationals:pointFromDegrees(x0, y0, radius, degrees)
    local x = x0 + radius * math.cos(math.rad(degrees))
    local y = y0 + radius * math.sin(math.rad(degrees)) * -1       --cartesian y is opposite screen y

    return x, y
end

--n is the number to be rounded off, decimals is the number of decimal places to round off
--decimals = 0 if no decimal places are needed to be rounded off
function Rationals:roundHalfUp(n, decimals)
    if decimals == nil then decimals = 0 end
    local multiplier = self:raise( 10, decimals )
    
    return math.floor( n * multiplier + 0.5 ) / multiplier
end

--returns the decimal equivalent of string s
--returns nil if the string is an invalid fraction
function Rationals:toDecimal(s)
    local numStr, denomStr, n, d
    local retValue = nil
    local fractionBarIdx =  string.find(s, "/", 1, true)
    
    if fractionBarIdx ~= nil and fractionBarIdx > 1 then 
        numStr = string.sub(s, 1, fractionBarIdx - 1)
        denomStr = string.sub(s, fractionBarIdx + 1, #s)
        
        n = tonumber(numStr)
        d = tonumber(denomStr)
        
        if n ~= nil and d ~= nil and d ~= 0 then
            retValue = tostring( self:divide(n, d) )
        end
    end
    
    return retValue
end

--allowSimplify = s is simplified first, parentheses are also removed if they are matching
--returns true if s can be simplified and returns a the simplified  value
function Rationals:validateRational(s, allowSimplify)
    s = self:removeWhiteSpace( s )
    if allowSimplify == true then s = app.expressions:removeParentheses(s) end
    
    local result = true
    local simplifiedValue = self:simplifyRational(s, allowSimplify)
    local fractionBarIdx = string.find(s, "/", 1, true)
    local isInvalidFraction = ( fractionBarIdx ~= nil and self:toDecimal( simplifiedValue ) == nil )
    local isNotRational = ( fractionBarIdx == nil and tonumber( simplifiedValue ) == nil )

    if isInvalidFraction or isNotRational then
        result = false
    end
    
    if allowSimplify == nil or allowSimplify == false then simplifiedValue = s end    

    return result, {simplifiedValue}
end

function Rationals:getPrimeNumbers( startNumber, endNumber )
    local tbl = {}
    
    for a = startNumber, endNumber do
        if #self:getFactors( a ) <= 2 then -- there is only 1 and its own
            tbl[ #tbl+1 ] = a
        end
    end
    
    return tbl
end

function Rationals:getCompositeNumbers( startNumber, endNumber )
    local tbl = {}
    
    for a = startNumber, endNumber do
        if #self:getFactors( a ) > 2 then
            tbl[ #tbl+1 ] = a
        end
    end
    
    return tbl
end

-- this function will check if the fraction is valid. with number numerator and denominator
-- note: this will just check if the fraction is a valid fraction
function Rationals:isFraction( s )
    s = app.stringTools:removeWhiteSpace( s ) -- remove additional white space
    local fraction = s
    local divisionSymbol = string.find( fraction, "/" ) -- look for the first division symbol.
    
    if not divisionSymbol then -- there is no division symbol
        return false, "Error: Division symbol (/) does not exist."
    end
    
    -- we found a division symbol. divide the numerator and the denominator.
    local numerator = tonumber( string.sub( fraction, 1, divisionSymbol - 1 ))
    local denominator = tonumber( string.sub( fraction, divisionSymbol + 1 ))
    
    if not numerator then -- numerator is not valid 
        return false, "Error: Invalid numerator."
    end
    
    if not denominator then -- denominator is not valid
        return false, "Error: Invalid denominator."
    end
    
    -- everything is valid to this point.
    return true, s
end

--##WIDGETS - CUSTOM
-----------------------------------------------------
