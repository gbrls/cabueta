#!/bin/sh

awscurl --verbose --service lambda -X POST "`$2`" -d "`cat $1`"
