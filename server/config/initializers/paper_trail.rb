# Switch to JSON Serializer, instead of default YAML.
# YAML deserialization raises security-related issues,
# specifically when deserializing TimeWithZone, TimeZone, Date, Time, etc.
PaperTrail.serializer = PaperTrail::Serializers::JSON
