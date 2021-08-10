/* --- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/objectfile.p
 > Purpose:         Find an object file
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP OBJECTFILE
 */

compile_mode:pop11 +strict;

section;

lconstant ARCH = sys_architecture,
    SUFFIX = '.so',
;

lvars popvision_bin_dir = systranslate('popvisionbindir') or
    systranslate('popsys') dir_>< '../packages/popvision/bin'
;

define procedure objectfile(name) -> obfilename;
    lvars name, obfilename;
    popvision_bin_dir dir_>< ARCH dir_>< (name sys_>< SUFFIX)
        -> obfilename;
    ;;; This should really throw an exception which can be caught
    ;;; by callers which can substitute pop-11 code when an
    ;;; object file is not available. Calling procedures ought to test
    ;;; this result before trying an exload anyway.
    unless readable(obfilename) then false -> obfilename endunless
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- David Young, Sep 24 1999
        Fixed to work with linux (thanks Aaron Sloman) and iris (thanks
        Anthony Worrall). Also tidied conditionals at start a little.
--- David S Young, Nov 13 1995
        Fixed typo in conditional compilation for alpha
--- David S Young, Sep 19 1995
        Made SUFFIX .so if machine type is alpha
--- David S Young, Jan 31 1994
        Made to use popfilename instead of pdprops(cucharin).
--- John Williams, Nov  5 1993
        Fixed for Solaris 2.x
--- David S Young, Nov 26 1992
        Changed to use -sys_machine_type-
 */
