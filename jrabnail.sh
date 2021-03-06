#!/usr/local/bin/bash
# rabnail.sh (a)2005 reboots at g-cipher.net - http://g-cipher.net~reboots/
# rabnail was originally conceived as a revision of Jacob Brown's WireThumb,
# which was released under the LGPL. See: http://austin2600.org/software.php
# Due to unfamiliarity with perl it has evolved into a wholly original work,
# and is effectively a feature-crept WireThumb workalike. This means as the
# author I am expected to come up with Terms & Conditions. Here goes:
# 1. Whereas reliance on copyright "law" only grants legitimacy to statist
#    dominion of human thought and action, and;
# 2. Whereas attempting to "license" a (barely) human-readable script cobbled
#    together from bits of bash tutorials would be inane in the extreme;
# The work below is hereby placed in the public domain. This software is
# free as in thought; do with it what you will.

# rabnail was renamed to jrabnail after jake at spaz dot org added some
# more features, like a test to see if we created index.html before 
# literally doing rm index*.html
# https://github.com/jerkey/jrabnail

# BUGS: Color may be a hex triplet, but the # must be escaped as: -c \#ffffff.
# No test for presence of user-specified files; lots of ugliness if files do
# not exist. Default text colors are invisible on some backgrounds.
# TODO: Add option to specify thumbnail height (preserve aspect ratio).
# Allow sorting by user-specified criteria rather than by type.
# Generate quick links to each gallery page in footer.

if grep -Fxq "Gallery generated by jrabnail</a>." index.html
then
    rm index*.html
elif [ ! -f index.html ]
then
    echo first time alright
else
    echo "aborting: index.html does not say Gallery generated by jrabnail"
    echo "if you want to use jrabnail, index.html needs to be deleted or renamed."
    exit 1
fi

# make sure current folder is readable
chmod a+rx .

# Options parser
while [ $# -gt 0 ]
do
  case "$1" in
    -o)  output="$2"; shift;;
    -q)  quality="$2"; shift;;
    -w)  width="$2"; shift;;
    -c)  color="$2"; shift;;
    -b)  border="$2"; shift;;
    -p)  pixperpage="$2"; shift;;
    --)	shift; break;;
    -*)
      echo
      echo "usage: $0 [options] [filename(s)]"
      echo
      echo '      -o  thumbnail type: jpg, png, gif   [jpg]'
      echo '      -q  quality: 0 smallest, 100 best   [75]'
      echo '      -w  width in pixels                 [150]'
      echo '      -b  thumbnail border in pixels      [0]'
      echo '      -p  thumbnails per page             [65]'
      echo '      -c  gallery color or hex "\#ffffff" [none]'
      echo
      exit 1;;
    *)  break;;
  esac
  shift
done

# Set option defaults
if [ -z "$output" ]; then output="jpg"; fi
if [ -z "$quality" ]; then quality="75"; fi
if [ -z "$width" ]; then width="150"; fi
if [ -z "$pixperpage" ]; then pixperpage="65"; fi
if [ -z "$border" ]; then border="0"; fi
if [ -z "$color" ]; then body="<body>"; else body="<body bgcolor=\"$color\">";fi
#if [ -z "$color" ]; then color=""; fi

# HTML template
header='<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"'"\n"'      "http://www.w3.org/TR/html4/loose.dtd">'"\n<html>\n<title>Gallery</title>\n"'<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">'"\n"
footer="<center>\nGallery generated by jrabnail</a>.\n</center>\n</body>\n</html>"

# Wildcard file testing. This is bullshit. Read at your own peril.
# There must be a better way to do this, and it probably fits on one line. 
userinput="$@"
if [ -z "$userinput" ]
  then 
    for file in *.jpg; do [ -a $file ] && jpg="*.jpg"; break; done 
    for file in *.JPG; do [ -a $file ] && JPG="*.JPG"; break; done 
    for file in *.gif; do [ -a $file ] && gif="*.gif"; break; done 
    for file in *.GIF; do [ -a $file ] && GIF="*.GIF"; break; done 
    for file in *.png; do [ -a $file ] && png="*.png"; break; done 
    for file in *.PNG; do [ -a $file ] && PNG="*.PNG"; break; done 
    for file in *.bmp; do [ -a $file ] && bmp="*.bmp"; break; done 
    for file in *.BMP; do [ -a $file ] && BMP="*.BMP"; break; done 
    if [ ! -n "$jpg$gif$png$bmp$JPG$GIF$PNG$BMP" ]
      then echo; echo "No image files present!"; echo; exit 1
      else input="$jpg $gif $png $bmp $JPG $GIF $PNG $BMP"
    fi
  else input="$userinput"
fi

# Generate indices and thumbnails
echo
echo "Creating thumbnails of type $output, quality $quality, width $width."
echo

if [ ! -e "thumbs" ]; then mkdir thumbs ; fi
idx=""

echo -e "Creating index.html" #debug
echo -e "$header $body" > "index$idx.html"

n=1

for file in $input
do
  if [ "$n" -gt "$pixperpage" ]
   then let "idx += 1"
     echo -e "$header $body" > "index$idx.html"
     echo -e "Creating index$idx.html" #debug
     n=1
  fi

  thumb=thumbs/`echo $file | { IFS="."; read a x ; echo $a ;}`_th.$output
  mogrify -auto-orient $file
  convert -verbose -quality $quality -thumbnail $width $file $thumb |
  { IFS=">x+ " ; read ; read ; read x x x x x width height x
  echo "<a href=\"$file\"><img alt=\"$file\" src=\"$thumb\" border=\"$border\" width=\"$width\" height=\"$height\"></a>" \
     >> "index$idx.html" ; }
  echo "$file --> $thumb"
  
  let "n += 1"

done

# Add navigation and finish indices
topen="<p><table width=\"95%\">\n<tr><td align=left>"
tclose="</td></tr>\n</table>"

indices="index*.html"
for file in $indices
do
  idx=`echo $file | { IFS="."; read a x ; echo ${a#index} ;}`
  next="index`{ let "idx +=1"; echo $idx ;}`.html"

  if [ "$idx" \> "1" ]
    then echo -e \
      "$topen<a href=\"index`{ let "idx -=1"; echo $idx ;}`.html\">Back</a>" \
        >> "$file"
      if [ -e "$next" ]
        then echo -e \
        "</td><td align=right><a href=\"$next\">Next</a>" >> "$file"
      fi
      echo -e "$tclose" >> "$file"

    else if [ "$idx" = "1" ]
      then echo -e "$topen<a href=\"index.html\">Back</a></td>" >> $file
        if [ -e "$next" ]
          then echo -e \
          "<td align=right><a href=\"$next\">Next</a>$tclose" >> $file
          else echo -e "<td align=right>$tclose" >> $file
        fi

      else if [ -z "$idx" ]
        then if [ -e "$next" ]
          then echo -e \
            "$topen</td><td align=right><a href=\"$next\">Next</a>$tclose" \
              >> $file
          else echo -e "<p>" >> $file
        fi
      fi
    fi  
  fi  
  echo -e "$footer" >> "$file"  
done

echo
echo "Finished!"
echo

exit 0
