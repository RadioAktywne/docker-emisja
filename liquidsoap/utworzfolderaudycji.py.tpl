import os

#---SED goes here
uid=33 #not here, tu standardowo www-data
gid=0
#---

def utworz(sciezka):
	try:
		os.mkdir(sciezka)
		print(sciezka +" Utworzony")
		os.chown(sciezka,uid,gid)
		os.chmod(sciezka,0o775)

	except FileExistsError:
		print(sciezka + " Juz istnieje")
	

def utworz_folder_audycji(slur):
	path = "/srv/ra/audycje/"+slur

	utworz(path)
	utworz(path+"/powtorka")
	utworz(path+"/powtorka/powtorka_puszki")
	utworz(path+"/archiwum")
	utworz(path+"/puszka")

plik = open("/home/liquidsoap/slury", 'r')
slury = plik.readlines()
plik.close()
for slur in slury:
	if "Playlista" not in slur:
		slur = slur.replace('\n','')
		utworz_folder_audycji(slur)
