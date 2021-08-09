/* --- Copyright University of Birmingham 2011. All rights reserved. ------
 > File:            $usepop/pop/lib/auto/list_to_string.p
 > Purpose:         Create a string by concatenating components of a list
 >                  (normally words)
 > Author:          Aaron Sloman, Nov 24 2011
 > Documentation:
 > Related Files:
 */


section;

define list_to_string(list);

    consstring(#| applist(list, destword<>erase) |#)

enddefine;

endsection;
