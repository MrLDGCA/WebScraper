#!/bin/bash
# Author	: L. D. G. Charith Akalanka
# Date		: 2020-01-29
# Purpose	: 
#	To download the "picture of the day" from space.com, for any single date or a range of dates



# This function downloads all the .html pages
siteGrabber(){

	# Create a temp folder to hold the scrap files
	[ -d .temp ] || mkdir .temp

	# Download the "Image of the day" page
	if [ ! -e ./.temp/34-image-day.html ]; then
		echo -e "_____ Searching Space.com _____\n"
		wget -q https://www.space.com/34-image-day.html -P .temp/

	# Identifying the number of pages
		pageCount=$(grep "^Page 1 of " ./.temp/34-image-day.html | sed "s/ /\n/g" | grep ":$" | sed "s/://g")

	# Downloading all the pages
		for ((i=1; i<=$pageCount; i++)); do
			[ -e ./.temp/$i.html ] || wget -q https://www.space.com/34-image-day/$i.html -P .temp/
		done
	fi
}

# This function deletes the /temp folder
cleanTemp(){
	rm -r ./.temp
}

# This function download the image, but only if its not already in the folder
imgDownloader(){
	# Check if an image is available to download
	if [ $noImage -eq 0 ]; then

		if [ ! -e "$imgName" ]; then
			echo -e "Downloading  \"$imgName\" \n"
			wget -q -O "$imgName" $imgURL
			echo -e "__________ Download Successful __________ \n\n"
		else
		# If the image was downloaded earlier, its information will be displayed
			echo -e "========== IMAGE TITLE: $title ========== \n"
			echo -e "DESCRIPTION: $imgDesc \n"
			echo -e "IMAGE CREDIT: $imgCredit \n\n\n"
		fi
	fi
}


# This function reads the fields related to the image
# Title, Description, Credits
isolate(){
	# change the format of the date given to $1 from YYYY-MM-DD to
	# date, month day, year

	searchYear=$(date -d $1 +%Y)
	searchMonth=$(date -d $1 +%B)
	searchDate=$(date -d $1 +%-d)
	searchDay=$(date -d $1 +%A)
	echo "______________________________________________________"
	echo "Searching date: "
	echo -e "\t\t$searchDay, $searchMonth $searchDate, $searchYear"
	echo

	# Search all .html files for the page with the searching date
	# save the body of the page to section.txt

	grep "$searchMonth $searchDate[.,] $searchYear" ./.temp/*.html | sed "s/<div\ id=\"article-body\"\ class=\"text-copy\ bodyCopy\ auto\">/<div\ id=\"article-body\"\ class=\"text-copy\ bodyCopy\ auto\">\n/g" | grep "$searchMonth $searchDate[.,] $searchYear" > .temp/section.txt

	if [ ! -s ./.temp/section.txt ]; then
		noImage=1
		echo -e "==========||   No picture found   ||==========\n"

	else
	# Isolate the image name from section.txt
		noImage=0

		title=$(sed "s/<h/\n<h/g" ./.temp/section.txt | grep -m1 "$searchMonth $searchDate[.,] $searchYear: </strong>"  | sed "s/<\/h/\n<\/h/g" | grep "<h" | sed "s/<\/\?[^>]\+>//g" | sed "s/&nbsp;//g ; s/'//g" )
		#echo "Title: $title"

		# Isolate the image url from section.txt
		imgURL=$(sed "s/data-original-mos=/\ndata-original-mos=/g" ./.temp/section.txt | grep -m1 "$searchMonth $searchDate[.,] $searchYear: </strong>" | sed "s/\ /\n/g" | grep -m1 "data-original-mos" | sed "s/\"\ /\"\n/g" | grep "data-original-mos" | sed "s/=/\n/g" | grep "^\"" | sed "s/\"//g")
		#echo "URL: $imgURL"

		# Isolate the file format from the URL (jpg, gif)
		imgType=$( echo $imgURL | sed "s/\./\n/g" | tail -1 )
		#echo "Type: $imgType"

		imgName=$title.$imgType
		#echo "File name: $imgName"

		# Isolate the image description from section.txt
		imgDesc=$(sed "s/<strong>/\n<strong>/g" ./.temp/section.txt | grep -m1 "$searchMonth $searchDate[.,] $searchYear: </strong>" | sed "s/<br>/<\/p>/g ; s/<\/strong>/<\/strong>\n/g" | grep -m1 "</p>" | sed "s/<\/p>/<\/p>\n/g" | grep -m1 "<\/p>" | sed "s/<\/\?[^>]\+>//g" | sed "s/&mdash;/-/g ; s/&nbsp;/\n/g" )
		#echo "Desc: $imgDesc"

		# Isolate the image credits
		imgCredit=$( sed "s/(Image\ credit:/\n(Image\ credit:/g" ./.temp/section.txt | grep -m1 "$searchMonth $searchDate[.,] $searchYear: </strong>" | sed "s/<\/span>/\n<\/span>/g" | grep -m1 "Image credit" | sed "s/<\/\?[^>]\+>//g" | sed "s/(Image\ credit://g ; s/)//g ; s/\&amp\;/\&/g")
		#echo "Credit: $imgCredit"

	fi
}
# =============================== MAIN ===================================================

echo "======================================"
echo "     Space.com Picture of the day     "
echo "======================================"
echo


# no paramters are provided by the user
# display an instruction page
if [ $# -lt 1 ]; then
	echo "This script can search the spcae.com archive and retrieve"
	echo "the picture-of-the-day posted on any date specified"
	echo
	echo "__________ Operation Modes __________"
	echo
	echo "1. ~$ ./WebScraper.sh YYYY-MM-DD"
	echo -e "\tDownload the image for the specified date"
	echo
	echo "2. ~$ ./WebScraper.sh YYYY-MM-DD YYYY-MM-DD"
	echo -e "\tDownload images for every day within the range"
	echo
	echo "3. ~$ ./WebScraper.sh –t YYYY-MM-DD"
	echo -e "\tRetrieve only the title of the image for the specified date"
	echo
	echo "4. ~$ ./WebScraper.sh –d YYYY-MM-DD"
	echo -e "\tRetrieve only the description of the image for the specified date"
	echo
	echo "5. ~$ ./WebScraper.sh –c YYYY-MM-DD"
	echo -e "\tRetrieve only the credits of the image for the specified date"
	echo
else
	# check connectivity
	echo -e "_____ Conntecting to Space.com _____\n"
	if [ $( HEAD https://www.space.com/34-image-day.html | grep '200\ OK' | wc -l) -eq 0 ]; then
		echo "Space.com is currently unavailable"

	else
		# Download the web pages
		siteGrabber

		# Checking the options selected
		while [ -n $1 ]; do
		case "$1" in
		-t) 	isolate $2
			if [ $noImage -eq 0 ]; then
				echo "IMAGE TITLE: $title"
				echo
			fi
			break;;

		-d) 	isolate $2
			if [ $noImage -eq 0 ]; then
				echo "IMAGE DESCRIPTION: $imgDesc"
				echo
			fi
			break;;

		-c) 	isolate $2
			if [ $noImage -eq 0 ]; then
				echo "IMAGE CREDITS: $imgCredit"
			fi
			break;;

		*)
			# 1 date is provided as a parameter
			if [ $# -eq 1 ]; then
				isolate $1
				imgDownloader
				echo "Finished"
				echo "======================================================================="
				echo


			# 2 days given
			elif [ $# -eq 2 ]; then
				# figuring out the older date and newr date
				if [ $(date -d $1 +%s) -gt $(date -d $2 +%s) ]; then
					young=$1
					old=$2
				else
					young=$2
					old=$1
				fi

				# Running the program for evey day since the oldest
				while [ ! $(date -d $old +%s) -gt $(date -d $young +%s) ]; do
					isolate $old
					imgDownloader
					old=$(date -d "$old + 1 day" +%F)
				done
				echo "Finished"
				echo "======================================================================="
				echo

			fi
			break;;


		esac
		done
		# Delete the temp folder before closing the script
		#cleanTemp
	fi
fi

