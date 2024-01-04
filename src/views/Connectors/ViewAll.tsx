import { Box, Breadcrumb, BreadcrumbItem, BreadcrumbLink, Button, Container, Flex, HStack } from "@chakra-ui/react";
import { AddIcon } from '@chakra-ui/icons';

const ViewAll = ( props:any ) => {
    console.log(props);
    
    return(
        <>
            <Box display='flex' width="full" height="100vh" flexDir='column' backgroundColor={""}>
                <Box padding="8" bgColor={''}>
                    <h1>{ props.connectorType }s</h1>
                    <Flex justifyContent="space-between" alignItems="center" p={4} borderBottom={"1px"} borderColor='gray.300' mb={4}>
                        <Breadcrumb>
                            <BreadcrumbItem>
                                <BreadcrumbLink href="#">Home</BreadcrumbLink>
                            </BreadcrumbItem>
                            <BreadcrumbItem>
                                <BreadcrumbLink href="#">{ props.connectorType }</BreadcrumbLink>
                            </BreadcrumbItem>
                        </Breadcrumb>
                        <Button leftIcon={<AddIcon />} backgroundColor="mw_orange" color="white" fontSize={16} size='sm' padding >
                            Source
                        </Button>
                    </Flex>
                </Box>
            </Box>
        </>
    )
}

export default ViewAll;