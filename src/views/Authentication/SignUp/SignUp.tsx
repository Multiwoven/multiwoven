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
import { signUp } from "@/services/authentication";
import Cookies from "js-cookie";
import titleCase from "@/utils/TitleCase";
import AuthFooter from "../AuthFooter";

const SignUpSchema = Yup.object().shape({
  company_name: Yup.string().required("Company name is required"),
  name: Yup.string().required("Name is required"),
  email: Yup.string()
    .email("Invalid email address")
    .required("Email is required"),
  password: Yup.string()
    .min(8, "Password must be at least 8 characters")
    .required("Password is required"),
  password_confirmation: Yup.string()
    .oneOf([Yup.ref("password"), ""], "Passwords must match")
    .required("Confirm Password is required"),
});

interface SignUpFormProps {
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
}: SignUpFormProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <FormLabel htmlFor={name}>{label}</FormLabel>
    <Input
      variant="outline"
      placeholder={placeholder}
      color="black.600"
      type={type}
      {...getFieldProps(name)}
    />
    <Text size="xs" color="red.500">
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);

type SignUpErrors = {
  source: {
    [key: string]: string;
  };
};

const SignUp = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const toast = useToast();

  const handleSubmit = async (values: any) => {
    setSubmitting(true);
    const result = await signUp(values);

    if (result.data?.attributes) {
      const token = result.data.attributes.token;
      Cookies.set("authToken", token, {
        secure: true,
        sameSite: "Lax",
      });
      result.data.attributes.token;
      setSubmitting(false);
      toast({
        title: "Account created.",
        status: "success",
        duration: 3000,
        isClosable: true,
        position: "bottom-right",
      });
      navigate("/");
    } else {
      setSubmitting(false);
      result.data?.errors?.map((error: SignUpErrors) => {
        Object.keys(error.source).map((error_key) => {
          toast({
            title: titleCase(error_key) + " " + error.source[error_key],
            status: "warning",
            duration: 5000,
            isClosable: true,
            position: "bottom-right",
            colorScheme: "red",
          });
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
            name: "",
            email: "",
            password: "",
            password_confirmation: "",
          }}
          onSubmit={(values) => handleSubmit(values)}
          validationSchema={SignUpSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Container width={{ base: "400px", sm: "500px" }} py="6">
                <Stack spacing="8">
                  <Stack spacing="6" alignItems={"center"}>
                    <img src={MultiwovenIcon} width={55} />
                    <Stack spacing="3" textAlign="center">
                      <Heading size="sm">Create an account</Heading>
                      <HStack spacing={1} justify="center">
                        <Text color="black.500" size="sm">
                          Already have an account?
                        </Text>
                        <Link to="/sign-in">
                          <Text color="brand.500" size="sm">
                            Sign In
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
                          label="Company Name"
                          placeholder="Enter company name"
                          name="company_name"
                          type="text"
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <FormField
                          label="Name"
                          placeholder="Enter name"
                          name="name"
                          type="text"
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
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
                          placeholder="Choose password"
                          name="password"
                          type="password"
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <FormField
                          label="Confirm Password"
                          placeholder="Confirm password"
                          name="password_confirmation"
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
                          loadingText="Signing Up"
                          variant="solid"
                          width="full"
                        >
                          Sign up
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

export default SignUp;
