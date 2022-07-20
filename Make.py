import os

make = """touch .depend
sudo chmod 777 *
sudo chmod 777 /*
sudo make
"""

parser_good = """./ptucc_scan < FLCode/sample001.fl
./ptucc < FLCode/sample001.fl > SourceCode/sample001.c
./ptucc_scan < FLCode/sample002.fl
./ptucc < FLCode/sample002.fl > SourceCode/sample002.c
./ptucc_scan < FLCode/sample003.fl
./ptucc < FLCode/sample003.fl > SourceCode/sample003.c
./ptucc_scan < FLCode/sample004.fl
./ptucc < FLCode/sample004.fl > SourceCode/sample004.c
./ptucc_scan < FLCode/sample005.fl
./ptucc < FLCode/sample005.fl > SourceCode/sample005.c
./ptucc_scan < FLCode/sample006.fl
./ptucc < FLCode/sample006.fl > SourceCode/sample006.c
./ptucc_scan < FLCode/correct1.fl
./ptucc < FLCode/correct1.fl > SourceCode/correct1.c
./ptucc_scan < FLCode/correct2.fl
./ptucc < FLCode/correct2.fl > SourceCode/correct2.c
"""

parser_bad = """./ptucc_scan < FLCode/bad001.fl
./ptucc < FLCode/bad001.fl > SourceCode/bad001.c
./ptucc_scan < FLCode/bad002.fl
./ptucc < FLCode/bad002.fl > SourceCode/bad002.c
./ptucc_scan < FLCode/bad003.fl
./ptucc < FLCode/bad003.fl > SourceCode/bad003.c
./ptucc_scan < FLCode/bad004.fl
./ptucc < FLCode/bad004.fl > SourceCode/bad004.c
./ptucc_scan < FLCode/bad005.fl
./ptucc < FLCode/bad005.fl > SourceCode/bad005.c
./ptucc_scan < FLCode/wrong1.fl
./ptucc < FLCode/wrong1.fl > SourceCode/wrong1.c
./ptucc_scan < FLCode/wrong2.fl
./ptucc < FLCode/wrong2.fl > SourceCode/wrong2.c
"""

complile = """gcc -Wall -std=c11 -o Executables/sample001 SourceCode/sample001.c
gcc -Wall -std=c11 -o Executables/sample002 SourceCode/sample002.c
gcc -Wall -std=c11 -o Executables/sample003 SourceCode/sample003.c
gcc -Wall -std=c11 -o Executables/sample004 SourceCode/sample004.c
gcc -Wall -std=c11 -o Executables/sample005 SourceCode/sample005.c
gcc -Wall -std=c11 -o Executables/sample006 SourceCode/sample006.c
gcc -Wall -std=c11 -o Executables/correct1 SourceCode/correct1.c
gcc -Wall -std=c11 -o Executables/correct2 SourceCode/correct2.c
"""

execute = """./Executables/sample001
./Executables/sample002
./Executables/sample003
./Executables/sample004
./Executables/sample005
./Executables/sample006
./Executables/correct1
./Executables/correct2
"""

print ("\n----------------------------------------------\n")
print ("\nCompling the parsers :\n")
os.system (make)

print ("\n----------------------------------------------\n")
print ("\nParsing the good samples:\n")
os.system (parser_good)

print ("\n----------------------------------------------\n")
print ("\nParsing the bad samples:\n")
os.system (parser_bad)

print ("\n----------------------------------------------\n")
print ("\nCompiling the good samples:\n")
os.system (complile)

print ("\n----------------------------------------------\n")
print ("\nRunning the programs:\n")
os.system (execute)
