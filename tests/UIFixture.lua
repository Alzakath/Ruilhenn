-- Control/event harness only; this does not simulate WoW rendering or taint.
return function(env)
    local create = env.CreateFrame
    local function region()
        local object = { shown = true, width = 0, height = 0, value = "", alpha = 1, regions = {} }
        function object:SetPoint(...) self.point = { ... } end
        function object:ClearAllPoints() self.point = nil end
        function object:SetSize(w, h) self.width, self.height = w, h end
        function object:SetWidth(w) self.width = w end
        function object:SetHeight(h) self.height = h end
        function object:GetWidth() return self.width end
        function object:GetHeight() return self.height end
        function object:SetText(value) self.value = value end
        function object:GetText() return self.value end
        function object:SetJustifyH(value) self.justifyH = value end
        function object:SetJustifyV() end
        function object:SetAlpha(value) self.alpha = value end
        function object:GetAlpha() return self.alpha end
        function object:SetWordWrap() end
        function object:SetTextColor(...) self.textColor = { ... } end
        function object:SetShown(value) self.shown = not not value end
        function object:SetTexture(value) self.texture = value end
        function object:SetColorTexture(...) self.color = { ... } end
        function object:SetRotation(value) self.rotation = value end
        function object:Show() self.shown = true end
        function object:Hide() self.shown = false end
        function object:IsShown() return self.shown end
        function object:GetObjectType() return self.objectType or "Texture" end
        function object:IsVisible()
            return self.shown and (not self.parent or self.parent:IsVisible())
        end
        return object
    end
    env.CreateFrame = function(kind, name, parent, template)
        local frame = create(kind, name)
        for key, method in pairs(region()) do frame[key] = method end
        frame.parent, frame.template = parent, template
        frame.frameType, frame.frameName, frame.children = kind, name, {}
        if parent then
            parent.children = parent.children or {}
            table.insert(parent.children, frame)
        end
        function frame:GetObjectType() return self.frameType end
        function frame:GetName() return self.frameName end
        function frame:GetChildren() return unpack(self.children) end
        function frame:GetRegions() return unpack(self.regions or {}) end
        function frame:SetBackdrop() end
        function frame:SetBackdropColor() end
        function frame:SetBackdropBorderColor() end
        function frame:SetScale() end
        function frame:SetFrameStrata() end
        function frame:SetClampedToScreen() end
        function frame:SetMovable() end
        function frame:EnableMouse() end
        function frame:RegisterForDrag() end
        function frame:StartMoving() end
        function frame:StopMovingOrSizing() end
        function frame:SetFrameLevel(level) self.level = level end
        function frame:GetFrameLevel() return self.level or 1 end
        function frame:SetScrollChild(child) self.child = child end
        function frame:SetVerticalScroll(value) self.scroll = value end
        function frame:SetAutoFocus() end
        function frame:ClearFocus() self.focused = false end
        function frame:HighlightText() self.highlighted = true end
        function frame:SetEnabled(value) self.enabled = value end
        function frame:Click()
            if self.shown ~= false and self.enabled ~= false and self.scripts.OnClick then self.scripts.OnClick(self) end
        end
        function frame:CreateFontString() return region() end
        function frame:CreateTexture() return region() end
        frame.fontString = region()
        function frame:GetFontString() return self.fontString end
        function frame:Hide()
            self.shown = false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        if template == "UIPanelScrollFrameTemplate" then
            frame.ScrollBar = env.CreateFrame("Slider", (name or "ScrollFrame") .. "ScrollBar", frame)
            frame.ScrollBar.regions = { region() }
            for _, arrowName in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
                local arrow = env.CreateFrame("Button", frame.ScrollBar.frameName .. arrowName, frame.ScrollBar)
                arrow.regions = {}
                for index = 1, 4 do
                    local texture = region()
                    texture.shown = index > 2
                    arrow.regions[index] = texture
                end
            end
        end
        return frame
    end
    env.UIParent = env.CreateFrame("Frame")
    env.UIParent:SetSize(1920, 1080)
    env.UISpecialFrames = {}
end
