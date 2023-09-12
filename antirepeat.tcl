# --------------------------------------------------------------
# Script Name: [antirepeat.tcl]
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

# Initialize a global array to keep track of user repeating data
array set repeat_data {}

# Procedure to unban users
proc unban_user {uhost chan} {
    putserv "MODE $chan -b $uhost"
}

# Main procedure to check for message repetition
proc check_repeat {nick uhost hand chan text} {
    global repeat_data

    # Check if the user is an operator (@) or has voice (+)
    if {[isop $nick $chan] || [isvoice $nick $chan]} {
        return
    }

    # Get the current time in seconds
    set current_time [clock seconds]

    # Check if the user exists in our repeat_data array
    if {[info exists repeat_data($nick)]} {
        set user_data [split $repeat_data($nick) "|"]
        set last_time [lindex $user_data 0]
        set last_text [lindex $user_data 1]
        set counter [lindex $user_data 2]
        set state [lindex $user_data 3]

        # Check if 2 minutes have passed to reset the state
        if {($current_time - $last_time) > 120} {
            set state "warn"
            set counter 0
            set last_text ""
        }

        # Check for repetition
        if {$last_text eq $text} {
            set counter [expr {$counter + 1}]
        } else {
            set counter 1
            set last_text $text
        }

        # Actions based on repetition
        if {$counter >= 7} {
            set state "kickban"
        } elseif {$counter >= 5} {
            set state "kick"
        } elseif {$counter >= 3} {
            set state "warn"
        }

        switch $state {
            "warn" {
                putserv "NOTICE $nick :Warning: You are violating channel and/or server rules! ( Reason: Repeating messages )"
            }
            "kick" {
                putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Repeating messages )"
            }
            "kickban" {
                putserv "MODE $chan +b $uhost"
                putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Repeating messages )"
                
                # Schedule the unban to happen in 10 minutes (600 seconds)
                timedate [expr {$current_time + 600}] [list unban_user $uhost $chan]
            }
        }

        # Update user's data
        set repeat_data($nick) "$current_time|$last_text|$counter|$state"
    } else {
        # First time encountering the user, initialize their data
        set repeat_data($nick) "$current_time|$text|1|warn"
    }
}

# Bind the check_repeat procedure to the public message event
bind pubm - "* *" check_repeat