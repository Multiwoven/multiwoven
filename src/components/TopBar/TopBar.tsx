import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, Button, Flex } from "@chakra-ui/react";
import { AddIcon } from '@chakra-ui/icons';
import { ConnectorType } from "../commonTypes";
import titleCase from "@/utils/TitleCase";



const TopBar = ( props:ConnectorType ) => {
    return (
        <>
            <Flex justifyContent="space-between" alignItems="center" p={4} borderBottom={"1px"} borderColor='gray.300' mb={4}>
                <Breadcrumb>
                    <BreadcrumbItem>
                        <BreadcrumbLink href="#">Home</BreadcrumbLink>
                    </BreadcrumbItem>
                    <BreadcrumbItem>
                        <BreadcrumbLink href="#">{ props.connectorType }</BreadcrumbLink>
                    </BreadcrumbItem>
                </Breadcrumb>
                <Button leftIcon={<AddIcon />} backgroundColor="mw_orange" color="white" fontSize={16} size='sm' onClick={ props.buttonOnClick } >
                    { titleCase(props.buttonText) }
                </Button>
            </Flex>
        </>
    )
}

export default TopBar;