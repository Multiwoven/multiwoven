import { Input } from "@chakra-ui/react";
import { useContext } from "react";
import { SteppedFormContext } from "../SteppedForm/SteppedForm";

const FirstForm = () => {
  const { dispatch } = useContext(SteppedFormContext);

  const handleOnChange = () => {
    dispatch({
      type: "UPDATE_CURRENT_FORM",
      payload: {
        data: "some random data",
      },
    });
  };

  return (
    <div>
      <Input placeholder="Name" onChange={handleOnChange} />
    </div>
  );
};

export default FirstForm;
