FROM centos:7
MAINTAINER yldgio <yldgio@gmail.com>
RUN yum -y update;yum clean all

COPY jdk-8u92-linux-x64.rpm /home/

RUN rpm -Uvh /home/jdk-8u92-linux-x64.rpm && \
    rm -f /home/jdk-8u92-linux-x64.rpm

ENV JAVA_HOME /usr/java/jdk1.8.0_92


##########################################################
# Download and unpack soapui
##########################################################

RUN groupadd -r soapui && useradd -r -g soapui -m -d /home/soapui soapui
COPY SoapUI-5.2.1-linux-bin.tar.gz /home/
RUN yum -y install tar && \
    tar -xzf /home/SoapUI-5.2.1-linux-bin.tar.gz -C /home/soapui
#RUN yum -y remove tar
RUN rm -f /home/SoapUI-5.2.1-linux-bin.tar.gz

RUN chown -R soapui:soapui /home/soapui
RUN find /home/soapui -type d -execdir chmod 770 {} \;
RUN find /home/soapui -type f -execdir chmod 660 {} \;

RUN yum -y install curl && \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64" && \
    chmod +x /usr/local/bin/gosu

############################################
# Setup MockService runner
############################################

USER soapui
ENV HOME /home/soapui
ENV SOAPUI_DIR /home/soapui/SoapUI-5.2.1
ENV SOAPUI_PRJ /home/soapui/soapui-prj
ENV MOCK_SERVICE_PORT 54321

############################################
# Add customization sub-directories (for entrypoint)
############################################

ADD docker-entrypoint-initdb.d  /docker-entrypoint-initdb.d
ADD soapui-prj                  $SOAPUI_PRJ

############################################
# Expose ports and start SoapUI mock service
############################################
USER root


COPY docker-entrypoint.sh /
RUN chmod 700 /docker-entrypoint.sh
RUN chmod 770 $SOAPUI_DIR/bin/*.sh

RUN chown -R soapui:soapui $SOAPUI_PRJ
RUN find $SOAPUI_PRJ -type d -execdir chmod 770 {} \;
RUN find $SOAPUI_PRJ -type f -execdir chmod 660 {} \;


############################################
# Start SoapUI mock service runner
############################################

#ENTRYPOINT ["/docker-entrypoint.sh"]
RUN chmod +x /docker-entrypoint.sh
CMD ["/docker-entrypoint.sh"]

EXPOSE $MOCK_SERVICE_PORT
