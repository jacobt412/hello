#!/bin/bash

#Function to output message to StdErr
echo_stderr ()
{
    echo "$@" >&2
}
echo "Hello Cruel World ======== "$1
