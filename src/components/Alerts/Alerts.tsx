import { AlertData } from "../commonTypes";
import {
    Alert,
    AlertIcon,
    AlertTitle,
    AlertDescription,
  } from '@chakra-ui/react'
  
export let alertMessage:AlertData = {
    status: undefined,
    title: '',
    description: ''
}

function AlertPopUp({ status, title, description }:AlertData) {
    return(
        <Alert status={status}>
            <AlertIcon />
            <AlertTitle>{title}</AlertTitle>
            <AlertDescription>{description}</AlertDescription>
        </Alert>
    )
}

export default AlertPopUp;