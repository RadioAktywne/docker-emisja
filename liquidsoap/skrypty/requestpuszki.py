import os
import subprocess
import argparse
import pathlib

import time

parser = argparse.ArgumentParser()
parser.add_argument("slur")
args = parser.parse_args()

timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
logfile_name = "log_" + time.strftime("%Y_%m")


path1 = "/srv/ra/audycje/"+args.slur+"/puszka/"
req = []
lista = os.listdir(path1)
lista.sort()
if lista:
	for plik in lista:
		subprocess.call(["/home/liquidsoap/requestpush.sh", args.slur, path1+plik])
		with open("/home/liquidsoap/request_"+args.slur+".log", "r") as f:
			req.append(f.readline())

		#edit 29.01.2021 H. Biedka - logowanie do pliku
		file_ascii = plik.encode("ascii","ignore").decode()
		csv_line = timestamp+";"+args.slur+";"+file_ascii
		with open("/srv/ra/log_puszek/"+logfile_name+".csv","a") as f:
			try:
				f.write(csv_line+"\n")
			except:
				pass


with open("/home/liquidsoap/queue_"+args.slur, "w") as f:
	f.writelines(req)
