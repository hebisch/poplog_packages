/* --- Copyright University of Birmingham 2013. All rights reserved. ------
 > File:            $usepop/pop/packages/vedmail/auto/ved_decode.p
 > previously:            $poplocal/local/auto/ved_decode.p
 > Purpose:         Decode attachment in mail file
 > Author:          Aaron Sloman, Mar 23 1998 (see revisions)
 > Documentation:   See HELP VED_DECODE
 > Related Files:
 */

/*

The following will (mostly) work on suns and linux machines. Not sure
about other versions of poplog.

*/


section;

;;; edit for your site

/*
The lhalw program can extract text from many though not all word files.
It is a Perl utility for extracting text from Word files. See
            http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh

*/


global vars
    ;;; lhalw_command = 'csh /bham/ums/common/pd/bin/lhalw -c 72 -F ';
    lhalw_command = 'csh antiword -t -w 72 ';

/*
Mimencode is a standard unix/linux tool for translating to and from
base-64 mime encoded format.

It can also decode quoted printable files.
*/

global vars

    mime_decode_command = 'mimencode -u ',
    mime_decode_and_crlf_command = 'mimencode -u -p ',
    mime_decode_quoted_printable_command = 'mimencode -u -q -p ',

    ;;; if this is false it tries to help with display.
    do_not_display_file = true,

;

define decode_file_into(command, infile, outfile);
    ;;; use `%` option in case path names include '~'
    ;;; Veddebug([decoding %infile% to %outfile%]);
    sysobey(command >< infile >< ' > ' >< outfile);
    ;;; Veddebug([decoded to %outfile%]);
enddefine;

;;; Make this false to use chmod 644 instead of 600
global vars
    decode_protect;

if isundef(decode_protect) then true -> decode_protect endif;

;;; Make this false to stop a blank line being treated as end of attachment.
global vars
    decode_end_blank;

if isundef(decode_end_blank) then true -> decode_protect endif;


;;; In case LIB ved_autosave is in use
;;; this is made false in ved_decode
global vars vedautosaving ;

;;; place to store decoded files from system mail file
;;; if no Mail and mail directories
global vars
    ved_decode_default_dir = '~';

;;; See HELP VED_DECODE
lconstant
;;; Types of files
    unknowntype = '.unknown',
    unencodedtype = '.unencoded',
    mimetype = '.mime',
;;; uuencoded
    uutype   = '.uu',
;;; Binhex: Use 'xbin' to decode
    binhextype = '.bhx',
;;; powerpoint
    ppttype  = '.ppt',
    pptxtype  = '.pptx',
    htmltype = '.html',
    htmtype  = '.htm',
    gztype   = '.gz',   ;;; Produced by gzip
    bzip2type = '.bz2', ;;; See man bzip2. Compresses better than gzip
    tgztype  = '.tgz',  ;;; Alternative to .tar.gz
    tartype  = '.tar',
    ziptype  = '.zip',
    jartype  = '.jar',
    pstype   = '.ps',
    doctype  = '.doc',
    docxtype  = '.docx',
    sdwtype  = '.sdw',  ;;; staroffice/openoffice
    sxwtype  = '.sxw',  ;;; staroffice/openoffice
    odttype  = '.odt',  ;;; OpenDocument Text
    odstype  = '.ods',  ;;; OpenDocument Spreadsheet
    odptype  = '.odp',  ;;; OpenDocument Presentation
    xlstype  = '.xls',
    xlsxtype  = '.xlsx',
    xlsmtype = '.xlsm', ;;; spread sheet with macros.
    wpdtype  = '.wpd',
    bmptype  = '.bmp',
    giftype  = '.gif',
    tiftype  = '.tif',
    pngtype  = '.png',
    jpgtype = '.jpg',
    jpegtype = '.jpeg',
    pbmtype  = '.pbm',
    mpegtype = '.mpeg',
    mp3type = '.mp3',
    mpgtype = '.mpg',
    avitype = '.avi',
    ;;; I don't know what this is!
    pcxtype  = '.pcx',
    pdftype  = '.pdf',
    texttype = '.text',
    txttype = '.txt',
    rtftype  = '.rtf',
    latextype  = '.tex',
    dvitype  = '.dvi',
    bibtype = '.bib',
    exetype = '.exe',
    pltype = '.pl',
    ptype = '.p',
    anytype = '',

    qp_field = 'quoted-printable',
    ht_field = 'text/html',

    no_decode_types =
    [^pstype ^htmltype ^htmtype ^texttype ^txttype ^latextype ^bibtype ^rtftype
            ^mpegtype ^mp3type ^mpgtype ^avitype ^pcxtype ^false],
    soffice_types =
    [^ppttype ^pptxtype ^doctype ^docxtype ^xlstype ^xlsxtype ^xlsmtype ^htmltype ^sdwtype ^sxwtype
        ^odttype ^odstype ^odptype],
    pdf_types = [^pdftype],
    netscape_types =
    [^pstype ^htmltype ^pdftype],
    text_types =
    [^latextype ^bibtype ^htmltype ^texttype ^txttype ^pltype ^ptype],
    tar_types =
        [^tartype ^tgztype],
;

;;; Various utilities

define lconstant markmime_field();

    dlocal ved_search_state;

    ;;; Mark from current field boundary to just before next
    lvars
        line,
        boundary_string = vedthisline();

    vedpositionpush();
    vedmarklo();
        ;;; vedlocate(boundary_string);

    ;;; Now find end of attachment header.
    ;;; move forward to next line that is empty
    until vvedlinesize == 0 do vedchardown() enduntil;

    ;;; Should be at end of attachment header. Find start of
    ;;; attachment contents
    while vvedlinesize == 0 do vedchardown() endwhile;

    vedline -> line;
    ;;; now find end of attachment
    ;;; first see if the boundary string can be found
    vedlocate(boundary_string);

    if vedline > line then
        ;;; found boundary
    else
        ;;; no boundary end, assume it's the first blank line

        vedjumpto(line, 1);
        until
            issubstring(boundary_string, 1, vedthisline()) or
            (decode_end_blank and vvedlinesize == 0)
        do vedchardown()
        enduntil;
    endif;

/*  
    if vedline <= vvedmarklo then
        vederror('Second boundary string not found '>< boundary_string);
    endif;
*/

    ;;; go back to first non-blank line
    vedcharup();
    while vvedlinesize == 0 do vedcharup() endwhile;

    if vedline <= line then
        vederror('Cannot find end of attachment');
    endif;

    vedmarkhi();

    ;;; Veddebug([^vedline %vedthisline()%]);

    vedpositionpop();
enddefine;

define lconstant markmime_contents();
    ;;; Assume mime field has already been marked by previous procedure
    ;;; find start of contents and mark from there
    ;;; could be improved
    lvars
        textline;

    vedmarkfind();
    vednextline();
    while
        vvedlinesize == 0
        or issubstring('content', (uppertolower(vedthisline()) ->> textline))
        ;;;or issubstring('content', (vedthisline()) ->> textline))
        or issubstring('decoding', textline)
        or issubstring('attachment', textline)
        ;;; next two deal with wrapped lines due to editing name field, etc.
        or isstartstring('charset=', textline)
        or isstartstring('name=', textline)
        or isstartstring('NAME=', textline)
        or isstartstring('\s', textline)
        or isstartstring('\t', textline)
    do
        vednextline();
        quitif(isstartstring('begin', vedthisline()))
            ;;; it is uuencoded
    endwhile;
    vedmarklo();
enddefine;


define lconstant getanswer(string) -> boole;
    ;;; string is a question. Display it. Accept y, Y or RETURN as Yes.
    vedputmessage(string);
    vedwiggle(0, 13+datalength(string)+datalength(vedcommand));
    lvars char = vedscr_read_ascii();
    strmember(char, 'yY\r') -> boole;
enddefine;

lvars files_saved = [];

define show_info(file);
    unless member(file, files_saved) then
        conspair(file, files_saved) -> files_saved
    endunless;
enddefine;

define lconstant showfiles();
    lvars
        oldfile = vedcurrentfile,
        file,
        all_files = nullstring;

    unless files_saved == [] then

        consstring(#|
                explode('ls -l '),
                for file in files_saved do
                    explode(file); `\s`;
                endfor, erase()
            |#) -> all_files;

        [] -> files_saved;

        dlocal
            show_output_on_status = false,
            vedargument = all_files;

        ;;; Veddebug('showing ' <> all_files);
        vedgenshell('/bin/sh', '');
        vedtopfile();
        vedlineabove();
        vedinsertstring('NEW FILE(S) CREATED. DELETE IF NOT WANTED');
        ;;; Veddebug('shown ' <> all_files);
        unless oldfile = vedcurrentfile then
            oldfile -> ved_current_file
        endunless;
    endunless;
enddefine;

define lconstant delete_coded(file);
    dlocal ved_current_file;
    ;;;Veddebug('Check deleting in ' >< vedpathname);
    if getanswer('Delete attachment from message?(y/n)') then
        lvars oldfile = vedcurrentfile;
        file -> ved_current_file;
        vedmarkfind();
        ;;; Veddebug('Deleteing in ' >< file);
        ved_d();
        oldfile -> ved_current_file;
    endif;
    ;;;Veddebug('No delete: '>< file);
enddefine;

define Isstartstring(string, item);
    isstring(item) and isstartstring(string, item)
enddefine;

define Isendstring(string, item);
    isstring(item) and
        isendstring(string, item) or isendstring(lowertoupper(string), item)

enddefine;

define Issubstring(string, item);
    isstring(item) and issubstring(string, item)
enddefine;


define get_field(field_string) -> found;
    ;;; Assume section to be decoded already marked.
    ;;; Return string with information about field
    lvars
        field_len = datalength(field_string),
        string,
        found = false;
    vedpositionpush();

    ;;; Go to start of marked range
    vedmarkfind();

    ;;; Search down for occurrence of the field_string, translating to
    ;;; lower case to simplify matching.
    while vedline < vvedmarkhi do
        uppertolower(vedthisline()) -> string;
        
        if isstartstring(field_string, string) then
            ;;; Found the field, return stuff to right
            ;;;allbutfirst(field_len, string) -> found;
            allbutfirst(field_len, vedthisline()) -> found;

            ;;; now see if field overflows
            lconstant white_space = '\s\t';
            repeat
                vednextline();
                quitif(vvedlinesize == 0);
                ;;; find end of white space
                if strmember(vedcurrentchar(), white_space) then
                    vedcharright();
                    while strmember(vedcurrentchar(), white_space) do
                        vedcharright();
                    endwhile;
                    ;;; text starts here, add it to the string
                    found sys_>< vedspacestring ><
                        allbutfirst(vedcolumn - 1, vedthisline()) -> found
                else
                    quitloop()
                endif;
            endrepeat;
            quitloop();
        elseif vvedlinesize == 0 then
            quitloop();
        endif;
        vedchardown();
    endwhile;
    vedpositionpop();
enddefine;

define get_all_fields() ->
    (content_type, content_disposition, content_description, content_transfer_encoding);

    ;;; Get information about fields
    ;;; Use lower case only, as get_field will convert line from
    ;;; file to lower case.

    get_field('content-type: ') -> content_type;
    ;;; Veddebug('Content type ' >< content_type);

    get_field('content-disposition: ') -> content_disposition;
    ;;; Veddebug('Disposition type ' >< content_disposition);

    get_field('content-description: ') -> content_description;
    ;;; Veddebug('Content-description: '><content_description);

    get_field('content-transfer-encoding: ') -> content_transfer_encoding;
    ;;; Veddebug('Coding type (1)' >< content_transfer_encoding);

enddefine;


/*
;;; tests

remove_quotes('cats.doc')=>
remove_quotes('"cats.doc"')=>
remove_quotes('"cat\'s.d``oc"')=>

*/

define lconstant remove_quotes(string) -> string;
    lvars loc;
    ;;; first get rid of bounding quotes.
    if strmember(`"`, string) ->> loc then
        ;;; remove first quote
        allbutfirst(loc, string) -> string;
        if strmember(`"`, string) ->> loc then
            ;;; remove last quote
            substring(1, loc-1, string)  -> string
        endif;
    endif;
    ;;; now get rid of included ` or '
    if strmember(`\``, string) or strmember(`'`, string) then
        lvars char, len = datalength(string);
        consstring(#|
                for loc from 1 to len do
                    subscrs(loc, string) -> char;
                    unless char == `\`` or char == `'` then char endunless;
                endfor
                |#) -> string
    endif   
enddefine;

define get_name(content_type, content_disposition) -> name;
    lconstant
        namestring1 = 'name=',
        len1 = datalength(namestring1),
        upnamestring1 = 'NAME=',
        namestring2 = 'filename=',
        len2 = datalength(namestring2);

    lvars loc, name = false;

    if content_type and
            ((issubstring(namestring1, content_type)->>loc)
            or issubstring(upnamestring1, content_type)->>loc)
        then
        ;;; get name
        allbutfirst(loc+len1-1, content_type) -> name;
            
    elseif content_disposition and issubstring(namestring2, content_disposition)->>loc then
        allbutfirst(loc+len2-1, content_disposition) -> name;
    endif;

    ;;; Veddebug('Name: ' >< name);

    if name then
        if strmember(`;`, name) ->> loc then
            substring(1, loc - 1, name) -> name;
            ;;; Veddebug('Name minus ";" ' >< name);
        endif;

        remove_quotes(name) -> name;
        ;;; Veddebug('Name minus quotes  ' >< name);
    
        ;;; replace spaces with hyphens
        lvars loc, foundspace = false;
        while (strmember(`\s`, name) ->> loc) do
            `-` -> fast_subscrs(loc, name);
            true -> foundspace;
        endwhile;
        if foundspace then
            vedputmessage('Replaced spaces with hyphens in file name');
            syssleep(100);
        endif;
    endif;
enddefine;

define ask_coding_type() -> coding_type;
    lvars coding_type = false;

    if getanswer('Is this literal (not encoded)? (y/n)') then
        unencodedtype -> coding_type;
    elseif getanswer('Is this base64 mime encoding? (y/n)') then
        'base64' -> coding_type;
    elseif getanswer('Is this uuencoded? (y/n)') then
        uutype -> coding_type;
    elseif getanswer('Is this binhex encoding? (y/n)') then
        binhextype -> coding_type;
    elseif getanswer('Treat it as unknown? (y/n)') then
        anytype -> coding_type;
    else
        vederror('Unknown coding type')
    endif;
enddefine;

define lconstant ask_file_type(filetype)->filetype;
    ;;; If type of decoded file not known, find out from user
    ;;;Veddebug([filetype is ^filetype]);
    if isstring(filetype) then
        ;;; filetype already known.
    elseif getanswer('Is it a DOC (Word) file? (y/n)') then
        doctype -> filetype
    elseif getanswer('Just save file? (y/n)') then
        ;;; treat as unknown.
        anytype -> filetype;
     elseif getanswer('Is it a SDW (StarOffice) file? (y/n)') then
        sdwtype -> filetype
    elseif getanswer('Is it a SXW (StarOffice) file? (y/n)') then
        sxwtype -> filetype
    elseif getanswer('Treat it as a plain text file? (y/n)') then
        texttype -> filetype
    elseif getanswer('Is it a postscript file? (y/n)') then
        pstype -> filetype
    elseif getanswer('Is it a PDF file? (y/n)') then
        pdftype -> filetype
    elseif getanswer('Is it an html file? (y/n)') then
        htmltype -> filetype
    elseif getanswer('Is it an Excel file? (y/n)') then
        xlstype -> filetype
    elseif getanswer('Is it a GZIPPED file? (y/n)') then
        gztype -> filetype
    elseif getanswer('Is it a Tarred Gzipped file? (y/n)') then
        tgztype -> filetype
    elseif getanswer('Is it a .ZIP file? (y/n)') then
        ziptype -> filetype
    elseif getanswer('Is it a .JAR file? (y/n)') then
        jartype -> filetype
    elseif getanswer('Is it a GIF file? (y/n)') then
        giftype -> filetype
    elseif getanswer('Is it a TIF file? (y/n)') then
        tiftype -> filetype
    elseif getanswer('Is it a PNG file? (y/n)') then
        pngtype -> filetype
    elseif getanswer('Is it a JPEG file? (y/n)') then
        jpegtype -> filetype
    elseif getanswer('Is it Powerpoint? (y/n)') then
        ppttype -> filetype
    elseif getanswer('Is this binhex encoding? (y/n)') then
        binhextype -> filetype
        ;;; not sure about next case? What is this?
    elseif getanswer('Is it a PCX file? (y/n)') then
        pcxtype -> filetype
    else
        ;;; more types to be added
        ;;;vederror('Unknown file type')
        ;;; treat as unknown.
        anytype -> filetype;
    endif;
enddefine;

define find_file_type(content_type, content_disposition, file_name) -> filetype;
    ;;; Veddebug('Finding File type ' >< file_name);
    if not(content_type) and not(content_disposition) then
        ;;; no information about type available
        false -> filetype;
    elseif Isendstring(bmptype, file_name)
        or Issubstring('image/bmp', content_type)
        then
        bmptype -> filetype;
    elseif (Issubstring('image/gif', content_type)
        or Isendstring(giftype, file_name)
        or Issubstring('.gif"', content_type)) then
        giftype -> filetype;
    elseif (Issubstring('image/tif', content_type)
        or Issubstring('image/tiff', content_type)
        or Isendstring(tiftype, file_name)
        or Issubstring('.tif"', content_type)) then
        tiftype -> filetype;
    elseif (Issubstring('image/png', content_type)
        or Isendstring(pngtype, file_name)
        or Issubstring('png"', content_type)) then
        pngtype -> filetype;
    elseif Isendstring(jpgtype, file_name) then
        jpgtype -> filetype
    elseif Issubstring('image/jpeg', content_type)
        or Isendstring(jpegtype, file_name)
    then
        jpegtype -> filetype;
    elseif Isendstring(mpgtype, file_name)
    then
        mpgtype -> filetype;
    elseif Isendstring(mp3type, file_name)
    then
        mp3type -> filetype;
    elseif Issubstring('mpeg', content_type)
        or Isendstring(mpegtype, file_name)
    then
        mpegtype -> filetype;

    elseif Isendstring(avitype, file_name) or Isendstring(lowertoupper(avitype), file_name)
    then
        avitype -> filetype;
    elseif Issubstring('pcx', content_type)
        or Isendstring(pcxtype, file_name)
    then
        pcxtype -> filetype;
    elseif Isendstring(pbmtype, file_name) then
        pbmtype -> filetype;
    elseif Issubstring('application/postscript', content_type)
        or Isendstring(pstype, file_name)
    then
        pstype -> filetype;
    elseif Isendstring(xlstype, file_name) then
        xlstype -> filetype;
    elseif Isendstring(xlsxtype, file_name) then
        xlsxtype -> filetype;
    elseif Isendstring(xlsmtype, file_name) then
        xlsmtype -> filetype;
    elseif Isendstring(sxwtype, file_name) then
        sxwtype -> filetype;
    elseif Isendstring(sdwtype, file_name) then
        sdwtype -> filetype;
    elseif Isendstring(odttype, file_name) then
        odttype -> filetype;
    elseif Isendstring(odstype, file_name) then
        odstype -> filetype;
    elseif Isendstring(odptype, file_name) then
        odptype -> filetype;
    elseif Issubstring('text/richtext', content_type)
        or Isendstring(rtftype, file_name)
    then
        rtftype -> filetype;
    elseif Isendstring(docxtype, file_name) then
        docxtype -> filetype;
    elseif Issubstring('application/msword', content_type)
        or Isendstring(doctype, file_name)
    then
        doctype -> filetype;
    elseif Issubstring('application/wordperfect', content_type)
        or Isendstring(wpdtype, file_name)
    then
        wpdtype -> filetype;
    elseif Issubstring('application/pdf', content_type)
        or Isendstring(pdftype, file_name)
    then
        pdftype -> filetype;
    elseif Issubstring('powerpoint', content_type)
        or Isendstring(ppttype, file_name)
    then
        ppttype -> filetype;
    elseif Isendstring(pptxtype, file_name)
    then
        pptxtype -> filetype;
    elseif Isendstring(dvitype, file_name) then
        dvitype -> filetype;
    elseif Issubstring('bibtex', content_type)
        or Isendstring(bibtype, file_name) then
        bibtype -> filetype;
    elseif Issubstring('text/html', content_type)
        or Isendstring(htmltype, file_name)
        or Isendstring(htmtype, file_name)
    then
        htmltype -> filetype;
    elseif Isendstring(gztype, file_name) then
        gztype -> filetype;
    elseif Isendstring(tartype, file_name) then
        tartype -> filetype;
    elseif Isendstring(bzip2type, file_name) then
        bzip2type -> filetype;
    elseif Isendstring(tgztype, file_name) then
        tgztype -> filetype;
    elseif Isendstring(ziptype, file_name) then
        ziptype -> filetype;
    elseif Isendstring(jartype, file_name) then
        jartype -> filetype;
    elseif Issubstring('text/plain', content_type)
        or Issubstring('message/rfc822', content_type)
        or Isendstring(texttype, file_name)
        or Isendstring(txttype, file_name)
    then
        if Isendstring(txttype, file_name) then
            txttype -> filetype;
        else
            texttype -> filetype;
        endif
    elseif Isendstring(exetype, file_name) then
        exetype -> filetype;
    elseif Isendstring(pltype, file_name) then
        pltype -> filetype;
    elseif Isendstring(ptype, file_name) then
        ptype -> filetype;      ;;; Pop-11, .p
    elseif Issubstring(bmptype, file_name) then
            bmptype -> filetype;
    elseif Issubstring(giftype, file_name) then
        giftype -> filetype;
    elseif Issubstring(tiftype, file_name) then
        tiftype -> filetype;
    elseif Issubstring(pngtype, file_name) then
        pngtype -> filetype;
    elseif Isendstring(jpgtype, file_name) then
        jpgtype -> filetype
    elseif Issubstring(jpegtype, file_name) then
            jpegtype -> filetype;
    elseif Issubstring(pbmtype, file_name) then
            pbmtype -> filetype;
    elseif Issubstring(sxwtype, file_name) then
            sxwtype -> filetype;
    elseif Issubstring(sdwtype, file_name) then
            sdwtype -> filetype;
    elseif Issubstring(odptype, file_name) then
            odptype -> filetype;
    elseif Issubstring(odstype, file_name) then
            odstype -> filetype;
    elseif Issubstring(odttype, file_name) then
            odttype -> filetype;
    elseif Issubstring(wpdtype, file_name) then
            wpdtype -> filetype;
    elseif Issubstring(pdftype, file_name) then
            pdftype -> filetype;
    elseif Issubstring(rtftype, file_name) then
            rtftype -> filetype;
    elseif Issubstring(htmltype, file_name)
        or Issubstring(htmtype, file_name) then
            htmltype -> filetype;
    elseif Issubstring(gztype, file_name) then
            gztype -> filetype;
    elseif Issubstring(tgztype, file_name) then
            tgztype -> filetype;
    elseif Issubstring(ziptype, file_name) then
            ziptype -> filetype;
    ;;; next one should be after zip and gz
    elseif Issubstring('latex', content_type)
        or Isendstring(latextype, file_name)
    then
        latextype -> filetype;
    elseif Issubstring(latextype, file_name) then
            latextype -> filetype;
    elseif Issubstring(jartype, file_name) then
            jartype -> filetype;
    else
        ask_file_type(filetype)->filetype;
    endif;
enddefine;

/*

find_application_type('foo')=>
find_application_type('application/foo')=>
find_application_type('application/msword;text')=>

*/

define lconstant find_application_type(content_type) -> application;
    ;;; Veddebug('Finding application type ' >< content_type);

    lconstant
            appstring = 'application/',
            applen = datalength(appstring);
    lvars
        endfield = false,
        loc = content_type and issubstring(appstring, content_type);

    if loc then
        locchar(`;`, loc + 1, content_type) -> endfield;
        unless endfield then
            datalength(content_type) + 1 -> endfield;
        endunless;

        substring(loc + applen, endfield - (loc + applen), content_type) -> application;
    else
        false -> application;
    endif;
enddefine;

define process_html(savedfile, lynx_path);
    ;;; Veddebug('SAVED: ' >< savedfile);
    lvars
        basename = sys_fname_path(savedfile)dir_><sys_fname_nam(savedfile),
        type = sys_fname_extn(savedfile);

    ;;; If lynx available, then get text version
    ;;; Veddebug(' checking for html');
    if isendstring(htmltype, savedfile)  and lynx_path then
        lvars   finalname = basename <> '.txt';
        sysobey('lynx -dump ' <> savedfile <> ' > ' <> finalname, `%`);
        show_info(finalname);
        finalname -> savedfile;
    else
        ;;;Veddebug('Show_info: ' >< savedfile);
        show_info(savedfile)
    endif;
    if member(type, text_types) then
        ;;; Veddebug(['About to edit' ^savedfile]);
        edit(savedfile);
    endif;
enddefine;

define process_qp(savedfile, quoted_printable, lynx_path) -> savedfile;
    ;;; handle a quoted printable file, which may be of type hmtl, ps, etc.
    ;;; remove -qp from file name.
    lvars
        nonqp = if quoted_printable and isendstring('-qp', savedfile)
            then allbutlast(3,savedfile) else savedfile endif;

    if quoted_printable then
        ;;;; Veddebug('qp_decoding savedfile =' <> savedfile);
        ;;; use mimencode -q to remove quoted printable

        lvars newnewname = nonqp;

        ;;; Veddebug([SAVED ^savedfile]);
        ;;; Veddebug([NEWNEWNAME ^newnewname]);
        ;;; Veddebug([running: ^mime_decode_quoted_printable_command]);
        decode_file_into(mime_decode_quoted_printable_command, savedfile, newnewname);
        ;;; qp encoded file is generally not worth saving
        ;;; Veddebug([DELETING QP file ^savedfile]);
        sysdelete(savedfile) ->;
        newnewname -> savedfile;
    endif;
    ;;;; Veddebug([show_info ^savedfile]);
    show_info(savedfile);
    ;;; Veddebug([process_html ^savedfile]);
    process_html(savedfile, lynx_path);
enddefine;

define ved_decode();

    dlocal
        ;;; needed to prevent "><" doing the wrong thing.
        pop_pr_quotes = false,
        ;;; this is changed in show_info
        files_saved = [],
        vedautowrite = false,
        vedautosaving = false,
        pop_file_mode =
            if decode_protect then
                8:600   ;;; readable only by user
            else
                8:644   ;;; readable by all
            endif,
        vedversions = false,
        pop_file_versions = 1;


    ;;; vedscreengraphoff();

    lvars
        deleteasked = false,
        path = vedpathname,
        mailfile = vedcurrentfile,
        ;;; directory in which to write temporary files
        savedir = sys_fname_path(path),
        lynx_path = sys_search_unix_path('lynx',systranslate('PATH')),
        DISPLAY = systranslate('DISPLAY'),
        ;
        
    if vedargument /= nullstring and Isstartstring(vedargument, 'doc') then
        ;;; invoked as "ENTER decode doc"
        ;;; decode doc file to right of cursor
        ;;; requires use of lhalw. Could use 'strings ^f | fmt -72'
        ;;; veddo(lhalw_command >< ' \'^f*\'');
        veddo(lhalw_command >< ' \'^f\'');
        return;
    endif;
    
    ;;; Veddebug('savedir '>< savedir);

    if member(savedir, ['/var/mail/' '/var/spool/mail/' '/usr/spool/mail/']) then
        ;;; if reading system mail file, store files in user's mail directory,
        ;;; or login directory
        if sysisdirectory('~/Mail') then '~/Mail'
        elseif sysisdirectory('~/mail') then '~/mail'
        else ved_decode_default_dir
        endif.sysfileok -> savedir
    endif;

    ;;; Veddebug('savedir '>< savedir);

    ;;; precaution, in case of disasters (and disc quota exceeded...)
    if vedwriteable and vedchanged then ved_w1() endif;

    lvars
        ;;; information from attachment header
        filetype = false,
        content_type = false,
        content_transfer_encoding = false,
        user_transfer_encoding = false,
        content_disposition = false,
        content_description = false,
        file_name,

        ;;; derived information about transfer encoding
        quoted_printable = false,
        mimencoded = false,
        binhexcoded = false,
        textcoded = false,
        uuencoded = false,
        rtfcoded = false,
        saved_file_type = nullstring,
        application_name = false,

        ;;; other derived information
        textfile = false,
        html_file = false,

        ;;; information about saved and/or decoded files
        uudecoded_file = false,
        savedfile = false,
        decodedfile = false,
        ;;; Path name for files with no clear name. Suffix added later
        savedpath = systmpfile(savedir, 'decoded', nullstring),
        ;

    ;;; Mark the whole field and get information about it.
    markmime_field();

    ;;; Get information about fields
    get_all_fields() ->
        (content_type, content_disposition, content_description, content_transfer_encoding);

    ;;; Work out name of file from name= or filename= sub-fields
    get_name(content_type, content_disposition) -> file_name;
    ;;; Veddebug([filename ^file_name]);
    unless file_name then
        ;;; anonymous, so create a name, depending on type
        lvars type =
            if issubstring('text/plain', content_type) then '.txt'
            elseif issubstring('text/html', content_type) then '.html'
            else '.txt'
            endif;
        systmpfile(nullstring, 'decoded', type) -> file_name;
    endunless;
    ;;; Veddebug([filename ^file_name]);


    if not(content_transfer_encoding) then
        ;;; see if user knows what's going on.
        ;;; Veddebug('No content_transfer_encoding');
        ask_coding_type() -> user_transfer_encoding;
        unless user_transfer_encoding == unencodedtype then
            user_transfer_encoding -> content_transfer_encoding
        endunless;
    endif;

    ;;; Veddebug('Content encoding:- ' >< content_transfer_encoding);

    if
        Isendstring(htmltype, file_name)
        or Isendstring(htmtype, file_name)
        or content_type
            and ( Issubstring('html', content_type)
                or Issubstring('htm', content_type) )
    then
        true -> html_file;
        ;;; replace .htm with .html
        if Isendstring(htmtype, file_name) then
            file_name >< 'l' -> file_name;
        endif;
    endif;


    ;;; Draw conclusions from content_transfer_encoding
    ;;; Veddebug('Coding type ' >< content_transfer_encoding);
    ;;; Veddebug('qp type ' >< quoted_printable);
    ;;; Veddebug('Content type ' >< content_type);
    ;;; Added 29 Jul 2013 to compensate for not translating whole line to lower case
    uppertolower(content_transfer_encoding) -> content_transfer_encoding;
    if content_transfer_encoding then
        if issubstring(qp_field, content_transfer_encoding) then
            true -> quoted_printable;
        elseif issubstring('base64', content_transfer_encoding)
        ;;;or issubstring('BASE64', content_transfer_encoding)
        then
            ;;; Veddebug('ENCODING: ' >< content_transfer_encoding);
            true -> mimencoded;
            mimetype -> saved_file_type;
        elseif isstartstring('7bit', content_transfer_encoding)
        or isstartstring('8bit', content_transfer_encoding) then
            true -> textfile;
            texttype -> saved_file_type;
        elseif issubstring('uu', content_transfer_encoding) then
            true -> uuencoded;
            uutype -> saved_file_type;
        elseif issubstring('binhex', content_transfer_encoding) then
            true -> binhexcoded;
            binhextype -> saved_file_type;
        elseif issubstring('rtf', content_transfer_encoding) then
            ;;; not sure this is possible
            true -> rtfcoded;
            rtftype -> saved_file_type;
        else
            'undefined' -> saved_file_type;
        endif;
    endif;
    ;;; Veddebug('qp type ' >< quoted_printable);
    ;;; Veddebug(['saved file type '  ^saved_file_type]);

    ;;; Find out type (suffix) of ultimate file to be saved
    ;;; e.g. after decoding
    ;;; If not worked out by VED, ask user.
    find_file_type(content_type, content_disposition, file_name) -> filetype;
    ;;; Veddebug('Filetype ' >< filetype);

    find_application_type(content_type) -> application_name;

    ;;; Veddebug('Application ' >< application_name);

    unless file_name then
        systmpfile(nullstring, 'decoded', filetype or anytype) -> file_name;
    endunless;

    ;;; Veddebug('File name ' >< file_name);

    ;;; Mark contents, ready to be written, and possibly deleted later
    markmime_contents();

    ;;; now should have filetype, content_transfer_encoding, content_type, file_name etc.
    ;;; Veddebug([saved_file_type ^saved_file_type]);

    lvars string = vedthisline();
    ;;; find out if it is uuencoded
    ;;; Veddebug(string);
    if Isstartstring('begin ', string) then
        uutype ->> content_transfer_encoding -> saved_file_type;
        vedwordright();vedwordright();
        ;;; read name of decoded file.
        vedexpandchars(`f`)() -> uudecoded_file;
    ;;;; elseif isstring(content_transfer_encoding) then
    elseif saved_file_type /= nullstring then
        ;;; already discovered
    elseif filetype then
        filetype -> saved_file_type
    elseif getanswer('Is it HTML? (y/n)') then
        htmltype -> saved_file_type;
    elseif getanswer('Is it a postscript file? (y/n)') then
        pstype -> saved_file_type;
    elseif getanswer('Is it a bibtex file? (y/n)') then
        bibtype -> saved_file_type;
    elseif getanswer('Is it a latex file? (y/n)') then
        latextype -> saved_file_type;
    elseif getanswer('Is it GZIPPED? (y/n)') then
        gztype -> saved_file_type;
    elseif getanswer('Is it Tarred and GZIPPED? (y/n)') then
        tgztype -> saved_file_type;
    elseif getanswer('Is it a ZIP file? (y/n)') then
        ziptype -> saved_file_type;
    elseif getanswer('Is it a JAR file? (y/n)') then
        jartype -> saved_file_type;
    elseif getanswer('Is it a JPEG file? (y/n)') then
        jpegtype -> saved_file_type;
    elseif getanswer('Is it Powerpoint? (y/n)') then
        ppttype -> saved_file_type;
    else
        ;;; use null string as type, by default
        vederror('Unknown coding type')
    endif;

    ;;; Veddebug('Revised saved file type ' >< saved_file_type);

    ;;; Work out name of file to write attachment into
    ;;; If necessary append suffix to name for writing.
    ;;; then and write the marked range

    if file_name then savedir dir_><  file_name -> savedfile
    elseif filetype then
        savedpath >< filetype -> savedfile;
    endif;

    ;;; Veddebug([filetype ^filetype saved ^saved_file_type]);

    if member(filetype, no_decode_types) and
        (saved_file_type = texttype or saved_file_type = txttype) then
        ;;; don't add file suffix

    elseunless Isendstring(saved_file_type, savedfile) then
        ;;; empty type works OK
        ;;; see if it is necessary to add a suffix.
        lvars suff = uppertolower(sys_fname_extn(savedfile));
    
        savedfile >< saved_file_type-> savedfile;
    endif;
    if quoted_printable then savedfile<>'-qp' -> savedfile endif;

    ;;; Veddebug('File about to be saved' >< savedfile);

/*
    ;;; XXXX add other saved file types here ???
    if mimencoded then savedfile >< mimetype -> savedfile
    elseif uuencoded then savedfile >< uutype -> savedfile
    elseunless Isendstring(filetype, savedfile) then
            savedfile >< filetype -> savedfile;
    endif;
*/

    ;;; Veddebug('writing to: ' >< savedfile);

    veddo('wr ' >< savedfile);
    vedputmessage(savedfile >< ' written.');

    ;;; Veddebug('written to: ' >< savedfile);

    ;;; pause half a second
    syssleep(50);

    ;;; Decide whether and how to decode it
    if mimencoded then
    
        if file_name then savedir dir_>< file_name
        else savedpath >< filetype
        endif -> decodedfile;

        ;;; Veddebug('DECODEDNAME: ' >< decodedfile);

        unless Isendstring(filetype, decodedfile) then
            decodedfile >< filetype -> decodedfile;
        endunless;

        ;;; Veddebug('Decoding Mimeencoded file to: ' >< decodedfile);
        if sys_file_exists(decodedfile) then
            vedputmessage('FILE: ' >< decodedfile >< ' already exists. Overwrite? (y/n)');
            lvars inchar = rawcharin();
            unless inchar = `y` or inchar == `Y` then
                vedputmessage('Aborting - rename file');
                exitfrom(ved_decode);
            endunless;
        endif;

        ;;; decode into new file, with correct suffix, and protect the file
        if member(filetype, text_types ) then
            ;;; remove crlf from text files sent by PC users
            decode_file_into(mime_decode_and_crlf_command, savedfile, decodedfile);
        else
            ;;; Veddebug('decoding non text_type: ' >< filetype);
            decode_file_into(mime_decode_command, savedfile, decodedfile);
        endif;

        ;;; Veddebug('Created Mimedecoded file to: ' >< decodedfile);
        ;;; protect the file if necessary
        sysobey(
            if decode_protect then 'chmod 640 ' else 'chmod 644 '
            endif >< decodedfile);

        ;;; work out length of file name excluding last 22 chars
        ;;; lvars len = max(0, datalength(savedfile) - 22);
        ;;; Ask if the original and mime file should be deleted, and show the results.
        ;;; if getanswer('Decoded! Delete mime file (...' <> allbutfirst(len, savedfile) <>') y/n?') then
        vedputmessage('Decoded! Deleting mime file');
        syssleep(50);
        sysdelete(savedfile) ->;
        false -> savedfile;
        ;;; else
        ;;; show_info(savedfile)
        ;;; endif;

        show_info(decodedfile);

        unless deleteasked then
            delete_coded(mailfile);
            true -> deleteasked;
        endunless;

        ;;;; Veddebug('Decoded: ' >< decodedfile);

        ;;; Attempt some processing, or advice for user
        if member(filetype, text_types) then
            ;;; Altered. AS 23 Nov 2006
            ;;; process_html(savedfile, lynx_path);
            process_html(decodedfile, lynx_path);
            if isendstring(htmltype, decodedfile) then
                if do_not_display_file then
                    ;;; don't try to display
                elseif DISPLAY and getanswer('Try netscape? (y/n)') then
                    veddo('bg netscape ' <> decodedfile);
                    vedputmessage('netscape launched. Please wait')
                elseif  getanswer('Try lynx? (y/n)') then
                    if vedusewindows == "x" then
                        sysobey('xterm -e lynx ' >< decodedfile >< ' &');
                    else
                        veddo('%lynx ' <> decodedfile);
                    endif;
                endif;
            endif;
            ;;; return();
        elseif filetype = doctype then
            lblock
            lvars oldfile = vedcurrentfile;
            ;;; try to decode doc file
            ;;; requires use of lhalw. Could use 'strings ^f | fmt -72'
            veddo(lhalw_command >< decodedfile);
            if vedcurrentfile == oldfile then
                vedputmessage('lhalw: Failed to extract text from Word file');
                syssleep(200);
            else
                ;;; decoding produced something
                ;;; Rename output
                veddo('name ' <> decodedfile >< texttype);
                ved_w1();
                show_info(vedpathname);
                vedtopfile();
                vedlinebelow();
                vedinsertstring('RESULT OF DECODING BY ANTIWORD: EDIT AS NEEDED');
                vedlinebelow();
            endif;
            endlblock;
;;;         elseif filetype = sdwtype or filetype = sxwtype then
;;;             ;;; try to decode StarOffice/OpenOffice file. Probably won't work
;;;             veddo(lhalw_command >< decodedfile);
;;;             ;;; Rename output
;;;             veddo('name ' <> decodedfile >< texttype);
;;;             ved_w1();
;;;             show_info(vedpathname);
;;;             vedtopfile();
;;;             vedlinebelow();
;;;             vedinsertstring('RESULT OF DECODING BY LHALW: EDIT AS NEEDED');
;;;             vedlinebelow();
        elseif member(filetype, text_types) then
            ;;; Veddebug(['Reading in ' ^decodedfile]);
            veddo('ved ' >< decodedfile);
        elseif filetype = pstype then
            vedputmessage('Try ghostview to view');
        elseif filetype = pdftype then
            vedputmessage('Try acroread to view');
        elseif filetype = xlstype or filetype = xlsmtype then
            vedputmessage('Try OpenOffice to view');
        elseif filetype = wpdtype then
            vedputmessage('Wordperfect file');
        elseif filetype = gztype then
            vedputmessage('Gzipped file');
        elseif filetype = bzip2type then
            vedputmessage('File compressed using bzip2');
        elseif filetype = tgztype then
            vedputmessage('Tarred and Gzipped file');
        endif;
    elseif member(content_transfer_encoding, no_decode_types)
    or content_transfer_encoding = qp_field
    then
        ;;; Veddebug('starting process_qp');
        process_qp(savedfile, quoted_printable, lynx_path) -> savedfile;
        ;;; Veddebug('Finished process_qp');
    elseif content_transfer_encoding = uutype then
        ;;; UUENCODED attachment (getting rarer)
        unless deleteasked then
            delete_coded(mailfile);
            true -> deleteasked;
        endunless;
        ;;; if getanswer('Write and fix ".uu" file? (y/n)') then
        ;;; Reading and writing with same file name, so must allow backup version
        2 -> pop_file_versions;
        veddo('fixuu '>< savedfile >< space >< savedfile);
        ;;; Now delete backup version
        sysdelete(savedfile >< '-') ->;
        veddo('dired -lt ' >< savedfile >< '*');
        ;;; if getanswer('Decode the file? (y/n)') then
        veddo('csh cd ' >< savedir >< ';uudecode ' <> savedfile);
        vedendfile();
        vedinsertstring(savedir dir_>< uudecoded_file ->> uudecoded_file);
        veddo('dired -l');
        if getanswer('Delete .uu file? (y/n)') then
            sysdelete(savedfile) ->;
        endif;
        ;;; should offer more intelligent processing options here. XXX
        if getanswer('Read into Ved? (y/n)') then
            edit(uudecoded_file);
        endif
    elseif content_transfer_encoding = binhextype then
        ;;; Veddebug('handling binhex');
        vedputmessage('handling binhex');
        unless deleteasked then
            delete_coded(mailfile);
            true -> deleteasked;
        endunless;


        veddo('dired -lt ' >< savedfile >< '*');
        if getanswer('Decode the file? (y/n)') then
            veddo('csh cd ' >< savedir >< ';xbin -v ' <> savedfile);
        endif;

    elseif member(filetype, text_types) then
        ;;; Veddebug('text_types ' <> savedfile);
        process_qp(savedfile, quoted_printable, lynx_path) -> savedfile;
        unless deleteasked then
            delete_coded(mailfile);
            true -> deleteasked;
        endunless;
        ;;; showfiles();
        ;;; return();
    else
        ;;; Veddebug([Uncategorised ^filetype]);
        vederror('Uncategorised type: ' >< filetype);
    endif;

    vedcheck();
    vedrefresh();

    unless deleteasked then
        delete_coded(mailfile);
    endunless;
    

    lvars
        DISPLAY = systranslate('DISPLAY'),
        displayfile = decodedfile or savedfile or uudecoded_file;


    ;;; Veddebug('trying to display ' >< displayfile);
    ;;; Veddebug('type ' >< filetype);
    if do_not_display_file or not(displayfile) or not(DISPLAY) then
        ;;; Do not offer to display
        ;;; Veddebug('displayfile false');
    else
        if DISPLAY and member(filetype, netscape_types)
        and getanswer('Try netscape? (y/n)') then
            veddo('bg netscape ' <> displayfile);
            vedputmessage('netscape launched. Please wait')
        elseif DISPLAY and member(filetype, soffice_types)
        and getanswer('Try StarOffice? OpenOffice (y/n)') then
            veddo('bg soffice ' <> displayfile);
            vedputmessage('Star/Open Office launched. Please wait')
        elseif DISPLAY and member(filetype, pdf_types)
        and getanswer('Try acroread? (y/n)') then
            veddo('bg acroread ' <> displayfile);
            vedputmessage('acroread launched. Please wait')
        elseif member(filetype, text_types) then
            veddo('ved ' >< displayfile);
        else
            vedputmessage('Don\'t know how to display')
        endif
    endif;

    showfiles();
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 14 2013
        Added pptxtype and test for pptxtype.
--- Aaron Sloman, Jul 29 2013
        Added test for whether file already exists. If so ask whether to overwrite.
        If answer is no, abort.
--- Aaron Sloman, Jul 29 2013
        Previously (in June) removed code for translating names to lower case.
        This prevented some file types being recognised, especially mime-encoded.
        Fixed now by translating content_transfer_encoding to lower case.
--- Aaron Sloman, Jun 14 2010
        Instead of replacing spaces in file names with dots, use hyphens.
--- Aaron Sloman, Oct  3 2009
        Added .xlsm files
--- Aaron Sloman, Sep 29 2009
        Allowed docx files.
--- Aaron Sloman, Nov 13 2008
        allowed mp3 as a category type. Changed file path name.
--- Aaron Sloman, Feb 12 2007
    Moved latex type to later, in case it clashes with something
    like Zip type.
--- Aaron Sloman, Nov 23 2006
    Altered find_file_type to keep '.txt' for files that already    
    have that.

    Replaced
            process_html(savedfile, lynx_path);
    with
            process_html(decodedfile, lynx_path);

    Commented out more calls of Veddebug

--- Aaron Sloman, 6 Nov 2006
    Stopped it reading in image files encoded as QP e.g. tiff

--- Aaron Sloman, 1 Oct 2006
    Modified to allow things like
        X-Attachment-Id: f_esryfy1c
--- Aaron Sloman, May 29 2006
        Added odttype, odptype, odstype, and removed some junk relating to
        StarOffice types.
--- Aaron Sloman, May 29 2006
        Removed pcvtypes
--- Aaron Sloman, Jul 11 2005
        Added jar type.
--- Aaron Sloman, Jun  9 2004
        Changed to cope with null name in text/plain text/html case
--- Aaron Sloman, Feb 23 2004
        Modfied to deal with upper case 'CONTENT-....' fields!
--- Aaron Sloman, Nov 22 2003
        Added '.jpeg' as an alternative to '.jpg'
        Separated jpgtype and jpegtype
        Made Isendstring(string, item) check separately for uppercase version
--- Aaron Sloman, Nov 12 2003
        added avitype
--- Aaron Sloman, Feb 23 2003
    Altered remove_quotes to remove ' or ` from file name.
--- Aaron Sloman, Feb 17 2003
    Improved handling of pcxtype
    Fixed handling of attachments without terminator line.
    Added additional test for do_not_display_file
--- Aaron Sloman, Jan 29 2003
    No longer offers display options. Controlled by
            do_not_display_file
    set true near beginning.
--- Aaron Sloman, Jan 13 2003
        Changed message to refer to antiword instead of lhalw
--- Aaron Sloman, Dec 16 2002
        Added tif to types
--- Aaron Sloman, Dec 13 2002
        Altered to use antiword
--- Aaron Sloman, Nov 15 2002
        Added png to types
--- Aaron Sloman, Aug  6 2002
        Changed to handle email messages with no terminator line.
        [had a bug fixed 17 Feb 2003]
        No longer adds .qp after removing qp encoding
        Various other minor improvements.
--- Aaron Sloman, May 17 2002
    Made it not treat rtf as a doc type file.
--- Aaron Sloman, Apr  4 2002
    Made it stop asking before deleting mime file.
    Also check if lhalw has produced a result before messing with current file.
--- Aaron Sloman, Feb 19 2002
    fixed test for linux mail directory. (missing '/').
--- Aaron Sloman, Feb  4 2002
    added bmptype
--- Aaron Sloman, May 13 2001
    Previously forgot to comment out one call of Veddebug. Now done
--- Aaron Sloman, May  7 2001
    Stoppped it adding '.text' for no_decode_types of files.
--- Aaron Sloman, May  5 2001
    added tartype, bzip2type, mpegtype, mpgtype
--- Aaron Sloman, Feb 11 2001
    Further rationalisation and clarification.
--- Aaron Sloman, Feb  5 2001
    Completely revamped to handle quoted printable using mimencode -q
    and html using lynx -dump
--- Aaron Sloman, Jan  8 2001
    Made it replace spaces in file names with dots.
--- Aaron Sloman, Aug 13 2000
    Added tgztype
--- Aaron Sloman, Jun  6 2000
    Allow crlf decoding in mime-decode only for text file types
--- Aaron Sloman, Apr  7 2000
    Improved handling of powerpoint, without asking.
--- Aaron Sloman, Apr  7 2000
    added no_decode_types
--- Aaron Sloman, Mar 21 2000
    Improved handling of uuencoded file. No longer asks - just does it, and
    offers to delete the file after decoding.
--- Aaron Sloman, Mar 15 2000
    Introduced decode_protect
    Made it detect more types from file names.
--- Aaron Sloman, Mar 14 2000
    Introduced pltype, ptype, text_types
--- Aaron Sloman, Mar 10 2000
    added exetype for .exe files
    added txttype for .txt files
    Improved markmime_contents();
    Improved recognition capabilites, e.g. for pstype and others
--- Aaron Sloman, Feb  7 2000
    Added find_file_type, added .zip as new file type.
--- Aaron Sloman, Dec 15 1999
    Since file names are now worked out, remove code that inserts
    'temp.' before them.
--- Aaron Sloman, Dec  4 1999
    Made it work out the file name from the text if possible.
--- Aaron Sloman, Oct 22 1999
    Added tests for .xls
--- Aaron Sloman, Jul 22 1999
    Inserted test for $DISPLAY
--- Aaron Sloman, Jun  7 1999
    added -p flag for decoding.
--- Aaron Sloman, Jan 14 1999
    Included use of content-disposition line
    Changed to launch PCV or star office or netscape
--- Aaron Sloman, Jan  6 1999
    Added help file and comments
--- Aaron Sloman, Jan  1 1999
    Substantially improved: extended and made  more automatic


         CONTENTS - (Use <ENTER> gg to access required sections)

 define decode_file_into(command, infile, outfile);
 define lconstant markmime_field();
 define lconstant markmime_contents();
 define lconstant getanswer(string) -> boole;
 define show_info(file);
 define lconstant showfiles();
 define lconstant delete_coded(file);
 define Isstartstring(string, item);
 define Isendstring(string, item);
 define Issubstring(string, item);
 define get_field(field_string) -> found;
 define get_all_fields() ->
 define lconstant remove_quotes(string) -> string;
 define get_name(content_type, content_disposition) -> name;
 define ask_coding_type() -> coding_type;
 define lconstant ask_file_type(filetype)->filetype;
 define find_file_type(content_type, content_disposition, file_name) -> filetype;
 define lconstant find_application_type(content_type) -> application;
 define process_html(savedfile, lynx_path);
 define process_qp(savedfile, quoted_printable, lynx_path) -> savedfile;
 define ved_decode();

 */