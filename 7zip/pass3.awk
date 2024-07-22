# MIT license (c) 2024 https://github.com/slowpeek
# Homepage: https://github.com/slowpeek/mc-extfs-sp

# Sample input ---
# VBoxAutostart -> VBox
# VBoxBalloonCtrl -> VBox
# X -> Xorg
#
# -rwxr-xr-x 1 test test 5878 05-02-2024 13:18:56#VBox
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxAutostart
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxBalloonCtrl
# lrwxrwxrwx 1 test test 4 04-09-2024 06:18:52#X
# -rwxr-xr-x 1 test test 274 04-09-2024 06:18:52#Xorg
# ---

# Result ---
# -rwxr-xr-x 1 test test 5878 05-02-2024 13:18:56#VBox
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxAutostart -> VBox
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxBalloonCtrl -> VBox
# lrwxrwxrwx 1 test test 4 04-09-2024 06:18:52#X -> Xorg
# -rwxr-xr-x 1 test test 274 04-09-2024 06:18:52#Xorg
# ---

BEGIN {
    init = 1
}

init {
    if ($0) {
        split($0, m, " -> ")
        map[m[1]] = m[2]
    } else {
        init = 0
        FS = "#"
    }

    next
}

/^l/ {
    link = substr($0, length($1)+2)
    if (link in map) print $0 " -> " map[link]
    next
}

1
