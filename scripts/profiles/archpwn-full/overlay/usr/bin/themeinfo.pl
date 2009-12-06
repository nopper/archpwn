#!/usr/bin/python

# themeinfo.py by dbbolton (envyouraudience at gmail)

import gconf
import os
import string
from os.path import exists
from subprocess import call
from time import strftime

#colors
blue = "\033[1;34m"
green = "\033[1;32m"
cyan = "\033[1;36m"
red = "\033[1;31m"
bblue = "\033[0;38;5;12m"
orange = "\033[0;38;5;202m"
yelloworange = "\033[0;38;5;208m"
gold = "\033[0;38;5;214m"
darkorange = "\033[0;38;5;130m"
darkcyan="\033[0;38;5;32m"

#change color back to default
end="\033[0m"

################################
#   OPTIONS
################################

# Which window manager?
include_mt = True #metacity
include_ob = False #openbox
include_aw = False  #awesome

# Which terminal are you using?
include_gt = True #gnome-terminal
include_xft = False #xfce4-terminal
include_tilda = False
include_urxvt = False

# Is your GTK theme specified in yout .gtkrc.mine file?
include_gtkrcmine = False

# What about your font?
my_font = False

# And your icons?
my_icons = False

# Do you use feh to set your wallpaper?
include_feh = False

################################
#   END OPTIONS
################################

#define key to get stuff from gconf
key = gconf.client_get_default()

#########################
# distro
#########################
if exists(os.path.expanduser("/etc/issue")):
    for line in open(os.path.expanduser("/etc/issue")):
        if " " in line:
            distro=line
                       #break
else:
    distro = "Linux"


#########################
# gtk
#########################
if include_gtkrcmine:
    if exists(os.path.expanduser("~/.gtkrc.mine")):
        for line in open(os.path.expanduser("~/.gtkrc.mine")):
            if "/gtk-2.0/gtkrc" in line:
                mygtk=line
                use_my_gtk = True
                           #break
            else:
                use_my_gtk = False
else:
    mygtk = "?"
    use_my_gtk = False

if include_gt:
    gnomegtk = key.get_value("/desktop/gnome/interface/gtk_theme")

#########################
# fonts
#########################
if my_font:
    if exists(os.path.expanduser("~/.gtkrc.mine")):
        for line in open(os.path.expanduser("~/.gtkrc.mine")):
            if "gtk-font-name" in line:
                myfont = line
                use_my_font = True
                           #break
            else:
                use_my_font = False
else:
    use_my_font = False

gnomefont = key.get_value("/desktop/gnome/interface/font_name")

#tilda
if exists(os.path.expanduser("~/.tilda/config_0")):
    for line in open(os.path.expanduser("~/.tilda/config_0")):
        if "font" in line:
            tildfont=line
                       #break
else:
    tildfont = "?"

#gnome-terminal

gtfont = key.get_value("/apps/gnome-terminal/profiles/Default/font")

#xfce4-terminal

if exists(os.path.expanduser("~/.config/Terminal/terminalrc")):
    for line in open(os.path.expanduser("~/.config/Terminal/terminalrc")):
        if "FontName" in line:
            xftfont=line
                       #break
else:
    xftfont = "?"

#urxvt

if exists(os.path.expanduser("~/.Xdefaults")):
    for line in open(os.path.expanduser("~/.Xdefaults")):
        if "urxvt*font" in line:
            urxvtfont=line
                       #break
else:
    urxvtfont = "?"

#########################
# icons
#########################
if my_icons:
    if exists(os.path.expanduser("~/.gtkrc.mine")):
        for line in open(os.path.expanduser("~/.gtkrc.mine")):
            if "icon-theme" in line:
                myicons = line
                use_my_icons = True
                break
            else:
                use_my_icons = False
else:
    myicons = "?"
    use_my_icons = False

gnomeicons = key.get_value("/desktop/gnome/interface/icon_theme")

#########################
# metacity 
#########################

if include_mt:
    metacitytheme = key.get_value("/apps/metacity/general/theme")
else:
    metacitytheme = "?"


#########################
# openbox
#########################
if exists(os.path.expanduser("~/.config/openbox/rc.xml")):
    for line in open(os.path.expanduser("~/.config/openbox/rc.xml")):
        if "<name>" in line:
            ob = line 
            break
else:
    ob = "?"


#########################
# wall
#########################
if include_feh:
    if exists(os.path.expanduser("~/.fehbg")):
        for line in open(os.path.expanduser("~/.fehbg")):
            if "feh" in line:
                fehwall = line
                break
            else:
                use_feh_wall = False
else:
    wall="?"
    use_feh_wall = False

gwallpath = key.get_value("/desktop/gnome/background/picture_filename")[0:-4]
gwallname = gwallpath.split('/')[-1]


######################
#print info
######################
print "\n"+orange+distro.split(' ')[0]+" "+distro.split(' ')[1]+"\n"


if use_my_gtk:
    print darkcyan+"  GTK:"+end+"                   "+mygtk.split('/')[4]
else:
    print darkcyan+"  GTK:"+end+"                   "+gnomegtk
if use_my_font:
    print darkcyan+"  Font (Apps):"+end+"           "+myfont.split('"')[1]
else:
    print darkcyan+"  Font (Apps):"+end+"           "+gnomefont
if include_tilda:
    print darkcyan+"  Font (Terminal):"+end+"       "+tildfont.split('"')[1]
elif include_gt:
    print darkcyan+"  Font (Terminal):"+end+"       "+gtfont
elif include_urxvt:
    print darkcyan+"  Font (Terminal):"+end+"       "+urxvtfont.split(':')[-1][0:-1]
elif include_xft:
    print darkcyan+"  Font (Terminal):"+end+"       "+xftfont.split('=')[1][0:-1]
if use_my_icons:
    print darkcyan+"  Icons:"+end+"                 "+myicons.split('"')[1]
else:
    print darkcyan+"  Icons:"+end+"                 "+gnomeicons
if include_mt:
    print darkcyan+"  Metacity:"+end+"              "+metacitytheme
elif include_ob:
    if exists(os.path.expanduser("~/.config/openbox/rc.xml")):
        print darkcyan+"  Openbox:"+end+"               "+ob.split('>')[1][0:-6]
    else:
        print "Openbox theme not found."
elif include_aw:
    print darkcyan+"  WM:"+end+"                    Awesome"
else:
    print darkcyan+"  WM:"+end+"                    ?"
if include_feh:
    print darkcyan+"  Wall:"+end+"                  "+fehwall.split('/')[-1][0:-2]+"\n"
else:
    print darkcyan+"  Wall:"+end+"                  "+gwallname+"\n"

print " "+strftime("%A %d %B %Y")+"\n"
######################
#take screenshot
######################
call(["sleep", "1"])
#call("scrot")