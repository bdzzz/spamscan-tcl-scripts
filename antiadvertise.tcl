# --------------------------------------------------------------
# Script Name: [antiadvertise.tcl]
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

# Initialize a global array to keep track of user advertising data
array set advertise_data {}

# Procedure to unban users
proc unban_user {uhost chan} {
    putserv "MODE $chan -b $uhost"
}

# Main procedure to check for advertising
proc check_advertise {nick uhost hand chan text} {
    global advertise_data

    # Check if the user is an operator (@) or has voice (+)
    if {[isop $nick $chan] || [isvoice $nick $chan]} {
        return
    }

    # Get the current time in seconds
    set current_time [clock seconds]

    # Check for advertising keywords in the message
    if {[regexp {(https?|ftp)://|www\.|#} $text]} {
        
        # Check if the user exists in our advertise_data array
        if {[info exists advertise_data($nick)]} {
            set user_data [split $advertise_data($nick) "|"]
            set last_time [lindex $user_data 0]
            set state [lindex $user_data 1]
            
            # Check if 2 minutes have passed to reset the state
            if {($current_time - $last_time) > 120} {
                set state "warn"
            }
            
            switch $state {
                "warn" {
                    putserv "NOTICE $nick :Warning: You are violating channel and/or server rules! ( Reason: Advertising )"
                    set state "kick"
                }
                "kick" {
                    putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Advertising )"
                    set state "kickban"
                }
                "kickban" {
                    putserv "MODE $chan +b $uhost"
                    putserv "KICK $chan $nick :You are violating channel and/or server rules! ( Reason: Advertising )"
                    set state "warn"
                    
                    # Schedule the unban to happen in 10 minutes (600 seconds)
                    timedate [expr {$current_time + 600}] [list unban_user $uhost $chan]
                }
            }
            
            # Update user's data
            set advertise_data($nick) "$current_time|$state"
        } else {
            # First time encountering the user, initialize their data
            set advertise_data($nick) "$current_time|warn"
            putserv "NOTICE $nick :Warning: You are violating channel and/or server rules! ( Reason: Advertising )"
            set advertise_data($nick) "$current_time|kick"
        }
    }
}

# Bind the check_advertise procedure to the public message event
bind pubm - "* *" check_advertise
