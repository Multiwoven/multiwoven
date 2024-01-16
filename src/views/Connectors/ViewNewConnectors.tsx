import TopBar from "@/components/TopBar";
import { getConnectorsDefintions } from "@/services/common";
import { Box, Flex, Image, SimpleGrid } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

export const ViewNewConnectors = (props: any) => {
  const [connectorsSpecs, setConnectorsSpecs] = useState<Array<any>>([]);

  useEffect(() => {
    async function fetchData() {
      const connectorType =
        props.connectorType === "sources" ? "source" : "destination";
      console.log(props.connectorType, connectorType);

      const response = await getConnectorsDefintions(connectorType);
      console.log(response);
      setConnectorsSpecs(response?.data);
    }

    fetchData();
  }, []);

  if (!connectorsSpecs) {
    return <>LOADING</>;
  }

  const connectorCategory =
    props.connectorType === "sources" ? "source" : "destination";

  return (
    <Box
      display="flex"
      width="full"
      margin={8}
      flexDir="column"
      backgroundColor={""}
    >
      <Box padding="8" bgColor={""}>
        {/* <TopBar
          connectorType={props.connectorType}
          buttonText={connectorCategory}
          buttonOnClick={() => console.log("new")}
          buttonVisible={false}
        /> */}
        <SimpleGrid columns={3} spacing={4}>
          {connectorsSpecs.map((item, index) => (
            <Link
              to={
                "config?type=" +
                connectorCategory +
                "&name=" +
                item.name.toLowerCase()
              }
              key={index}
            >
              <Box
                bgColor="gray.100"
                _hover={{ bgColor: "gray.200" }}
                shadow="sm"
                p={5}
                borderRadius={12}
              >
                <Flex dir="row" justifyContent="left" justifyItems="left">
                  <Image
                    src={"/icons/" + item.icon}
                    // alt={`${item.name} Icon`}
                    height="8"
                    w="min"
                    mr={3}
                  />
                  <h1>{item.name}</h1>
                </Flex>
              </Box>
            </Link>
          ))}
        </SimpleGrid>
      </Box>
    </Box>
  );
};
