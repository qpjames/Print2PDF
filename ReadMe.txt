ReadMe for Print2PDF.prg
Last Updated July, 2009 by Paul James of Life-Cycle Technologies, Inc.

**-> If you encounter problems, read the comments at the top of Print2Pdf.PRG <-**

The actual program code is very heavily documented, please look there for details.

****** IMPORTANT NOTE starting with Version 1.75:
* To support Windows Vista, I have added the (default) ability to use the freeware BullZip Printer Driver (www.bullzip.com)
* to control the entire process, instead of manually controlling the PS Driver and Ghostscript.
*     BullZip still uses Ghostscript internally (but only works with newer versions).
*     BullZip uses a free version of bioPDF (www.biopdf.com)
* The Bullzip installation is very simple and includes optionally/automatically installing a version of Ghostscript (lite).
* Just download Bullzip, perform a default installation, allow it to automatically download/install Ghostscript, and you are ready to use this code!
*
* To control the BullZip functionality, the following Properties were added to this class:
*    lUseBullzip     = .t.                       && MAIN Toggle that controls whether to use the Bullzip API to create the PDF instead of the Postscript Driver?
*    cbzShowSettings = "never"           && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowSaveAS   = "never"          && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowProgress = "no"              && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowProgressFinished = "no"  && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowPDF      = "no"                && Bullzip Setting - see BullzipToPDF method below.
*    cbzConfirmOverwrite = "no"           && Bullzip Setting - see BullzipToPDF method below.

To try out the functionality:
 1. Download Bullzip
 2. Perform a default installation
 3. Allow it to automatically download/install Ghostscript
 4. Run P2Demo.prg from within VFP.

This code was tested under VFP 6, 7, 8, and 9.

*If you DO NOT use the Bullzip option...
If you do not have a Generic Postscript printer driver installed, the demo
will automatically install it for you.  Also, if you do not have Ghostscript
installed, the demo will automatically install it also.

Once you have run the Demo, you can delete the files p2demo*.* and books.*

I hope this code is beneficial to you as it is a small contribution 
by me to the development community that has given me so much.

Thank You!
Paul James
Life-Cycle Technologies, Inc.

paulj@lifecyc.com

