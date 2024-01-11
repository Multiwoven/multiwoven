import { Box } from "@chakra-ui/react";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";
import ConnectorTable from "@/components/ConnectorTable";
import { useEffect, useState } from "react";
import { getUserConnectors } from "@/services/common";
import NoConnectors from "./NoConnectors";

const ViewAll = (props: any) => {
  // console.log(props);
  const [payload, setPayload] = useState<any>();
  const navigate = useNavigate();

  function navToPage(route: string) {
    navigate(route);
  }

  let connectorName: string = "";
  const connectorType = props.connectorType;

  if (connectorType === "sources") {
    connectorName = "Source";
  } else if (connectorType === "destinations") {
    connectorName = "Destination";
  }

  const samplePayload = [
    {
      id: 1,
      name: "Sample connector",
      connector_type: "source",
      workspace_id: "1",
      status: "active",
      updated_at: "timestamp",
      configuration: {
        public_api_key: "config_v",
        private_api_key: "config_value_2",
      },
      connector_definiton: {
        name: "Snowflake",
        connector_type: "source",
        connector_subtype: "database",
        documentation_url: "https://docs.mutliwoven.com",
        github_issue_label: "source-snowflake",
        icon: "icons/snowflake.png",
        license: "MIT",
        release_stage: "alpha",
        support_level: "community",
        tags: ["language:ruby", "multiwoven"],
      },
    },
  ];

  useEffect(() => {
    async function fetchData() {
      const response = await getUserConnectors(connectorName);
      // console.log(response);
      if (response.success === false) {
        setPayload([])
      } else {
        setPayload(response.data);
      }
    }

    fetchData();
  }, []);

  if (!payload) {
    return <></>;
  }

  // console.log("Payload:",payload);
  

  return (
    <>
      <Box
        display="flex"
        width="full"
        margin={8}
        flexDir="column"
        backgroundColor={""}
      >
        <Box padding="8" bgColor={""}>
          {/* <h1>{ props.connectorType }s</h1> */}
          <TopBar
            connectorType={props.connectorType}
            buttonText={props.connectorType === "sources" ? "source" : "destination" }
            buttonOnClick={() => navToPage("new")}
            buttonVisible={true}
          />
          {!payload ? (
            <></>
          ) : payload.length > 0 ? (
            <ConnectorTable payload={payload} />
          ) : (
            <NoConnectors connectorType={connectorName.toLowerCase()} />
          )}
        </Box>
      </Box>
    </>
  );
};

export default ViewAll;
