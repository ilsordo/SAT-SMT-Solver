#/bin/sh
./resol -test1 $1 > test/mytest ; minisat test/mytest test/out ; time ./resol test/mytest
