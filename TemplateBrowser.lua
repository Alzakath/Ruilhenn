local _, ns = ...
local UI = { widgets = {}, fonts = {}, category = "overview" }
ns.TemplateBrowser = UI
local Store, L = ns.TemplateStore, ns.L
local categoryKeys = { overview = "UI_OVERVIEW", talents = "UI_TALENTS", bars = "UI_BARS",
    bindings = "UI_BINDINGS", clicks = "UI_CLICKS" }
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local layout = { contentWidth = 748, listWidth = 720, rowHeight = 40, rowGap = 2, overviewHeight = 62 }

local function text(value)
    return tostring(value or ""):gsub("|", "||")
end

local function fadeScrollBarArrowArt(self, scrollBar)
    local skin = self.skin
    if not skin or type(skin.IsEnabled) ~= "function" or not scrollBar or type(scrollBar.GetChildren) ~= "function" then return end
    local enabled, isEnabled = pcall(skin.IsEnabled)
    if not enabled or isEnabled ~= true then return end
    local ok, children = pcall(function() return { scrollBar:GetChildren() } end)
    if not ok then return end

    for _, child in ipairs(children) do
        local gotIdentity, name, objectType = pcall(function()
            return child:GetName(), child:GetObjectType()
        end)
        local isArrow = gotIdentity and type(name) == "string" and
            (name:match("ScrollUpButton$") or name:match("ScrollDownButton$"))
        if isArrow and objectType == "Button" and type(child.GetRegions) == "function" then
            local gotRegions, regions = pcall(function() return { child:GetRegions() } end)
            if gotRegions then
                for _, region in ipairs(regions) do
                    local gotType, regionType = pcall(region.GetObjectType, region)
                    if gotType and regionType == "Texture" and type(region.SetAlpha) == "function" then
                        pcall(region.SetAlpha, region, 0)
                    end
                end
            end
        end
    end
end

local function applySkin(self, widget, kind, options)
    local primitive = self.skin and self.skin[kind]
    if type(primitive) ~= "function" then return false end
    primitive(widget, options)
    if kind == "ScrollBar" then
        fadeScrollBarArrowArt(self, widget)
    end
    return true
end

function UI:Style(frame, kind)
    local options = kind == "Button" and { "icon", "selectionMarker" } or nil
    if options and frame.categoryParts then
        for i = 1, #frame.categoryParts do options[#options + 1] = "categoryPart" .. i end
    end
    self.widgets[#self.widgets + 1] = { frame = frame, kind = kind, options = options }
    applySkin(self, frame, kind, options)
end

local function panel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(0.09, 0.11, 0.12, 0.98)
    frame:SetBackdropBorderColor(0.25, 0.29, 0.30)
    return frame
end

local textColors = {
    primary = { 0.94, 0.95, 0.95 },
    secondary = { 0.76, 0.80, 0.82 },
    supporting = { 0.61, 0.66, 0.68 },
    accent = { 0.047, 0.824, 0.616 },
    green = { 0.35, 0.90, 0.55 },
    amber = { 1.00, 0.70, 0.25 },
    red = { 0.95, 0.35, 0.35 },
}

local function accentColor()
    if UI.skin and UI.skin.GetAccentColor then return UI.skin.GetAccentColor() end
    return textColors.accent[1], textColors.accent[2], textColors.accent[3]
end

local function classColor(class)
    if not class or not C_ClassColor or type(C_ClassColor.GetClassColor) ~= "function" then return end
    local ok, color = pcall(C_ClassColor.GetClassColor, class)
    if not ok or not color then return end
    local r, g, b = color.r, color.g, color.b
    if type(r) ~= "number" and type(color.GetRGB) == "function" then r, g, b = color:GetRGB() end
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then return r, g, b end
end

local sourceNeutral, sourceClassWeight = { 0.72, 0.76, 0.78 }, 0.55
local function sourceColor(class)
    local r, g, b = classColor(class)
    if not r then return unpack(textColors.supporting) end
    return r * sourceClassWeight + sourceNeutral[1] * (1 - sourceClassWeight),
        g * sourceClassWeight + sourceNeutral[2] * (1 - sourceClassWeight),
        b * sourceClassWeight + sourceNeutral[3] * (1 - sourceClassWeight)
end

local function coloredText(value, class, blend)
    local r, g, b
    if blend then r, g, b = sourceColor(class) else r, g, b = classColor(class) end
    local safe = text(value)
    if not r then return safe end
    return ("|cff%02x%02x%02x%s|r"):format(math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), safe)
end

local function segment(texture, parent, x1, y1, x2, y2, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local angle
    if dx == 0 then angle = dy < 0 and -math.pi / 2 or math.pi / 2
    else
        angle = math.atan(dy / dx)
        if dx < 0 then angle = angle + math.pi end
    end
    texture:SetSize(math.sqrt(dx * dx + dy * dy), thickness or 1.8)
    texture:SetPoint("CENTER", parent, "CENTER", x1 + dx / 2 + 14 - parent:GetWidth() / 2,
        9 - (y1 + dy / 2))
    texture:SetRotation(angle)
end

local categoryGlyphs = {
    overview = { {1,8,8,1}, {8,1,15,8}, {3,7,3,16}, {13,7,13,16}, {3,16,13,16}, {6,11,6,16}, {6,11,9,11}, {9,11,9,16} },
    talents = { {8,2,8,7}, {8,7,3,11}, {8,7,13,11}, {3,11,3,15}, {13,11,13,15}, {3,15,13,15}, {1,11,5,11}, {11,11,15,11} },
    bars = { {2,2,14,2}, {2,8,14,8}, {2,14,14,14}, {2,2,2,14}, {8,2,8,14}, {14,2,14,14} },
    bindings = { {1,3,15,3}, {1,13,15,13}, {1,3,1,13}, {15,3,15,13}, {4,5,4,7}, {7,5,7,7}, {10,5,10,7}, {13,5,13,7}, {4,9,4,11}, {7,9,7,11}, {10,9,10,11}, {13,9,13,11} },
    clicks = { {8,1,8,3}, {5,3,11,3}, {3,6,4,12}, {4,4,6,3}, {11,3,13,4}, {13,4,14,7}, {14,7,14,12}, {14,12,12,15}, {12,15,5,15}, {5,15,3,12}, {3,12,3,6}, {6,5,6,9}, {9,5,9,9} },
}

local function createCategoryIcon(control, glyph)
    control.categoryParts = {}
    for i, coords in ipairs(categoryGlyphs[glyph]) do
        local texture = control:CreateTexture(nil, "ARTWORK")
        control["categoryPart" .. i], control.categoryParts[i] = texture, texture
        texture:SetColorTexture(0.7, 0.74, 0.76, 1)
        segment(texture, control, unpack(coords))
    end
    control.categoryGlyph = glyph
end

local function setTextRole(font, role)
    if not font then return end
    font.ruilhennTextRole = role
    local color = textColors[role]
    if role == "accent" then
        local r, g, b = accentColor()
        font:SetTextColor(r, g, b)
    elseif color then
        font:SetTextColor(color[1], color[2], color[3])
    end
end

local function label(parent, size, role)
    local template = size == "large" and "GameFontNormalLarge" or size == "body" and "GameFontNormal" or
        size == "bodySmall" and "GameFontNormalSmall" or "GameFontHighlightSmall"
    local font = parent:CreateFontString(nil, "OVERLAY", template)
    font:SetJustifyH("LEFT")
    font:SetJustifyV("TOP")
    font:SetWordWrap(true)
    UI.fonts[#UI.fonts + 1] = font
    if UI.skin and UI.skin.Font then UI.skin.Font(font) end
    setTextRole(font, role or (size == "large" and "primary" or "secondary"))
    return font
end

local function button(parent, caption, width, callback, kind, glyph)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetSize(width, 28)
    control:SetText(caption)
    control:SetScript("OnClick", callback)
    local font = control:GetFontString()
    font:SetWordWrap(true)
    font:SetTextColor(0.9, 0.94, 0.95)
    if glyph then
        font:ClearAllPoints()
        font:SetPoint("LEFT", 42, 0)
        font:SetPoint("RIGHT", -10, 0)
        font:SetJustifyH("LEFT")
        createCategoryIcon(control, glyph)
    end
    UI.fonts[#UI.fonts + 1] = font
    if UI.skin and UI.skin.Font then UI.skin.Font(font) end
    -- Supply preserved regions before initial skin setup; the public skin
    -- captures these references for later theme updates.
    control.icon = control:CreateTexture(nil, "ARTWORK")
    control.icon:Hide()
    control.selectionMarker = control:CreateTexture(nil, "OVERLAY")
    control.selectionMarker:SetPoint("TOPLEFT", 2, -4)
    control.selectionMarker:SetPoint("BOTTOMLEFT", 2, 4)
    control.selectionMarker:SetWidth(3)
    control.selectionMarker:Hide()
    UI:Style(control, kind or "Button")
    return control
end

local function scroll(parent, name, width, height)
    local frame = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    frame.scrollBarHideable = true
    frame:SetSize(width, height)
    local child = CreateFrame("Frame", nil, frame)
    child:SetSize(width, 1)
    frame:SetScrollChild(child)
    UI:Style(frame.ScrollBar, "ScrollBar")
    return frame, child
end

local function selectNavigation(control, selected)
    control:SetAlpha(1)
    local r, g, b = accentColor()
    if selected then control:GetFontString():SetTextColor(r, g, b)
    else control:GetFontString():SetTextColor(0.7, 0.74, 0.76) end
    if not control.selectionMarker then
        control.selectionMarker = control:CreateTexture(nil, "OVERLAY")
        control.selectionMarker:SetPoint("TOPLEFT", 2, -4)
        control.selectionMarker:SetPoint("BOTTOMLEFT", 2, 4)
        control.selectionMarker:SetWidth(3)
    end
    control.selectionMarker:SetColorTexture(r, g, b, 1)
    control.selectionMarker:SetShown(selected)
    for _, part in ipairs(control.categoryParts or {}) do
        if selected then part:SetColorTexture(r, g, b, 1)
        else part:SetColorTexture(0.7, 0.74, 0.76, 1) end
    end
end

local function actionState(control, enabled, primary)
    control:SetEnabled(enabled)
    local r, g, b = 0.9, 0.94, 0.95
    if not enabled then r, g, b = 0.45, 0.48, 0.50
    elseif primary then
        r, g, b = accentColor()
    end
    control:GetFontString():SetTextColor(r, g, b)
end

function UI:ApplySkin(skin)
    self.skin = skin
    if skin.OnLooksChanged and not self.skinLooksHooked then
        self.skinLooksHooked = true
        skin.OnLooksChanged(function() self:RefreshIfShown(true) end)
    end
    for _, item in ipairs(self.widgets) do
        applySkin(self, item.frame, item.kind, item.options)
    end
    for _, font in ipairs(self.fonts) do
        if skin.Font then skin.Font(font) end
        if font.ruilhennTextRole then setTextRole(font, font.ruilhennTextRole) end
    end
    self:RefreshIfShown(true)
end

function UI:RegisterSettings()
    if self.settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local canvas = CreateFrame("Frame")
    local title = label(canvas, "large")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Ruilhenn")
    local description = label(canvas)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    description:SetWidth(500)
    description:SetText(L.UI_SETTINGS_DESCRIPTION)
    local open = button(canvas, L.UI_OPEN, 240, function() self:Show() end)
    open:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -24)
    self.settingsCategory = Settings.RegisterCanvasLayoutCategory(canvas, "Ruilhenn")
    Settings.RegisterAddOnCategory(self.settingsCategory)
end

function UI:Initialize()
    if self.initialized then return end
    self.initialized = true
    if EllesmereUI and type(EllesmereUI.RegisterSkin) == "function" then
        EllesmereUI.RegisterSkin("Ruilhenn", function(skin) self:ApplySkin(skin) end)
    end
    self:RegisterSettings()
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_SPECIALIZATION_CHANGED",
        "SPELLS_CHANGED", "ADDON_LOADED" }) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "ADDON_LOADED" then self:RegisterSettings(); return end
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
        if self.confirmation then self.confirmation:Hide() end
        self.pending = nil
        self:RefreshIfShown()
    end)
end

function UI:Create()
    if self.frame then return end
    local frame = panel(UIParent)
    self.frame = frame
    frame:SetSize(1040, 680)
    frame:SetScale(math.min(1, UIParent:GetWidth() / 1080, UIParent:GetHeight() / 720))
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnHide", function()
        self.pending = nil
        if self.confirmation then self.confirmation:Hide() end
    end)
    _G.RuilhennTemplateBrowser = frame
    table.insert(UISpecialFrames, "RuilhennTemplateBrowser")
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetSize(1040, 42)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local title = label(titleBar, "large")
    title:SetPoint("TOPLEFT", 20, -9)
    title:SetText("Ruilhenn")
    local close = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() frame:Hide() end)
    self:Style(frame, "Shell")
    self:Style(close, "CloseButton")

    local sidebar = panel(frame)
    sidebar:SetPoint("TOPLEFT", 14, -48)
    sidebar:SetSize(228, 612)
    self:Style(sidebar, "Panel")
    self.characterLabel = label(sidebar, "small", "supporting")
    self.characterLabel:SetPoint("TOPLEFT", 14, -14)
    self.characterLabel:SetSize(200, 16)
    self.characterName = label(sidebar, "large", "primary")
    self.characterName:SetPoint("TOPLEFT", 14, -32)
    self.characterName:SetSize(200, 24)
    self.characterRealm = label(sidebar, "small", "supporting")
    self.characterRealm:SetPoint("TOPLEFT", 14, -56)
    self.characterRealm:SetSize(200, 18)
    self.characterSpec = label(sidebar, "body", "secondary")
    self.characterSpec:SetPoint("TOPLEFT", 14, -74)
    self.characterSpec:SetSize(200, 18)
    self.characterActive = label(sidebar, "small", "supporting")
    self.characterActive:SetPoint("TOPLEFT", 14, -94)
    self.characterActive:SetSize(200, 16)
    self.tabs = {}
    for i, key in ipairs({ "overview", "talents", "bars", "bindings", "clicks" }) do
        local tab = button(sidebar, L[categoryKeys[key]], 200, function()
            self:Navigate(key)
        end, nil, key)
        tab:SetHeight(34)
        tab:SetPoint("TOPLEFT", 14, -128 - (i - 1) * 42)
        self.tabs[key] = tab
    end

    self.templateRow = CreateFrame("Frame", nil, frame)
    self.templateRow:SetPoint("TOPLEFT", 266, -54)
    self.templateRow:SetSize(748, 34)
    self.templateButtons = {}
    self.heading = label(frame, "large")
    self.heading:SetPoint("TOPLEFT", 266, -106)
    self.heading:SetSize(324, 30)
    setTextRole(self.heading, "primary")
    self.subtitle = label(frame)
    self.subtitle:SetPoint("TOPLEFT", 266, -140)
    self.subtitle:SetSize(324, 32)
    setTextRole(self.subtitle, "secondary")
    self.sourcePanel = panel(frame)
    self.sourcePanel:SetPoint("TOPLEFT", 602, -102)
    self.sourcePanel:SetSize(412, 66)
    self:Style(self.sourcePanel, "Panel")
    self.sourceTitle = label(self.sourcePanel, "small", "supporting")
    self.sourceTitle:SetPoint("TOPLEFT", 12, -8)
    self.sourceTitle:SetSize(388, 16)
    self.source = label(self.sourcePanel, "body", "primary")
    self.source:SetPoint("TOPLEFT", 12, -25)
    self.source:SetSize(388, 18)
    self.sourceSavedAt = label(self.sourcePanel, "small", "supporting")
    self.sourceSavedAt:SetPoint("TOPLEFT", 12, -44)
    self.sourceSavedAt:SetSize(388, 20)
    self.notice = label(frame)
    self.notice:SetPoint("TOPLEFT", 266, -180)
    self.notice:SetSize(748, 38)
    self.summary = label(frame)
    self.summary:SetPoint("TOPLEFT", 266, -218)
    self.summary:SetSize(748, 22)
    setTextRole(self.summary, "secondary")
    self.tableHeader = panel(frame)
    self.tableHeader:SetPoint("TOPLEFT", 266, -244)
    self.tableHeader:SetSize(748, 28)
    self:Style(self.tableHeader, "Panel")
    for _, column in ipairs({ { "UI_COLUMN_INPUT", 12, 228 }, { "UI_COLUMN_ACTION", 276, 270 },
        { "UI_COLUMN_STATUS", 570, 166 } }) do
        local heading = label(self.tableHeader)
        heading:SetPoint("TOPLEFT", column[2], -7)
        heading:SetWidth(column[3])
        heading:SetText(L[column[1]])
    end
    self.contentScroll, self.contentChild = scroll(frame, "RuilhennTemplateContents", 720, 240)
    self.contentScroll:SetPoint("TOPLEFT", 266, -276)
    self.rows = {}
    self.empty = CreateFrame("Frame", nil, frame)
    self.empty:SetPoint("TOPLEFT", 266, -256)
    self.empty:SetSize(748, 260)
    self.emptyTitle = label(self.empty, "large")
    self.emptyTitle:SetPoint("TOPLEFT", 26, -46)
    self.emptyTitle:SetSize(696, 44)
    self.emptyTitle:SetJustifyH("CENTER")
    self.emptyDescription = label(self.empty)
    self.emptyDescription:SetPoint("TOPLEFT", 46, -100)
    self.emptyDescription:SetSize(656, 64)
    self.emptyDescription:SetJustifyH("CENTER")
    self.emptySave = button(self.empty, "", 320, function() self:Confirm("Save") end)
    self.emptySave:SetHeight(34)
    self.emptySave:SetPoint("TOP", 0, -180)
    self.detail = label(frame)
    self.detail:SetPoint("TOPLEFT", 266, -532)
    self.detail:SetSize(748, 66)
    setTextRole(self.detail, "secondary")
    self.talentEffect = label(frame, "body", "secondary")
    self.talentEffect:SetPoint("TOPLEFT", 266, -520)
    self.talentEffect:SetSize(748, 22)
    self.talentPrerequisites = label(frame, "small", "supporting")
    self.talentPrerequisites:SetPoint("TOPLEFT", 266, -542)
    self.talentPrerequisites:SetSize(748, 18)
    self.talentHint = label(frame, "small", "supporting")
    self.talentHint:SetPoint("TOPLEFT", 266, -562)
    self.talentHint:SetSize(748, 18)
    self.export = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.export:SetPoint("TOPLEFT", 272, -588)
    self.export:SetSize(730, 24)
    self.export:SetAutoFocus(false)
    self.export:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    self.export:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
    self.export:SetScript("OnTextChanged", function(box, userInput)
        if userInput then box:SetText(self.exportText or ""); box:HighlightText() end
    end)
    self:Style(self.export, "EditBox")
    self.save = button(frame, "", 240, function() self:Confirm("Save") end)
    self.save:SetHeight(34)
    self.save:SetPoint("BOTTOMLEFT", 266, 22)
    self.reload = button(frame, L.UI_REFRESH, 152, function() self:Refresh() end)
    self.reload:SetHeight(34)
    self.reload:SetPoint("BOTTOMLEFT", 518, 22)
    self.load = button(frame, "", 264, function() self:Confirm("Load") end)
    self.load:SetHeight(34)
    self.load:SetPoint("BOTTOMRIGHT", -26, 22)
    self.copyAccountBindings = button(frame, L.UI_COPY_ACCOUNT_BINDINGS, 244, function()
        self:ConfirmAccountBindingsCopy()
    end)
    self.copyAccountBindings:SetHeight(30)
    self.copyAccountBindings:SetPoint("TOPLEFT", 266, -574)
    frame:Hide()
end

function UI:Navigate(category)
    if self.confirmation then self.confirmation:Hide() end
    self.pending, self.talentIndex, self.category = nil, nil, category
    self.contentScroll:SetVerticalScroll(0)
    self:Refresh()
end
function UI:RefreshIfShown(preserveTalentSelection)
    if self.frame and self.frame:IsShown() then self:Refresh(preserveTalentSelection) end
end

function UI:UpdateScrollBarVisibility()
    local scrollFrame, scrollBar = self.contentScroll, self.contentScroll and self.contentScroll.ScrollBar
    if not scrollBar then return end
    scrollBar:SetShown(scrollFrame:IsShown() and self.contentChild:GetHeight() > scrollFrame:GetHeight())
end

function UI:RenderRows(rows, category)
    local overview, clicks, talents = category == "overview", category == "clicks", category == "talents"
    local height = overview and layout.overviewHeight or talents and 54 or layout.rowHeight
    for i, item in ipairs(rows) do
        local control = self.rows[i]
        if not control then
            control = button(self.contentChild, "", layout.listWidth, function(row)
                local value = row.item
                if value.category then self:Navigate(value.category)
                elseif value.talentIndex then
                    self.talentIndex = value.talentIndex
                    self:UpdateActionState()
                    self.exportText = value.detail
                    self.export:SetText(self.exportText)
                    self.export:Show()
                    self.talentHint:SetText(L.UI_SELECTED_TALENT:format(text(value.text)))
                    for _, row in ipairs(self.rows) do
                        local selected = row.item and row.item.talentIndex == self.talentIndex
                        if selected then row.selectionMarker:SetColorTexture(accentColor()) end
                        row.selectionMarker:SetShown(selected)
                        setTextRole(row.input, selected and "accent" or "primary")
                    end
                end
            end)
            control.input = label(control, "body", "primary")
            control.input:SetPoint("TOPLEFT", 12, -10)
            control.action = label(control)
            control.action:SetPoint("TOPLEFT", 276, -10)
            control.status = label(control)
            control.status:SetPoint("TOPLEFT", 570, -10)
            control.secondary = label(control)
            control.secondary:SetPoint("TOPLEFT", 12, -32)
            control.secondary:SetWidth(layout.listWidth - 24)
            control.chevron = label(control, "large", "supporting")
            control.chevron:SetPoint("TOPRIGHT", -12, -8)
            control.chevron:SetSize(18, 32)
            control.chevron:SetJustifyH("RIGHT")
            control.icon:SetPoint("TOPLEFT", 246, -8)
            control.icon:SetSize(24, 24)
            self.rows[i] = control
        end
        control.item = item
        control:SetHeight(height)
        control:SetPoint("TOPLEFT", 0, -(i - 1) * (talents and 56 or (height + layout.rowGap)))
        -- Explicitly reset all reusable presentation fields before changing roles.
        for _, font in ipairs({ control.input, control.action, control.status, control.secondary }) do
            font:SetText("")
            setTextRole(font, "secondary")
            font:SetJustifyH("LEFT")
            font:Hide()
        end
        control.icon:SetTexture(nil)
        control.icon:Hide()
        control.chevron:Hide()
        control.selectionMarker:SetShown(talents and item.talentIndex == self.talentIndex)
        if talents and item.talentIndex == self.talentIndex then
            setTextRole(control.input, "accent")
            control.selectionMarker:SetColorTexture(accentColor())
        end
        control.input:Show()
        control.input:SetSize(clicks and 228 or overview and 410 or talents and 476 or 696, talents and 36 or 28)
        control.input:SetText(text(item.input or item.text))
        if clicks then
            control.action:ClearAllPoints()
            control.action:SetPoint("TOPLEFT", 276, -10)
            control.action:SetSize(276, 28)
            control.action:SetJustifyH("LEFT")
            setTextRole(control.input, "primary")
            control.action:SetText(text(item.action))
            control.action:Show()
            control.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            control.icon:Show()
            control.status:ClearAllPoints()
            control.status:SetPoint("TOPLEFT", 570, -10)
            control.status:SetSize(138, 28)
            control.status:SetJustifyH("LEFT")
            control.status:SetText(L["UI_CLICK_STATUS_" .. item.status:upper()])
            if item.status == "skipped" then setTextRole(control.status, "amber")
            elseif item.status == "available" then setTextRole(control.status, "green") end
            control.status:Show()
        elseif overview then
            setTextRole(control.input, "primary")
            control.action:SetSize(240, 28)
            control.action:ClearAllPoints()
            control.action:SetPoint("TOPRIGHT", -38, -12)
            control.action:SetJustifyH("RIGHT")
            control.action:SetText(text(item.state))
            control.action:Show()
            if item.saved then
                local source = item.sourceName and coloredText(item.sourceName, item.sourceClass, true) or
                    text(item.sourceCharacter or L.UI_UNKNOWN_SOURCE)
                if item.sourceRealm then source = source .. " — " .. text(item.sourceRealm) end
                if item.savedDate then source = source .. " · " .. L.UI_SAVED_AT:format(text(item.savedDate)) end
                control.secondary:SetText(L.UI_SOURCE:format(source))
                setTextRole(control.secondary, "supporting")
                control.secondary:Show()
            elseif item.state then
                control.secondary:SetText(text(item.state))
                setTextRole(control.secondary, "supporting")
                control.secondary:Show()
                control.action:SetText("")
            end
            control.chevron:SetText("›")
            control.chevron:Show()
        elseif talents then
            setTextRole(control.input, item.talentIndex == self.talentIndex and "accent" or "primary")
            if item.status == "present" or item.status == "available" then
                control.status:ClearAllPoints()
                control.status:SetPoint("TOPRIGHT", -30, -17)
                control.status:SetSize(200, 22)
                control.status:SetJustifyH("RIGHT")
                control.status:SetText(item.status == "present" and L.UI_TALENT_EXISTS or L.UI_TALENT_AVAILABLE)
                setTextRole(control.status, "secondary")
                control.status:Show()
            end
        elseif item.note then
            control.input:SetSize(696, 28)
            setTextRole(control.input, "primary")
            control.secondary:SetText(text(item.note))
            setTextRole(control.secondary, "secondary")
            control.secondary:Show()
        else
            setTextRole(control.input, "primary")
        end
        control:Show()
    end
    for i = #rows + 1, #self.rows do self.rows[i]:Hide() end
    self.contentChild:SetHeight(math.max(1, #rows * (talents and 56 or (height + layout.rowGap))))
    self:UpdateScrollBarVisibility()
end

function UI:UpdateActionState()
    if not self.frame then return end
    local category, entry = self.category, self.selected
    local overview = category == "overview"
    local saved = not overview and type(Store:Data(entry, category)) == "table"
    local compatible = Store:Compatible(entry)
    local current = Store:Current()
    local bindingBlock = category == "bindings" and ns.BindingsManager:OperationBlockReason()
    local canChange = compatible and not InCombatLockdown() and not bindingBlock
    local talentBlock = category == "talents" and ns.TalentManager:RestoreBlockReason()
    local notice = InCombatLockdown() and L.UI_COMBAT or not compatible and
        L.UI_VIEWING_INACTIVE:format(entry and text(entry.specName) or L.UI_NO_SPEC,
            current and text(current.specName) or L.UI_NO_SPEC) or bindingBlock or talentBlock or ""
    self.notice:SetText(notice)
    setTextRole(self.notice, notice ~= "" and "amber" or "supporting")
    self.save:SetText(L["UI_SAVE_" .. category:upper()] or L.UI_SAVE)
    self.load:SetText(category == "talents" and self.talentIndex and L.UI_LOAD_ONE or
        L["UI_LOAD_" .. category:upper()] or L.UI_LOAD)
    self.emptySave:SetText(L["UI_SAVE_" .. category:upper()] or L.UI_SAVE)
    actionState(self.save, canChange, false)
    actionState(self.emptySave, canChange, true)
    actionState(self.load, canChange and saved and not talentBlock, true)
    self.copyAccountBindings:SetShown(category == "bindings")
    actionState(self.copyAccountBindings, compatible and not bindingBlock, false)
    self.save:SetShown(not overview and saved)
    self.load:SetShown(not overview)
end

function UI:Refresh(preserveTalentSelection)
    if not self.frame then return end
    local previousTalentIndex = preserveTalentSelection and self.talentIndex
    self.talentIndex, self.exportText = nil, nil
    self.export:SetText("")
    self.export:Hide()
    local catalog, selected = Store:Catalog()
    local current = Store:Current()
    for _, entry in ipairs(catalog) do if entry.key == self.selectedKey then selected = entry end end
    if not selected then
        for _, entry in ipairs(catalog) do
            if Store:Compatible(entry) then selected = entry; break end
        end
        selected = selected or catalog[1]
    end
    self.selected, self.selectedKey = selected, selected and selected.key
    local identity = Store:CharacterDetails()
    self.characterName:SetText(text(identity.name))
    local characterR, characterG, characterB = classColor(identity.class)
    if characterR then self.characterName:SetTextColor(characterR, characterG, characterB)
    else setTextRole(self.characterName, "primary") end
    self.characterRealm:SetText(text(identity.realm))
    self.characterSpec:SetText(current and
        (coloredText(current.className, current.class) .. " · " .. text(current.specName)) or L.UI_NO_SPEC)
    self.characterActive:SetText(L.UI_ACTIVE_SPECIALIZATION)
    local specWidth = (layout.contentWidth - math.max(0, #catalog - 1) * 8) / math.max(1, #catalog)
    for i, entry in ipairs(catalog) do
        local control = self.templateButtons[i]
        if not control then
            control = button(self.templateRow, "", specWidth, function(button)
                if self.confirmation then self.confirmation:Hide() end
                self.pending, self.selectedKey = nil, button.entry.key
                self.contentScroll:SetVerticalScroll(0)
                self:Refresh()
            end)
            control:SetHeight(34)
            self.templateButtons[i] = control
        end
        control.entry = entry
        control:SetWidth(specWidth)
        control:SetPoint("TOPLEFT", (i - 1) * (specWidth + 8), 0)
        local active = Store:Compatible(entry)
        control:SetText(text(entry.specName) .. (active and (" · " .. L.UI_ACTIVE_TAG) or ""))
        control:Show()
        selectNavigation(control, entry == selected)
    end
    for i = #catalog + 1, #self.templateButtons do self.templateButtons[i]:Hide() end
    for key, tab in pairs(self.tabs) do selectNavigation(tab, key == self.category) end
    local category, overview = self.category, self.category == "overview"
    local data = not overview and Store:Data(selected, category) or nil
    local saved = type(data) == "table"
    local compatible = Store:Compatible(selected)
    self.heading:SetText(overview and L.UI_TEMPLATE_OVERVIEW or L[categoryKeys[category]])
    self.subtitle:SetText(selected and L.UI_SHARED_SPEC:format(text(selected.className), text(selected.specName)) or L.UI_NO_SPEC)
    self.sourcePanel:SetShown(saved)
    local source = saved and Store:SourceDetails(selected, category) or nil
    self.sourceTitle:SetText(saved and L.UI_TEMPLATE_SOURCE or "")
    self.source:SetText(source and (source.name and
        (coloredText(source.name, source.class, true) .. " — " .. text(source.realm)) or text(source.character)) or "")
    self.sourceSavedAt:SetText(source and source.savedDate and L.UI_SAVED_AT:format(text(source.savedDate)) or "")
    if category == "bindings" and saved then
        local sourceSet = data.bindingSet == 1 and L.UI_ACCOUNT or data.bindingSet == 2 and L.UI_CHARACTER_SET or
            L.UI_BINDING_SCOPE_UNKNOWN
        local bindingSet = L.UI_BINDING_SAVED_FROM:format(sourceSet)
        self.sourceSavedAt:SetText(self.sourceSavedAt:GetText() ~= "" and
            (self.sourceSavedAt:GetText() .. " · " .. bindingSet) or bindingSet)
    end
    setTextRole(self.sourceTitle, "supporting")
    setTextRole(self.source, "primary")
    setTextRole(self.sourceSavedAt, "supporting")
    self:UpdateActionState()
    self.reload:SetPoint("BOTTOMLEFT", (overview or not saved) and 266 or 518, 22)
    self.empty:Hide()
    self.tableHeader:SetShown(category == "clicks" and saved)
    self.contentScroll:SetShown(saved or overview)
    self.contentScroll:SetPoint("TOPLEFT", 266, category == "clicks" and -276 or -244)
    self.contentScroll:SetHeight(category == "clicks" and 240 or category == "bindings" and 264 or 272)
    self.detail:ClearAllPoints()
    self.detail:SetPoint("TOPLEFT", 266, category == "bindings" and -520 or -532)
    self.detail:SetHeight(category == "bindings" and 48 or 66)
    self.detail:SetShown(category ~= "talents" and not overview)
    local rows = {}
    if overview then
        local savedCount
        rows, savedCount = Store:Overview(selected)
        for _, item in ipairs(rows) do
            item.text = L[categoryKeys[item.category]]
            item.state = not item.saved and L.UI_NO_BACKUP or item.count == 0 and L.UI_SAVED_EMPTY or
                L["UI_COUNT_" .. item.category:upper()]:format(item.count)
        end
        self.summary:SetText(L.UI_SAVED_CATEGORIES:format(savedCount))
        setTextRole(self.summary, "secondary")
        self.detail:SetText("")
    else
        rows = Store:Inspect(selected, category)
        local detailText = category == "talents" and "" or L["UI_EFFECT_" .. category:upper()]
        if category == "bindings" then
            detailText = detailText .. "\n" .. L.UI_BINDING_COPY_HELP
        end
        self.detail:SetText(detailText)
        if not saved then
            self.summary:SetText("")
            self.empty:Show()
            self.emptyTitle:SetText(L["UI_NO_BACKUP_" .. category:upper()])
            self.emptyDescription:SetText(L.UI_EMPTY_HINT:format(L[categoryKeys[category]],
                selected and text(selected.specName) or L.UI_NO_SPEC))
            self.emptySave:SetShown(compatible)
        elseif category == "clicks" then
            local available, skipped = Store:ClickSummary(rows)
            self.summary:SetText(not compatible and L.UI_CLICK_CHECK_ACTIVE or
                L.UI_CLICK_SUMMARY:format(available, skipped))
            setTextRole(self.summary, "secondary")
            self.detail:SetText(self.detail:GetText() .. "\n" .. L.UI_CLICK_AVAILABLE_NOTE)
            if #rows == 0 then self.detail:SetText(L.UI_EMPTY_CLICK_EFFECT) end
        elseif category == "talents" then
            self.summary:SetText(Store:TalentSummary(selected, rows))
            setTextRole(self.summary, "secondary")
        else
            self.summary:SetText(#rows == 0 and L.UI_SAVED_EMPTY or
                L["UI_COUNT_" .. category:upper()]:format(#rows))
            setTextRole(self.summary, "secondary")
        end
        if category == "bindings" then
            local countText = saved and (#rows == 0 and L.UI_SAVED_EMPTY or L.UI_COUNT_BINDINGS:format(#rows)) or nil
            self.summary:SetText(countText and (L.UI_BINDING_DESTINATION .. " · " .. countText) or
                L.UI_BINDING_DESTINATION)
            setTextRole(self.summary, "secondary")
        end
        if saved and #rows == 0 then
            self.empty:Show()
            self.tableHeader:Hide()
            self.contentScroll:Hide()
            self.emptyTitle:SetText(L.UI_SAVED_EMPTY)
            self.emptyDescription:SetText(category == "clicks" and L.UI_EMPTY_CLICK_EFFECT or L.UI_EMPTY_SNAPSHOT_HINT)
            self.emptySave:Hide()
        end
    end
    local showTalentGuidance = category == "talents" and saved and #rows > 0
    self.talentEffect:SetShown(showTalentGuidance)
    self.talentPrerequisites:SetShown(showTalentGuidance)
    self.talentHint:SetShown(showTalentGuidance)
    self.talentEffect:SetText(showTalentGuidance and L.UI_EFFECT_TALENTS or "")
    self.talentPrerequisites:SetText(showTalentGuidance and L.UI_TALENT_PREREQUISITES or "")
    self.talentHint:SetText(showTalentGuidance and L.UI_TALENT_HINT or "")
    if previousTalentIndex and category == "talents" and rows[previousTalentIndex] then
        local selected = rows[previousTalentIndex]
        self.talentIndex, self.exportText = previousTalentIndex, selected.detail
        self.export:SetText(self.exportText)
        self.export:Show()
        self.talentHint:SetText(L.UI_SELECTED_TALENT:format(text(selected.text)))
        self:UpdateActionState()
    end
    self:RenderRows(rows, category)
end
function UI:Confirm(action)
    local entry, category, index = self.selected, self.category, self.talentIndex
    if category == "overview" or not Store:Compatible(entry) or InCombatLockdown() then return end
    if action == "Save" and entry.global then return end
    local data = Store:Data(entry, category)
    if action == "Load" and not data then return end
    if not self.confirmation then
        local dialog = panel(self.frame)
        self.confirmation = dialog
        _G.RuilhennTemplateConfirmation = dialog
        table.insert(UISpecialFrames, "RuilhennTemplateConfirmation")
        dialog:SetFrameLevel(self.frame:GetFrameLevel() + 30)
        dialog:SetSize(620, 360)
        dialog:SetPoint("CENTER")
        dialog:EnableMouse(true)
        self:Style(dialog, "Panel")
        self.confirmText = label(dialog)
        self.confirmText:SetPoint("TOPLEFT", 24, -24)
        self.confirmText:SetSize(572, 260)
        local cancel = button(dialog, L.UI_CANCEL, 160, function() dialog:Hide(); self.pending = nil end)
        self.confirmCancel = cancel
        cancel:SetPoint("BOTTOMLEFT", 24, 20)
        local accept = button(dialog, L.UI_CONFIRM, 200, function() self:Accept() end)
        self.confirmAccept = accept
        accept:SetPoint("BOTTOMRIGHT", -24, 20)
    end
    self.pending = { action = action, entry = entry, category = category, talentIndex = index, data = data }
    local caption = L[categoryKeys[category]]
    local source = text(Store:Source(entry, category))
    local character = text(Store:Character())
    local message = action == "Save" and not data and L.UI_CONFIRM_CREATE:format(caption, character,
        text(entry.className .. " / " .. entry.specName)) or
        action == "Save" and L.UI_CONFIRM_SAVE:format(caption, character,
        text(entry.className .. " / " .. entry.specName), source) or
        L.UI_CONFIRM_LOAD:format(caption, source, character, L["UI_EFFECT_" .. category:upper()])
    if action == "Load" and category == "clicks" then
        local rows = Store:Inspect(entry, category)
        local available, skipped = Store:ClickSummary(rows)
        message = message .. "\n\n" .. (#rows == 0 and L.UI_EMPTY_CLICK_EFFECT or
            L.UI_CLICK_SUMMARY:format(available, skipped))
    elseif action == "Load" and category == "bindings" then
        local savedFrom = data.bindingSet == 1 and L.UI_ACCOUNT or data.bindingSet == 2 and L.UI_CHARACTER_SET or
            L.UI_BINDING_SCOPE_UNKNOWN
        message = L.UI_BINDING_LOAD_CONFIRM:format(text(savedFrom), text(character))
    end
    if action == "Load" and category == "talents" and index and data[index] then
        message = message .. "\n\n" .. L.UI_SELECTED_TALENT:format(text(data[index].name))
    end
    self.confirmText:SetText(message)
    self.confirmation:Show()
end

function UI:ConfirmAccountBindingsCopy()
    if self.category ~= "bindings" or not Store:Compatible(self.selected) or InCombatLockdown() then return false end
    local block = ns.BindingsManager:OperationBlockReason()
    if block then self.notice:SetText(block); setTextRole(self.notice, "amber"); return false end
    local baseline, fingerprint = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    if not baseline then
        self.notice:SetText(fingerprint == L.UI_BINDING_READ_FAILED and L.UI_BINDING_COPY_READ_FAILED or
            fingerprint or L.UI_BINDING_COPY_READ_FAILED)
        setTextRole(self.notice, "amber")
        return false
    end
    if not self.confirmation then
        self:Confirm("Save")
        if self.confirmation then self.confirmation:Hide() end
    end
    local current = Store:Current()
    if not current then return false end
    local character = Store:Character()
    self.pending = { action = "CopyAccountBindings", category = "bindings", class = current.class,
        specID = current.specID, character = character, baselineFingerprint = fingerprint }
    self.confirmText:SetText(L.UI_BINDING_COPY_CONFIRM:format(text(character), #baseline.bindings))
    self.confirmation:Show()
    return true
end

function UI:Accept()
    local pending = self.pending
    self.pending = nil
    if self.confirmation then self.confirmation:Hide() end
    if not pending then return end
    if pending.action == "CopyAccountBindings" then
        local current = Store:Current()
        if self.category ~= "bindings" or not current or current.class ~= pending.class or
            current.specID ~= pending.specID or Store:Character() ~= pending.character then
            ns.Log:Warning(L.UI_STALE)
            self:Refresh()
            return
        end
        local ok, result = pcall(ns.BindingsManager.CopyAccountBindings, ns.BindingsManager,
            pending.baselineFingerprint)
        if not ok then ns.Log:Error(L.UI_OPERATION_ERROR:format(tostring(result))) end
        self:Refresh()
        return
    end
    -- A slash save, spec change or new selection while confirmation was open
    -- must not apply a different snapshot than the one the user reviewed.
    local data = Store:Data(pending.entry, pending.category)
    local changed = data ~= pending.data
    if pending.entry.global then
        changed = not data or data.bindings ~= pending.data.bindings or data.version ~= pending.data.version or
            data.bindingSet ~= pending.data.bindingSet
    end
    if self.selectedKey ~= pending.entry.key or self.category ~= pending.category or changed then
        ns.Log:Warning(L.UI_STALE); return
    end
    local destinationSet = pending.category == "bindings" and pending.action == "Load" and 2 or nil
    local ok, err = pcall(Store.Execute, Store, pending.action, pending.entry, pending.category,
        pending.talentIndex, destinationSet)
    if not ok then ns.Log:Error(L.UI_OPERATION_ERROR:format(tostring(err))) end
    self.talentIndex = nil
    self:Refresh()
    -- Existing managers own success/error output, including async completion.
end

function UI:Show()
    self:Create()
    self:Refresh()
    self.frame:Show()
end

function UI:Toggle()
    if self.frame and self.frame:IsShown() then self.frame:Hide() else self:Show() end
end

ns.Commands.ui = function() UI:Toggle() end
