parameters pcFileName, pcReport

**********************************************************************************************************
* Print2PDF.PRG  Version 1.75  (July 20, 2009)
*
* Parms: 	pcReport 				= Name of VFP report to run
*			pcOutputFile 			= Name of finished PDF file to create.
*
* Author:	Paul James (Life-Cycle Technologies, Inc.) mailto:paulj@lifecyc.com
*
* This file is free for anyone to use and distribute.  
* You cannot sell it or transfer the rights to it, blah, blah, blah.
* If you plan any commercial distribution, you are responsible for securing any needed licenses.
*
*
****** IMPORTANT NOTE starting with Version 1.75:
* To support Windows Vista, I have added the (default) ability to use the freeware BullZip Printer Driver (www.bullzip.com) 
* to control the entire process, instead of manually controlling the PS Driver and Ghostscript.
*     BullZip still uses Ghostscript internally (but only works with newer versions).
*     BullZip uses a free version of bioPDF (www.biopdf.com)
* The Bullzip installation is very simple and includes optionally/automatically installing a version of Ghostscript (lite).
* Just download Bullzip, perform a default installation, allow it to automatically download/install Ghostscript, and you are ready to use this code!
*
* To control the BullZip functionality, the following Properties were added to this class:
*    lUseBullzip     = .t.           && MAIN Toggle that controls whether to use the Bullzip API to create the PDF instead of the Postscript Driver?
*    cbzShowSettings = "never"       && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowSaveAS   = "never"       && Bullzip Setting - see BullzipToPDF method below. 
*    cbzShowProgress = "no"          && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowProgressFinished = "no"  && Bullzip Setting - see BullzipToPDF method below.
*    cbzShowPDF      = "no"          && Bullzip Setting - see BullzipToPDF method below.
*    cbzConfirmOverwrite = "no"      && Bullzip Setting - see BullzipToPDF method below.
*   
*    
****** PURPOSE:
* This program will run a VFP report and output it to a postscript file (temporary filename, temp folder).
* This part of the code uses the Adobe postscript printer driver.
* (It will automatically select the appropriate Postscript printer driver.)
* It will then turn that postscript file into a PDF file (named whatever you want in whatever folder you want).
* This part of the code calls Ghostscript to turn the postscript file into a PDF.
*
****** REQUIREMENTS/SETUP:
*	The "Zip" file this file was included in, contains everything you need to start creating PDF's.
*	Just run the "Demo" program (P2Demo.prg) and it will automatically walk you through installing
*	Ghostscript and the Adobe Postscript driver.  It will then "print" a demo VFP report to a PDF!
*
****** COLOR PRINTING:
*	If you want to have "color" in your PDF's, you will need an additional file.
*	 The "Zip" file includes this file.  It is a "Generic Color PostScript" PPD from Adobe.

*	When you are installing the Adobe PostScript driver:
*		In the install dialogue, choose Local Printer.
*		Choose an output port of FILE.
*		When prompted to "Select Printer Model", click the "Browse" button, 
*		locate the file (included with this program) named DEFPSCOL.PPD,
*		Choose the "Generic Color Printer" from the printer list.
*
*	The following web page has excellent additional documentation: 
*		http://www.ep.ph.bham.ac.uk/general/printing/winsetup.html
*
****** NOTES:
*	If an Error ocurrs, a .False. return code will be returned, but you should check the .lError property.
*	If .lError is .True., then the .cError property will have text explaining the error.
*
*	Because this is a class, you can either call the Main() method to execute all logic,
*	or you can set the properties yourself and call individual methods as needed (sweet).
*
****** DEBUGGING/PROBLEMS:
*   If you save your printer settings/printer environment in your report, 
*   then try to use this code to produce a PDF, it will probably fail.
*   You will get an empty PDF, a PDF with zero pages, or no PDF at all.  This is because
*   this code specifically prints your report to a postscript printer, but if you have printer
*   settings stored in your report, it screws up the postscript file so it becomes unreadable by Ghostscript.
*
*   If you are having problems during the conversion from Postscript (PS) to PDF,
*   you can set the property "lErasePSFile = .F." which will cause this class to leave the
*   raw Postscript file intact.  The postscript file will have the same name as the requested name
*   for the PDF file, but will have the extension ".ps".  The location of the postscript file
*   is determined by the "print2pdf.ini" file.  the "cTempPath" setting determines the folder name
*   and "cPSFile" property determines the name of the actual file (unless you pass in the name
*   of the requested PDF, in which case the postscript will have the same name as the PDF).
*
*   Once you have the raw postscript (.ps) file, you can run GSView.exe (which is described above).
*   GSView gives you the ability to view/convert your .ps file without the need to know complex 
*   Ghostscript commands.  It will help you find out if there are errors in the actual postscript 
*   file that is being produced by your printer driver.
*
*   For additional debugging, you can manually run Ghostscript, turn the file
*   into a PDF, and see any messages that occur.  For information on running Ghostscript manually,
*   please see the Ghostscript documentation.
*
****** EXAMPLE CALLS:
*	1.	*A one line call (nice and neat)
*		loPDF = createobject("Print2PDF", lcMyPDFName, lcMyVFPReport, .t.)
*
*	2.	*This is probably the most typical example.*
*		set procedure to Print2PDF.prg additive
*		loPDF = createobject("Print2PDF")
*		if isnull(loPDF)
*			=messagebox("Could not setup PDF class!",48,"Error")
*			return .f.
*		endif
*
*		loPDF.cReport		= "C:\Myapp\Reports\MyVFPReport.frx"
*		loPDF.cOutputFile 	= "C:\Output\myfile.pdf"
*		llResult 			= loPDF.Main()
*
*		if !llResult or loPDF.lError
*			=messagebox("This error ocurred creating the PDF:"+chr(13)+;
*						alltrim(loPDF.cError),48,"Error Message")
*		endif
*
*	3.	*This example shows manually setting some properties.
*		loPDF = createobject("Print2PDF")
*		loPDF.cINIFile 		= "C:\Myapp\Print2PDF.ini"
*		loPDF.cReport 		= "C:\MyApp\Reports\MyVfpReport.frx"
*		loPDF.cOutputFile 	= "C:\Output\myfile.pdf"
*		loPDF.cPSPrinter 	= "My PS Printer Name"
*		llResult 			= loPDF.Main()
*
*	4.	*This example assumes you have created the (.ps) Postscript file yourself and just want to create the PDF.
*		loPDF = createobject("Print2PDF")
*		loPDF.ReadIni()
*		loPDF.cOutputFile = "C:\Output\myfile.pdf"
*		loPDF.cPSFile = "C:\temp\myfile.ps"
*		llResult = loPDF.MakePDF()
*
*	5.	*This example is for those times when you want to produce multiple PDFs without resetting this class each time.
*		loPDF = createobject("Print2PDF")
*		loPDF.ReadIni()										&&Read the .ini settings
*		loPDF.SetPrinter()									&&Set printer to Postscript driver
*		loPDF.GSFind()										&&Locate/Install Ghostscript
*		loPDF.cReport = "C:\Myapp\Reports\MyVFPReport.frx"	&&Specify VFP Report form.
*		loPDF.cExtraRptClauses = "NEXT 1"					&&Specify scope for VFP report form.
*		Do while !eof('MyTable')
*			loPDF.cOutputFile = "C:\Output\" + alltrim(MyTable.Company) + ".pdf"	&&Specify PDF output file name.
*			loPDF.MakePS()															&&Print To Postscript file
*			loPDF.MakePDF()															&&Turn Postscript into PDF
*			skip in MyTable
*		EndDo
*		loPDF.Cleanup()			&&Put things back the way they were
*		loPDF = .NULL.
*		release loPDF
*
****** COOL HELPER APPS AND UTILITIES:
*
*	GSView by Ghostgum
*	------------------
*	This cool utility is Windows-based and will allow you to view the intermediate Postscript (.ps) file
*	and turn it into a PDF where it will report any conversion problems.  It is also a cool PDF viewer.
*
*	GSView is a graphical interface for Ghostscript, an interpreter for the PostScript language and PDF. 
*	GSview allows selected pages to be viewed, printed, or converted to bitmap, PostScript or PDF formats. 
*	http://www.ghostgum.com.au/
*
*
*	RedMon by Ghostgum
*	------------------
*	This cool utility will allow you to emulate the Adobe ACROBAT functionality. It allows a user to
*	create a PDF from ANY application simply by "printing" to this special "printer".
*	It will set up a Windows "Printer" that is not a real printer.
*	It simply emulates a printer that redirects the print stream to Ghostscript.
*
*	Since you have the ability to automate many applications, you could force them to print to the RedMon
*	printer, and create PDFs of things like Spreadsheets, E-Mail messages, Documents, etc.
*
*	The RedMon port monitor redirects a special printer port to standard input of a program. 
*	RedMon is commonly used with Ghostscript and a non-PostScript printer to emulate a PostScript printer.
*	http://www.cs.wisc.edu/~ghost/redmon/
*
*	
*	Ghostscript
*	-----------
*	I am including a reference back to Ghostscript itself here because while we may be using it
*	to create PDF documents, it has the ability to create many output formats.  Here are a few:
*	Images... PNG, JPEG, TIFF, BMP, PSX, PSD
*	Fax... Raw fax, TIFF
*	Print Streams... PS, EPS, PDF
*	...and many more
*
*	You could use Ghostscript to...
*	- Print directly to a Fax file which you could then feed directly to any fax program.  
*	- Print to a JPEG file and post it to a website.
*	- Print to a BMP file and set it as the Windows desktop.
*	- Print to a PS/EPS file, and send that file to someone who could send that file directly to
*	  their printer allowing them to locally print your native report without having your application.
*	  This is especially handy for output that PDF does not handle well.
*
****** OTHER LINKS:
*	If you want to make sure you have a recent copy of the Adobe Generic Postscript printer driver:
*		http://www.adobe.com/support/downloads/detail.jsp?ftpID=1500
*		This link changes periodically, so you might also just try:
*		http://www.adobe.com/support/downloads/product.jsp?product=44&platform=Windows
*
*	Main Ghostscript Web Site:	http://www.ghostscript.com/doc/AFPL/index.htm
*	Licensing Page: http://www.ghostscript.com/doc/cvs/New-user.htm#Find_Ghostscript
*
****** GHOSTSCRIPT:
*	Ghostscript does NOT register it's DLL file with Windows, so this code has a function called GSFind()
*	that will try to find the Ghostscript DLL.  Here is what it does:
*	1. See if it is in the VFP Path.
*	2. Grab the location out of the Print2PDF.INI file (if it exists)
*	3. Look in the default installation folder of C:\GS\
*	If the program uses option #3 (my preference) then it will automatically detect the
*	subfolder used to contain the DLL.  Since I am running version 8.11, my
*	folder is "C:\gs\gs8.11\bin\".  The program looks for "C:\GS\GSxxxxx\bin\"
*
*   7/29/2008 - Added the ability to search for Ghostscript in C:\Program Files\GS\ and/or D:\Program Files\GS\
*
*	GhostScript's job (in this class) is to take a "postscript file" (.ps) and turn
*	it into a PDF file (compatible with Adobe 3.x and above).  A "postscript file"
*	is basically a file that contains all of the "printer commands" necessary to
*	print the document, including fonts, pictures, etc.  You could go to a DOS prompt
*	and "copy" a postscript file to your printer port, and it should print the document
*	(providing your printer was Postscript Level 2 capable).  Ghostscript has many other
*	abilities, including converting a PDF back into a postscript file.
*
*	Ghostscript ONLY "prints" what is in the postscript file.  What gets into the
*	postscript file is determined by the "Postscript Printer Driver" that you are
*	using.  If you want COLOR for example, you must use a driver that supports color.
*	Also, because it is setup in Windows like any other 'printer', you can use the
*	Printer Control Panel to change the settings of the driver (cool).
*
*	The "Aladdin Free Public License" (AFPL) version of Ghostscript is "free" as long as
*	it is not a commercial package.
*	The Ghostscript web site has the most recent "publicly released" version.  Also,
*	you can download the actual Source Code for Ghostscript (written in C), and you
*	also get the developer's documentation which describes all parameters, etc.  The
*	parms used here are pretty generally acceptable, but if you need higher resolution,
*	debug messages, printer specific stuff, etc. it's good to have.
*
*	Once you install Ghostscript (usually C:\program files\gs\), you can run it (gswin32.exe)
*	It's main interface is a "command prompt" where you can interactively enter GS commands.
*	You can also enter "devicenames ==" at the GS command prompt to get a current list
*	of all "output devices" currently supported (DEVICE=pdfwrite, DEVICE=laserject, etc.)
*
****** REVISION HISTORY:
*	Version 1.2
*	---------------------------------------------------------------------------------
*	Turned this "thing" into a Class.
*	Added Flags and logic to allow the user to install Postscript on-the-fly.
*	Added Flags and logic to allow the user to install Ghostscript on-the-fly.
*	Added Flags and logic to allow the user to install Adobe Acrobat on-the-fly.
*	Added the ability to read most setting from the .INI file.
*
*	Version 1.3
*	---------------------------------------------------------------------------------
*	Corrected some logic bugs, and bugs in the .ini processing.
*	Changed .ini setting names to be the same as the variable names for clarity**.
*	Added all new properties to .ini file.
*	Added "cStartFolder" property to hold the folder the program is running from.
*	Added "cTempPath" property to hold the folder for storing temporary files.
*	Added support for printing "color" in pdf.
*		Added "lUseColor" to determine color printer use.
*		Added "cColorPrinter" property (and .ini setting) to hold color printer driver.
*	Added "cPrintResolution" so you can change printer resolution on-the-fly.
*	Added the ability to use "dynamic" or "variable" paths in the Install Paths (including this.cStartFolder)
*	Made this file callable as a "procedure".
*	Included Demo program, dbf, report.
*	Included Ghostscript and Postscript installs.
*
*	Version 1.41
*	---------------------------------------------------------------------------------
*	Completely changed the calls to Ghostscript, removing the DLL calls and using the API.
*	Added some timing mechanisms to make sure we are not trying to delete files while they are in use.
*
*	Version 1.42
*	---------------------------------------------------------------------------------
*	Updated the .INI file for Ghostscript 8.11.  Tested using this new version of Ghostscript.
*	Compiled and tested under VFP 8.0.
*	Added the DEBUGGING/PROBLEMS section to give hints for common problems and solutions.
*
*	Version 1.50
*	---------------------------------------------------------------------------------
*	Removed all usage of WITH...ENDWITH to avoid stupid mistakes.
*	Added code to Save existing VFP printer to SetPrinter() method.
*	Added "plSecondTry" parm to SetPrinter() to avoid endless loop.
*	Additional documentation for GSView and RedMon.
*
*   Version 1.51
*   ---------------------------------------------------------------------------------
*   Removed checking for specific version of Ghostscript.
*   Added the ability to search for Ghostscript in C:\Program Files\GS\ and/or D:\Program Files\GS\
*   Made ADeleteFile() method more robust and informative.
*   Force GSFind() method to actually get Ghostscript path so call to GS does not fail.
*   Reworked logic about adding Ghostscript to VFP path.
*
*   Version 1.75
*   ---------------------------------------------------------------------------------
*   Added the (default) ability to use the freeware BullZip Printer Driver (www.bullzip.com) 
*      to control the entire process, instead of manually controlling the PS Driver and Ghostscript.
*      BullZip still uses Ghostscript internally (but only works with newer versions).
*      BullZip uses a free version of bioPDF (www.biopdf.com)
*   Fixed a bug when setting the color printer driver.
*   The Bullzip installation is very simple and includes optionally/automatically installing a version of Ghostscript.
******************************************************************************************************************


*************************************************************************************************
*** The following code allows you to call the Print2PDF class as a Function/Procedure,
*** just pass in the Output Filename and the Report Filename like:
***		Do Print2PDF with "MyPdfFile" "MyVfpReport"
*** If you use Print2PDF as a class, this code NEVER gets hit!
*************************************************************************************************
if vartype(pcFileName) <> "C" or vartype(pcReport) <> "C" or empty(pcFileName) or empty(pcReport)
	=messagebox("No Parms passed to Print2PDF",48,"Error")
	return .f.
endif

local loPDF
loPDF = .NULL.

loPDF = createobject("Print2PDF")

if isnull(loPDF)
	=messagebox("Could not setup PDF class!",48,"Error")
	return .f.
endif

loPDF.cOutputFile 	= pcFileName
loPDF.cReport		= pcReport
llResult 			= loPDF.Main()

if !llResult or loPDF.lError
	=messagebox("This error ocurred creating the PDF:"+chr(13)+alltrim(loPDF.cError),48,"Error Message")
endif

loPDF = .NULL.
release loPDF

return .t.



**************************************************************************************
** Class Definition :: Print2PDF
**************************************************************************************
define class Print2PDF as relation
	**Please note that any of these properties can be set by you in your code.
	**You can also set most of them by using the .ini file.

	**Set these properties (required)
	cReport			= space(0)	&&Name of VFP report to Run
	cOutputFile		= space(0)	&&Name of finished PDF file to create.

	**User-Definable properties (most of these can be set in the .ini file)
	cStartFolder	= justpath(sys(16))+iif(right(justpath(sys(16)),1)="\","","\")	&&Folder this program started from.
	cTempPath		= space(0)	&&Folder for Temporary Files (default = VFP temp path)
	cExtraRptClauses= space(0)	&&Any extra reporting clauses for the "report form" command
	lReadINI		= .t.		&&Do you want to pull settings out of Print2PDF.ini file?
	cINIFile		= this.cStartFolder+"Print2PDF.ini"	&&Name of INI file to use.  If not in current folder or VFP path, specify full path.
	lFoundPrinter	= .f.		&&Was the PS printer found?
	lFoundGS		= .f.		&&Was Ghostscript found?
	cPSPrinter		= space(0)	&&Name of the Windows Printer that is the Postscript Printer (default = "GENERIC POSTSCRIPT PRINTER")
	cPSColorPrinter	= space(0)	&&Name of the Windows Printer that is the Postscript Printer (default = "GENERIC COLOR POSTSCRIPT")
	lUseColor		= .f.		&&Use "color" printer driver?
	cPrintResolution= space(0)	&&Printer resolution string (300, 600x600, etc.) (default = "300")
	cPSFile			= space(0)	&&Path/Filename for Postscript file (auto-created if not passed)
	lErasePSFile	= .t.		&&Erase the .ps file after conversion?  Set to .F. to save postscript file for debugging.
	cGSFolder		= space(0)	&&Path where Ghostscript exists	(auto-populated if not passed)
    lUseBullzip     = .t.       &&Use the Bullzip API to create the PDF instead of the Postscript Driver?
    cbzShowSettings = "never"   &&Bullzip Setting - see BullzipToPDF method below.
    cbzShowSaveAS   = "never"   &&Bullzip Setting - see BullzipToPDF method below. 
    cbzShowProgress = "no"      &&Bullzip Setting - see BullzipToPDF method below.
    cbzShowProgressFinished = "no"  &&Bullzip Setting - see BullzipToPDF method below.
    cbzShowPDF      = "no"      &&Bullzip Setting - see BullzipToPDF method below.
    cbzConfirmOverwrite = "no"  &&Bullzip Setting - see BullzipToPDF method below.


	**Internal properties
	lError			= .f.		&&Indicates that this class had an error.
	cError			= ""		&&Error message generated by this class
	cOrigSafety		= space(0)	&&Original "set safety" settting
	cOrigPrinter	= space(0)	&&Original "Set printer" setting


	**AutoInstall properties	&&See the ReadINI method for more details
	iInstallCount	= 1			&&Number of programs setup for AutoInstallation

	dimension aInstall[1, 7]

	aInstall[1,1] = space(0)	&&Program Identifier (used to find program in array)
	aInstall[1,2] = .t.			&&Can we install this product
	aInstall[1,3] = space(0)	&&Product Name (for user)
	aInstall[1,4] = space(0)	&&Description of product for user
	aInstall[1,5] = space(0)	&&Folder where install files are stored
	aInstall[1,6] = space(0)	&&Setup Executable name
	aInstall[1,7] = space(0)	&&Notes to show user before installing


	**************************************************************************************
	** Class Methods
	**************************************************************************************
	**********************
	** Init Method
	**********************
	procedure init(pcFileName, pcReport, plRunNow)
		this.cOrigSafety = set("safety")
		this.cOrigPrinter = set("Printer", 3)

		this.lError = .f.
		this.cError = ""

		if type("pcFileName") = "C" and !empty(pcFileName)
			this.cOutputFile = alltrim(pcFileName)
		endif

		if type("pcReport") = "C" and !empty(pcReport)
			this.cReport = alltrim(pcReport)
		endif

		set safety off

		**Did User pass in parm to autostart the Main method?
		if type("plRunNow") = "L" and plRunNow = .t.
			return this.main()
		endif
	endproc


	**********************
	** Destroy Method
	**********************
	procedure destroy
		this.CleanUp
		dodefault()
	endproc


	**********************************************************************
	** Cleanup Method
	** 	Make sure all objects are released, etc.
	**********************************************************************
	function CleanUp
		local lcOrigPrinter, lcOrigSafety

		lcOrigSafety = this.cOrigSafety
		lcOrigPrinter = this.cOrigPrinter

		if !empty(lcOrigSafety)
			set safety &lcOrigSafety
		endif

		if !empty(lcOrigPrinter)
			set printer to
			set printer to name "&lcOrigPrinter"
		endif

		return
	endfunc


	**********************************************************************
	** ResetError Method
	** 	Call this method on each subsequent call to SendFax or CheckLog
	**********************************************************************
	function ResetError
		this.lError = .f.
		this.iError = 0
		this.cError = ""
		return .t.
	endfunc



	**************************************************************************************
	* Main Method - Main code
	*	If you wanted to run each piece seperately, you can make your own calls
	*	to each of the methods called below from within your program and not
	*	call this method at all.  That way, you could execute only the methods you want.
	*	For example, if your postscript file already existed, you could simply set
	*	the properties for the file location, then skip the calls that create the PS file
	*	and go straight to the MakePDF() method.
	**************************************************************************************
	function main(pcFileName, pcReport)
		local x, llRptError
		store 0 to x
		store .f. to llRptError

		if type("pcFileName") = "C" and !empty(pcFileName)
			this.cOutputFile = alltrim(pcFileName)
		endif

		if type("pcReport") = "C" and !empty(pcReport)
			this.cReport = alltrim(pcReport)
		endif

		if empty(this.cReport) or empty(this.cOutputFile)
            Set Step On
			this.lError = .t.
			this.cError(".cReport and/or .cOutputFile empty",48,"Error")
			return .f.
		endif

		**Get values from Print2Pdf.ini file
		**Also sets default values even if .ini is not used.
		if !this.lError
			=this.ReadINI()
			wait clear
		else
			if !llRptError
				=messagebox(this.cError,48,"PDF Creation Error")
				llRptError = .t.
			endif
		endif

		**Set printer to PostScript
		if !this.lError
			=this.SetPrinter()
			wait clear				
		else
			if !llRptError
				=messagebox(this.cError,48,"PDF Creation Error")
				llRptError = .t.
			endif
		endif

        If this.lUseBullZip
            **Create the PDF
            if !this.lError
                =this.BullzipToPDF()
                wait clear                

                if this.lError
                    =messagebox(this.cError,48,"PDF Creation Error")
                    llRptError = .t.
                endif
            Endif
        Else
            **Use Postscript driver.
            
    		**Create the Postscript file
    		if !this.lError
    			=this.MakePS()
    			wait clear				
    		else
    			if !llRptError
    				=messagebox(this.cError,48,"PDF Creation Error")
    				llRptError = .t.
    			endif
    		endif

    		**Make sure Ghostscript can be found
    		if !this.lError
    			=this.GSFind()
    			wait clear				
    		else
    			if !llRptError
    				=messagebox(this.cError,48,"PDF Creation Error")
    				llRptError = .t.
    			endif
    		endif

    		**Turn Postscript into PDF
    		if !this.lError
    			=this.MakePDF()
    			wait clear
    		else
    			if !llRptError
    				=messagebox(this.cError,48,"PDF Creation Error")
    				llRptError = .t.
    			endif
    		endif

            **Install PDF Reader
            if !this.lError
                =this.InstPDFReader()
                wait clear                
            else
                if !llRptError
                    =messagebox(this.cError,48,"PDF Creation Error")
                    llRptError = .t.
                endif
            endif
        EndIf
        
		this.CleanUp()

		if !empty(this.cError) and !llRptError
			=messagebox(this.cError,48,"PDF Creation Error")
			llRptError = .t.
		endif

		wait clear
		return !this.lError
	endfunc



	**************************************************************************************
	* ReadIni()	-	Function to open/read contents of Print2PDF.INI file.
	*			-	If the .ReadINI property is .False., this method will not run
	*			-	This method examines each property, it will not overwrite a property
	*				with a value from the .INI that you have already populated via code.
	**************************************************************************************
	function ReadINI()
		local lcTmp
		store "" to lcTmp

		**If we're not supposed to read the INI, make sure default values are set
		if this.lReadINI = .t.
			**Win API declaration
			declare integer GetPrivateProfileString ;
				in WIN32API ;
				string cSection,;
				string cEntry,;
				string cDefault,;
				string @cRetVal,;
				integer nSize,;
				string cFileName


			**Read INI settings
			**General Properties
			**Postscript Printer Driver Name
			if empty(this.cPSPrinter)
				this.cPSPrinter = this.ReadIniSetting("PostScript", "cPSPrinter")
			endif

			**Color Postscript Printer Driver Name
			if empty(this.cPSColorPrinter)
				this.cPSColorPrinter = this.ReadIniSetting("PostScript", "cPSColorPrinter")
			endif
		
			**Name of PostScript file
			if empty(this.cPSFile)
				this.cPSFile = this.ReadIniSetting("PostScript", "cPSFile")
			endif

			**Name of folder to hold Temporary postscript files
			if empty(this.cTempPath)
				this.cTempPath = this.ReadIniSetting("PostScript", "cTempPath")
			endif

			**Name of Ghostscript folder (where installed to)
			if empty(this.cGSFolder)
				this.cGSFolder = this.ReadIniSetting("GhostScript", "cGSFolder")
			endif

			**Resolution for PDF files
			if empty(this.cPrintResolution)
				this.cPrintResolution = this.ReadIniSetting("PostScript", "cPrintResolution")
			endif

			**Installation Packages
			**# of packages to store settings for
			lcTmp = this.ReadIniSetting("Install", "iInstallCount")
			if !empty(lcTmp)
				this.iInstallCount = val(lcTmp)

				if this.iInstallCount > 1
					dimension this.aInstall[this.iInstallCount, 7]
				endif

				for x = 1 to this.iInstallCount
					**What is the "programmatic" ID for this package
					this.aInstall[x,1] = upper(this.ReadIniSetting("Install", "cInstID"+transform(x)))

					**Can we install this package?
					lcTmp = upper(this.ReadIniSetting("Install", "lAllowInst"+transform(x)))
					this.aInstall[x,2] = iif("T" $ lcTmp or "Y" $ lcTmp, .t., .f.)

					**Product Name
					this.aInstall[x,3] = this.ReadIniSetting("Install", "cInstProduct"+transform(x))

					**Description of Product to show user
					this.aInstall[x,4] = this.ReadIniSetting("Install", "cInstUserDescr"+transform(x))

					**Folder where installation files exist
					this.aInstall[x,5] = this.ReadIniSetting("Install", "cInstFolder"+transform(x))

					**Executable file to start installation
					this.aInstall[x,6] = this.ReadIniSetting("Install", "cInstExe"+transform(x))
						
					**Instructions to User
					this.aInstall[x,7] = this.ReadIniSetting("Install", "cInstInstr"+transform(x))
				endfor
			endif
		ENDIF
		
		**Make sure these basic settings are not blank
		if empty(this.cPSPrinter)
            If this.lUseBullZip = .T.
                this.cPSPrinter = "BULLZIP PDF PRINTER"
            Else
    			this.cPSPrinter	= "GENERIC POSTSCRIPT PRINTER"
            Endif
		endif
		if empty(this.cPSColorPrinter)
            If this.lUseBullZip = .T.
                this.cPSPrinter = "BULLZIP PDF PRINTER"
            Else
    			this.cPSColorPrinter = "GENERIC COLOR POSTSCRIPT"
            Endif
		ENDIF
		if empty(this.cTempPath)
			this.cTempPath = sys(2023) + iif(right(sys(2023),1)="\","","\")
		endif
		if empty(this.cPrintResolution)
			this.cPrintResolution= "300"
		endif
		return .t.
	endfunc



	**************************************************************************************
	* ReadIniSetting() - Returns the value of a "setting" from an "INI" file (text file)
	*				 	 (returns "" if string is not found)
	*	Parms:	pcSection	= The "section" in the INI file to look in...	[Section Name]
	*			pcSetting	= The "setting" to return the value of			Setting="MySetting"
	**************************************************************************************
	function ReadIniSetting(pcSection, pcSetting)
		local lcRetValue, lnNumRet, lcFile
		
		lcFile = alltrim(this.cIniFile)

		lcRetValue = space(8196)

		**API call to get string
		lnNumRet = GetPrivateProfileString(pcSection, pcSetting, "[MISSING]", @lcRetValue, 8196, lcFile)

		
		lcRetValue = alltrim(substr(lcRetValue, 1, lnNumRet))
		
		if lcRetValue == "[MISSING]"
			lcRetValue = ""
		endif
		
		return lcRetValue
	endfunc



	**************************************************************************************
	* SetPrinter() - Set the printer to the PostScript Printer
	*	Parms:	plSecondTry (will be .T. if this method is called recursively)
	**************************************************************************************
	function SetPrinter(plSecondTry)
		local x, lcPrinter, llSecondTry
		x = 0
		lcPrinter = ""
		llSecondTry = .F.
		
		If Pcount() > 0 and Type('plSecondTry') = "L"
			llSecondTry = plSecondTry
		endif

		*Save original VFP Printer if we have not done so yet.
		If Empty(this.cOrigPrinter)
			this.cOrigPrinter = set("Printer", 3)
		endif

		*Load defaults for PS printer names if none loaded yet.		
		if empty(this.cPSPrinter)
            If this.lUseBullzip
                this.cPSPrinter = "BULLZIP PDF PRINTER"
            Else
    			this.cPSPrinter = "GENERIC POSTSCRIPT PRINTER"
            Endif
		endif
		if empty(this.cPSColorPrinter)
            If this.lUseBullzip
                this.cPSColorPrinter = "BULLZIP PDF PRINTER"
            Else
    			this.cPSColorPrinter = "GENERIC COLOR POSTSCRIPT"
            Endif
		endif

		if this.lUseColor = .t.
			lcPrinter = this.cPSColorPrinter
		else
			lcPrinter = this.cPSPrinter
		endif
			
		this.lFoundPrinter = .f.

		***Make sure a Postscript printer exists on this PC
		if aprinters(laPrinters) > 0
			for x = 1 to alen(laPrinters)
				if alltrim(upper(laPrinters[x])) == lcPrinter
					this.lFoundPrinter = .t.
					exit
				endif
			endfor

			if !this.lFoundPrinter
				this.cError = lcPrinter+" is not installed!!"
                Set Step On
				this.lError = .t.
			endif
		else
			this.cError = "NO printer drivers are installed!!"
            Set Step On
			this.lError = .t.
		endif

		if this.lFoundPrinter
			*** Set the printer to Generic Postscript Printer
			lcEval = "SET PRINTER TO NAME '" +lcPrinter+"'"
			&lcEval

			if alltrim(upper(set("PRINTER",3))) == alltrim(upper(lcPrinter))
			else
				this.cError = "Could not set printer to: "+alltrim(lcPrinter)
                Set Step On
				this.lError = .t.
				this.lFoundPrinter = .f.
			endif
		endif

		**Auto-Install, If no PS printer was found.
		if !this.lFoundPrinter
			If llSecondTry
				this.cError = "NO printer drivers are installed!!"
                Set Step On
				this.lError = .t.
				Return .f.
			EndIf
			
			if this.Install("POSTSCRIPT")	&&Install PS driver
				return this.SetPrinter(.T.)	&&Call this function again
			endif
		endif
	
		return this.lFoundPrinter
	endfunc




    **************************************************************************************
    * BullzipToPDF() - Use Bullzip to manage the process of turning the report into a PDF.
    * See http://www.biopdf.com/guide/settings.php
    * Configuration Files
    *   The program is controlled by a wide variety of settings. Each of these settings can influence the output or the user experience. 
    *   When the program runs it looks for the settings in a set of setting files. These files and their location are described in more detail below.
    * 
    * Runonce Settings
    *   When a print job is sent to the program it will look for a runonce file. 
    *   The runonce setting file is used to control the PDF creation from another program. 
    *   A runonce setting file is only valid for one print job and will be removed automatically when it is read. 
    *   All other setting files are ignored if a runonce file exists.
    * 
    * Normal Settings
    *   In case there is no runonce file, the program will look for a normal settings file. 
    *   The normal settings file is written by the options dialog, which can be launched from the Start menu.
    * 
    * Global Settings
    *   The settings read from the normal settings file can be overwritten by settings in a global settings file. 
    *   A global settings file can contain a list of forced settings that apply to all users on the system. 
    *   If the same setting is specified in both the normal setting file and the global setting file then the resulting value is taken from the global setting file.
    * 
    * Default Settings
    *   Default settings are the values that are used in case no values was specified elsewhere.
    * 
    * User Settings
    *   A user file is created to store information such as the last file and folder name used by the user.
    * 
    * The table below lists the configuration files and their location. 
    * %APPDATA% and %Program Files% refers to the value of the APPDATA and Program Files environment variables. 
    * These locations vary with different versions of the Microsoft Windows operating system. 
    * Their values also change for different language versions of the operating system.
    *   Runonce Settings    runonce@printername.ini    %APPDATA%\bioPDF\PDF Writer\
    *   Normal Settings     settings@printername.ini   %APPDATA%\bioPDF\PDF Writer\
    *   Global Settings     global@printername.ini     %Program Files%\bioPDF\PDF Writer\
    *   Default Settings    defaults@printername.ini   %Program Files%\bioPDF\PDF Writer\
    *   User Settings       user@printername.ini       %APPDATA%\bioPDF\PDF Writer\    
    **************************************************************************************
    function BullzipToPDF()
        Local oBullZip         && As Bullzip.PDFPrinterSettings
        Local lcOutputFile, lcReport, lcExtra
        Store "" to lcOutputFile, lcReport, lcExtra
        
        lcOutputFile    = this.cOutputFile
        lcReport        = this.cReport
        lcExtra         = this.cExtraRptClauses

        if empty(lcReport)
            this.cError = "No Report File was specified."
            Set Step On
            this.lError = .t.
            return .f.
        endif

        *Delete existing PDF if it exists.
        if !ADeleteFile(lcOutputFile)
            this.cError = "Could not remove existing file: "+lcOutputFile
            Set Step On
            this.lError = .t.
            return !this.lError
        endif

        **If BullZip was not set a default printer yet, do it.
        if !this.lFoundPrinter
            if !this.SetPrinter()
                return .f.
            endif
        endif

        *Setup BullZip
        oBullZip = CREATEOBJECT("Bullzip.PDFPrinterSettings")
        
        if Type('oBullZip') <> 'O' or IsNull(oBullZip)
            this.cError = "Could not instantiate BullZip object."
            this.lError = .t.
            Set Step On            
            return !this.lError                
        endif

        *Setup the RunOnce.ini settings file.
        =oBullZip.SetValue("output", lcOutputFile)
        =oBullZip.SetValue("showsettings", this.cbzShowSettings)
        =oBullZip.SetValue("ShowSaveAS", this.cbzShowSaveAs)
        =oBullZip.SetValue("ShowProgress", this.cbzShowProgress)
        =oBullZip.SetValue("ShowProgressFinished", this.cbzShowProgressFinished)
        =oBullZip.SetValue("ShowPDF", this.cbzShowPDF)
        =oBullZip.SetValue("ConfirmOverwrite", this.cbzConfirmOverwrite)
        
        =oBullZip.WriteSettings(.T.) &&writes the settings in a runonce.ini that it immediately deleted after being used.
        
        =asleep(2)    &&pause to make sure file gets written and closed before trying to proceed.

        oBullZip = .NULL.
        Release oBullZip
        
        wait window "Creating PDF..." timeout .5
        report form (lcReport) &lcExtra to printer noconsole

        **Wait for 20 seconds for the file to be converted.
        for x = 1 to 20
            wait window "Waiting for PDF: "+alltrim(lcOutputFile) nowait noclear
            =ASleep(1000)
            if file(lcOutputFile)
                exit
            endif
        endfor
        wait clear

        if !file(lcOutputFile)
            this.cError = "Could not create: "+lcOutputFile+chr(13)+;
                            "No errors, just no file exists."
            this.lError = .t.
            Set Step On            
            return !this.lError                
        endif
        
        wait clear
        return !this.lError
    endfunc




	**************************************************************************************
	* MakePS() - Run the VFP report to a PostScript file
	**************************************************************************************
	function MakePS()
		local lcReport, lcExtra, lcPSFile

		wait window "Creating PostScript File" timeout .5
		
		set safety off

		**If no PS printer was found yet, find it
		if !this.lFoundPrinter
			if !this.SetPrinter()
				return .f.
			endif
		endif

		lcReport	= this.cReport
		lcExtra		= this.cExtraRptClauses

		if empty(lcReport)
			this.cError = "No Report File was specified."
            Set Step On
			this.lError = .t.
			return .f.
		endif

		if empty(this.cPSFile)
			*** We'll create a Postscript Output File (use VFP temporary path and temp filename)
			=ASleep(500)
			wait window "Creating File..." nowait
			this.cPSFile = this.cTempPath + sys(2015) + ".ps"
		endif

		lcPSFile = this.cPSFile

		*** Make sure we erase any existing file first
		if !ADeleteFile(lcPSFile)
			this.cError = "Could not remove Pre-Existing PS file: "+lcPSFile
            Set Step On
			this.lError = .t.
			return !this.lError
		endif
		report form (lcReport) &lcExtra noconsole to file &lcPSFile

		if !file(lcPSFile)
			this.cError = "Could not create PostScript file"
            Set Step On
			this.lError = .t.
			return .f.
		endif

		return .t.
	endfunc



	**************************************************************************************
	* GSFind() - Finds the Ghostscript path and adds it to the VFP path
	**************************************************************************************
	function GSFind()
		local x, lcPath, lcGSDir
		store "" to lcPath, lcGSDir
		store 0 to x

		wait window "Finding Ghostscript..." timeout .5
		
		this.lFoundGS = .f.

		**Try location specified in INI file
		if !empty(this.cGSFolder)
			lcTmp = this.cGSFolder + "gswin32c.exe"			&&Make sure the file can be found
			if !file(lcTmp)
				this.cGSFolder = ""
			endif
		endif

		*Look for them to exist in C:\gs\gsX.XX\bin\, C:\Program Files\gs\gsX.XX\bin\, or D:\Program Files\gs\gsX.XX\bin\
		if empty(this.cGSFolder)
			if directory("C:\gs")
                lcGSDir = "C:\gs"
            Else
                If Directory("C:\Program Files\gs")
                    lcGSDir = "C:\Program Files\gs"
                Else
                    If Directory("D:\Program Files\gs")
                        lcGSDir = "D:\Program Files\gs"
                    Endif
                EndIf
            EndIf
            
            If Empty(lcGSDir)
				this.cError = "Could not find GhostScript."
                Set Step On
				this.lError = .t.
				return .f.
			endif


			liGS = adir(laGSFolders, Addbs(lcGSDir)+"*.*","D")
			if liGS < 1
				this.cError = "Could not find GhostScript."
                Set Step On
				this.lError = .t.
				return .f.
			endif

			for x = 1 to alen(laGSFolders,1)
				lcTmp = alltrim(upper(laGSFolders[x,1]))
				if "GS" = left(lcTmp,2) and "D" $ laGSFolders[x,5]
					this.cGSFolder = lcTmp
					exit
				endif
			endfor

			if empty(this.cGSFolder)
				this.cError = "Could not find GhostScript."
                Set Step On
				this.lError = .t.
				return .f.
			endif

			this.cGSFolder = Addbs(lcGSDir)+alltrim(this.cGSFolder)+"\bin\"
		endif

        if !empty(this.cGSFolder)
            lcTmp = this.cGSFolder + "gswin32c.exe"            &&Make sure the file can be found
            if !file(lcTmp)
                this.cGSFolder = ""
            endif
        endif

		if empty(this.cGSFolder)
			this.cError = "Could not find GhostScript."
            Set Step On
			this.lError = .t.
			return .f.
		else
			this.lFoundGS = .t.
		endif

        If this.lFoundGS = .t.
            **Add Ghostscript to the VFP path.  Probably unnecessary.
            if !File("gswin32c.exe")    &&file("gsdll32.dll")
    	    	lcPath = alltrim(set("Path"))
                If "\GS\" $ Upper(lcPath)
                Else
    	    	    lcPath = lcPath + Iif(Right(lcPath,1)=";","",";")                        && Append semi-colon if one does not exist.
                    lcPath = lcPath + this.cGSFolder
                    lcPath = Iif(Right(lcPath,1)="\", Left(lcPath,Len(lcPath)-1), lcPath)    && Get rid of trailing backslash.
                    lcPath = lcPath + ";"
                    set path to lcPath
                Endif
            EndIf
        EndIf
            
		return .t.
	endfunc




	**************************************************************************************
	* MakePDF() - Run Ghostscript to create PDF file from the Postscript file
	**************************************************************************************
	function MakePDF()
		local lcOutputFile, lcPSFile

		wait window "Creating PDF..." timeout .5
		
		set safety off
		
		**Make sure Ghostscript has been found (or install)
		if !this.lFoundGS
			wait window "Looking for GS..." nowait noclear
			if !this.GSFind()

				**Auto-Install, Ghostscript
				if this.Install("GHOSTSCRIPT")
					if !this.GSFind()	&&Call function again
						this.cError = "Could not Install Ghostscript!"
                        Set Step On
						this.lError = .t.
						return .f.
					endif
				endif
			endif
		endif

		lcOutputFile	= this.cOutputFile
		lcPSFile		= this.cPSFile

		if !ADeleteFile(lcOutputFile)
			this.cError = "Could not remove existing file: "+lcOutputFile
            Set Step On
			this.lError = .t.
			return !this.lError
		endif

		wait window "Converting PS file..." nowait noclear
		if !this.GSConvertFile(lcPSFile, lcOutputFile)
			if empty(this.cError)
				this.cError = "Could not create: "+lcOutputFile+chr(13)+;
								"GSConvertFile() encountered an error."
			endif
            Set Step On
			this.lError = .t.
			return !this.lError				
		endif

		**Get rid of .ps file
		if this.lErasePSFile
			if !ADeleteFile(lcPSFile)
				this.cError = "Could not remove PS file: "+lcPSFile
                Set Step On
				this.lError = .t.
				return !this.lError
			endif
		endif

		if !file(lcOutputFile)
			this.cError = "Could not create: "+lcOutputFile+chr(13)+;
							"No errors, just no file exists."
			this.lError = .t.
            Set Step On            
			return !this.lError				
		endif

		wait clear
		return !this.lError
	endfunc



	**************************************************************************************
	* GSConvert() - Use API ShellExecute to call Ghostscript
	*	I previously used Sergey's calls to the GS DLL files, but for simplicity I
	*	have replace them with a simple API ShellExecute call.  Please note that
	*	you can get similar results using the "ps2pdf.bat" that ships with GS.
	**************************************************************************************
	function GSConvertFile(tcFileIn, tcFileOut)
		wait window "Converting File..." timeout .5
		
		set safety off
		local lcProg, lcParms, lcCmd
		store "" to lcProg, lcParms, lcCmd

        If Empty(this.cGSFolder)
            If !this.GSFind() or Empty(this.cGSFolder)
                Set Step On
                this.lError = .T.
                this.cError = "Ghostscript EXE could not be found!  GSConvertFile()"
                Return .F.
            Endif
        endif

		lcProg = Addbs(alltrim(this.cGSFolder)) + "gswin32c.exe"
		*lcProg = addbs(alltrim(this.cGSFolder)) + "..\lib\ps2pdf.bat"

		lcParms = 	"-sDEVICE=pdfwrite"+;
					" -sOutputFile="+tcFileOut+;
					" -r"+this.cPrintResolution+;
					" -dBATCH"+;
					" -dNOPAUSE"+;
					" -q"+;
					" -c 3000000 setvmthreshold .setpdfwrite -f "+;
					tcFileIn
					
		lcCmd = lcProg + lcParms

		**ShellExecute API declaration
		DECLARE INTEGER ShellExecute ;
			IN SHELL32.DLL ;
			INTEGER nWinHandle,;
			STRING cOperation,;   
			STRING cFileName,;
			STRING cParameters,;
			STRING cDirectory,;
			INTEGER nShowWindow

		liRetVal = ShellExecute(0, "open", lcProg, lcParms, this.cGSFolder, 2)

		**Wait for 10 seconds for the file to be converted.
		for x = 1 to 10
			wait window "Waiting for PDF: "+alltrim(tcFileOut) nowait noclear
			=ASleep(1000)
			if file(tcFileOut)
				exit
			endif
		endfor
		wait clear
		
		if !file(tcFileOut)
            Set Step On
			this.lError = .t.
			this.cError = "Ghostscript could not create the file:"+chr(13)+tcFileOut
			return .f.
		else
			return .t.
		endif
	endfunc



	**************************************************************************************
	* InstPDFReader Method - Installs the PDFReader if needed
	**************************************************************************************
	function InstPDFReader()
		**Make sure the PDF file has been created
		if !file(this.cOutputFile)
			return .f.
		endif

		**Ask Windows which EXE is associated with this file (extension)
		lcExe = this.AssocExe(this.cOutputFile)

		if empty(lcExe)
			**Install the PDF Reader
			return this.Install("PDFREADER")
		else
			return .t.
		endif
	endfunc


	**************************************************************************************
	* AssocExe Method - Returns the Executable File associated with a file
	**************************************************************************************
	function AssocExe(pcFile)
		local lcExeFile
		store "" to lcExeFile

		declare integer FindExecutable in shell32;
			string   lpFile,;
			string   lpDirectory,;
			string @ lpResult

		lcExeFile = space(250)

		if FindExecutable(pcFile, "", @lcExeFile) > 32
			lcExeFile = left(lcExeFile, at(chr(0), lcExeFile) -1)
		else
			lcExeFile = ""
		endif

		return lcExeFile
	endfunc


	**************************************************************************************
	* Install Method - Installs software on the PC
	**************************************************************************************
	function Install(pcID)
		local llFound, x, lcEval, lcProduct, lcDesc, lcTmp, ;
				lcFolder, lcInstEXE, lcInstruct, llDynaPath
		store "" to lcEval, lcProduct, lcAbbr, lcDesc, lcTmp, lcFolder, lcInstEXE, lcInstruct
		store .f. to llFound, llDynaPath

		pcID = alltrim(upper(pcID))

		**See if this Installation ID is in our array
		for x = 1 to alen(this.aInstall,1)
			if alltrim(upper(this.aInstall[x,1])) == pcID
				llFound = .t.
				exit
			endif
		endfor

		if !llFound
            Set Step On
			this.lError = .t.
			this.cError = "Installation parms do not exist for ID: "+pcID
			return .f.
		endif

		**Copy array contents to variables
		llDoInst	= this.aInstall[x,2]
		lcProduct	= this.aInstall[x,3]
		lcDesc		= this.aInstall[x,4]
		lcFolder	= this.aInstall[x,5]
		lcInstEXE	= this.aInstall[x,6]
		if !empty(this.aInstall[x,7])
			lcInstruct	= ALLTRIM(this.aInstall[x,7])
			if "+" $ lcInstruct
				lcInstruct = &lcInstruct
			endif
		else
			lcInstruct	= "Please accept the 'Default Values'"+chr(13)+"during the installation."
		endif

		**See if the path is "dynamically" generated based on variables
		if "+" $ lcFolder
			llDynaPath = .t.
		else
			llDynaPath = .f.
		endif
			
		**Are we allowed to install this product?
		if llDoInst = .t.
			**Make sure we have the Folder and Executable to install from?
			if !empty(lcFolder) and !empty(lcInstEXE)
				if llDynaPath
					lcFolder = alltrim(lcFolder)
					lcEval = &lcFolder
					lcEval = lcEval+alltrim(lcInstEXE)	&&command string
				else
					if right(lcFolder,1) <> "\"				&&Make sure the final backslash exists
						lcFolder = lcFolder + "\"
					endif
				
					lcEval = alltrim(lcFolder)+alltrim(lcInstEXE)	&&command string
				endif

				**Make sure install .exe exists in the path given
				if !llDynaPath and !file(lcEval)
					this.cError = "Could not find installer for "+lcProduct+" in:"+chr(13)+alltrim(lcEval)
                    Set Step On
					this.lError = .t.
				else
					if 7=messagebox(lcProduct+" needs to be installed on your computer."+chr(13)+;
							lcDesc+chr(13)+;
							"Is it OK to install now?",36,"Confirmation")
                        Set Step On
						this.lError = .t.
						this.cError = "User cancelled "+lcProduct+" Installation."
						return .f.
					endif

					=messagebox(lcInstruct,64,"Instructions")

					**Do the Installation
					this.aInstall[x,2] = .f.		&&Do not allow ourselves to get into a loop
					lcEval = "run /n "+lcEval
					?lcEval 
					&lcEval

					=messagebox("When the Installation has finished"+chr(13)+;
								"COMPLETELY, please click OK...",64,"Waiting for Installation...")

					**Did it work?
					if 7=messagebox("Was the installation successfull?"+chr(13)+chr(13)+;
									"If no errors ocurred during the Installation"+chr(13)+;
									"and everything went OK, please click 'Yes'...",36,"Everything OK?")
                        Set Step On
						this.lError = .t.
						this.cError = "Errors ocurred during "+lcProduct+" Installation."
						return .f.
					else
						this.lError = .f.
						this.cError = ""
						return .t.
					endif
				endif
			endif
		endif
		return .f.
	endfunc

enddefine
*** End of Class Print2PDF ***


*------------------------------------------------------------------
*| ASleep() - Causes an idle timeout specified in milliseconds.
*------------------------------------------------------------------
function ASleep(liMSecs)
	DECLARE Sleep IN kernel32 INTEGER dwMilliseconds 
	=Sleep(liMSecs)
	return
endfunc


*-------------------------------------------------
*| ADeleteFile() - Deletes the file passed.
*-------------------------------------------------
function ADeleteFile(lcFileName)
	local liRetval, llRetVal, x, llContinue
	liRetVal   = 0
	llRetVal   = .f.
    llContinue = .t.
    
	if !file(lcFileName)
		return .t.
	endif
	
	DECLARE INTEGER DeleteFile IN kernel32 ;
		STRING lpFileName 

    **Try to delete file until it is gone or user gives up trying.
    Do while llContinue
    	**Try over a 15-second timeframe to delete the file.	
    	for x = 1 to 15
	    	liRetVal = DeleteFile(lcFileName) 
		    if liRetVal <> 0 or !file(lcFileName)
                llContinue = .F.
    			exit
	    	endif
		    wait window "Waiting to delete file: "+alltrim(lcFileName) nowait noclear
    		=ASleep(1000)
	    endfor

        if liRetVal = 0 or File(lcFileName)
            Wait clear
            If 6 <> MessageBox("File: "+JustFname(lcFileName)+"  must be deleted to continue,"+Chr(13)+;
                               "but it cannot be deleted for some reason."+Chr(13)+Chr(13)+;
                               "If you have the file open (for viewing, e-mailing, etc.),"+Chr(13)+;
                               "please close the file (and perhaps the application that has it open), then click OK",;
                               1,"Existing file cannot be deleted!")
                llContinue = .F.
            EndIf
        Endif
    EndDo

	wait clear
    if file(lcFileName)
        return .F.
    Else
        Return .T.
    endif
endfunc


*---------------------------------------------------------------------
*| ACopyFile() - Copies "lcFrom" to "lcTo".
*|					If liOver = 0, overwrite if exists.
*---------------------------------------------------------------------
Function ACopyFile(lcFrom as string, lcTo as String, liOver as Integer)

	DECLARE INTEGER CopyFile IN kernel32; 
	    STRING  lpExistingFileName,; 
	    STRING  lpNewFileName,; 
	    INTEGER bFailIfExists 

	if pcount() < 3 or type('liOver') <> "N"
		liOver = 0
	endif
	
	if 0 = CopyFile(lcFrom, lcTo, liOver)
		return .f.
	endif
	
	return .t.
endfunc


*---------------------------------------------------------------------
*| AGetEnvVar
*---------------------------------------------------------------------
Function AGetEnvVar(lcVarToGet as String)

    DECLARE INTEGER GetEnvironmentVariable IN kernel32;
        STRING lpName, STRING @lpBuffer, INTEGER nSize
 
    LOCAL lcBuffer, lnResult
    lcBuffer = SPACE(1024)
    lnResult = GetEnvironmentVariable (lcVarToGet, @lcBuffer, Len(lcBuffer))

    If lnResult = 0
        return "#ERROR#"
    Else
        Return Left(lcBuffer, lnResult)
    EndIf
EndFunc


*---------------------------------------------------------------------
*| ASetEnvVar
*---------------------------------------------------------------------
Function ASetEnvVar(lcVarToSet as String, lcValue as String)

    DECLARE INTEGER SetEnvironmentVariable IN kernel32;
        STRING lpName, STRING lpValue
 
RETURN SetEnvironmentVariable(lcVarToSet, lcValue) <> 0
