/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popneural/lib/cload.p
 > Purpose:         Convenient macros for loading c procs
 > Author:          Julian Clinton, Feb 26 1993.
 */

section;


include sysdefs;

lvars systype = sys_architecture;


lvars packages_bindir = systranslate('poppackagesbindir') or
                        systranslate('popsys') dir_>< '../packages'
;

lvars popneural_bindir = packages_bindir dir_>< 'neural/bin/'
                            dir_>< systype dir_>< '/';

global vars c_liblist;

    npr(';;; cload: using C libraries...');
    [] -> c_liblist;

printf(c_liblist, ';;; Link options: %p\n');

;;; specify location of shared library

lvars link_file_stub =
    popneural_bindir dir_>< '%p.so'
;


;;; load shared library
;;;
define global macro cload name;
lvars name file;

    pr(';;; Linking ');
    sprintf(name, link_file_stub) -> file;
    npr(file);
    "external", "load", name, ";",
        explode(c_liblist), file;
    "endexternal", ";"
enddefine;

endsection;

/*  --- Revision History --------------------------------------------------
--- Julian Clinton, Aug 25 1995
    Changes for 15.0.
--- Julian Clinton, Jul 11 1994
    Added support for IRIX 5.x
--- Julian Clinton, Mar  7 1994
    Added support for Solaris 2
--- Julian Clinton, Aug  5 1993
    Changed back to use external instead of newexternal.
--- Julian Clinton, Jul  6 1993
    Changed to use newexternal instead of external.
--- Julian Clinton, Jun 17 1993
    Modified DECstation load options.
*/
