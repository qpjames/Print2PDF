**Demo call for Print2PDF
set echo off
set talk off
set safety off
SET PATH TO
SET EXACT off
CLEAR ALL
CLOSE ALL
SET PROCEDURE TO
SET CLASSLIB TO 

set procedure to print2pdf.prg

do print2pdf with "p2demo.pdf", "p2demo.frx"

if file("p2demo.pdf")
	=messagebox("Print2PDF created the file 'P2Demo.pdf'", 48, "Success!")
else
	=messagebox("Print2PDF Failed!", 16, "Sorry")
endif
