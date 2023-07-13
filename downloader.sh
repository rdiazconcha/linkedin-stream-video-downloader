# Based on this code: https://github.com/zephinzer/blogpost-linkedin-video-downloader


#!/bin/sh
set -e;

# Search for this and manually copy it out from the request named `manifest(...`
# Should include the '-livemanifest.ism' ending suffix.
VIDEO_ID='b28edd6d-58ee-4035-84a0-7fb3064b7445/L4E6252a8167f867000-livemanifest.ism';
echo "VIDEO_ID: ${VIDEO_ID}";

DATA_FOLDER="data"
OUTPUT_FOLDER="output"
OUTPUT_PATH='./output/video.mp4';
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"
REFERER="https://www.linkedin.com/"
ORIGIN="https://www.linkedin.com"

if [ ! -d "$DATA_FOLDER" ]; then
  mkdir "$DATA_FOLDER"
  echo "Directory '$DATA_FOLDER' created."
else
  echo "Directory '$DATA_FOLDER' already exists."
fi

if [ ! -d "$OUTPUT_FOLDER" ]; then
  mkdir "$OUTPUT_FOLDER"
  echo "Directory '$OUTPUT_FOLDER' created."
else
  echo "Directory '$OUTPUT_FOLDER' already exists."
fi

# https://livectorprodmedia15-use2.licdn.com/b28edd6d-58ee-4035-84a0-7fb3064b7445/L4E6252a8167f867000-livemanifest.ism/manifest(format=m3u8-aapl-v3)

curl "https://livectorprodmedia15-use2.licdn.com/${VIDEO_ID}/manifest(format=m3u8-aapl-v3)" \
		-H "User-Agent: $USER_AGENT" \
		-H "Referer: $REFERER" \
		-H "Origin: $ORIGIN" --compressed \
		> ./data/quality_manifest;

QUALITY_LEVEL="$(cat ./data/quality_manifest | grep -v '#' | cut -f 2 -d '(' | cut -f 1 -d ')' | sort -n | tail -n 1)";
echo "QUALITY_LEVEL: ${QUALITY_LEVEL}";

curl "https://livectorprodmedia15-use2.licdn.com/${VIDEO_ID}/QualityLevels(${QUALITY_LEVEL})/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)" \
	-H "User-Agent: $USER_AGENT" \
	-H "Referer: $REFERER" \
	-H "Origin: $ORIGIN" --compressed \
	> ./data/video_manifest;

FRAGMENT_IDS=$(cat ./data/video_manifest | grep -v '#' | cut -f 2 -d '=' | cut -f 1 -d ',');
printf "${FRAGMENT_IDS}" > ./data/fragment_ids;
echo "N_FRAGMENTS: $(printf "${FRAGMENT_IDS}" | wc -l)";

echo "OUTPUT_PATH: ${OUTPUT_PATH}";
rm -rf ${OUTPUT_PATH};
touch ${OUTPUT_PATH};

while read FRAGMENT_ID; do
  echo "DOWNLOADING FRAGMENT[$FRAGMENT_ID]...";
  FULL_URL="https://livectorprodmedia15-use2.licdn.com/${VIDEO_ID}/QualityLevels(${QUALITY_LEVEL})/Fragments(video=${FRAGMENT_ID},format=m3u8-aapl-v3,audiotrack=audio_und)";
  echo "FULL URL IS: ${FULL_URL} \n\n\n";
  curl $FULL_URL \
    -H "Host: livectorprodmedia15-use2.licdn.com" \
    -H "User-Agent: $USER_AGENT" \
    -H "Accept: */*" \
    -H "Accept-Language: en-US,en;q=0.5" \
    -H "Accept-Encoding: gzip, deflate, br" \
    -H "Referer: $REFERER" \
    -H "Origin: $ORIGIN" \
     >> ${OUTPUT_PATH};
done <data/fragment_ids;

# https://livectorprodmedia15-use2.licdn.com/b28edd6d-58ee-4035-84a0-7fb3064b7445/L4E6252a8167f867000-livemanifest.ism/QualityLevels(3200000)/Fragments(video=295746030,format=m3u8-aapl-v3,audiotrack=audio_und)