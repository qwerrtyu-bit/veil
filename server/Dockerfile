FROM dart:stable
WORKDIR /app
COPY signal_server.dart .
COPY certs/ ./certs/
RUN dart pub global activate webdev
EXPOSE 8443
CMD ["dart", "signal_server.dart"]