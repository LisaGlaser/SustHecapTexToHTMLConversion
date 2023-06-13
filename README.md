# SustHecapTexToHTMLConversion
A script to convert the Sustainability in HECAP+ reflection document from a .tex to .html version.

Starting out from a .zip in the main directory (e.g. the .zip downloaded from overleaf, but should also work with an arXiv version), this unpacks the file and then processes it to a .html.

In the process all .pdf figures are converted to .png and cropped, and a lot of formatting relevant tasks are done via sed replacements.

