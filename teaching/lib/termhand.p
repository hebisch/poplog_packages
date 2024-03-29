/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/termhand.p
 >  Purpose:        a robot hand for the blocks world demo with badpath recovery
 >  Author:         David Hogg, Richard Bignell, Oct 20 1986 (see revisions)
 >  Documentation:  TEACH * MSDEMO
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;


/* This file is a modification of LIB * MSHAND to provide recovery for
when a bad path is encountered */

;;; uses VTURTLE.

vars popturtlefile;
unless isstring(popturtlefile) then
    popval([lib vturtle;])
endunless;

vars isgrave gravity; false -> isgrave;


define 4 ===> x;
    ;;; for error messages
    ;;; Scroll();
    x =>
enddefine;

vars holding, Wx, Wy;
false->holding;

define drawclaw;
    if holding then "H"->picture(Wx,Wy)
    else   "/"->picture(Wx-1,Wy);
        "-"->picture(Wx,Wy);
        "'\\'"->picture(Wx+1,Wy)
    endif
enddefine;

define drawhand(atx,aty);
    "-" ->> picture(atx-1,15) ->> picture(atx,15) -> picture(atx+1,15);
    jumpto(atx,14);
    "|"->paint;
    drawto(atx,aty);
    atx->Wx;
    aty->Wy;
    .drawclaw
enddefine;

define clearclaw;
    space->picture(Wx,Wy);
    unless holding then
        space->>picture(Wx-1,Wy) ->picture(Wx+1,Wy)
    endunless
enddefine;

define drawbox(c,x,y,zbx,zby);
    vars h,i;
    for h from x to zbx+x-1 do
        for i from y to zby+y-1 do
            c -> picture(h,i);
        endfor;
    endfor;
enddefine;

define drawthebox(p);
    vars ox,oy,sx,sy;
    if holding then
        lookup([size ^holding ?sx ?sy]);
        lookup([held ?ox ?oy]);
        if p=space then space->paint else lookup([colour ^holding ?paint])
        endif;
        drawbox(paint,Wx-ox,Wy-oy,sx,sy)
    endif
enddefine;


define overlaps x1 y1 w1 h1 x2 y2 w2 h2;
    max(x1,x2) < min(x1+w1,x2+w2)
        and
    max(y1,y2) < min(y1+h1,y2+h2)
enddefine;

define newrect(x,y,w,h,ac,upp);
    if ac < 0 then x + ac else x endif;
    if upp < 0 then y + upp else y endif;
    w + abs(ac);
    h + abs(upp);
enddefine;

define inside(boxlist,listbox);
    vars xframe,yframe,wframe,hframe,x,y,w,h,box;
    listbox.dl->hframe->wframe->yframe->xframe;
    until boxlist=[] do
        boxlist.hd->box;
        boxlist.tl->boxlist;
        box.dl->h->w->y->x;
        if xframe>x or yframe>y or xframe+wframe<x+w or yframe+hframe<y+h
        then return(false) endif;
    enduntil;
    true
enddefine;


define badpath(ac,upp);
    vars shape,sx,sy,ox,oy,b,shtemp;
    if holding then
        lookup([size ^holding ?sx ?sy]);
        lookup([held ?ox ?oy]);
        [%[% newrect(Wx,Wy,1,15-Wy,ac,upp) %],
             [% newrect(Wx-2,15,5,1,ac,upp) %],
             [% newrect(Wx-ox,Wy-oy,sx,sy,ac,upp)%]%]->shape
    else [%[% newrect(Wx,Wy+1,1,14-Wy,ac,upp)%],
             [% newrect(Wx-2,15,5,1,ac,upp) %],
             [% newrect(Wx-1,Wy,3,1,ac,upp)%] %]->shape
    endif;
    if not(inside(shape,[1 1 75 28])) then
        'cannot move through pictureframe' ===>;
        "pictureframe"
    else
        foreach [?b at ?ox ?oy] do
            lookup([size ^b ?sx ?sy]);
            shape->shtemp;
            if member(true,[%
                         until shtemp=[] do
                             overlaps(shtemp.hd.dl,ox,oy,sx,sy);
                             shtemp.tl->shtemp
                         enduntil%])
            then    ('cannot move through ' >< b) ===>;
                return(b)
            endif;
        endforeach;
        false
    endif
enddefine;

vars Raise;
define Lower(a) -> outcome;
vars outcome;
    if a<0 then Raise(-a) -> outcome;
    elseif not(badpath(0,-a)) then
        drawthebox(space);
        .clearclaw;
        "|"->paint;
        jumpto(Wx,Wy);
        if Wy-a<1 then 1->Wy
        else Wy-a->Wy
        endif;
        drawto(Wx,Wy);
        .drawclaw;
        drawthebox(undef);
        true -> outcome;
    else
        false -> outcome;
    endif
enddefine;

define Raise(a) -> outcome;
vars outcome;
    if a<0 then Lower(-a)
    elseif not(badpath(0,a)) then
        drawthebox(space);
        space->paint;
        .clearclaw;
        jumpto(Wx,Wy);
        if Wy+a>14 then 14->Wy
        else Wy+a->Wy
        endif;
        drawto(Wx,Wy);
        .drawclaw;
        drawthebox(undef);
        true -> outcome;
    else
        false -> outcome;
    endif
enddefine;

define Across(x) -> outcome;
    vars newx outcome;
    unless badpath(x,0) then
        Wx+x->newx;
        drawthebox(space);
        .clearclaw;
        jumpto(Wx,Wy);
        space -> paint;
        drawto(Wx,15);
        jumpto(Wx-2,15);
        drawto(Wx+2,15);
        jumpto(Wx,Wy);
        drawto(newx,Wy);
        drawhand(newx,Wy);
        drawthebox(undef);
        .gravity;
        true -> outcome;
    else
        false -> outcome;
    endunless
enddefine;

define Down() -> outcome;
    vars x,box,y,lx,rx,ox,sx,sy,d,outcome;
    1 -> d;
    if holding then
        lookup([size ^holding ?sx =]);
        lookup([held ?ox =]);
        Wx-ox+sx-1->rx;
        Wx-ox->lx
    else   Wx-1->lx;Wx+1->rx
    endif;
    foreach [?box at ?x ?y] do
        unless x > rx then
            lookup([size ^box ?sx ?sy]);
            unless x+sx <= lx or y+sy <= d then
                y+sy->d
            endunless
        endunless
    endforeach;
    if holding then lookup([size ^holding = ?sy]); d+sy->d endif;
    Lower(Wy-d) -> outcome;
enddefine;

define Hold;
    vars box,x,y,sx,sy;
    if holding then 'Already holding'===>;
    else
        foreach [?box at ?x ?y] do
            unless x>Wx do
                lookup([size ^box ?sx ?sy]);
                if y+sy=Wy and x+sx>Wx then
                    .clearclaw;
                    box->holding;
                    remove([^box at ^x ^y]);
                    add([held %Wx-x,Wy-y%]);
                    .drawclaw;
                    return
                endif
            endunless
        endforeach;
        'nothing to hold'===>;
    endif
enddefine;

define Letgo;
    if not(holding) then 'nothing held'===>;
    elseif picture(Wx-1,Wy)/=space
            or picture(Wx+1,Wy)/=space
    then 'can\'t open claw'===>;
    else
        lookup([held ?ox ?oy]);
        remove([held = =]);
        add([^holding at %Wx-ox,Wy-oy%]);
        false->holding;
        .drawclaw;
        .gravity;
    endif
enddefine;

define Getabove(b) -> outcome;
    vars x,sx,outcome;
        if holding==b then ('holding ' >< b)===>;
        else
            unless Wy=14 then
                if Raise(13) then
                    true -> outcome;
                else
                    false -> outcome;
                    return;
                endif;
            endunless;
            lookup([^b at ?x =]);
            lookup([size ^b ?sx =]);
            sx//2->sx; .erase;
            if Across(x+sx-Wx) then
                true -> outcome;
            else
                Lower(13) ->;   ;;; undo the Raise
                false -> outcome; return;
            endif;
        endif
enddefine;

define Findspace() -> outcome;
    vars sx,p,x,b,rx,tx,done,outcome;
    if holding then
        if Raise(13) then true -> outcome; else false -> outcome; return; endif;
        lookup([size ^holding ?sx =]);
        sx-1->sx;
        for (false->done;1->>p->rx) step rx->p till done do
            true->done;
            foreach [?b at ?x =] do
                if x >= p then
                    unless p+sx<x then
                        false->done;
                        lookup([size ^b ?tx =]);
                        if x+tx>rx then x+tx->rx endif
                    endunless
                else lookup([size ^b ?tx =]);
                    unless x+tx<=p then
                        false->done;
                        if x+tx>rx then x+tx->rx endif
                    endunless
                endif
            endforeach;
            if done and (lookup([held ?tx =]); p+tx<3) then false->done;
                3-tx->rx endif
        endfor;
        if Across(p+tx-Wx) then true -> outcome;
        else
            Down() ->;
            false -> outcome;
            return;
        endif;
        if Down() then
            true -> outcome;
        else
            Across(-(p+tx-Wx)) ->;  ;;; undo the Across
            Down() ->;              ;;; undo the Raise
            false -> outcome;
            return;
        endif;
    else 'not holding' ===>;
    endif
enddefine;

define balanced(x,y,sx);
    vars yt llim rlim xmid;
    unless y=1 or x=1 or x+sx>75 then
        y-1 -> yt;  x -> llim;  x+sx-1 -> rlim;
        while (picture(llim,yt) == space) and (llim < rlim) do
            llim+1 -> llim
        endwhile;
        while (picture(rlim,yt) == space) and (llim <= rlim) do
            rlim-1 -> rlim
        endwhile;
        x+(sx-1)/2 -> xmid;
        if rlim < llim then 0
        elseif llim > xmid and picture(x-1,yt) == space then -1
        elseif rlim < xmid and picture(x+sx,yt) == space then 1
        else return(true)
        endif;
        false;
    else
        true;
    endunless;
enddefine;

define gravity;
    vars box x y sx sy p dir ax ex moved globalmoved;
    if isgrave then
        false -> globalmoved;
        foreach [?box at ?x ?y] do
            false -> moved;
            lookup([size ^box ?sx ?sy]);
            lookup([colour ^box ?p]);
            until balanced(x,y,sx) do
                -> dir; true ->> globalmoved -> moved;
                if dir = 0 then
                    drawbox(space,x,y+sy-1,sx,1);
                    y-1 -> y;
                    drawbox(p,x,y,sx,1);
                else
                    if dir > 0 then x; x+sx else x+sx-1; x-1 endif
                    -> ax -> ex;
                    drawbox(space,ex,y,1,sy);
                    drawbox(p,ax,y,1,sy);
                    x+dir -> x;
                endif;
            enduntil;
            if moved then
                remove([^box at = =]);
                add([^box at ^x ^y]);
            endif;
        endforeach;
        if globalmoved then gravity() endif;
    endif;
enddefine;

define showdata;
    vars database x y b c zbx zby;
    while [?b at ?x ?y].present do
        lookup([colour ^b ?c]);
        lookup([size ^b ?zbx ?zby]);
        drawbox(c,x,y,zbx,zby);
        remove([^b at ^x ^y])
    endwhile;
    false -> vedwriteable;
enddefine;

/* --- Revision History ---------------------------------------------------
--- John Gibson, Aug  1 1995
        Added +oldvar at top
--- Aaron Sloman, Jan 24 1987
    Moved to public library
--- Richard Bignell, Oct 20 1986 - this is an extension of LIB * MSHAND to
    allow LIB * MSDEMO to restore itself after a bad path is encountered
    in a move.
*/
