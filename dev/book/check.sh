#!/bin/bash
yamllint manifest.yaml
../bin/book manifest check manifest.yaml
c=$(cat manifest.yaml | grep '}}}' | wc -l)
if ! [ $c -eq 0 ]; then
    echo "too many curly braces - app may not work!"
	cat manifest.yaml | grep '}}}'
fi
c=$(cat manifest.yaml | grep '{{{' | wc -l)
if ! [ $c -eq 0 ]; then
    echo "too many curly braces - app may not work!"
	cat manifest.yaml | grep '{{{'
fi
