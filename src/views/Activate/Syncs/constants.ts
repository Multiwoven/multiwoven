import { Step } from "@/components/Breadcrumbs/types";
import { SyncColumnEntity } from "./types";

export const SYNC_TABLE_COLUMS: SyncColumnEntity[] = [
  {
    key: "model",
    name: "Model",
  },
  {
    key: "destination",
    name: "Destination",
  },
  {
    key: "lastUpdated",
    name: "Last Updated",
  },
  {
    key: "status",
    name: "Status",
  },
];

export const EDIT_SYNC_FORM_STEPS: Step[] = [
  {
    name: "Syncs",
    url: "/activate/syncs",
  },
  {
    name: "Sync",
    url: "",
  },
];
