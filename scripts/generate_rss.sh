#!/bin/bash

# Generate RSS by meta.json

set -e;

SCRIPTS=$(dirname "$0");

# Getting basic info
TITLE=$(jq -r '.title' config.json);
echo ">>> Title set to \"$TITLE\"";
DESC=$(jq -r '.description' config.json);
echo ">>> Description set to \"$DESC\"";
LINK=$(jq -r '.link' config.json);
echo ">>> Link set to \"$LINK\"";
META=$(jq -r '.meta' config.json);
echo ">>> Meta set to \"$META\"";
MODE=$(jq -r '.mode' config.json);
echo ">>> Mode set to $MODE";
if [ $MODE == "js" ]; then
	POST=$(jq -r '.post' config.json);
fi
OUTPUT=$(jq -r '.feed' config.json);
echo ">>> Output set to \"$OUTPUT\"";

# Find markdown.sh
echo ">>> Finding markdown.sh";
if [ -f $SCRIPTS/markdown.sh ]; then
	echo ">>> Found existing markdown.sh";
else
	echo ">>> No existing markdown.sh found, getting one via curl...";
	curl https://raw.githubusercontent.com/chadbraunduin/markdown.bash/master/markdown.sh -o $SCRIPTS/markdown.sh;
fi

# Generate items
ITEMS="";
# https://starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
POSTS=$(jq -r '.posts' $META);
for ROW in $(echo "${POSTS}" | jq -r '.[] | @base64'); do
	_jq() {
		echo ${ROW} | base64 --decode | jq -r ${1};
	}

	POST_TITLE=$(_jq '.title');
	echo ">>> Adding $POST_TITLE";
	POST_DESC=$(cat $(_jq '.file') | /bin/bash $SCRIPTS/markdown.sh);
	if [ $MODE == "js" ]; then
		POST_LINK="$LINK/$POST?post=$(_jq '.id')";
	fi
	ITEMS="$ITEMS<item><title>$POST_TITLE</title><description>$POST_DESC</description><link>$POST_LINK</link></item>";
done

FEED="<?xml version=\"1.0\" encoding=\"UTF-8\" ?><rss version=\"2.0\"><channel><title>$TITLE</title><link>$LINK</link><description>$DESC</description>$ITEMS</channel></rss>";

echo $FEED | tee $OUTPUT;