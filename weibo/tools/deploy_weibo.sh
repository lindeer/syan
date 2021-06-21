#!/bin/bash

hexo g
mv public/index.html public/weibo
rm -rf ../public/weibo ; cp -r public/weibo ../public
