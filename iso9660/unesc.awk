# MIT license (c) 2024 https://github.com/slowpeek
# Homepage: https://github.com/slowpeek/mc-extfs-sp

# This script reverts xorriso's Text_shellsafe() in output of `xorriso .. -find
# .. -exec lsdl`. Pseudocode for the function:
#
# Text_shellsafe( s) {
#     return q(') replace(q('), q('"'"'), s) q(')
# }
#
# Xorriso_ls() uses two formats for pathes:
# - generic: Text_shellsafe(path)
# - symlink: Text_shellsafe(link) q( -> ) Text_shellsafe(target)
#
# References in xorriso sources:
# - iso_tree.c:Xorriso_ls()
# - text_io.c:Xorriso_esc_filepath()
# - misc_funct.c:Text_shellsafe()

{
    # Start of the path part
    i = index($0, "'")

    s = substr($0, i)
    # The path part with the wrapping quotes removed
    s = substr(s, 2, length(s)-2)

    if (substr($0, 1, 1) == "l") {
        s1=s
        if (gsub("->", "", s1) > 1) {
            # Ambiguity: either the link or its target contains q(->) in
            # addition to the link/target delimiter
            next
        }

        j = index(s, "' -> '")
        # link -> target with the wrapping quotes removed from both
        s = substr(s, 1, j-1) " -> " substr(s, j+6)
    } else if (index(s, "->")) {
        # Ambiguity: not a symlink, but there is q(->)
        next
    }

    gsub("'\"'\"'", "'", s)
    print substr($0, 1, i-1) s
}
