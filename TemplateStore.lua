local _, ns = ...
local Store = { categories = { "talents", "bars", "bindings", "clicks" } }
ns.TemplateStore = Store
local L = ns.L
local managers = { talents = "TalentManager", bars = "ActionBarsManager",
    bindings = "BindingsManager", clicks = "ClickCastingManager" }

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

local function at(root, class, spec)
    return type(root) == "table" and type(root[class]) == "table" and root[class][spec] or nil
end

function Store:Current()
    local index = C_SpecializationInfo.GetSpecialization()
    if not index then return end
    local id, name = C_SpecializationInfo.GetSpecializationInfo(index)
    local className, class, classID = UnitClass("player")
    if not id or not class then return end
    return { class = class, className = className, classID = classID,
        specID = id, specIndex = index, specName = name }
end

function Store:CharacterDetails()
    local name, realm = UnitFullName("player")
    local className, class = UnitClass("player")
    return { name = name or UnitName("player"), realm = realm or GetRealmName(),
        className = className, class = class }
end

function Store:Character()
    local details = self:CharacterDetails()
    return details.name .. " — " .. details.realm
end

-- Called only after a manager has successfully captured its backup, including
-- captures through the original slash commands. Old saves never gain guessed owners.
function Store:Record(category)
    local current = self:Current()
    if not current then return end
    local db = RuilhennDB
    db.templateInfo = db.templateInfo or {}
    db.templateInfo[current.class] = db.templateInfo[current.class] or {}
    local record = db.templateInfo[current.class][current.specID] or {}
    db.templateInfo[current.class][current.specID] = record
    record.specIndex, record.specName, record.className = current.specIndex, current.specName, current.className
    record.sources = record.sources or {}
    record.sources[category] = { character = self:Character(), savedAt = time() }
    if category == "bindings" then
        db.bindingTemplates = db.bindingTemplates or {}
        db.bindingTemplates[current.class] = db.bindingTemplates[current.class] or {}
        db.bindingTemplates[current.class][current.specID] = {
            bindings = copy(db.keyBindings), version = db.keyBindingsVersion, bindingSet = db.bindingSet,
        }
    end
    if ns.TemplateBrowser then ns.TemplateBrowser:RefreshIfShown() end
end

function Store:Compatible(entry)
    local current = self:Current()
    return current and entry and not entry.global and
        entry.class == current.class and entry.specID == current.specID or false
end

function Store:Catalog()
    local entries, seen, classIDs = {}, {}, {}
    local _, playerClass = UnitClass("player")
    if C_CreatureInfo and C_CreatureInfo.GetClassInfo and CLASS_SORT_ORDER then
        for id = 1, #CLASS_SORT_ORDER do
            local info = C_CreatureInfo.GetClassInfo(id)
            if info then classIDs[info.classFile] = { id = id, name = info.className } end
        end
    end
    local function add(class, index, specID, name)
        if class ~= playerClass then return end
        local identity = class .. ":" .. tostring(specID or ("index" .. index))
        if seen[identity] then return end
        local info = classIDs[class]
        local metadata = at(RuilhennDB.templateInfo, class, specID)
        local entry = { class = class, specID = specID, specIndex = index,
            className = info and info.name or metadata and metadata.className or class,
            specName = name or metadata and metadata.specName or L.UI_SPEC_INDEX:format(index or 0) }
        entry.key = identity
        entries[#entries + 1], seen[identity] = entry, true
    end
    for _, root in ipairs({ "talents", "actionBars" }) do
        for class, specs in pairs(type(RuilhennDB[root]) == "table" and RuilhennDB[root] or {}) do
            if class == playerClass and type(specs) == "table" then
                for index in pairs(specs) do
                    if type(index) == "number" then
                        local id, name
                        if classIDs[class] and GetSpecializationInfoForClassID then
                            id, name = GetSpecializationInfoForClassID(classIDs[class].id, index)
                        end
                        -- Metadata also resolves saves on clients with a limited catalog API.
                        for specID, metadata in pairs(type(RuilhennDB.templateInfo) == "table" and
                            type(RuilhennDB.templateInfo[class]) == "table" and RuilhennDB.templateInfo[class] or {}) do
                            if metadata.specIndex == index then id, name = specID, metadata.specName end
                        end
                        local current = self:Current()
                        if current and current.class == class and current.specIndex == index then
                            id, name = current.specID, current.specName
                        end
                        add(class, index, id, name)
                    end
                end
            end
        end
    end
    for _, root in ipairs({ "clickCasting", "bindingTemplates", "templateInfo" }) do
        for class, specs in pairs(type(RuilhennDB[root]) == "table" and RuilhennDB[root] or {}) do
            if class == playerClass and type(specs) == "table" then
                for specID in pairs(specs) do
                    if type(specID) == "number" then
                        local index, name
                        if classIDs[class] and GetSpecializationInfoForClassID then
                            for i = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classIDs[class].id) do
                                local id, specName = GetSpecializationInfoForClassID(classIDs[class].id, i)
                                if id == specID then index, name = i, specName; break end
                            end
                        end
                        local metadata = at(RuilhennDB.templateInfo, class, specID)
                        local current = self:Current()
                        if current and current.class == class and current.specID == specID then
                            index, name = current.specIndex, current.specName
                        end
                        add(class, metadata and metadata.specIndex or index, specID,
                            name or L.UI_SPEC_ID:format(specID))
                    end
                end
            end
        end
    end
    local current = self:Current()
    if current then add(current.class, current.specIndex, current.specID, current.specName) end
    table.sort(entries, function(a, b)
        return a.class == b.class and (a.specIndex or 99) < (b.specIndex or 99) or
            a.class ~= b.class and a.className < b.className
    end)
    -- Unscoped legacy key bindings have no proven class/spec ownership.
    -- Keep them for the original slash command, outside this template list.
    return entries
end

function Store:Data(entry, category)
    if not entry then return end
    if category == "bindings" then
        if entry.global then return { bindings = RuilhennDB.keyBindings,
            version = RuilhennDB.keyBindingsVersion, bindingSet = RuilhennDB.bindingSet } end
        return at(RuilhennDB.bindingTemplates, entry.class, entry.specID)
    end
    if entry.global then return end
    if category == "clicks" then return at(RuilhennDB.clickCasting, entry.class, entry.specID) end
    return at(category == "talents" and RuilhennDB.talents or RuilhennDB.actionBars,
        entry.class, entry.specIndex)
end

function Store:SourceDetails(entry, category)
    local metadata = entry and at(RuilhennDB.templateInfo, entry.class, entry.specID)
    local source = metadata and metadata.sources and metadata.sources[category]
    local character = source and source.character or L.UI_UNKNOWN_SOURCE
    local name, realm
    if type(character) == "string" then name, realm = character:match("^(.-) — (.+)$") end
    if name == "" or realm == "" then name, realm = nil, nil end
    return {
        character = character,
        name = name,
        realm = realm,
        class = name and entry.class or nil,
        savedAt = source and source.savedAt,
        savedDate = source and source.savedAt and date("%Y-%m-%d %H:%M", source.savedAt) or nil,
    }
end

function Store:Source(entry, category)
    local source = self:SourceDetails(entry, category)
    return source.character .. (source.savedDate and (" · " .. source.savedDate) or "")
end

function Store:Overview(entry)
    local rows, savedCount = {}, 0
    for _, category in ipairs(self.categories) do
        local data = self:Data(entry, category)
        local saved = type(data) == "table"
        local count = saved and #self:Inspect(entry, category) or 0
        local source = saved and self:SourceDetails(entry, category) or nil
        if saved then savedCount = savedCount + 1 end
        rows[#rows + 1] = { category = category, saved = saved, count = count,
            provenance = saved and self:Source(entry, category) or nil,
            sourceCharacter = source and source.character,
            sourceName = source and source.name,
            sourceRealm = source and source.realm,
            sourceClass = source and source.class,
            savedDate = source and source.savedDate }
    end
    return rows, savedCount
end

function Store:TalentSummary(entry, rows)
    local count, present, available = #rows, 0, 0
    if count == 0 then return L.UI_SAVED_EMPTY end
    if not self:Compatible(entry) then return L.UI_COUNT_TALENTS:format(count) end
    for _, row in ipairs(rows) do
        if row.status == "present" then present = present + 1
        elseif row.status == "available" then available = available + 1 end
    end
    if present == count then return L.UI_TALENT_SUMMARY_ALL_PRESENT:format(count) end
    if available == count then return L.UI_TALENT_SUMMARY_ALL_AVAILABLE:format(count) end
    return L.UI_TALENT_SUMMARY_MIXED:format(count, present, available)
end

function Store:ClickSummary(rows)
    local available, skipped = 0, 0
    for _, row in ipairs(rows) do
        if row.missing then skipped = skipped + 1
        elseif row.status == "available" then available = available + 1 end
    end
    return available, skipped
end

local function clickInput(button, modifiers)
    local names = { LeftButton = L.UI_MOUSE_LEFT, RightButton = L.UI_MOUSE_RIGHT, MiddleButton = L.UI_MOUSE_MIDDLE }
    local number = button:match("^Button(%d+)$")
    local name = names[button] or (number and L.UI_MOUSE_NUMBER:format(tonumber(number))) or L.UI_UNKNOWN_INPUT
    local modifier = GetStringFromModifiers and GetStringFromModifiers(modifiers) or ""
    modifier = modifier:gsub("%-$", ""):gsub("%-", " + ")
    return modifier ~= "" and (modifier .. " + " .. name) or name
end

function Store:Inspect(entry, category)
    local data, rows = self:Data(entry, category), {}
    if type(data) ~= "table" then return rows end
    if category == "talents" then
        local present = self:Compatible(entry) and ns.TalentManager:GetConfigMap(entry.specID) or {}
        for index, build in ipairs(data) do
            local status = self:Compatible(entry) and (present[build.name] and "present" or "available") or "unchecked"
            rows[#rows + 1] = { text = build.name, detail = build.importString or "", talentIndex = index,
                status = status, note = status == "present" and L.UI_TALENT_EXISTS or
                    status == "available" and L.UI_TALENT_AVAILABLE or nil }
        end
    elseif category == "bars" then
        for bar, actions in ipairs(data) do
            for slot, action in ipairs(actions) do
                if action.type and action.id then
                    local name = action.type == "spell" and C_Spell.GetSpellName(action.id) or
                        action.type == "item" and C_Item.GetItemInfo(action.id) or nil
                    rows[#rows + 1] = { text = L.UI_BAR_ROW:format(bar, slot,
                        L["UI_ACTION_" .. action.type:upper()] or action.type,
                        name or tostring(action.id)) }
                end
            end
        end
    elseif category == "bindings" then
        for _, binding in ipairs(data.bindings or {}) do
            rows[#rows + 1] = { text = (GetBindingText and GetBindingText(binding.command, "BINDING_NAME_") or binding.command)
                .. "  ·  " .. (binding.key1 or "—") .. " / " .. (binding.key2 or "—") }
        end
    elseif category == "clicks" then
        local compatible = self:Compatible(entry)
        for _, row in ipairs(data.bindings or {}) do
            local types = Enum.ClickBindingType
            local name, icon, kind = nil, nil, "none"
            if row.type == types.Spell or row.type == types.PetAction then
                kind = row.type == types.Spell and "spell" or "pet"
                name = C_Spell.GetSpellName(row.actionID)
                icon = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(row.actionID)
            elseif row.type == types.Macro then
                kind, name = "macro", row.macro and row.macro.name
            elseif row.type == types.Interaction then
                kind = "interaction"
                name = row.actionID == Enum.ClickBindingInteraction.Target and L.UI_TARGET or L.UI_CONTEXT_MENU
            else name = L.UI_UNASSIGNED end
            name = name or L["UI_UNRESOLVED_" .. kind:upper()] or L.UI_UNRESOLVED_ACTION
            local missing = row.type == types.Spell and compatible and
                not C_SpellBook.IsSpellInSpellBook(row.actionID, Enum.SpellBookSpellBank.Player, false)
            local bindingText = clickInput(row.button, row.modifiers)
            rows[#rows + 1] = { text = L.UI_CLICK_ROW:format(bindingText, name),
                input = bindingText, action = name, kind = kind, icon = icon,
                status = not compatible and "unchecked" or missing and "skipped" or "available",
                detail = missing and L.UI_UNLEARNED or "", missing = not not missing }
        end
    end
    return rows
end

function Store:Execute(action, entry, category, talentIndex, destinationSet)
    if InCombatLockdown() then ns.Log:Warning(L.UI_COMBAT); return false end
    if not managers[category] or not self:Compatible(entry) then
        ns.Log:Warning(L.UI_INCOMPATIBLE); return false
    end
    if action == "Save" then
        if entry.global then return false end
        if category == "bindings" then return ns.BindingsManager:SaveForBrowser() end
        return ns[managers[category]]:Save()
    end
    if action ~= "Load" or not self:Data(entry, category) then return false end
    if category == "bindings" then
        return ns.BindingsManager:Load(self:Data(entry, category), destinationSet)
    elseif category == "talents" then
        return ns.TalentManager:Load(talentIndex)
    end
    return ns[managers[category]]:Load()
end
