# MIT license (c) 2024 https://github.com/slowpeek
# Homepage: https://github.com/slowpeek/mc-extfs-sp

# Sample input ---
# Path = VBox
# Size = 5878
# Packed Size = 2511
# Modified = 2024-05-02 13:18:56
# Attributes = A -rwxr-xr-x
# CRC = 329C9116
# Encrypted = -
# Method = LZMA2:13
# Block = 0
#
# Path = VBoxAutostart
# Size = 4
# Packed Size =
# Modified = 2024-05-02 13:18:56
# Attributes = A lrwxrwxrwx
# CRC = 008758AA
# Encrypted = -
# Method = LZMA2:13
# Block = 0
#
# Path = VBoxBalloonCtrl
# Size = 4
# Packed Size =
# Modified = 2024-05-02 13:18:56
# Attributes = A lrwxrwxrwx
# CRC = 008758AA
# Encrypted = -
# Method = LZMA2:13
# Block = 0
#
# Path = X
# Size = 4
# Packed Size =
# Modified = 2024-04-09 06:18:52
# Attributes = A lrwxrwxrwx
# CRC = A2A99BC3
# Encrypted = -
# Method = LZMA2:13
# Block = 0
#
# Path = Xorg
# Size = 274
# Packed Size =
# Modified = 2024-04-09 06:18:52
# Attributes = A -rwxr-xr-x
# CRC = AA6C2403
# Encrypted = -
# Method = LZMA2:13
# Block = 0
#
# ---

# Command ---
# awk -v env_uid=test -v env_gid=test -v env_umask=0022 \
#     -v env_mtime='07-02-2024 23:50:52' ..
# ---

# Result ---
# -rwxr-xr-x 1 test test 5878 05-02-2024 13:18:56#VBox
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxAutostart
# lrwxrwxrwx 1 test test 4 05-02-2024 13:18:56#VBoxBalloonCtrl
# lrwxrwxrwx 1 test test 4 04-09-2024 06:18:52#X
# -rwxr-xr-x 1 test test 274 04-09-2024 06:18:52#Xorg
# ---

function init() {
    skip = 0
    path = ""
    size = ""
    packed_size = ""
    mtime = ""
    perm = ""
}

# umask_apply( "rwx", 2) => "r-x"
function umask_apply( ps, u) {
    split(ps, pa, "")

    for ( i=3; i>0; i--) {
        if (u % 2 == 1) {
            pa[i] = "-"
            u--
        }

        u /= 2
    }

    return pa[1] pa[2] pa[3]
}

BEGIN {
    init()
    FS = "="

    l = length(env_umask)
    if (l < 2) {
        env_umask = (l < 1) ? "22" : "0" env_umask
        l = 2
    }

    umask_o = substr(env_umask, l, 1)
    umask_g = substr(env_umask, l-1, 1)

    # auto_perm array is used to decide on perms when only DRHSA attrs are
    # set. Out of those, only D and R attrs are of interest. R attr for dirs is
    # intentionally ignored. Usage: auto_perm[2*is_dir + is_ro + 1]
    #
    # [1] = file
    # [2] = file, ro
    # [3] = dir
    # [4] = dir

    t = umask_apply("rwx", umask_g) umask_apply("rwx", umask_o)

    auto_perm[1] = "-rw-" t
    gsub("x", "-", auto_perm[1])
    auto_perm[2] = auto_perm[1]
    gsub("w", "-", auto_perm[2])

    auto_perm[3] = "drwx" t
    auto_perm[4] = auto_perm[3]
}

{
    if (!NF) {
        if (!skip) {
            if (size == "") size = packed_size ? packed_size : 0

            if (perm && mtime && path)
                print perm, 1, env_uid, env_gid, size, mtime "#" path
        }

        init()
        next
    }

    if (skip) next

    l = length($1) - 1
    field = substr($1, 1, l)

    # Reassign $0 to the value and split it the usual way
    FS = " "
    $0 = substr($0, l + 4)

    if (field == "Path") {
        if ($0) {
            if (!index($0, "->")) {
                path = $0
            } else { # We dont like q(->) in path
                skip = 1
            }
        } else { # Unknown format
            skip = 1
        }
    } else if (field == "Size") {
        if (NF == 1) {
            size = $1
        } else if (NF > 1) { # Unknown format
            skip = 1
        }
    } else if (field == "Packed Size") {
        if (NF == 1) {
            packed_size = $1
        } else if (NF > 1) { # Unknown format
            skip = 1
        }
    } else if (field == "Modified") {
        if (NF == 2) {
            split($1, dt, "-");
            mtime = dt[2] "-" dt[3] "-" dt[1] " " $2
        } else if (!NF) {
            # `7z a -mtm=off ..` does not set mtime
            if (!mtime) mtime = env_mtime
        } else { # Unknown format
            skip = 1
        }
    } else if (field == "Attributes") {
        if (NF == 2) { # DRHSA q( ) posix
            if (length($2) == 10) { # Posix
                perm = $2
            } else { # Unknown format
                skip = 1
            }
        } else if (NF == 1) { # Either DRHSA or posix
            l = length($1)

            if (l < 10) { # DRHSA
                perm = auto_perm[2*(index($1, "D") > 0) + (index($1, "R") > 0) + 1]
            } else if (l == 10) { # Posix
                perm=$1
            } else { # Unknown format
                skip = 1
            }
        } else if (!NF) { # No attrs
            # `7z a -sifn_arc < fn` does not set any attrs
            perm = auto_perm[1]
        } else { # Unknown format
            skip = 1
        }
    }

    FS = "="
}
