import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import {
	Box,
	Flex,
	FormControl,
	FormLabel,
	Input,
	Select,
	Stack,
	Text,
	Textarea,
    VStack,
} from "@chakra-ui/react";
import { Form, Formik, FormikHelpers } from "formik";
import { useContext } from "react";

const FinalizeModel = (): JSX.Element => {
	interface Values {
		firstName: string;
		lastName: string;
		email: string;
	}

    const { state } = useContext(SteppedFormContext);

    console.log(state);
    

	return (
		<>
			<Box w='5xl' mx='auto' bgColor='gray.100' px={6} py={4}>
				<Text mb={6} fontWeight='bold'>Finalize settings for this model</Text>
				<Formik
					initialValues={{
						firstName: "",
						lastName: "",
						email: "",
					}}
					onSubmit={(
						values: Values,
						{ setSubmitting }: FormikHelpers<Values>
					) => {
						setTimeout(() => {
							alert(JSON.stringify(values, null, 2));
							setSubmitting(false);
						}, 500);
					}}
				>
					<Form>
						<VStack spacing={5}>
							<FormControl>
								<FormLabel htmlFor='modelName' fontSize='sm' fontWeight='semibold'>Model Name</FormLabel>
								<Input
									id='modelName'
									name='modelName'
									placeholder='Enter a name'
                                    bgColor='white'
								/>
							</FormControl>
							<FormControl>
								<FormLabel htmlFor='description' fontWeight='bold'>
									<Flex alignItems='center' fontSize='sm'>
										Description{" "}
										<Text ml={2} fontSize='xs'>
											{" "}
											(optional)
										</Text>
									</Flex>
								</FormLabel>
								<Textarea
									id='description'
									name='description'
									placeholder='Enter a description'
                                    bgColor='white'
								/>
							</FormControl>
                            <FormControl>
							<FormLabel htmlFor='primaryKey' fontSize='sm' fontWeight='bold'>Primary Key</FormLabel>
							<Select placeholder='Select Primary Key' bgColor='white' w='lg'>
								<option value='option1'>Option 1</option>
								<option value='option2'>Option 2</option>
								<option value='option3'>Option 3</option>
							</Select>
                            </FormControl>
						</VStack>
					</Form>
				</Formik>
			</Box>
		</>
	);
};

export default FinalizeModel;
