#/bin/bash
# returning a user_name indicates the server is alive (this routing does not need a token)
#ok=$(curl -s -XPOST https://dev.practable.io/book/api/v1/users/unique | jq 'has("user_name")' 2>&1 )
#if [ ${ok:0:4} != "true" ]
#then
#   echo "health is BAD:"
   curl -s -XPOST https://dev.practable.io/book/api/v1/users/unique
#fi

