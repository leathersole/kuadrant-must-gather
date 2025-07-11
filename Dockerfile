FROM quay.io/openshift/origin-must-gather:4.16

ENV KUADRANT_MUSTGATHER_VERSION=0.0.2

# Save original gather script
RUN mv /usr/bin/gather /usr/bin/gather_original

# Use our gather script in place of the original one
COPY gather_kuadrant.sh /usr/bin/gather
COPY version /usr/bin/version

# Make it executable
RUN chmod +x /usr/bin/gather

ENTRYPOINT /usr/bin/gather
