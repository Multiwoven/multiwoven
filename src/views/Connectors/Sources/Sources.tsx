import SteppedForm from "../SteppedForm";
import FirstForm from "./FirstForm";
import SecondForm from "./SecondForm";

const Sources = () => {
  const steps = [
    {
      formKey: "first",
      name: "First Form",
      component: <FirstForm />,
    },
    {
      formKey: "second",
      name: "Second Form",
      component: <SecondForm />,
    },
  ];

  return <SteppedForm steps={steps} />;
};

export default Sources;
