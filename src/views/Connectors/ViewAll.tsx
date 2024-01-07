import { Box } from "@chakra-ui/react";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";
import ConnectorTable from "@/components/ConnectorTable";
import { useEffect, useState } from "react";
import getUserConnectors from "@/services/user-connectors";

const ViewAll = ( props:any ) => {
    // console.log(props);
    const [ payload, setPayload ] = useState<any>();

    const navigate = useNavigate();

    function navToPage(route:string) {
        navigate(route)
    }

    // const samplePayload = [
    //     {
    //       "id": 1,
    //       "name": "Sample connector",
    //       "connector_type": "destination",
    //       "workspace_id": "1",
    //       "status": "active",
    //       "updated_at": "timestamp",
    //       "configuration": {
    //         "public_api_key": "config_v",
    //         "private_api_key": "config_value_2"
    //       },
    //       "connector_definiton": {
    //         "name": "Snowflake",
    //         "connector_type": "source",
    //         "connector_subtype": "database",
    //         "documentation_url": "https://docs.mutliwoven.com",
    //         "github_issue_label": "source-snowflake",
    //         "icon": "icons/snowflake.png",
    //         "license": "MIT",
    //         "release_stage": "alpha",
    //         "support_level": "community",
    //         "tags": [
    //           "language:ruby",
    //           "multiwoven"
    //         ]
    //       }
    //     }
    // ]

    useEffect(() => { 
      async function fetchData() {
        const response = await getUserConnectors();
        console.log(response);
        setPayload(response) // Uncomment and use this line if you have a state setter for payload
      }

      fetchData();
    } , []);

    if (!payload) {
      return(
        <></>
      )
    }

    return(
        <>
            <Box display='flex' width="full" height="100vh" margin={8} flexDir='column' backgroundColor={""}>
                <Box padding="8" bgColor={''}>
                    {/* <h1>{ props.connectorType }s</h1> */}
                    <TopBar connectorType={ props.connectorType } buttonText={ props.connectorType } buttonOnClick={() => navToPage('new')}  />
                    {!payload ? <></> : payload.length>0 ? <ConnectorTable payload={payload} /> : <></>  }
                </Box>
            </Box>
        </>
    )
}

export default ViewAll;