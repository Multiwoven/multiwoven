import { useState } from "react";
import {
  Formik,
  Form,
  ErrorMessage,
  FormikTouched,
  FormikErrors,
  FieldInputProps,
} from "formik";
import * as Yup from "yup";
import { Link, useNavigate } from "react-router-dom";
import {
  Box,
  Button,
  FormControl,
  Input,
  Heading,
  Text,
  Container,
  Stack,
  FormLabel,
  useToast,
  Flex,
  HStack,
} from "@chakra-ui/react";
import MultiwovenIcon from "@/assets/images/icon.png";
import {
  SignInErrorResponse,
  SignInPayload,
  signIn,
} from "@/services/authentication";
import Cookies from "js-cookie";
import titleCase from "@/utils/TitleCase";
import AuthFooter from "../AuthFooter";

const SignInSchema = Yup.object().shape({
  email: Yup.string()
    .email("Invalid email address")
    .required("Email is required"),
  password: Yup.string()
    .min(8, "Password must be at least 8 characters")
    .required("Password is required"),
});

interface SignInFormProps {
  label: string;
  name: string;
  type: string;
  placeholder?: string;
  getFieldProps: (
    nameOrOptions:
      | string
      | {
          name: string;
          value?: any;
          onChange?: (e: any) => void;
          onBlur?: (e: any) => void;
        }
  ) => FieldInputProps<any>;
  touched: FormikTouched<any>;
  errors: FormikErrors<any>;
}

const FormField = ({
  label,
  name,
  type,
  getFieldProps,
  touched,
  errors,
  placeholder,
}: SignInFormProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <FormLabel htmlFor={name} fontSize="xs" fontWeight="medium">
      {label}
    </FormLabel>
    <Input
      variant="outline"
      placeholder={placeholder}
      _placeholder={{ color: "black.100" }}
      type={type}
      {...getFieldProps(name)}
      fontSize="sm"
      color="black.500"
    />
    <Text size="xs" color="red.500" mt={2}>
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);

const SignIn = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const toast = useToast();

  const handleSubmit = async (values: SignInPayload) => {
    setSubmitting(true);
    const result = await signIn(values);

    if (result.data?.attributes) {
      const token = result.data.attributes.token;
      Cookies.set("authToken", token, {
        secure: true,
        sameSite: "Lax",
      });
      result.data.attributes.token;
      setSubmitting(false);
      toast({
        title: "Signed In",
        status: "success",
        duration: 3000,
        isClosable: true,
        position: "bottom-right",
      });
      navigate("/setup/sources");
    } else {
      setSubmitting(false);
      result.data?.errors?.map((error: SignInErrorResponse) => {
        toast({
          title: titleCase(error.detail),
          status: "warning",
          duration: 5000,
          isClosable: true,
          position: "bottom-right",
          colorScheme: "red",
        });
      });
    }
  };

  return (
    <>
      <Flex
        justify="center"
        w="100%"
        minHeight="90vh"
        alignItems="center"
        overflowY="auto"
      >
        <Formik
          initialValues={{
            email: "",
            password: "",
          }}
          onSubmit={(values) => handleSubmit(values)}
          validationSchema={SignInSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Container width={{ base: "400px", sm: "500px" }} py="6">
                <Stack spacing="8">
                  <Stack spacing="6" alignItems={"center"}>
                    <img src={MultiwovenIcon} width={55} />
                    <Stack spacing="3" textAlign="center">
                      <Heading size="sm">Sign in to your account</Heading>
                      <HStack spacing={1} justify="center">
                        <Text color="black.500" size="sm">
                          Don't have an account?{" "}
                        </Text>
                        <Link to="/sign-up">
                          <Text color="brand.500" size="sm">
                            Sign Up
                          </Text>
                        </Link>
                      </HStack>
                    </Stack>
                  </Stack>
                  <Box
                    padding="20px"
                    borderRadius="xl"
                    border="2px"
                    borderColor="gray.400"
                  >
                    <Stack spacing="6">
                      <Stack spacing="5">
                        <FormField
                          label="Email"
                          placeholder="Enter email"
                          name="email"
                          type="text"
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <FormField
                          label="Password"
                          placeholder="Enter password"
                          name="password"
                          type="password"
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                      </Stack>
                      <Stack spacing="6">
                        <Button
                          type="submit"
                          isLoading={submitting}
                          loadingText="Signing In"
                          variant="solid"
                          width="full"
                        >
                          Sign In
                        </Button>
                      </Stack>
                    </Stack>
                  </Box>
                </Stack>
              </Container>
            </Form>
          )}
        </Formik>
      </Flex>
      <AuthFooter />
    </>
  );
};

export default SignIn;
