    /*
        cat2html.l: cat to HTML converter specification
        (c) 1993 by Harald Schlangmann
        Permission is granted to use this code. Send additions
        and bug reports to my address below.
        
        v1.0    Harald Schlangmann, July 20 1993
            schlangm@informatik.uni-muenchen.de
        v1.1    Bold style x^H{x^H}* implemented.

        v2.0   Carl Lindberg lindberg@mac.com
              Added blank line suppressing.
        v2.1  New cat2html to spit out HTML with links -CEL
        
     */

    #include <string.h>
    
    #define BOLDFLAG    1
    #define ULINEFLAG    2

    int flags = 0, neededflags = 0;
    
    #define SETB    neededflags |= BOLDFLAG
    #define UNSETB  neededflags &= ~BOLDFLAG
    #define SETU    neededflags |= ULINEFLAG
    #define UNSETU  neededflags &= ~ULINEFLAG
    
    /*
     *    Default settings, may be changed using options...
     */
    
    static char *startBold = "<b>";
    static char *stopBold = "</b>";
    static char *startULine = "<u>";
    static char *stopULine = "</u>";
    static char *startHeader = "<font face=\"Helvetica\">";
    static char *stopHeader = "</font>";
    static int addLinks = 0;
    static int markHeaders = 0;
    static int lineCount = 0;
    static int maxLineCount = 3;


    /* Decode a UTF8 sequence to return the unicode number */
    static unsigned decodeUTF8(unsigned char *buf, yy_size_t len)
    {
        int n = buf[0] & (0x7f >> len);
        yy_size_t i;

        for (i=1; i<len; i++)
            n = (n << 6) | (buf[i] & 0x3f);

        return (unsigned)n;
    }

    static void emitPreamble(void)
    {
        /* Explicitly set Courier font so that bold/italic attributes are
           preserved during the HTML parsing and so can be displayed if the user
           is using a font that can do those styles. If left alone here,
           NSAttributedString will use Monaco, and the bold/italic information
           is lost forever. */
        fputs("<html><head></head><body><pre><font face=\"Courier\">",stdout);
    }
    
    static void emitPostamble(void)
    {
        fputs("</font></pre>\n</body></html>",stdout);
    }

    #define adjust() if( neededflags!=flags ) _adjust()
    
    static void _adjust(void) {
    
        if( (flags^neededflags)&ULINEFLAG )
            fputs(neededflags&ULINEFLAG?
                startULine:stopULine,stdout);
        if( (flags^neededflags)&BOLDFLAG )
            fputs(neededflags&BOLDFLAG?
                startBold:stopBold,stdout);
        flags = neededflags;
    }
    
    static void emitChar(int ch) {        
        adjust();

        if (ch=='\n') {
            if (lineCount > maxLineCount) return;
            lineCount++;
        }
        else lineCount = 0;

        switch(ch) {
            case '"': fputs("&quot;",stdout); break;
            case '<': fputs("&lt;"  ,stdout); break;
            case '>': fputs("&gt;"  ,stdout); break;
            case '&': fputs("&amp;" ,stdout); break;
            default:  fputc(ch,stdout);
        }
    }

    static void emitString(char *string)
    {
        size_t i, len=strlen(string);
        for (i=0;i<len;i++)
            emitChar(string[i]);
    }

    static void emitRaw(char *string)
    {
        adjust();
        lineCount = 0;
        fputs(string,stdout);
    }

    static void emitBackspacedLetters(char *charblock, yy_size_t lengthLeft, int doBold)
    {
        /* If there is a trailing backspace, then both letters are deleted, so print nothing */
        if (lengthLeft >= 4 && charblock[3] == '\010')
            return;

        /* If the characters are equal, they are printed on top of each other, so make it bold */
        if( charblock[0] == charblock[2] ) {
            if (doBold) SETB;
            emitChar(charblock[0]);
            if (doBold) UNSETB;
        }
        /* Otherwise, just emit the second character. */
        else {
    #ifdef DEBUGBACKSPACE
            fprintf(stderr, "Unknown backspace pair %c and %c\n", charblock[0], charblock[2]);
    #endif
            emitChar(charblock[2]);
        }
    }

    static void emitBackspacedText(char *text, yy_size_t length)
    {
        yy_size_t i=0;
        while (i < length) {
            if ((i < (length-1)) && text[i+1] == '\010') {
                emitBackspacedLetters(&text[i], 3, 0);
                i+=3;
            }
            else {
                emitChar(text[i]);
                i++;
            }
        }
    }

    /* Use hexidecimal entities */
    static void emitUnicode(unsigned charNum)
    {
        char entityBuf[20];
        sprintf(entityBuf, "&#x%x;", charNum);
        emitRaw(entityBuf);
    }


ALLBUTUL     [^\n_\010]
NEEDQUOTE    [<>&"]
VERBATIM     [^_\n\010\x1B<>&( \t"\xC2-\xF4]
UPPER        [A-Z]
UPPERCONT    [A-Z0-9 \t()]
UPPERBS      {UPPER}\010{UPPER}
UPPERBSCONT  ({UPPERBS}|[ \t()])
UTF8START    [\xC2-\xF4]
UTF8CONT     [\x80-\xBF]
UTF8SEQ      {UTF8START}({UTF8CONT}{1,3})
SGRSTART     \x1B\[

%option debug
%option noyywrap
%option noinput
%option 8bit
%option prefix="cat2html"

%x FIRSTLINE

%%

    /*
     *    Start state FIRSTLINE is used to treat the first non-empty
     *    line special. (First line contains header).
     */

    /* Some X.org X11 pages have a weird #pragma at the start; strip it out. */
<FIRSTLINE>"#pragma".*\n {}

<FIRSTLINE>.    {    SETB; emitChar(yytext[0]); }

<FIRSTLINE>.\n  {
                SETB;
                emitChar(yytext[0]);
                UNSETB;
                emitChar('\n');
                BEGIN(INITIAL);
            }

<FIRSTLINE>\n   {    UNSETB; emitChar('\n');  }

    /* Part of the X11 thing gets put on a separate line by nroff, sigh. */
^"vate/var/tmp/X11".*\n  {}

    /*
     *    Put a special HREF around likely looking links to other man pages
     */
[_a-zA-Z][-a-zA-Z0-9._]*(-[ \t\n]+[-a-zA-Z0-9._]+)?[ \t\n]*"("[1-9n][a-zA-Z]?")"  {

            if (!addLinks)
            {
                 emitString(yytext);
            }
            else
            {
                int i;
                char href[yyleng+1];

                /* Change newlines to spaces in the href portion */
                strcpy(href, yytext);
                for(i=0; i<yyleng; i++)
                    if (href[i] == '\n') href[i] = ' ';
 
                emitRaw("<a href=\"manpage:");
                emitRaw(href);
                emitRaw("\">");
                emitString(yytext);
                emitRaw("</a>");
            }
       }


    /*
     *    Non-empty, all-uppercase lines are treated as headers
     */
^{UPPER}{UPPERCONT}*$  {
                SETB;
                if (markHeaders) emitRaw(startHeader);
                emitString(yytext);
                if (markHeaders) emitRaw(stopHeader);
                UNSETB;
                emitChar('\n');
            }

    /* Similar for all-uppercase lines that use backspace for bolding */
^{UPPERBS}{UPPERBSCONT}*$ {
                SETB;
                if (markHeaders) emitRaw(startHeader);
                emitBackspacedText(yytext, yyleng);
                if (markHeaders) emitRaw(stopHeader);
                UNSETB;
                emitChar('\n');
            }

    /*
     *    nroff +-
     */

"+"\010_        emitRaw("&plusmn;");

    /*
     *    underline (part 1)
     */

{ALLBUTUL}\010_        {
                SETU;
                emitChar(yytext[0]);
                UNSETU;
            }

    /*
     *    nroff bullets
     */
o\010"+"               emitRaw("&middot;");   // "&bull;" does not work
"+"\010o               emitRaw("&middot;");
o\010o\010"+"\010"+"   emitRaw("&middot;");
"+"\010"+\010"o\010o   emitRaw("&middot;");

    /*
     *    underline (part 2)
     */

_\010{ALLBUTUL}        {
                SETU;
                emitChar(yytext[2]);
                UNSETU;
            }

    /*
     *    handle further BS combinations
     */

.\010.\010?            {
                emitBackspacedLetters(yytext, yyleng, 1);
            }

  /* Same idea but with UTF-8 characters */
{UTF8SEQ}\010{UTF8SEQ}\010? {
        if (yytext[yyleng-1] != '\010') {
            char *backspace = index(yytext, '\010');
            if (backspace != NULL) {
                emitUnicode(decodeUTF8((unsigned char *)backspace+1, (yyleng - (backspace-yytext) - 1)));
            }
        }
    }

  /* If we find a UTF8 sequence, decode it */
{UTF8SEQ} {
    emitUnicode(decodeUTF8((unsigned char *)yytext, yyleng));
}

  /* Some versions of nroff/grotty use SGR escape sequences instead of the backspace hacks */
{SGRSTART}0?m          UNSETU;UNSETB;
{SGRSTART}1m           SETB;
{SGRSTART}[347]m       SETU;
{SGRSTART}(21|22)m     UNSETB;
{SGRSTART}(23|24|27)m  UNSETU;
{SGRSTART}[0-9;]+m     {/*ignore any other codes*/}

    /*
        group characters in VERBATIM to make this
        filter faster...
     */
[ \t\n]+             emitString(yytext);
{VERBATIM}+/[^\010]     emitString(yytext);

    /*
        remaining specials
     */

   /* \n            emitChar('\n'); */ /*Matched by above whitespace matching rule */
.            emitChar(yytext[0]);

%%

static void usage() {

    fprintf(stderr,"Usage: cat2html [-il] [<filename>]\n"
        "\tTranslate output of (g)nroff to HTML. If no\n"
        "\t<filename> is given, cat2html reads stdin.\n"
        "\toption -i uses italic characters for underlining.\n"
        "\toption -l adds 'manpage:' HREF links to other man pages.\n"
        "\tHTML output is sent to stdout.\n");
    exit(1); 
}

int main(int argc, char *argv[])
{
    int c;

    yy_flex_debug = 0;

    /* Keep the same args as cat2rtf, even though -s does not really make much difference */
    while ((c = getopt(argc, argv, "dgGiISs:lH")) != EOF)
    {
        switch( c ) {
            case 'd':
                yy_flex_debug = 1;
                break;
            case 'g':
            case 'G':
                startBold = ""; // "<font color=\"#333333\">";
                stopBold =  ""; // "</font>";
                break;
            case 'i':
            case 'I':
                startULine = "<i>";
                stopULine = "</i>";
                break;
            case 's':
                maxLineCount = atoi(optarg);
                break;
            case 'S':
                maxLineCount = -1;
                break;
            case 'l':
                addLinks = 1;
                break;
            case 'H':
                markHeaders = 1;
                break;
            case '?':
            default:
                usage();
        }
    }
    
    if( optind < argc )
        yyin = fopen(argv[optind], "r");
    else
        yyin = stdin;
    
    emitPreamble();
    BEGIN(FIRSTLINE);
    yylex();
    emitPostamble();
    
    /* Shuts up a compiler warning */
    if (0) unput('h');

    return 0;
}
