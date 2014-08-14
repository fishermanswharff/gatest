#!/bin/sh

########################## Developed by Christopher Spence at Educational Media Solutions, 2012 #################################
# This compression scripts uses the <!-- @BEGIN CSS MINIFY --> <!-- @END CSS MINIFY --> <!-- @BEGIN JS MINIFY --> and			#
# <!-- @END JS MINIFY--> directives in the specified index source file to determine which css and javascript files to compress.	#
# The last portion of the script replaces the links to dev css and js files with links to the minified files.					#
#																																#
#																																#
# Use:																															#
# ./ems-compressor 																												#
#	/Users/spencech/Desktop/yuicompressor-2.4.6/build/yuicompressor-2.4.6.jar 			## YUI compressor						#
#	/Users/spencech/Desktop/projects/project/src 										## Project source root (input)			#
#	/Users/spencech/Desktop/projects/project/release 									## Release directory root (input)		#
#	/Users/spencech/Desktop/projects/project/src/html/index.html 						## HTML source index file (input)		#
#	/Users/spencech/Desktop/projects/project/release/index.html 						## Release index file (output)			#
#	/Users/spencech/Desktop/projects/project/release/css/styles.min.css 				## Minified css file (output			#
#	/Users/spencech/Desktop/projects/project/release/js/scripts/script.min.js 			## Minified js file (output)			#
#################################################################################################################################


args=($@);

COMPRESSOR=${args[0]};
PROJECT_DIRECTORY=${args[1]};
RELEASE_DIRECTORY=${args[2]};
INPUT_FILE=${args[3]};
HTML_OUTPUT=${args[4]};
CSS_OUTPUT=${args[5]};
JS_OUTPUT=${args[6]};
STAGING_DIRECTORY=${args[7]};
CSS_HREF=$(echo $CSS_OUTPUT | sed "s|$RELEASE_DIRECTORY\/||g");
JS_SRC=$(echo $JS_OUTPUT | sed "s|$RELEASE_DIRECTORY\/||g"); 


listing_css=false;
listing_js=false;
css_begin="BEGIN CSS MINIFY";
css_end="END CSS MINIFY";
js_begin="BEGIN JS MINIFY";
js_end="END JS MINIFY";

exec 3<&0;
exec 0<$INPUT_FILE;

declare -a css=();
declare -a js=();

echo "Beginning Javascript and CSS minification...";
echo "Extracting files..."

while read line
	do
		if [[ "$line" == *$css_begin* ]]; then
 		listing_css=true;
 		continue;
		fi
		if [[ "$line" == *$css_end* ]]; then
 		listing_css=false;
		fi
		
		if [[ "$line" == *$js_begin* ]]; then
 		listing_js=true;
 		continue;
		fi
		if [[ "$line" == *$js_end* ]]; then
 		listing_js=false;
		fi
		
		if $listing_css; then
		
			src=$(echo "$line" | sed 's/<link.*href="\(.*\)".*\/>/\1/');
			css=("${css[@]}" "${src}");
		fi
		if $listing_js; then
			src=$(echo "$line" | sed 's/<script.*src="\(.*\)".*><\/script>/\1/');
			js=("${js[@]}" "${src}");
		fi
	done

exec 0<&3


cd $RELEASE_DIRECTORY;
if [ -e "$HTML_OUTPUT" ]; then
	echo "Removing previously compiled library";
    rm $HTML_OUTPUT
fi
if [ -e "$JS_OUTPUT" ]; then
	echo "Removing previously compiled library";
    rm $JS_OUTPUT
fi
if [ -e "$CSS_OUTPUT" ]; then
	echo "Removing previously compiled library";
    rm $CSS_OUTPUT
fi

echo "Beginning CSS compression";

let count=${#css[@]};

for ((i=0;i<count;i++))
	do
		sourcefile=${css[$i]};
		path=$STAGING_DIRECTORY"/"${sourcefile%/*};
		file=${sourcefile##*/};	
		filename=${file%%.*};
		cd ${path};
		min_filename=$(echo "$filename-min.css");
		echo "... Compressing $file to $min_filename";
		java -jar $COMPRESSOR $path/$file -o $RELEASE_DIRECTORY/$min_filename;
		cat $RELEASE_DIRECTORY/$min_filename >> $RELEASE_DIRECTORY/._compressTemp.file;
		rm $RELEASE_DIRECTORY/$min_filename;
	done
	
	echo "Compiling CSS library...";
	
	css_output_dir=${CSS_OUTPUT%/*};
	mkdir -p $css_output_dir;
	cat $RELEASE_DIRECTORY/._compressTemp.file > $CSS_OUTPUT;
	echo "Cleaning up...";
	rm $RELEASE_DIRECTORY/._compressTemp.file;
	echo "CSS compilation complete"

echo "---";
echo "Beginning JS compression";
let count=${#js[@]};

for ((i=0;i<count;i++))
	do
		sourcefile=${js[$i]};
		path=$PROJECT_DIRECTORY"/"${sourcefile%/*};
		file=${sourcefile##*/};	
		filename=${file%%.*};
		cd ${path};
		min_filename=$(echo "$filename-min.js");
		echo "... Compressing $file to $min_filename";
		java -jar $COMPRESSOR $path/$file -o $RELEASE_DIRECTORY/$min_filename;
		cat $RELEASE_DIRECTORY/$min_filename >> $RELEASE_DIRECTORY/._compressTemp.file;
		rm $RELEASE_DIRECTORY/$min_filename;
	done
	
	echo "Compiling JS library...";
	
	js_output_dir=${JS_OUTPUT%/*};
	mkdir -p $js_output_dir;
	cat $RELEASE_DIRECTORY/._compressTemp.file > $JS_OUTPUT;
	echo "Cleaning up...";
	rm $RELEASE_DIRECTORY/._compressTemp.file;
	echo "JS Compilation Complete";
	echo "---";

echo "Removing development script and style links from index.html page...";
cat $INPUT_FILE | sed -n '1h;1!H;${;g;s|<!-- @BEGIN CSS MINIFY -->.*<!-- @END CSS MINIFY -->|<link rel="stylesheet" href="'"${CSS_HREF}"'"\/>|g;p;}' | sed -n '1h;1!H;${;g;s|<!-- @BEGIN JS MINIFY -->.*<!-- @END JS MINIFY -->|<script type="text/javascript" src="'"${JS_SRC}"'"></script>|g;p;}'  > $HTML_OUTPUT;
echo "Minification Complete!";
