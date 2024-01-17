import { useParams } from "react-router-dom";

const Setup = (): JSX.Element => {
  const { setupType } = useParams();
  return <div>{setupType}</div>;
};

export default Setup;
