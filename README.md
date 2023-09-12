# Eggdrop TCL Scripts for Channel Moderation

This repository contains a collection of TCL scripts designed for channel moderation on IRC networks using the Eggdrop bot.

## Scripts Included

- `antispam.tcl`: Monitors and takes action against spamming behavior.
- `antiadvertise.tcl`: Detects and punishes advertising within the channel.
- `antirepeat.tcl`: Monitors for message repetition and takes action accordingly.
- `anticaps.tcl`: Detects excessive use of capital letters in messages.

## Features

### Common Features

- Operator and voiced users are ignored by all scripts.
- User state is reset after 2 minutes of inactivity.
- Automatic unbans occur after 10 minutes.

### antispam.tcl

- Monitors messages within a 10-second interval.
- Warning after 5 quick messages.
- Kick after another quick message spree.
- Kickban after a third quick message spree.

### antiadvertise.tcl

- Checks for common advertising keywords (`http`, `https`, `www`, `ftp`, `#channel`).
- Warning after first instance of advertising.
- Kick after a second instance within 2 minutes.
- Kickban after a third instance within 2 minutes.

### antirepeat.tcl

- Checks for repeated messages from the same user.
- Warning after 3 repeated messages.
- Kick after 5 repeated messages.
- Kickban after 7 repeated messages.

### anticaps.tcl

- Checks for messages with more than 70% capital letters.
- Only triggers for messages with at least 10 characters.
- Warning after first instance of excessive caps.
- Kick after a second instance within 2 minutes.
- Kickban after a third instance within 2 minutes.

## Installation

1. Download the desired `.tcl` script files.
2. Place the downloaded files into your Eggdrop `scripts/` directory.
3. Open your `eggdrop.conf` file and add a line to source the script, like so:
    ```tcl
    source scripts/antispam.tcl
    ```
    Repeat this step for each script you want to use.
4. Save changes to `eggdrop.conf`.
5. Rehash the bot or restart it to apply changes.

## Contributing

Feel free to contribute to these scripts by creating a pull request.

## License

These scripts are released under the MIT License. Please refer to the individual script files for detailed licensing information.
