-- Grab environment
local utils = require("freedesktop.utils")
local io = io
local string = string
local table = table
local os = os
local ipairs = ipairs

module("freedesktop.menu")

all_menu_dirs = { '/usr/share/applications/' }

show_generic_name = false

--- Create menus for applications
-- @param menu_dirs A list of application directories (optional).
-- @return A prepared menu w/ categories
function new(arg)
    -- the categories and their synonyms where shamelessly copied from lxpanel
    -- source code.
    local programs = {}
    local config = arg or {}

    programs['AudioVideo'] = {}
    programs['Development'] = {}
    programs['Education'] = {}
    programs['Game'] = {}
    programs['Graphics'] = {}
    programs['Network'] = {}
    programs['Office'] = {}
    programs['Settings'] = {}
    programs['System'] = {}
    programs['Utility'] = {}
    programs['Other'] = {}

    -- ArchPwn Menu
    programs['Bluetooth'] = {}
    programs['Bruteforce'] = {}
    programs['Cisco'] = {}
    programs['Database'] = {}
    programs['DECT'] = {}
    programs['Defense'] = {}
    programs['Enumeration'] = {}
    programs['Exploits'] = {}
    programs['Forensics'] = {}
    programs['Fuzzing'] = {}
    programs['Misc'] = {}
    programs['Password'] = {}
    programs['Reversing'] = {}
    programs['Scanners'] = {}
    programs['Smartcards'] = {}
    programs['Sniffing'] = {}
    programs['Spoofing'] = {}
    programs['Tunneling'] = {}
    programs['VoIP'] = {}
    programs['Windows'] = {}
    programs['Wireless'] = {}
    programs['WWW'] = {}

    for i, dir in ipairs(config.menu_dirs or all_menu_dirs) do
        local entries = utils.parse_desktop_files({dir = dir})
        for j, program in ipairs(entries) do
            -- check whether to include in the menu
            if program.show and program.Name and program.cmdline then
                if show_generic_name and program.GenericName then
                    program.Name = program.Name .. ' (' .. program.GenericName .. ')'
                end
                local target_category = nil
                if program.categories then
                    for _, category in ipairs(program.categories) do
                        if programs[category] then
                            target_category = category
                            break
                        end
                    end
                end
                if not target_category then
                    target_category = 'Other'
                end
                if target_category then
                    table.insert(programs[target_category], { program.Name, program.cmdline, program.icon_path })
                end
            end
        end
    end

    local menu = {
        { "Accessories", programs["Utility"], utils.lookup_icon({ icon = 'applications-accessories.png' }) },
        { "ArchPwn", {
            { "Bluetooth",   programs['Bluetooth'],   utils.lookup_icon({ icon = 'terminal' }) }, 
            { "Bruteforce",  programs['Bruteforce'],  utils.lookup_icon({ icon = 'terminal' }) },
            { "Cisco",       programs['Cisco'],       utils.lookup_icon({ icon = 'terminal' }) },
            { "Database",    programs['Database'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "DECT",        programs['DECT'],        utils.lookup_icon({ icon = 'terminal' }) },
            { "Defense",     programs['Defense'],     utils.lookup_icon({ icon = 'terminal' }) },
            { "Enumeration", programs['Enumeration'], utils.lookup_icon({ icon = 'terminal' }) },
            { "Exploits",    programs['Exploits'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "Forensics",   programs['Forensics'],   utils.lookup_icon({ icon = 'terminal' }) },
            { "Fuzzing",     programs['Fuzzing'],     utils.lookup_icon({ icon = 'terminal' }) },
            { "Misc",        programs['Misc'],        utils.lookup_icon({ icon = 'terminal' }) },
            { "Password",    programs['Password'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "Reversing",   programs['Reversing'],   utils.lookup_icon({ icon = 'terminal' }) },
            { "Scanners",    programs['Scanners'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "Smartcards",  programs['Smartcards'],  utils.lookup_icon({ icon = 'terminal' }) },
            { "Sniffing",    programs['Sniffing'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "Spoofing",    programs['Spoofing'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "Tunneling",   programs['Tunneling'],   utils.lookup_icon({ icon = 'terminal' }) },
            { "VoIP",        programs['VoIP'],        utils.lookup_icon({ icon = 'terminal' }) },
            { "Windows",     programs['Windows'],     utils.lookup_icon({ icon = 'terminal' }) },
            { "Wireless",    programs['Wireless'],    utils.lookup_icon({ icon = 'terminal' }) },
            { "WWW",         programs['WWW'],         utils.lookup_icon({ icon = 'terminal' }) },
        }, utils.lookup_icon({ icon = 'file-manager.png' }) },
        { "Development", programs["Development"], utils.lookup_icon({ icon = 'applications-development.png' }) },
        { "Education", programs["Education"], utils.lookup_icon({ icon = 'applications-science.png' }) },
        { "Games", programs["Game"], utils.lookup_icon({ icon = 'applications-games.png' }) },
        { "Graphics", programs["Graphics"], utils.lookup_icon({ icon = 'applications-graphics.png' }) },
        { "Internet", programs["Network"], utils.lookup_icon({ icon = 'applications-internet.png' }) },
        { "Multimedia", programs["AudioVideo"], utils.lookup_icon({ icon = 'applications-multimedia.png' }) },
        { "Office", programs["Office"], utils.lookup_icon({ icon = 'applications-office.png' }) },
        { "Other", programs["Other"], utils.lookup_icon({ icon = 'applications-other.png' }) },
        { "Settings", programs["Settings"], utils.lookup_icon({ icon = 'applications-utilities.png' }) },
        { "System Tools", programs["System"], utils.lookup_icon({ icon = 'applications-system.png' }) },
    }

    -- Removing empty entries from menu
    local cleanedMenu  = {}
    for index, item in ipairs(menu) do
	itemTester = item[2]
        if itemTester[1] then
            table.insert(cleanedMenu, item)
        end
    end

    return cleanedMenu
end
