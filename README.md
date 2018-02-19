# Intro

> based on https://github.com/SingularitiesCR/hadoop-docker

> use hadoop 2.8.3 

> start yarn by default

> set locale to en_US.UTF-8

> set timezone=cst(Asia/Shanghai)

# Notes

## HDFS_USER environment var

when HDFS_USER=root, it would be easy to use, 
otherwise we have lot of things to do to make hadoop running correctly.
such as hadoop's permissions, passwordless ssh login settings etc.

## Docker Compose

> the container which yarn's master in need to know all of slaves' hostname ( or ip ), so take a look the `slaves` file in `volumes` folder

> if you change the `hostname` of datanode or slave container, just make sure those are same with name in the `slaves` file
