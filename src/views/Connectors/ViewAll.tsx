import { Box } from "@chakra-ui/react";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";

const ViewAll = ( props:any ) => {
    console.log(props);

    const navigate = useNavigate();

    function navToPage(route:string) {
        navigate(route)
    }

    
    return(
        <>
            <Box display='flex' width="full" height="100vh" margin={8} flexDir='column' backgroundColor={""}>
                <Box padding="8" bgColor={''}>
                    {/* <h1>{ props.connectorType }s</h1> */}
                    <TopBar connectorType={ props.connectorType } buttonText={ props.connectorType } buttonOnClick={() => navToPage('new')}  />
                </Box>
            </Box>
        </>
    )
}

export default ViewAll;