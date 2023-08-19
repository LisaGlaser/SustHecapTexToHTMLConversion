#!/bin/bash
### This script extracts the  sust hecap reflection document from a .zip archive and converts it to html
### required tools: unzip, pandoc, pandoc-crossref (can do without, but then no figure numbers), convert, sed
### a lot of things are done via sed in pre and post processing steps

inarchive="White Paper Sustainability in HEP V2.0.zip"
outfile="SustHecap.html"
infile="SustainableHep.tex"

echo pwd
unzip "$inarchive"

cd Sections
### convert all images to .png for the website
find ./Figs -type f -name "*.pdf" |while read line
do  
   dir=${line%/*}
   file=${line##*/}
   file=${file%.*}
   convert -transparent white -trim $line ${file}.png
   #echo mv ${file}.png ${dir}/${file}.png
   mv ${file}.png ${dir}/${file}.png
   rm ${dir}/${file}.pdf
done

### edit the *.tex files
### change the image filenames to .png
### change center environment for figures to get numbering
for f in *.tex
do
    echo $f
    sed -i "s/\.pdf}/\.png}/g" "$f"
    sed -i "s/{center}/{figure}/g" "$f"
    sed -i 's/\\subfloat/ /g' "$f"
done

### replacing \currentname with the right titles for the reco2 environments
array=("Introduction.tex" "Energy.tex" "Computing.tex" "Food.tex" "Technology.tex" "Travel.tex" "Waste.tex")
array2=('Impelling Positive Change'  "Energy" "Computing" "Food" 'Research Infrastructure and Technology' "Mobility" 'Resources and Waste')

for index in ${!array[*]}; do 
  echo "${array[$index]} has the recommendation ${array2[$index]}"
  x=${array2[$index]}
  sed -i 's|\\currentname|\\subsection*{Recommendations -- '"$x"'}|g' ${array[$index]}
done


cd ../
### need to change some definitions in Whitepaper.sty to have the reco2
### recommendation titles show up after conversion
sed -i 's|\\begin{mdframed}|\\begin{mdframed} \n #1 \n |g' Whitepaper.sty
sed -i 's|\[\]\\relax%| |g' Whitepaper.sty
pwd

### 
### --filter=pandoc-crossref does give figure numbers
pandoc -s SustainableHEP.tex  --filter=pandoc-crossref --number-sections  --bibliography=SustainableHEP.bib --citeproc --csl resources/ieee.csl --metadata title="Environmental sustainability in basic research" --standalone --listings --toc --toc-depth 2 -o temp.html -t html5 --mathjax  

### get the image paths correct
for part in "Intro" "Computing" "Energy" "Common" "Food" "Technology" "Travel" "Waste"
do
    echo $part
    sed -i "s/${part}\//Sections\/Figs\/${part}\//" temp.html
done
### fixing the fix
sed -i "s/Sections\/Figs\/Sections\/Figs\//Sections\/Figs\//" temp.html
### try to remove bad alt text
sed -i 's/alt="image"//g' temp.html
### pandoc creates some linebreaks that mess with me, I can remove them like this 
sed -i ':a;N;$!ba;s/\nstyle/ style/g' temp.html

### get the alt text from file 
sed -e 's/^/s|/; s/$/|g/' resources/replacelist_edited.txt | sed -i -f - temp.html

### fix the SDG goals
sed -e 's/^/s|/; s/$/|g/' resources/goals_replace.txt | sed -i -f - temp.html

# ### convoluted way to add the commands to get the right font in
head -12 temp.html >$outfile
echo "@import url("https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:wght@400\;700\&display=swap");">>$outfile
echo "body {" >> $outfile
echo "font-family: "Atkinson Hyperlegible", sans-serif;"  >>$outfile
tail +14 temp.html >>$outfile 

### makes the case studies and the recommendations pretty
sed -i "s/blockquote {/.marginline { \n margin: 1em 0 1em 1.7em;\n    padding-left: 1em;\n   border-left: 4px solid green;\n   }\n    .mdframed{\n     border-width:4px; border-style:solid; border-color:green; padding: 1em; \n } \n blockquote {\n/" $outfile

### adding section titles for references and footnotes 

sed -i 's|class="references csl-bib-body" role="list">|class="references csl-bib-body" role="list"><h1 class="unnumbered" id="sec:Bibliography">References</h1>|' $outfile

sed -i 's|role="doc-endnotes">|role="doc-endnotes"> <h1 class="unnumbered" id="footnotes">Footnotes</h1>|' $outfile

sed -i 's|<p><strong>Environmental sustainability in basic research</strong><br />| |' $outfile

sed -i 's|An HTML version of this document|The original PDF version of this document|' $outfile

sed -i 's|This document has been typeset in LaTeX using Atkinson Hyperlegible|This document has been converted from LaTeX using Pandoc. The font used is Atkinson Hyperlegible|' $outfile

### This adds a sidebar with the table of contents.
sed -i "s|</style>|  .sidebar { \n    margin: 0;\n    margin-top: -50px;\n   margin-left:-400px;\n  padding: 0px; \n  width: 300px;\n  background-color: #f1f1f1;\n  position: fixed;\n  height: 100%;\n  overflow: auto;\n}\n\n/* Sidebar links */\n.sidebar a {\n  display: block;\n  color: black;\n  padding: 16px;\n  text-decoration: none;\n}\n\n/* Active/current link */\n .sidebar a.active {\n  background-color: #04AA6D;\n  color: white;\n}\n\n/* Links on mouse-over */\n .sidebar a:hover:not(.active) {\n  background-color: #555;\n  color: white;\n}\n</style>|" $outfile

sed -i 's|<header id="title-block-header">| |' $outfile
sed -i 's|<h1 class="title">Environmental sustainability in basic research</h1>| |' $outfile
sed -i 's|</header>|<div class="sidebar">|' $outfile 

sed -i 's|<div class="titlepage">|</div>\n<header id="title-block-header">\n<h1 class="title">Environmental sustainability in basic research</h1>\n</header>\n<div class="titlepage">|' $outfile


### adding bibliography and footnotes into the toc

sed -i 's|<li><a href="#endorsers" id="toc-endorsers">Endorsers</a></li>|<li><a href="#endorsers" id="toc-endorsers">Endorsers</a></li> \n <li><a href="#refs" id="toc-references">Bibliography</a></li>\n <li><a href="#footnotes" id="toc-endorsers">Footnotes</a></li>\n|' $outfile

## cleanup after
 rm temp.html
 rm Sections/*.tex
 rm Sections/*.txt
 rm *.tex
 rm *.sty
 rm *.bst
 rm *.bib
