%include "config.liq"

set("server.telnet",true)
set("server.telnet.bind_addr","127.0.0.1")
set("server.telnet.port",1234)
set("server.socket",true)
set("server.socket.path","/home/liquidsoap/socket")


set ("log.file.path", "/var/log/liquidsoap/radio.log")
set("init.daemon.pidfile.path", "/var/run/liquidsoap/pi.pid")


#-------INPUTY---------
#Live - Master

live=input.harbor("live", user="source", password=input_pass, port=8004)
testy=input.harbor("testy", user="source", password=input_pass, port=8019)
studio=input.harbor("studio", user="source", password=input_pass, port=8009, buffer=7.)
qastream=input.harbor("qastream", user="source", password=input_pass, port=8005)

#Playlista
playlista_dzien = playlist(reload=86400,"/srv/ra/playlista/dzien")
playlista_noc = playlist(reload=86400,"/srv/ra/playlista/noc")

#safe konieczny zeby nie wyrzucalo "that source is fallable" - dalem jakiegos randomowego jingla
safe = single("/srv/ra/start.wav")
muzyka = switch([({06h00m - 22h00m},playlista_dzien),({ true },playlista_noc)])
muzyka = fallback([muzyka,safe])

#Jingle ---- to też
jingle = playlist(mode="random", reload=86400, "/srv/ra/jingle")
silentium = single("/srv/5minsilence.ogg")

#miks muzyki z jinglami
muzyka = rotate(weights=[1,5], [jingle, muzyka])
#dalej mozna rotejta z promosami
muzyka = normalize(target=-17., window = 0.03, gain_min= -32., gain_max = 0., muzyka)

#--AUDYCJE

#--AUDYCJE

radio=fallback(track_sensitive=false,
[switch(track_sensitive= false,[
#--SWITCH

#--SWITCH
]),
muzyka])


full=fallback(track_sensitive=false, [live,radio])
testo=fallback(track_sensitive=false, [testy,silentium])
qa=fallback(track_sensitive=false, [qastream,silentium])
#------------OUTPUTY

output.icecast(%mp3(bitrate=256), 
	icy_metadata="true", 
	encoding="UTF-8", 
	id="ramp3", 
	fallible=true, 
	host=output_host, 
	port=8000, 
	password=output_pass, 
	mount="ramp3", 
	genre="", 
	description="Radio Aktywne", 
	name="Radio Aktywne", 
	url="http://radioaktywne.pl/", 
	full)

output.icecast(%vorbis(quality=0.8), 
	icy_metadata="false", 
	encoding="UTF-8", 
	id="raogg", 
	fallible=true, 
	host=output_host, 
	port=8000, 
	password=output_pass, 
	mount="raogg", 
	genre="", 
	description="Radio Aktywne", 
	name="Radio Aktywne", 
	url="http://radioaktywne.pl/", 
	full)

output.icecast(%mp3(bitrate=256), 
	icy_metadata="true", 
	encoding="ISO-8859-2", 
	id="ramp3koncert", 
	fallible=true, 
	host=output_host, 
	port=8000, 
	password=output_pass, 
	mount="ramp3koncert", 
	genre="", 
	description="Radio Aktywne", 
	name="Radio Aktywne", 
	url="http://radioaktywne.pl/", 
	testo)

output.icecast(%mp3(bitrate=256), 
	icy_metadata="true", 
	encoding="ISO-8859-2", 
	id="qa", 
	fallible=true, 
	host=output_host, 
	port=8000, 
	password=output_pass, 
	mount="qa", 
	genre="", 
	description="Radio Aktywne", 
	name="Radio Aktywne", 
	url="http://radioaktywne.pl/", 
	qa)



time_stamp = '%m-%d-%Y, %H:%M:%S'

output.file(%vorbis, "/srv/ra/master/master_#{time_stamp}.ogg", fallible=true, start=true, reopen_when={0m}, live)
#output.icecast(%vorbis, icy_metadata="true", encoding="UTF-8",id="nagrywanie",fallible=true,host="localhost",port=8006,password=input_pass,mount="nagrywanie",studio)


dyn_sources = ref []

out = output.file(%vorbis(quality=0.8))

def create_output(uri) =
  output = out(uri, append=true, fallible=true, studio)
  dyn_sources := 
      list.append( [(uri,output)],
                    !dyn_sources )
  "Done!"
end

def destroy_output(uri) = 
  def parse_list(ret, current_element) = 
    matching_sources = fst(ret)
    remaining_sources = snd(ret)

    current_uri = fst(current_element)
    if current_uri == uri then
      (list.append( [snd(current_element)], 
                     matching_sources),
       remaining_sources)
    else
      (matching_sources,
       list.append([current_element], 
                    remaining_sources))
    end
  end
    
  result = list.fold(parse_list, ([], []), !dyn_sources)
  matching_sources = fst(result)
  remaining_sources = snd(result)

  dyn_sources := remaining_sources

  if list.length(matching_sources) == 0 then
    "Error: no matching sources!"
  else
    list.iter(source.shutdown, matching_sources)
    "Done!"
  end
end

server.register(namespace="dynamic_file",
                description="Start a new dynamic file output.",
                usage="start <uri>",
                "start",
                create_output)
server.register(namespace="dynamic_file",
                description="Stop a dynamic file output.",
                usage="stop <uri>",
                "stop",
                destroy_output)


#out = nagryw
