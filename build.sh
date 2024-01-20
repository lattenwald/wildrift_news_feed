#!/bin/sh
docker pull elixir:alpine
docker build --network host -t wildrift_news_feed -t lattenwald/wildrift_news_feed .
