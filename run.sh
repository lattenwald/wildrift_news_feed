#!/bin/sh
exec docker run -p 4093:4093 -i -t wildrift_news_feed $@
