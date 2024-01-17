import SteppedForm from "../../SteppedForm";
import SecondForm from "../SecondForm";
import SelectDataSourceForm from "../SelectDataSourceForm";

const Sources = () => {
  const steps = [
    {
      formKey: "first",
      name: "Select a data source",
      component: <SelectDataSourceForm />,
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
