#!/bin/bash

# Read this -https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion

pdflatex equations.tex
pdfseparate equations.pdf equation-%d.pdf
for pdf_file in equation-*.pdf; do
    png_file="${pdf_file%.pdf}.png"
    # For wiki - text sized
    #convert -density 120 -transparent white "$pdf_file" "$png_file"
    # For slides
    convert -density 150 -transparent white "$pdf_file" "$png_file"
done
