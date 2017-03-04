#! /usr/bin/python

import json
import csv
import random

for i in range(1, 10):
    target = open("itemIdsRandom" + str(i) + ".txt", 'w')
    with open('itemIdsEntire3_correct.txt', "rt") as f:
        for line in f:
            x = line.split(',')
        print len(x)
        random.shuffle(x)
        print len(x)

        j = 0
        for itemId in x:
        	target.write(str(itemId))
        	target.write("\n")
        	j = j+1
        print j
    print (str(i) + " file finished.")
            
    target.close()
