local Controls = {}

function Controls.CreateStatusLabel(tab, defaultText)
    local label = tab:Label(defaultText or "Status: Ready")

    return {
        Set = function(_, text)
            label:Set(tostring(text))
        end,
        Raw = label,
    }
end

function Controls.CreateToggle(tab, title, defaultValue, callback, extra)
    return tab:Toggle(title, defaultValue, callback, extra or {})
end

function Controls.CreateDropdown(tab, title, options, defaultValue, callback, extra)
    return tab:Dropdown(title, options, defaultValue, callback, extra or {})
end

function Controls.CreateButton(tab, title, callback)
    return tab:Button(title, callback)
end

function Controls.CreateLabel(tab, text)
    return tab:Label(text)
end

function Controls.CreateDivider(tab, text)
    return tab:Divider(text)
end

return Controls