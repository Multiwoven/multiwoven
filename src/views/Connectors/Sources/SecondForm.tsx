import { Input } from "@chakra-ui/react";
import { useContext } from "react";
import { SteppedFormContext } from "../SteppedForm/SteppedForm";

const SecondForm = () => {
  const { state } = useContext(SteppedFormContext);
  console.log(state);
  return (
    <div>
      <Input placeholder="Phone Number" />
      <Input placeholder="Email" />
    </div>
  );
};

export default SecondForm;
