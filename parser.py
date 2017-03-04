#! /usr/bin/python

import json

target = open("itemIdsEntire3_correct.txt", 'w')

data = {}
with open('filteredDataEntire') as f:
#	for line in f:
#data.append(json.loads(line))
#		data['']
#print(data)

	i = 0
	for index, val in enumerate(f):
		val_dict = json.loads(val)
#		print "%d: %s" % (index, val)
#		print val_dict['result']['data']
#		print len(val_dict['result']['data'])
		for oneEntry in val_dict['result']['data']:
			if oneEntry['type'] == "ITEMPRODUCT":
#					print oneEntry['itemId']
				target.write(",")
				target.write(str(oneEntry['itemId']))
				i = i+1

#		print val['result']#This is throwing: string indices must be integers, not str
#	break

# this is not working because json_string is still a string!! Not a JSON object.
#		json_string = json.dumps(val)
#		print json_string['result']



#for i in data['result']['data']:
#for i in data['result']:
#	if i['type'] == "ITEMPRODUCT":
#		print i['itemId']
#	print loadedFile['result']['data']
print i
target.close()
