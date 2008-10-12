#!/bin/bash

CURL="curl -#"
URLBASE=http://localhost:8080
ERRORS=no

do_test () {
    test_name=$1
    shift
    echo "doing test $test_name"
    $CURL -o out.$test_name -b cookies.txt "$@"
    if diff "expected.$test_name" "out.$test_name" ; then
	true
    else
	echo "differences in expected.$test_name and out.$test_name"
	ERRORS=yes
    fi
}

do_dump_test () {
    version=$1
    shift
    do_test dump${version} -F "lesson=bla" -L $URLBASE/dump
}

do_list_tests () {
    version=$1
    shift
    for ((i=0 ; i <= $version ; ++i )) ; do
	do_test list${i}to${version} -F "lesson=bla" -F "version=$i" -L $URLBASE/list
    done
}

do_version_tests () {
    version=$1
    do_dump_test $version
    do_list_tests $version
    if [ $ERRORS = yes ] ; then
	exit 1
    fi
}

do_upload_tests () {
    version=$1
    echo "uploading $version"
    $CURL -o /dev/null -b cookies.txt -F "lesson=bla" -F "data=@upload.${version}.xml" -L $URLBASE/upload
    do_version_tests $version
}

do_update_tests () {
    version=$1
    echo "updating $version"
    $CURL -o /dev/null -b cookies.txt -F "lesson=bla" -F "data=@update.${version}.xml" -L $URLBASE/update
    do_version_tests $version
}

rm cookies.txt

echo "login"
$CURL -o /dev/null -c cookies.txt -F "email=test@example.com" -F "admin=True" -F "action=Login" -L $URLBASE/_ah/login

do_version_tests 0

count=1
while true ; do
    if [ -f upload.${count}.xml ] ; then
	do_upload_tests $count
    elif [ -f update.${count}.xml ] ; then
	do_update_tests $count
    else
	echo "successful"
	exit 0
    fi
    count=$((count+1))
done
