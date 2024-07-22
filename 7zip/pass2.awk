# MIT license (c) 2024 https://github.com/slowpeek
# Homepage: https://github.com/slowpeek/mc-extfs-sp

# This script is supposed to be run under LC_ALL=C

# Sample input ---
# VBoxVBoxXorg
# -rwxr-xr-x 1 test test 5878 05-02-2024 13:18:56#VBox
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxAutostart
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxBalloonCtrl
# lrwxrwxrwx 1 test test 4 04-09-2024 06:18:52#X
# -rwxr-xr-x 1 test test 274 04-09-2024 06:18:52#Xorg
# ---

# Result ---
# VBoxAutostart -> VBox
# VBoxBalloonCtrl -> VBox
# X -> Xorg
# ---

NR == 1 {
    targets = $0
    offset = 1
    next
}

/^l/ {
    # Under LC_ALL=C, the substr() below does count bytes. This is the desired
    # behavior, since the "size" column is in bytes.
    target = substr(targets, offset, $5)
    offset += $5

    # We dont like q(->) in targets
    if (!index(target, "->")) print substr($0, index($0, "#") + 1) " -> " target
}
