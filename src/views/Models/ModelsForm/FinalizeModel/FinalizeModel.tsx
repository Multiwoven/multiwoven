import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import {
	Box,
	Flex,
	FormControl,
	FormLabel,
	Input,
	Select,
	Text,
	Textarea,
	VStack,
} from "@chakra-ui/react";
import { Formik, Form, Field, ErrorMessage } from "formik";
import { useContext } from "react";
import * as Yup from "yup";

const FinalizeModel = (): JSX.Element => {
	const { state } = useContext(SteppedFormContext);
	console.log(state);

	// Yup schema
	const validationSchema = Yup.object().shape({
		modelName: Yup.string().required("Model name is required"),
		description: Yup.string(),
		primaryKey: Yup.string().required("Primary Key is required"),
	});

	return (
		<>
			<Box w='5xl' mx='auto' bgColor='gray.100' px={6} py={4}>
				<Text mb={6} fontWeight='bold'>
					Finalize settings for this model
				</Text>
				<Formik
					initialValues={{
						modelName: "",
						description: "",
						primaryKey: "",
					}}
					validationSchema={validationSchema}
					onSubmit={(values, { setSubmitting }) => {
						setTimeout(() => {
							alert(JSON.stringify(values, null, 2));
							setSubmitting(false);
						}, 500);
					}}
				>
					{({}) => (
						<Form>
							<VStack spacing={5}>
								<FormControl>
									<FormLabel
										htmlFor='modelName'
										fontSize='sm'
										fontWeight='semibold'
									>
										Model Name
									</FormLabel>
									<Field
										as={Input}
										id='modelName'
										name='modelName'
										placeholder='Enter a name'
										bgColor='white'
									/>
									<Text color='red.500' fontSize='sm'>
										<ErrorMessage name='modelName' />
									</Text>
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
									<Field
										as={Textarea}
										id='description'
										name='description'
										placeholder='Enter a description'
										bgColor='white'
									/>
								</FormControl>
								<FormControl>
									<FormLabel
										htmlFor='primaryKey'
										fontSize='sm'
										fontWeight='bold'
									>
										Primary Key
									</FormLabel>
									<Field
										as={Select}
										placeholder='Select Primary Key'
										name='primaryKey'
										bgColor='white'
										w='lg'
									>
										<option value='option1'>Option 1</option>
										<option value='option2'>Option 2</option>
										<option value='option3'>Option 3</option>
									</Field>
									<Text color='red.500' fontSize='sm'>
										<ErrorMessage name='primaryKey' />
									</Text>
								</FormControl>
							</VStack>
						</Form>
					)}
				</Formik>
			</Box>
		</>
	);
};

export default FinalizeModel;
