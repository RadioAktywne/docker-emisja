FROM debian:8

ARG conf

#tworzenie usera/grupy liquidsoap
#tu trzeba wrzucic uid i gid usera liquidsoap z systemu
RUN groupadd -g 123 liquidsoap
RUN useradd -u 115 -g 123 -s /bin/bash liquidsoap

#zainstaluj liquidsoap
RUN apt-get update && apt-get install -y liquidsoap

#instalacja pythona i podstawowych rzeczy
RUN apt-get install -y python3 curl cron git vim socat

#instalacja pip3
RUN curl https://bootstrap.pypa.io/pip/3.4/get-pip.py | python3

#instalacja pakietów pythonowych
RUN pip3 install httplib2 python-crontab
RUN pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib
RUN pip3 install oauth2client

#kopjuj ra.liq do /etc/liquidsoap
COPY --chown=liquidsoap:liquidsoap ra.liq /etc/liquidsoap/ra.liq
COPY --chown=liquidsoap:liquidsoap config.liq.$conf /etc/liquidsoap/config.liq


#tworzy /home/liquidsoap
RUN mkdir /home/liquidsoap
RUN chown liquidsoap:liquidsoap /home/liquidsoap

#kopiuj skrypty
COPY --chown=liquidsoap:liquidsoap liquidsoap/ /home/liquidsoap/
RUN chmod +x /home/liquidsoap/*.sh

#zmien gid w /srv/utworzfolderaudycji na liquidsoap
USER liquidsoap
RUN sed -e "s/gid=0/gid=`id -g liquidsoap`/" /home/liquidsoap/utworzfolderaudycji.py.tpl > /home/liquidsoap/utworzfolderaudycji.py

#ustaw timezone
USER root
RUN ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

#wpisy do crona
COPY cron.tab /tmp/cron.tab
RUN cat /tmp/cron.tab >> /etc/crontab
RUN rm /tmp/cron.tab

#skrypt startowy - (sync, utworz foldery audycji, start crona i liquidsoapa)

WORKDIR /home/liquidsoap
CMD ["sh","./emisja.sh"]
