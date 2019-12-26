!/bin/bash
curl -X POST -H "Expect:" http://root:1234@localhost:8042/instances --data-binary @./incoming/$1
if [ $? -eq 0 ]
then
  rm ./incoming/$1
else
  mv ./incoming/$1 ./failed/$1
fi