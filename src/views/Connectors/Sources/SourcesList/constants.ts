import { ConnectorTypes } from "./types";

export const CONNECTORS: Record<ConnectorTypes, Record<string, string>> = {
  source: {
    name: "Source",
    key: "source",
  },
  destination: {
    name: "Destinations",
    key: "destination",
  },
  model: {
    name: "Destination",
    key: "model",
  },
};
