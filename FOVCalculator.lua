local atan,sqrt,deg,sine,cos,abs = math.atan,math.sqrt,math.deg,math.sin,math.cos,math.abs
local dWriteTextClipped = ui.dwriteDrawTextClipped
local fontDraw = ui.pushDWriteFont
local cspFont = "notosans_cjk@extension"
local vec2save = vec2
local function gcf(a,b)
    if a == 0 or b == 0 then return 0 end
    while b ~= 0 do
        a, b = b, a % b
    end
    return abs(a)
end
local inchCM = 2.54
local sim = ac.getSim()
local firstPersonFOV = {}
local iniConfig = ac.INIConfig
local FOVSetupINI = iniConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/FOVCalculator/FOVSetup.ini")
function firstPersonFOV:init()
    self.resX,self.resY = sim.renderSize.x,sim.renderSize.y
    self.monitorDiagonal = FOVSetupINI:get("SETTING","DIAGONAL",27)
    self.screenDist = FOVSetupINI:get("SETTING","DIST_TO_SCREEN",60)
    self.curvedScreen = FOVSetupINI:get("SETTING","CURVED",false) --Only for hFOV calc, which is not Assetto Corsa's FOV calculation method, used for other sims
    self.curvedRadius = FOVSetupINI:get("SETTING","CURVED_RADIUS",1800) --As above
    self.aspectRatio = self.resX/self.resY
    self.vFOV,self.hFOV = 50,0
    self.ARGCF = gcf(self.resX,self.resY)
    self.ARX,self.ARY = self.resX/self.ARGCF,self.resY/self.ARGCF
end
firstPersonFOV:init()
function firstPersonFOV:calc()
    self.monitorHeight = self.monitorDiagonal/sqrt(self.aspectRatio^2+1)*inchCM
    self.monitorWidth = self.aspectRatio*self.monitorHeight
    self.vFOV = 2*deg(atan(self.monitorHeight/(2*self.screenDist))) --vFOV
    if self.curvedScreen then --hFOV
        self.hFOV = 2*deg(atan((self.curvedRadius*sine(self.monitorWidth/(2*self.curvedRadius)))/(self.screenDist-self.curvedRadius+self.curvedRadius*cos(self.monitorWidth/(2*self.curvedRadius)))))
    else
        self.hFOV = 2*deg(atan(self.monitorWidth/(2*self.screenDist)))
    end
    return self.vFOV,self.hFOV
end
---@param label string
---@param min number
---@param max number
---@param width number
---@param refNumberLabel refnumber
---@param format string
---@param number number
local function simpleSlider(label,min,max,width,refNumberLabel,format,number)
    ui.setNextItemWidth(width)
    ui.slider(label,refNumberLabel,min,max,format)
    return refNumberLabel.value
end
function script.windowMainScript()
    firstPersonFOV:calc()
    if sim.isVRMode or sim.isTripleMode then
        fontDraw(cspFont..";Weight=Bold")
        dWriteTextClipped("This app does not support",25,vec2save(0,50),vec2save(400,80),rgbm.colors.white)
        dWriteTextClipped("VR or Triple Screen.",25,vec2save(0,80),vec2save(400,110),rgbm.colors.white)
        fontDraw(cspFont)
        dWriteTextClipped("For triples, use the default triple screen app.",15,vec2save(0,130),vec2save(400,150),rgbm.colors.white)
        dWriteTextClipped("For VR, FOV ceases to exist.",15,vec2save(0,150),vec2save(400,170),rgbm.colors.white)
        return
    else
        fontDraw(cspFont)
        local refMonitorDiagonal = refnumber(firstPersonFOV.monitorDiagonal)
        local refDistance = refnumber(firstPersonFOV.screenDist)
        local refCurvedRadius = refnumber(firstPersonFOV.curvedRadius)

        ui.text("Diagonal Monitor Size:")
        ui.sameLine()
        firstPersonFOV.monitorDiagonal = simpleSlider("##monitorDiagonal",5,60,ui.availableSpaceX(),refMonitorDiagonal,'%.1f"',firstPersonFOV.monitorDiagonal)
        if ui.itemDeactivatedAfterEdit() then FOVSetupINI:setAndSave("SETTING","DIAGONAL",firstPersonFOV.monitorDiagonal) end

        ui.newLine(-14)
        ui.text("Distance to Screen:")
        ui.sameLine(159)
        firstPersonFOV.screenDist = simpleSlider("##screenDist",20,120,ui.availableSpaceX(),refDistance,'%.1f cm',firstPersonFOV.screenDist)
        if ui.itemDeactivatedAfterEdit() then FOVSetupINI:setAndSave("SETTING","DIST_TO_SCREEN",firstPersonFOV.screenDist) end

        ui.newLine(-14)
        if ui.checkbox("Curved Monitor", firstPersonFOV.curvedScreen) then firstPersonFOV.curvedScreen = not firstPersonFOV.curvedScreen end
        if ui.itemDeactivatedAfterEdit() then FOVSetupINI:setAndSave("SETTING","CURVED",firstPersonFOV.curvedScreen) end
        ui.sameLine(159)
        if firstPersonFOV.curvedScreen then
            firstPersonFOV.curvedRadius = simpleSlider("##curvedRadius",100,5000,ui.availableSpaceX(),refCurvedRadius,"Radius: %.fR",firstPersonFOV.curvedRadius)
            if ui.itemDeactivatedAfterEdit() then FOVSetupINI:setAndSave("SETTING","CURVED_RADIUS",firstPersonFOV.curvedRadius) end
        end

        ui.drawRectFilled(vec2save(0,109),vec2save(400,111),rgbm.colors.gray)
        ui.drawRectFilled(vec2save(199,111),vec2save(201,180),rgbm.colors.gray)
        ui.drawRectFilled(vec2save(0,180),vec2save(400,182),rgbm.colors.gray)
        dWriteTextClipped("vFOV (vertical)",12,vec2save(0,112),vec2save(200,130),rgbm.colors.white)
        dWriteTextClipped("hFOV (horziontal)",12,vec2save(200,112),vec2save(400,130),rgbm.colors.white)
        dWriteTextClipped(string.format("%.2f°",firstPersonFOV.vFOV),40,vec2save(10,120),vec2save(200,170),rgbm.colors.white)
        dWriteTextClipped("Used for all AC's franchise.",10,vec2save(0,160),vec2save(200,185),rgbm.colors.white)
        dWriteTextClipped(string.format("%.2f°",firstPersonFOV.hFOV),40,vec2save(210,120),vec2save(400,170),rgbm.colors.white)
        dWriteTextClipped("Used for some other sims.",10,vec2save(200,160),vec2save(400,185),rgbm.colors.white)
        dWriteTextClipped("Everything saves automatically.",10,vec2save(10,183),vec2save(200,195),ui.Alignment.Start,ui.Alignment.Center,false,rgbm.colors.white)
        dWriteTextClipped(string.format("Res: %.dx%.d, AR: %.d:%.d",firstPersonFOV.resX,firstPersonFOV.resY,firstPersonFOV.ARX,firstPersonFOV.ARY),10,vec2save(200,183),vec2save(390,195),ui.Alignment.End,ui.Alignment.Center,false,rgbm.colors.white)
    end
end
function script.update()
    if sim.isVRMode or sim.isTripleMode then
        return
    else
        ac.setFirstPersonCameraFOV(firstPersonFOV:calc())
    end
end