# --------------------------------------------------------------
# Script Name: [anticaps.tcl]
# Author: Rikard Våhlström (bdz)
# Copyright (C) [2023] Rikard Våhlström
# 
# License:
# This script is free software; you are free to use, modify,
# and redistribute it under the terms of the MIT License.
# 
# Disclaimer:
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
# Notice:
# If you modify or distribute this script, please retain this
# copyright notice and authorship in the script.
# --------------------------------------------------------------

# Initialize a global array to keep track of user caps usage
array set caps_data {}

# Procedure to unban users
proc unban_user {uhost chan} {
    putserv "MODE $chan -b $uhost"
}

# Main procedure to check for excessive use of caps
proc check_caps {nick uhost hand chan text} {
    global caps_data

    # Check if the user is an operator (@) or has voice (+)
    if {[isop $nick $chan] || [isvoice $nick $chan]} {
        return
    }

    # Get the current time in seconds
    set current_time [clock seconds]

    # Check if the message is at least 10 characters long
    if {[string length $text] < 10} {
        return
    }

    # Calculate the percentage of uppercase letters in the message
    set total_chars [string length $text]
    set upper_chars [string length [regexp -all -inline {[A-Z]} $text]]
    set upper_percent [expr {($upper_chars / $total_chars) * 100}]

    # Check if more than 70% of the message is in uppercase
    if {$upper_percent <= 70} {
        return
    }

    # Check if the user exists in our caps_data array
    if {[info exists caps_data($nick)]} {
        set user_data [split $caps_data($nick) "|"]
        set last_time [lindex $user_data 0]
        set state [lindex $user_data 1]

        # Check if 2 minutes have passed to reset the state
        if {($current_time - $last_time) > 120} {
            set state "warn"
        }

        switch $state {
            "warn" {
                putserv "NOTICE $nick :Warning: You are violating channel and/or server rules! ( Reason: Excessive use of caps )"
                set state "kick"
            }
            "kick" {
                putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Excessive use of caps )"
                set state "kickban"
            }
            "kickban" {
                putserv "MODE $chan +b $uhost"
                putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Excessive use of caps )"
                
                # Schedule the unban to happen in 10 minutes (600 seconds)
                timedate [expr {$current_time + 600}] [list unban_user $uhost $chan]
                
                set state "warn"
            }
        }

        # Update user's data
        set caps_data($nick) "$current_time|$state"
    } else {
        # First time encountering the user, initialize their data
        set caps_data($nick) "$current_time|warn"
        putserv "NOTICE $nick :Warning: You are violating channel and/or server rules! ( Reason: Excessive use of caps )"
        set caps_data($nick) "$current_time|kick"
    }
}

# Bind the check_caps procedure to the public message event
bind pubm - "* *" check_caps