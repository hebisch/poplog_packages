/* --- Copyright University of Birmingham 2011. All rights reserved. ------
 > File:            $usepop/pop/packages/newkit/prb/auto/rdl.p
 > Purpose:         Redefine prb_readline for use in
 >                  TEACH number-rulebase.p
 > Author:          Aaron Sloman, Nov 25 2011
 > Documentation:   TEACH number-rulebase.p
 > Related Files:   LIB poprulebase
 */



section;

uses poprulebase;

unless identprops("prb_readline_orig") = undef then
    [endsection;] -> proglist;
endunless;

;;; 'Compiling new prb_readline' =>

global constant prb_readline_orig = prb_readline;


define vars prb_readline();
    lvars item, list;
    dlocal popprompt = pop_readline_prompt, popnewline, proglist;

    define lconstant repeater();
        ;;; special character repeater to suppress string quotes
        ;;; and null characters (needed?)
        lvars char = charin();
        ;;; ignore string quotes and null characters
        while char == 0 or char == `'` do charin() -> char endwhile;
        if char == `\n` or char == termin then
            termin
        else
            uppertolower(char)
        endif
    enddefine;

    pdtolist(incharitem(repeater)) -> proglist;

    true -> popnewline;
    [%
        until null(proglist)
        or (dest(proglist) -> (item, proglist); item == newline or item == termin)
        do
            item
        enduntil
    %] -> list;
    if list == [] and item == termin then termin else list endif;
enddefine;

global vars procedure rdl = prb_readline;

endsection;
