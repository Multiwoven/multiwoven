import { Button, Flex, Heading } from "@chakra-ui/react";
import { AddIcon } from '@chakra-ui/icons';
import { ConnectorType } from "../commonTypes";
import titleCase from "@/utils/TitleCase";



const TopBar = ( props:ConnectorType ) => {
    return (
        <>
            <Flex justifyContent="space-between" alignItems="center" p={4} borderBottom={"1px"} borderColor='gray.300' mb={4}>
                <Heading size="md">{ titleCase(props.connectorType) }</Heading>
                <Button leftIcon={<AddIcon />} backgroundColor="mw_orange" color="white" fontSize={16} size='sm' onClick={ props.buttonOnClick } >
                   Add New { titleCase(props.buttonText) }
                </Button>
            </Flex>
        </>
    )
}

export default TopBar;